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
        manager = @@instances[cmd]

        if manager.nil? || !manager.alive?
          # ignore any errors trying to tear down this unusable instance
          manager.exit if manager rescue nil
          @@instances[cmd] = PowerShellManager.new(cmd)
        end

         @@instances[cmd]
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
        @usable = true
        # @stderr should never be written to as PowerShell host redirects output
        @stdin, @stdout, @stderr, @ps_process = Open3.popen3(cmd)

        Puppet.debug "#{Time.now} #{cmd} is running as pid: #{@ps_process[:pid]}"

        init_ready_event_name =  "Global\\#{SecureRandom.uuid}"
        init_ready_event = self.class.create_event(init_ready_event_name)

        code = make_ps_init_code(init_ready_event_name)
        out, err = exec_read_result(code, init_ready_event)

        Puppet.debug "#{Time.now} PowerShell initialization complete for pid: #{@ps_process[:pid]}"

        at_exit { exit }
      end

      def alive?
        # powershell process running
        @ps_process.alive? &&
          # explicitly set during a read / write failure, like broken pipe EPIPE
          @usable &&
          # an explicit failure state might not have been hit, but IO may be closed
          self.class.is_stream_valid?(@stdin) &&
          self.class.is_stream_valid?(@stdout) &&
          self.class.is_stream_valid?(@stderr)
      end

      def execute(powershell_code, timeout_ms = nil, working_dir = nil)
        output_ready_event_name =  "Global\\#{SecureRandom.uuid}"
        output_ready_event = self.class.create_event(output_ready_event_name)

        code = make_ps_code(powershell_code, output_ready_event_name, timeout_ms, working_dir)

        # err is drained stderr pipe (not captured by redirection inside PS)
        # or during a failure, a Ruby callstack array
        out, err = exec_read_result(code, output_ready_event)

        # an error was caught during execution that has invalidated any results
        return { :exitcode => -1, :stderr => err } if !@usable && out.nil?

        # Powershell adds in newline characters as it tries to wrap output around the display (by default 80 chars).
        # This behavior is expected and cannot be changed, however it corrupts the XML e.g. newlines in the middle of
        # element names; So instead, part of the XML is Base64 encoded prior to being put on STDOUT and in ruby all
        # newline characters are stripped. Then where required decoded from Base64 back into text
        out = REXML::Document.new(out.gsub(/\n/,""))

        # picks up exitcode, errormessage, stdout and stderr
        props = REXML::XPath.each(out, '//Property').map do |prop|
          name = prop.attributes['Name']
          value = (name == 'exitcode') ?
            prop.text.to_i :
            (prop.text.nil? ? nil : Base64.decode64(prop.text))
          # if err contains data it must be "real" stderr output
          # which should be appended to what PS has already captured
          if name == 'stderr'
            value = value.nil? ? [] : [value]
            value += err if !err.nil?
          end
          [name.to_sym, value]
        end

        Hash[ props ]
      ensure
        CloseHandle(output_ready_event) if output_ready_event
      end

      def exit
        @usable = false

        Puppet.debug "PowerShellManager exiting..."
        # ignore any failure to call exit against PS process
        @stdin.puts "\nexit\n" if !@stdin.closed? rescue nil
        @stdin.close if !@stdin.closed?
        @stdout.close if !@stdout.closed?
        @stderr.close if !@stderr.closed?
      end

      def self.init_path
        path = File.expand_path('../../../templates', __FILE__)
        path = File.join(path, 'init_ps.ps1').gsub('/', '\\')
        "\"#{path}\""
      end

      def make_ps_init_code(init_ready_event_name)
        debug_output = Puppet::Util::Log.level == :debug ? '-EmitDebugOutput' : ''
        <<-CODE
. #{self.class.init_path} -InitReadyEventName '#{init_ready_event_name}' #{debug_output}
        CODE
      end

      def make_ps_code(powershell_code, output_ready_event_name, timeout_ms = nil, working_dir = nil)
        begin
          timeout_ms = Integer(timeout_ms)
          # Lower bound protection. The polling resolution is only 50ms
          if (timeout_ms < 50) then timeout_ms = 50 end
        rescue
          timeout_ms = 300 * 1000
        end
        <<-CODE
$params = @{
  Code = @'
#{powershell_code}
'@
  EventName = "#{output_ready_event_name}"
  TimeoutMilliseconds = #{timeout_ms}
  WorkingDirectory = "#{working_dir}"
}

Invoke-PowerShellUserCode @params
        CODE
      end

      private

      def self.is_readable?(stream, timeout = 0.5)
        raise Errno::EPIPE if !is_stream_valid?(stream)
        read_ready = IO.select([stream], [], [], timeout)
        read_ready && stream == read_ready[0][0]
      end

      # when a stream has been closed by handle, but Ruby still has a file
      # descriptor for it, it can be tricky to determine that it's actually dead
      # the .fileno will still return an int, and calling get_osfhandle against
      # it returns what the CRT thinks is a valid Windows HANDLE value, but
      # that may no longer exist
      def self.is_stream_valid?(stream)
        # when a stream is closed, its obviously invalid, but Ruby doesn't always know
        !stream.closed? &&
        # so calling stat will yield an EBADF when underlying OS handle is bad
        # as this resolves to a HANDLE and then calls the Windows API
        !stream.stat.nil?
      # any exceptions mean the stream is dead
      rescue
        false
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
      end

      def read_from_pipe(pipe, timeout = 0.1, &block)
        if self.class.is_readable?(pipe, timeout)
          l = pipe.gets
          Puppet.debug "#{Time.now} PIPE> #{l}"
          # since gets can return a nil at EOF, skip returning that value
          yield l if !l.nil?
        end

        nil
      end

      def drain_pipe_until_signaled(pipe, signal)
        output = []

        read_from_pipe(pipe) { |s| output << s } until !signal.locked?

        # there's ultimately a bit of a race here
        # read one more time after signal is received
        read_from_pipe(pipe, 0) { |s| output << s } until !self.class.is_readable?(pipe)
        output
      end

      def read_stdout(output_ready_event, wait_interval_ms = 50)
        pipe_done_reading = Mutex.new
        pipe_done_reading.lock
        start_time = Time.now

        stdout_reader = Thread.new { drain_pipe_until_signaled(@stdout, pipe_done_reading) }
        stderr_reader = Thread.new { drain_pipe_until_signaled(@stderr, pipe_done_reading) }

        # wait until an event signal
        # OR a terminal state with child process / streams has been reached
        while WAIT_TIMEOUT == self.class.wait_on(output_ready_event, wait_interval_ms)
          # if reader threads have died, likely due to closed streams / handles
          break if !stdout_reader.alive? || !stderr_reader.alive?

          # Ruby will gleefully allow trying to read stdout / stderr that are
          # no longer connected to a live process, so therefore check the
          # liveness here and raise the broken pipe error that Ruby would usually
          # since stdin isn't checked here, fail if process dead instead
          raise Errno::EPIPE if !@ps_process.alive?
        end

        Puppet.debug "Waited #{Time.now - start_time} total seconds."

        # signal stdout / stderr readers via mutex
        pipe_done_reading.unlock

        [
          stdout_reader.value.join(''),
          stderr_reader.value
        ]
      end

      def exec_read_result(powershell_code, output_ready_event)
        write_stdin(powershell_code)
        read_stdout(output_ready_event)
      # if any pipes are broken, the manager is totally hosed
      # bad file descriptors mean closed stream handles
      rescue Errno::EPIPE, Errno::EBADF => e
        @usable = false
        return nil, [e.inspect, e.backtrace].flatten
      # catch closed stream errors specifically
      rescue IOError => ioerror
        raise if !ioerror.message.start_with?('closed stream')
        @usable = false
        return nil, [ioerror.inspect, ioerror.backtrace].flatten
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
