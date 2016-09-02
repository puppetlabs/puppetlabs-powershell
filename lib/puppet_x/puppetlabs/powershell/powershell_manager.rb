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

      def self.instance(cmd, debug = false)
        key = cmd + debug.to_s
        manager = @@instances[key]

        if manager.nil? || !manager.alive?
          # ignore any errors trying to tear down this unusable instance
          manager.exit if manager rescue nil
          @@instances[key] = PowerShellManager.new(cmd, debug)
        end

         @@instances[key]
      end

      def self.win32console_enabled?
        @win32console_enabled ||= defined?(Win32) &&
          defined?(Win32::Console) &&
          Win32::Console.class == Class
      end

      def self.supported?
        Puppet::Util::Platform.windows? && !win32console_enabled?
      end

      def initialize(cmd, debug)
        @usable = true

        init_ready_event_name = "Global\\#{SecureRandom.uuid}"
        named_pipe_name = "#{SecureRandom.uuid}PuppetPsHost"

        # create the event for PS to signal once the pipe server is ready
        init_ready_event = self.class.create_event(init_ready_event_name)

        ps_args = ['-File', self.class.init_path, "\"#{init_ready_event_name}\"", "\"#{named_pipe_name}\""]
        ps_args << '"-EmitDebugOutput"' if debug
        # @stderr should never be written to as PowerShell host redirects output
        stdin, @stdout, @stderr, @ps_process = Open3.popen3("#{cmd} #{ps_args.join(' ')}")
        stdin.close

        Puppet.debug "#{Time.now} #{cmd} is running as pid: #{@ps_process[:pid]}"

        # wait for the pipe server to signal ready, and fail if no response in 10 seconds
        ps_pipe_wait_ms = 10 * 1000
        if WAIT_TIMEOUT == self.class.wait_on(init_ready_event, ps_pipe_wait_ms)
          fail "Failure waiting for PowerShell process #{@ps_process[:pid]} to start pipe server"
        end

        # pipe is opened in binary mode and must always
        @pipe = File.open("\\\\.\\pipe\\#{named_pipe_name}" , 'r+b')

        Puppet.debug "#{Time.now} PowerShell initialization complete for pid: #{@ps_process[:pid]}"

        at_exit { exit }
      end

      def alive?
        # powershell process running
        @ps_process.alive? &&
          # explicitly set during a read / write failure, like broken pipe EPIPE
          @usable &&
          # an explicit failure state might not have been hit, but IO may be closed
          self.class.is_stream_valid?(@pipe) &&
          self.class.is_stream_valid?(@stdout) &&
          self.class.is_stream_valid?(@stderr)
      end

      def execute(powershell_code, timeout_ms = nil, working_dir = nil)
        output_ready_event_name =  "Global\\#{SecureRandom.uuid}"
        output_ready_event = self.class.create_event(output_ready_event_name)

        code = make_ps_code(powershell_code, output_ready_event_name, timeout_ms, working_dir)

        # err is drained stderr pipe (not captured by redirection inside PS)
        # or during a failure, a Ruby callstack array
        out, native_stdout, err = exec_read_result(code, output_ready_event)

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
            (prop.text.nil? ? nil : Base64.decode64(prop.text).force_encoding(Encoding::UTF_8))
          # if err contains data it must be "real" stderr output
          # which should be appended to what PS has already captured
          if name == 'stderr'
            value = value.nil? ? [] : [value]
            value += err if !err.nil?
          end
          [name.to_sym, value]
        end
        props << [:native_stdout, native_stdout]

        Hash[ props ]
      ensure
        CloseHandle(output_ready_event) if output_ready_event
      end

      def exit
        @usable = false

        Puppet.debug "PowerShellManager exiting..."
        # pipe may still be open, but if stdout / stderr are dead PS process is in trouble
        # and will block forever on a write to the pipe
        # its safer to close pipe on Ruby side, which gracefully shuts down PS side
        @pipe.close if !@pipe.closed?
        @stdout.close if !@stdout.closed?
        @stderr.close if !@stderr.closed?

        # wait up to 2 seconds for the watcher thread to fully exit
        @ps_process.join(2)
      end

      def self.init_path
        # a PowerShell -File compatible path to bootstrap the instance
        path = File.expand_path('../../../templates', __FILE__)
        path = File.join(path, 'init_ps.ps1').gsub('/', '\\')
        "\"#{path}\""
      end

      def make_ps_code(powershell_code, output_ready_event_name, timeout_ms = nil, working_dir = nil)
        begin
          timeout_ms = Integer(timeout_ms)
          # Lower bound protection. The polling resolution is only 50ms
          if (timeout_ms < 50) then timeout_ms = 50 end
        rescue
          timeout_ms = 300 * 1000
        end
        # PS side expects Invoke-PowerShellUserCode is always the return value here
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

      # 1 byte command identifier
      #     0 - Exit
      #     1 - Execute
      def pipe_command(command)
        case command
        when :exit
          "\x00"
        when :execute
          "\x01"
        end
      end

      # Data format is:
      # 4 bytes - Little Endian encoded 32-bit integer length of string
      #           Intel CPUs are little endian, hence the .NET Framework typically is
      # variable length - UTF8 encoded string bytes
      def pipe_data(data)
        msg = data.encode(Encoding::UTF_8)
        # https://ruby-doc.org/core-1.9.3/Array.html#method-i-pack
        [msg.bytes.length].pack('V') + msg.force_encoding(Encoding::BINARY)
      end

      def write_pipe(input)
        # for compat with Ruby 2.1 and lower, its important to use syswrite and not write
        # otherwise the pipe breaks after writing 1024 bytes
        written = @pipe.syswrite(input)
        @pipe.flush()

        if written != input.length
          msg = "Only wrote #{written} out of #{input.length} expected bytes to PowerShell pipe"
          raise Errno::EPIPE.new(msg)
        end
      end

      def read_from_pipe(pipe, timeout = 0.1, &block)
        if self.class.is_readable?(pipe, timeout)
          l = pipe.gets
          Puppet.debug "#{Time.now} PIPE> #{l}"
          # since gets can return a nil at EOF, skip returning that value
          yield l.force_encoding(Encoding::UTF_8) if !l.nil?
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

      def read_streams(output_ready_event, wait_interval_ms = 50)
        pipe_done_reading = Mutex.new
        pipe_done_reading.lock
        start_time = Time.now

        pipe_reader = Thread.new { drain_pipe_until_signaled(@pipe, pipe_done_reading) }
        stdout_reader = Thread.new { drain_pipe_until_signaled(@stdout, pipe_done_reading) }
        stderr_reader = Thread.new { drain_pipe_until_signaled(@stderr, pipe_done_reading) }

        # wait until an event signal
        # OR a terminal state with child process / streams has been reached
        while WAIT_TIMEOUT == self.class.wait_on(output_ready_event, wait_interval_ms)
          # if reader threads have died, likely due to closed streams / handles
          break if !pipe_reader.alive? || !stdout_reader.alive? || !stderr_reader.alive?

          # Ruby will gleefully allow trying to read stdout / stderr that are
          # no longer connected to a live process, so therefore check the
          # liveness here and raise the broken pipe error that Ruby would usually
          # since stdin isn't checked here, fail if process dead instead
          raise Errno::EPIPE if !@ps_process.alive?
        end

        Puppet.debug "Waited #{Time.now - start_time} total seconds."

        # signal stdout / stderr readers via mutex
        pipe_done_reading.unlock

        # given redirection on PowerShell side, this should always be empty
        stdout = stdout_reader.value

        [
          pipe_reader.value.join(''),
          stdout == [] ? nil : stdout.join(''), # native stdout
          stderr_reader.value # native stderr
        ]
      end

      def exec_read_result(powershell_code, output_ready_event)
        write_pipe(pipe_command(:execute))
        write_pipe(pipe_data(powershell_code))
        read_streams(output_ready_event)
      # if any pipes are broken, the manager is totally hosed
      # bad file descriptors mean closed stream handles
      rescue Errno::EPIPE, Errno::EBADF => e
        @usable = false
        return nil, nil, [e.inspect, e.backtrace].flatten
      # catch closed stream errors specifically
      rescue IOError => ioerror
        raise if !ioerror.message.start_with?('closed stream')
        @usable = false
        return nil, nil, [ioerror.inspect, ioerror.backtrace].flatten
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
