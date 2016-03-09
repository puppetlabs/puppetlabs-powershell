require 'securerandom'
require 'open3'
require 'ffi' if Puppet::Util::Platform.windows?

module PuppetX
  module Dsc
    class PowerShellManager
      extend FFI::Library if Puppet::Util::Platform.windows?

      @@instances = {}

      def self.instance(cmd)
        @@instances[:cmd] ||= PowerShellManager.new(cmd)
      end

      def initialize(cmd)
        @stdin, @stdout, @ps_process = Open3.popen2(cmd)

        Puppet.debug "#{Time.now} #{cmd} is running as pid: #{@ps_process[:pid]}"

        at_exit { exit }
      end

      def execute(powershell_code, timeout_ms = 300 * 1000)
        output_ready_event_name =  "Global\\#{SecureRandom.uuid}"
        output_ready_event = self.class.create_event(output_ready_event_name)

        code = make_ps_code(powershell_code, output_ready_event_name, timeout_ms)
        out = exec_read_result(code, output_ready_event)

        { :stdout => out }
      ensure
        CloseHandle(output_ready_event) if output_ready_event
      end

      def exit
        Puppet.debug "PowerShellManager exiting..."
        @stdin.puts "\nexit\n"
        @stdin.close
        @stdout.close

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
        File.expand_path('../../templates', __FILE__)
      end

      def make_ps_code(powershell_code, output_ready_event_name, timeout_ms = 300 * 1000)
        template_file = File.new(template_path + "/invoke_ps_command.erb").read
        template = ERB.new(template_file, nil, '-')
        template.result(binding)
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

      def drain_stdout
        output = []
        while self.class.is_readable?(@stdout, 0.1) do
          l = @stdout.gets
          Puppet.debug "#{Time.now} STDOUT> #{l}"
          output << l
        end
        output
      end

      def read_stdout(output_ready_event, wait_interval_ms = 50)
        output = []
        waited = 0

        # drain the pipe while waiting for the event signal
        while WAIT_TIMEOUT == self.class.wait_on(output_ready_event, wait_interval_ms)
          output << drain_stdout
          waited += wait_interval_ms
        end

        Puppet.debug "Waited #{waited} total milliseconds."

        # once signaled, ensure everything has been drained
        output << drain_stdout

        output.join('')
      rescue => e
        msg = "Error reading STDOUT: #{e}"
        raise Puppet::Util::Windows::Error.new(msg)
      end

      def exec_read_result(powershell_code, output_ready_event)
        write_stdin(powershell_code)
        read_stdout(output_ready_event)
      end

      if Puppet::Util::Platform.windows?
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
        attach_function_private :CreateEventW, [:pointer, :int32, :int32, :buffer_in], :handle

        # http://msdn.microsoft.com/en-us/library/windows/desktop/ms724211(v=vs.85).aspx
        # BOOL WINAPI CloseHandle(
        #   _In_  HANDLE hObject
        # );
        ffi_lib :kernel32
        attach_function_private :CloseHandle, [:handle], :int32

        # http://msdn.microsoft.com/en-us/library/windows/desktop/ms687032(v=vs.85).aspx
        # DWORD WINAPI WaitForSingleObject(
        #   _In_  HANDLE hHandle,
        #   _In_  DWORD dwMilliseconds
        # );
        ffi_lib :kernel32
        attach_function_private :WaitForSingleObject,
          [:handle, :uint32], :uint32
      end
    end
  end
end
