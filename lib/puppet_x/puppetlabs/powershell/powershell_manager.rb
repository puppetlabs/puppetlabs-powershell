require 'rexml/document'
require 'securerandom'
require 'open3'
require 'base64'
require 'ffi' if Puppet::Util::Platform.windows?

module PuppetX
  module PowerShell
    class PowerShellManager
      extend FFI::Library if Puppet::Util::Platform.windows?

      @@instances = {}

      def self.instance(cmd)
        @@instances[:cmd] ||= PowerShellManager.new(cmd)
      end

      def self.win32console_enabled?
        @win32console_enabled ||= defined?(Win32) &&
          defined?(Win32::Console) &&
          Win32::Console.class == Class
      end

      def self.supported?
        Puppet::Util::Platform.windows? && !win32console_enabled?
      end

      def initialize(cmd)
        @stdin, @stdout, @stderr, @ps_process = Open3.popen3(cmd)

        Puppet.debug "#{Time.now} #{cmd} is running as pid: #{@ps_process[:pid]}"

        init_ready_event_name =  "Global\\#{SecureRandom.uuid}"
        init_ready_event = self.class.create_event(init_ready_event_name)

        code = make_ps_init_code(init_ready_event_name)
        out, err = exec_read_result(code, init_ready_event)

        Puppet.debug "#{Time.now} PowerShell initialization complete for pid: #{@ps_process[:pid]}"

        at_exit { exit }
      end

      def execute(powershell_code, timeout_ms = 300 * 1000)
        output_ready_event_name =  "Global\\#{SecureRandom.uuid}"
        output_ready_event = self.class.create_event(output_ready_event_name)

        code = make_ps_code(powershell_code, output_ready_event_name, timeout_ms)

        out, err = exec_read_result(code, output_ready_event)

        # Powershell adds in newline characters as it tries to wrap output around the display (by default 80 chars).
        # This behavior is expected and cannot be changed, however it corrupts the XML e.g. newlines in the middle of
        # element names; So instead, part of the XML is Base64 encoded prior to being put on STDOUT and in ruby all
        # newline characters are stripped. Then where required decoded from Base64 back into text
        out = REXML::Document.new(out.gsub(/\n/,""))

        # picks up exitcode, errormessage and stdout
        props = REXML::XPath.each(out, '//Property').map do |prop|
          name = prop.attributes['Name']
          value = (name == 'exitcode') ?
            prop.text.to_i :
            (prop.text.nil? ? nil : Base64.decode64(prop.text))
          [name.to_sym, value]
        end
        props << [:stderr, err]

        Hash[ props ]
      ensure
        CloseHandle(output_ready_event) if output_ready_event
      end

      def exit
        Puppet.debug "PowerShellManager exiting..."
        @stdin.puts "\nexit\n"
        @stdin.close
        @stdout.close
        @stderr.close

        exit_msg = "PowerShell process did not terminate in reasonable time"
        begin
          Timeout.timeout(3) do
            Puppet.debug "Awaiting PowerShell process termination..."
            @exit_status = @ps_process.value
          end
        rescue Timeout::Error
        end

        exit_msg = "PowerShell process exited: #{@exit_status}" if @exit_status
        Puppet.debug(exit_msg)
        if @ps_process.alive?
          Puppet.debug("Forcefully terminating PowerShell process.")
          Process.kill('KILL', @ps_process[:pid])
        end
      end

      def template_path
        File.expand_path('../../../templates', __FILE__)
      end

      def make_ps_init_code(init_ready_event_name)
        template_file = File.new(template_path + "/init_ps.ps1.erb").read
        template = ERB.new(template_file, nil, '-')
        template.result(binding)
      end

      def make_ps_code(powershell_code, output_ready_event_name, timeout_ms = 300 * 1000)
        <<-CODE
$params = @{
  Code = @'
#{powershell_code}
'@
  EventName = "#{output_ready_event_name}"
  TimeoutMilliseconds = #{timeout_ms}
}

Invoke-PowerShellUserCode @params

# always need a trailing newline to ensure PowerShell parses code

        CODE
      end

      private

      def self.is_readable?(stream, timeout = 0.5)
        read_ready = IO.select([stream], [], [], timeout)
        read_ready && stream == read_ready[0][0]
      end

      # copied directly from Puppet 3.7+ to support Puppet 3.5+
      def self.wide_string(str)
        # ruby (< 2.1) does not respect multibyte terminators, so it is possible
        # for a string to contain a single trailing null byte, followed by garbage
        # causing buffer overruns.
        #
        # See http://svn.ruby-lang.org/cgi-bin/viewvc.cgi?revision=41920&view=revision
        newstr = str + "\0".encode(str.encoding)
        newstr.encode!('UTF-16LE')
      end

      NULL_HANDLE = 0
      WIN32_FALSE = 0

      def self.create_event(name, manual_reset = false, initial_state = false)
        handle = NULL_HANDLE

        str = wide_string(name)
        # :uchar because 8 bits per byte
        FFI::MemoryPointer.new(:uchar, str.bytesize) do |name_ptr|
          name_ptr.put_array_of_uchar(0, str.bytes.to_a)

          handle = CreateEventW(FFI::Pointer::NULL,
            manual_reset ? 1 : WIN32_FALSE,
            initial_state ? 1 : WIN32_FALSE,
            name_ptr)

          if handle == NULL_HANDLE
            msg = "Failed to create new event #{name}"
            raise Puppet::Util::Windows::Error.new(msg)
          end
        end

        handle
      end

      WAIT_ABANDONED = 0x00000080
      WAIT_OBJECT_0 = 0x00000000
      WAIT_TIMEOUT = 0x00000102
      WAIT_FAILED = 0xFFFFFFFF

      def self.wait_on(wait_object, timeout_ms = 50)
        wait_result = WaitForSingleObject(wait_object, timeout_ms)

        case wait_result
        when WAIT_OBJECT_0
          Puppet.debug "Wait object signaled"
        when WAIT_TIMEOUT
          Puppet.debug "Waited #{timeout_ms} milliseconds..."
        # only applicable to mutexes - should never happen here
        when WAIT_ABANDONED
          msg = 'Catastrophic failure: wait object in inconsistent state'
          raise Puppet::Util::Windows::Error.new(msg)
        when WAIT_FAILED
          msg = 'Catastrophic failure: waiting on object to be signaled'
          raise Puppet::Util::Windows::Error.new(msg)
        end

        wait_result
      end

      def write_stdin(input)
        @stdin.puts(input)
      rescue => e
        msg = "Error writing STDIN / reading STDOUT: #{e}"
        raise Puppet::Util::Windows::Error.new(msg)
      end

      def drain_pipe(pipe, iterations = 10)
        output = []
        0.upto(iterations) do
          break if !self.class.is_readable?(pipe, 0.1)
          l = pipe.gets
          Puppet.debug "#{Time.now} PIPE> #{l}"
          output << l
        end
        output
      end

      def read_stdout(output_ready_event, wait_interval_ms = 50)
        output = []
        errors = []
        waited = 0

        # drain the pipe while waiting for the event signal
        while WAIT_TIMEOUT == self.class.wait_on(output_ready_event, wait_interval_ms)
          # TODO: While this does ensure that both pipes have been
          # drained it can block on either longer than necessary or
          # deadlock waiting for one or the other to finish. The correct
          # way to deal with this is to drain each pipe from seperate threads
          # but time ran on in this implementation and this will be addressed soon
          output << drain_pipe(@stdout)
          errors << drain_pipe(@stderr)
          waited += wait_interval_ms
        end

        Puppet.debug "Waited #{waited} total milliseconds."

        # once signaled, ensure everything has been drained
        output << drain_pipe(@stdout, 1000)
        errors << drain_pipe(@stderr, 1000)

        errors = errors.reject { |e| e.empty? }

        return output.join(''), errors
      rescue => e
        msg = "Error reading PIPE: #{e}"
        raise Puppet::Util::Windows::Error.new(msg)
      end

      def exec_read_result(powershell_code, output_ready_event)
        write_stdin(powershell_code)
        read_stdout(output_ready_event)
      end

      if Puppet::Util::Platform.windows?
        private

        ffi_convention :stdcall

        # NOTE: Puppet 3.7+ contains FFI typedef helpers, but to support 3.5
        # use the unaliased native FFI names for parameter types

        # https://msdn.microsoft.com/en-us/library/windows/desktop/ms682396(v=vs.85).aspx
        # HANDLE WINAPI CreateEvent(
        #   _In_opt_ LPSECURITY_ATTRIBUTES lpEventAttributes,
        #   _In_     BOOL                  bManualReset,
        #   _In_     BOOL                  bInitialState,
        #   _In_opt_ LPCTSTR               lpName
        # );
        ffi_lib :kernel32
        attach_function :CreateEventW, [:pointer, :int32, :int32, :buffer_in], :uintptr_t

        # http://msdn.microsoft.com/en-us/library/windows/desktop/ms724211(v=vs.85).aspx
        # BOOL WINAPI CloseHandle(
        #   _In_  HANDLE hObject
        # );
        ffi_lib :kernel32
        attach_function :CloseHandle, [:uintptr_t], :int32

        # http://msdn.microsoft.com/en-us/library/windows/desktop/ms687032(v=vs.85).aspx
        # DWORD WINAPI WaitForSingleObject(
        #   _In_  HANDLE hHandle,
        #   _In_  DWORD dwMilliseconds
        # );
        ffi_lib :kernel32
        attach_function :WaitForSingleObject,
          [:uintptr_t, :uint32], :uint32
      end
    end
  end
end
