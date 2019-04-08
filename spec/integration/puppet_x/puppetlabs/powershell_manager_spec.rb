require 'spec_helper'
require 'puppet/type'
require 'puppet_x/puppetlabs/powershell/powershell_manager'

module PuppetX
  module PowerShell
    class PowerShellManager; end
    if Puppet::Util::Platform.windows?
      module WindowsAPI
        require 'ffi'
        extend FFI::Library

        ffi_convention :stdcall

        # https://msdn.microsoft.com/en-us/library/ks2530z6%28v=VS.100%29.aspx
        # intptr_t _get_osfhandle(
        #    int fd
        # );
        ffi_lib [FFI::CURRENT_PROCESS, 'msvcrt']
        attach_function :get_osfhandle, :_get_osfhandle, [:int], :uintptr_t

        # http://msdn.microsoft.com/en-us/library/windows/desktop/ms724211(v=vs.85).aspx
        # BOOL WINAPI CloseHandle(
        #   _In_  HANDLE hObject
        # );
        ffi_lib :kernel32
        attach_function :CloseHandle, [:uintptr_t], :int32
      end
    end
  end
end

shared_examples_for "a PowerShellManager" do |ps_command, ps_args|

describe PuppetX::PowerShell::PowerShellManager do

  def create_manager(ps_command, ps_args)
    PuppetX::PowerShell::PowerShellManager.instance(ps_command, ps_args, debug: true)
  end

  def line_end
    Puppet::Util::Platform.windows? ? "\r\n" : "\n"
  end

  def is_osx?
     # Note this test fails if running in JRuby, but because the unit tests are MRI only, this is ok
    !RUBY_PLATFORM.match(/darwin/).nil?
  end

  let (:manager) { create_manager(ps_command, ps_args) }

  describe "when managing the powershell process" do
    describe "the PowerShellManager::instance method" do
      it "should return the same manager instance / process given the same cmd line" do
        first_pid = manager.execute('[Diagnostics.Process]::GetCurrentProcess().Id')[:stdout]

        manager_2 = create_manager(ps_command, ps_args)
        second_pid = manager_2.execute('[Diagnostics.Process]::GetCurrentProcess().Id')[:stdout]

        expect(manager_2).to eq(manager)
        expect(first_pid).to eq(second_pid)
      end

      it "should fail if the manger is created with a short timeout" do
        expect {
          PuppetX::PowerShell::PowerShellManager.new(
            ps_command,
            ps_args,
            debug: false,
            pipe_timeout: 0.01
          )
        }.to raise_error do |e|
          expect(e).to be_a(RuntimeError)
          expected_error = /Failure waiting for PowerShell process (\d+) to start pipe server/
          expect(e.message).to match expected_error
          pid = expected_error.match(e.message)[1].to_i

          # We want to make sure that enough time has elapsed since the manager called kill
          # for the OS to finish killing the process and doing all of it's cleanup.
          # We have found that without an appropriate wait period, the kill call below
          # can return unexpected results and fail the test.
          sleep(1)
          expect{Process.kill(0, pid)}.to raise_error(Errno::ESRCH)
        end
      end

      def bad_file_descriptor_regex
        # Ruby can do something like:
        # <Errno::EBADF: Bad file descriptor>
        # <Errno::EBADF: Bad file descriptor @ io_fillbuf - fd:10 >
        @bad_file_descriptor_regex ||= (
          ebadf = Errno::EBADF.new()
          '^' + Regexp.escape("\#<#{ebadf.class}: #{ebadf.message}")
        )
      end

      def pipe_error_regex
        @pipe_error_regex ||= (
          epipe = Errno::EPIPE.new()
          '^' + Regexp.escape("\#<#{epipe.class}: #{epipe.message}")
        )
      end

      # reason should be a string for an exact match
      # else an array of regex matches
      def expect_dead_manager(manager, reason, style = :exact)
        # additional attempts to use the manager will fail for the given reason
        result = manager.execute('Write-Host "hi"')
        expect(result[:exitcode]).to eq(-1)

        if reason.is_a?(String)
          expect(result[:stderr][0]).to eq(reason) if style == :exact
          expect(result[:stderr][0]).to match(reason) if style == :regex
        elsif reason.is_a?(Array)
          expect(reason).to include(result[:stderr][0]) if style == :exact
          if style == :regex
            expect(result[:stderr][0]).to satisfy("should match expected error(s): #{reason}") do |msg|
              reason.any? { |m| msg.match m }
            end
          end
        end

        # and the manager no longer considers itself alive
        expect(manager.alive?).to eq(false)
      end

      def expect_different_manager_returned_than(manager, pid)
        # acquire another manager instance using the same command and arguments
        new_manager = create_manager(manager.powershell_command, manager.powershell_arguments)

        # which should be different than the one passed in
        expect(new_manager).to_not eq(manager)

        # with a different PID
        second_pid = new_manager.execute('[Diagnostics.Process]::GetCurrentProcess().Id')[:stdout]
        expect(pid).to_not eq(second_pid)
      end

      def close_stream(stream, style = :inprocess)
        if style == :inprocess
          stream.close
        else style == :viahandle
          handle = PuppetX::PowerShell::WindowsAPI.get_osfhandle(stream.fileno)
          PuppetX::PowerShell::WindowsAPI.CloseHandle(handle)
        end
      end

      it "should create a new PowerShell manager host if user code exits the first process" do
        first_pid = manager.execute('[Diagnostics.Process]::GetCurrentProcess().Id')[:stdout]
        exitcode = manager.execute('[Diagnostics.Process]::GetCurrentProcess().Kill()')[:exitcode]

        # when a process gets torn down out from under manager before reading stdout
        # it catches the error and returns a -1 exitcode
        expect(exitcode).to eq(-1)

        expect_dead_manager(manager, pipe_error_regex, :regex)

        expect_different_manager_returned_than(manager, first_pid)
      end

      it "should create a new PowerShell manager host if the underlying PowerShell process is killed" do
        first_pid = manager.execute('[Diagnostics.Process]::GetCurrentProcess().Id')[:stdout]
        # kill the PID from Ruby
        # Note - On Windows, creating the powershell manager starts one process, whereas on unix it starts two (one via sh and one via pwsh). Not sure why
        # So instead kill the parent process instead of the child
        Process.kill('KILL', first_pid.to_i)

        # Windows uses named pipes, unix uses sockets
        Puppet::Util::Platform.windows? ?
          expect_dead_manager(manager, pipe_error_regex, :regex) :
          # WSL raises an EOFError
          # Ubuntu 16.04 raises an ECONNRESET:Connection reset by peer
          expect_dead_manager(manager,
            [EOFError.new('end of file reached').inspect, Errno::ECONNRESET.new.inspect],
            :exact
          )

        expect_different_manager_returned_than(manager, first_pid)
      end

      context "on Windows" do
        # On Windows we're using named pipes so these tests only apply on Windows.
        before :each do
          skip('Not on Windows platform') unless Puppet::Util::Platform.windows?   
        end

        it "should create a new PowerShell manager host if the input stream is closed" do
          first_pid = manager.execute('[Diagnostics.Process]::GetCurrentProcess().Id')[:stdout]

          # closing pipe from the Ruby side tears down the process
          close_stream(manager.instance_variable_get(:@pipe), :inprocess)

          expect_dead_manager(manager, IOError.new('closed stream').inspect, :exact)

          expect_different_manager_returned_than(manager, first_pid)
        end

        it "should create a new PowerShell manager host if the input stream handle is closed" do
          first_pid = manager.execute('[Diagnostics.Process]::GetCurrentProcess().Id')[:stdout]

          # call CloseHandle against pipe, therby tearing down the PowerShell process
          close_stream(manager.instance_variable_get(:@pipe), :viahandle)

          expect_dead_manager(manager, bad_file_descriptor_regex, :regex)

          expect_different_manager_returned_than(manager, first_pid)
        end

        it "should create a new PowerShell manager host if the output stream is closed" do
          first_pid = manager.execute('[Diagnostics.Process]::GetCurrentProcess().Id')[:stdout]

          # closing stdout from the Ruby side allows process to run
          close_stream(manager.instance_variable_get(:@stdout), :inprocess)

          # fails with vanilla EPIPE or closed stream IOError depening on timing / Ruby version
          msgs = [ Errno::EPIPE.new().inspect, IOError.new('closed stream').inspect ]
          expect_dead_manager(manager, msgs, :exact)

          expect_different_manager_returned_than(manager, first_pid)
        end

        it "should create a new PowerShell manager host if the output stream handle is closed" do
          # currently skipped as it can trigger an internal Ruby thread clean-up race
          # its unknown why this test fails, but not the identical test against @stderr
          skip('This test can cause intermittent segfaults in Ruby with w32_reset_event invalid handle')
          first_pid = manager.execute('[Diagnostics.Process]::GetCurrentProcess().Id')[:stdout]

          # call CloseHandle against stdout, which leaves PowerShell process running
          close_stream(manager.instance_variable_get(:@stdout), :viahandle)

          # fails with vanilla EPIPE or various EBADF depening on timing / Ruby version
          msgs = [
            '^' + Regexp.escape(Errno::EPIPE.new().inspect),
            bad_file_descriptor_regex
          ]
          expect_dead_manager(manager, msgs, :regex)

          expect_different_manager_returned_than(manager, first_pid)
        end

        it "should create a new PowerShell manager host if the error stream is closed" do
          first_pid = manager.execute('[Diagnostics.Process]::GetCurrentProcess().Id')[:stdout]

          # closing stderr from the Ruby side allows process to run
          close_stream(manager.instance_variable_get(:@stderr), :inprocess)

          # fails with vanilla EPIPE or closed stream IOError depening on timing / Ruby version
          msgs = [ Errno::EPIPE.new().inspect, IOError.new('closed stream').inspect ]
          expect_dead_manager(manager, msgs, :exact)

          expect_different_manager_returned_than(manager, first_pid)
        end

        it "should create a new PowerShell manager host if the error stream handle is closed" do
          first_pid = manager.execute('[Diagnostics.Process]::GetCurrentProcess().Id')[:stdout]

          # call CloseHandle against stderr, which leaves PowerShell process running
          close_stream(manager.instance_variable_get(:@stderr), :viahandle)

          # fails with vanilla EPIPE or various EBADF depening on timing / Ruby version
          msgs = [
            '^' + Regexp.escape(Errno::EPIPE.new().inspect),
            bad_file_descriptor_regex
          ]
          expect_dead_manager(manager, msgs, :regex)

          expect_different_manager_returned_than(manager, first_pid)
        end
      end
    end
  end

  let(:powershell_runtime_error) { '$ErrorActionPreference = "Stop";$test = 1/0' }
  let(:powershell_parseexception_error) { '$ErrorActionPreference = "Stop";if (1 -badoperator 2) { Exit 1 }' }
  let(:powershell_incompleteparseexception_error) { '$ErrorActionPreference = "Stop";if (1 -eq 2) {  ' }

  describe "when provided powershell commands" do
    it "shows ps version" do
      result = manager.execute('$psversiontable')
      puts result[:stdout]
    end

    it "should return simple output" do
      result = manager.execute('write-output foo')

      expect(result[:stdout]).to eq("foo#{line_end}")
      expect(result[:exitcode]).to eq(0)
    end

    it "should return the exitcode specified" do
      result = manager.execute('write-output foo; exit 55')

      expect(result[:stdout]).to eq("foo#{line_end}")
      expect(result[:exitcode]).to eq(55)
    end

    it "should return the exitcode 1 when exception is thrown" do
      result = manager.execute('throw "foo"')

      expect(result[:stdout]).to eq(nil)
      expect(result[:exitcode]).to eq(1)
    end

    it "should return the exitcode of the last command to set an exit code" do
      result =Puppet::Util::Platform.windows? ?
        manager.execute("$LASTEXITCODE = 0; write-output 'foo'; cmd.exe /c 'exit 99'; write-output 'bar'") :
        manager.execute("$LASTEXITCODE = 0; write-output 'foo'; /bin/sh -c 'exit 99'; write-output 'bar'")

      expect(result[:stdout]).to eq("foo#{line_end}bar#{line_end}")
      expect(result[:exitcode]).to eq(99)
    end

    it "should return the exitcode of a script invoked with the call operator &" do
      fixture_path = File.expand_path(File.dirname(__FILE__) + '../../../../exit-27.ps1')
      result = manager.execute("& #{fixture_path}")

      expect(result[:stdout]).to eq(nil)
      expect(result[:exitcode]).to eq(27)
    end

    it "should collect anything written to stderr" do
      result = manager.execute('[System.Console]::Error.WriteLine("foo")')

      expect(result[:stderr]).to eq(["foo#{line_end}"])
      expect(result[:exitcode]).to eq(0)
    end

    it "should collect multiline output written to stderr" do
      # induce a failure in cmd.exe that emits a multi-iline error message
      result = Puppet::Util::Platform.windows? ?
        manager.execute('cmd.exe /c foo.exe') :
        manager.execute('/bin/sh -c "echo bar 1>&2 && foo.exe"')

      expect(result[:stdout]).to eq(nil)
      if Puppet::Util::Platform.windows?
        expect(result[:stderr]).to eq(["'foo.exe' is not recognized as an internal or external command,\r\noperable program or batch file.\r\n"])
      elsif is_osx?
        expect(result[:stderr][0]).to match(/foo\.exe: command not found/)
        expect(result[:stderr][0]).to match(/bar/)
      else
        expect(result[:stderr][0]).to match(/foo\.exe: not found/)
        expect(result[:stderr][0]).to match(/bar/)
      end
      expect(result[:exitcode]).to_not eq(0)
    end

    it "should handle writting to stdout (cmdlet) and stderr" do
      result = manager.execute('Write-Host "powershell";[System.Console]::Error.WriteLine("foo")')

      expect(result[:stdout]).not_to eq(nil)
      expect(result[:native_stdout]).to eq(nil)
      expect(result[:stderr]).to eq(["foo#{line_end}"])
      expect(result[:exitcode]).to eq(0)
    end

    it "should handle writting to stdout (shell out to another program) and stderr" do
      result = Puppet::Util::Platform.windows? ?
        manager.execute('cmd.exe /c echo powershell;[System.Console]::Error.WriteLine("foo")') :
        manager.execute('/bin/sh -c "echo powershell";[System.Console]::Error.WriteLine("foo")')

      expect(result[:stdout]).to eq(nil)
      expect(result[:native_stdout]).not_to eq(nil)
      expect(result[:stderr]).to eq(["foo#{line_end}"])
      expect(result[:exitcode]).to eq(0)
    end

    it "should handle writing to stdout natively" do
      result = manager.execute('[System.Console]::Out.WriteLine("foo")')

      expect(result[:stdout]).to eq("foo#{line_end}")
      expect(result[:native_stdout]).to eq(nil)
      expect(result[:stderr]).to eq([])
      expect(result[:exitcode]).to eq(0)
    end

    it "should properly interleave output written natively to stdout and via Write-XXX cmdlets" do
      result = manager.execute('Write-Output "bar"; [System.Console]::Out.WriteLine("foo"); Write-Warning "baz";')

      expect(result[:stdout]).to eq("bar#{line_end}foo#{line_end}WARNING: baz#{line_end}")
      expect(result[:stderr]).to eq([])
      expect(result[:exitcode]).to eq(0)
    end

    it "should handle writing to regularly captured output AND stdout natively" do
      result = manager.execute('Write-Host "powershell";[System.Console]::Out.WriteLine("foo")')

      expect(result[:stdout]).not_to eq("foo#{line_end}")
      expect(result[:native_stdout]).to eq(nil)
      expect(result[:stderr]).to eq([])
      expect(result[:exitcode]).to eq(0)
    end

    it "should handle writing to regularly captured output, stderr AND stdout natively" do
      result = manager.execute('Write-Host "powershell";[System.Console]::Out.WriteLine("foo");[System.Console]::Error.WriteLine("bar")')

      expect(result[:stdout]).not_to eq("foo#{line_end}")
      expect(result[:native_stdout]).to eq(nil)
      expect(result[:stderr]).to eq(["bar#{line_end}"])
      expect(result[:exitcode]).to eq(0)
    end

    context "it should handle UTF-8" do
      # different UTF-8 widths
      # 1-byte A
      # 2-byte ۿ - http://www.fileformat.info/info/unicode/char/06ff/index.htm - 0xDB 0xBF / 219 191
      # 3-byte ᚠ - http://www.fileformat.info/info/unicode/char/16A0/index.htm - 0xE1 0x9A 0xA0 / 225 154 160
      # 4-byte 𠜎 - http://www.fileformat.info/info/unicode/char/2070E/index.htm - 0xF0 0xA0 0x9C 0x8E / 240 160 156 142
      let (:mixed_utf8) { "A\u06FF\u16A0\u{2070E}" } # Aۿᚠ𠜎

      it "when writing basic text" do
        code = "Write-Output '#{mixed_utf8}'"
        result = manager.execute(code)

        expect(result[:stdout]).to eq("#{mixed_utf8}#{line_end}")
        expect(result[:exitcode]).to eq(0)
      end

      it "when writing basic text to stderr" do
        code = "[System.Console]::Error.WriteLine('#{mixed_utf8}')"
        result = manager.execute(code)

        expect(result[:stderr]).to eq(["#{mixed_utf8}#{line_end}"])
        expect(result[:exitcode]).to eq(0)
      end
    end

    it "should execute cmdlets" do
      result = manager.execute('Get-Verb')

      expect(result[:stdout]).not_to eq(nil)
      expect(result[:exitcode]).to eq(0)
    end

    it "should execute cmdlets with pipes" do
      result = manager.execute('Get-Process | ? { $_.PID -ne $PID }')

      expect(result[:stdout]).not_to eq(nil)
      expect(result[:exitcode]).to eq(0)
    end

    it "should execute multi-line" do
      result = manager.execute(<<-CODE
$foo = ls
$count = $foo.count
$count
      CODE
      )

      expect(result[:stdout]).not_to eq(nil)
      expect(result[:exitcode]).to eq(0)
    end

   it "should execute code with a try/catch, receiving the output of Write-Error" do
     result = manager.execute(<<-CODE
try{
 $foo = ls
 $count = $foo.count
 $count
}catch{
 Write-Error "foo"
}
     CODE
     )

     expect(result[:stdout]).not_to eq(nil)
     expect(result[:exitcode]).to eq(0)
   end

    it "should be able to execute the code in a try block when using try/catch" do
      result = manager.execute(<<-CODE
 try {
  $foo = @(1, 2, 3).count
  exit 400
 } catch {
  exit 1
 }
      CODE
      )

      expect(result[:stdout]).to eq(nil)
      # using an explicit exit code ensures we've really executed correct block
      expect(result[:exitcode]).to eq(400)
    end

   it "should be able to execute the code in a catch block when using try/catch" do
     result = manager.execute(<<-CODE
try {
  throw "Error!"
  exit 0
} catch {
  exit 500
}
     CODE
     )

     expect(result[:stdout]).to eq(nil)
     # using an explicit exit code ensures we've really executed correct block
     expect(result[:exitcode]).to eq(500)
   end


    it "should reuse the same PowerShell process for multiple calls" do
      first_pid = manager.execute('[Diagnostics.Process]::GetCurrentProcess().Id')[:stdout]
      second_pid = manager.execute('[Diagnostics.Process]::GetCurrentProcess().Id')[:stdout]

      expect(first_pid).to eq(second_pid)
    end

    it "should remove psvariables between runs" do
      manager.execute('$foo = "bar"')
      result = manager.execute('$foo')

      expect(result[:stdout]).to eq(nil)
    end

    it "should remove env variables between runs" do
      manager.execute('[Environment]::SetEnvironmentVariable("foo", "bar", "process")')
      result = manager.execute('Test-Path env:\foo')

      expect(result[:stdout]).to eq("False#{line_end}")
    end

    it "should set custom environment variables" do
      result = manager.execute('Write-Output $ENV:foo',nil,nil,['foo=bar'])

      expect(result[:stdout]).to eq("bar#{line_end}")
    end

    it "should remove custom environment variables between runs" do
      manager.execute('Write-Output $ENV:foo',nil,nil,['foo=bar'])
      result = manager.execute('Write-Output $ENV:foo',nil,nil,[])

      expect(result[:stdout]).to be nil
    end

    it "should ignore malformed custom environment variable" do
      result = manager.execute('Write-Output $ENV:foo',nil,nil,['=foo','foo','foo='])

      expect(result[:stdout]).to be nil
    end

    it "should use last definition for duplicate custom environment variable" do
      result = manager.execute('Write-Output $ENV:foo',nil,nil,['foo=one','foo=two','foo=three'])

      expect(result[:stdout]).to eq("three#{line_end}")
    end

    def current_powershell_major_version(ps_command, ps_args)
      # As this is only used to detect old PS versions we can
      # short circuit detecting the version for PowerShell Core
      return 6 if ps_command.end_with?('pwsh') || ps_command.end_with?('pwsh.exe')
      begin
        version = `#{ps_command} #{ps_args.join(' ')} -Command \"$PSVersionTable.PSVersion.Major.ToString()\"`.chomp!.to_i
      rescue
        puts "Unable to determine PowerShell version"
        version = -1
      end

      version
    end

    def output_cmdlet(ps_command, ps_args)
      # Write-Output is the default behavior, except on older PS2 where the
      # behavior of Write-Output introduces newlines after every width number
      # of characters as specified in the BufferSize of the custom console UI
      # Write-Host should usually be avoided, but works for this test in old PS2
      current_powershell_major_version(ps_command, ps_args) >= 3 ?
        'Write-Output' :
        'Write-Host'
    end

    it "should be able to write more than the 64k default buffer size to the managers pipe without deadlocking the Ruby parent process or breaking the pipe" do
      # this was tested successfully up to 5MB of text
      # we add some additional bytes so it's not always on a 1KB boundary and forces pipe reading in different lengths, not always 1K chunks
      buffer_string_96k = 'a' * ((1024 * 96) + 11)
      result = manager.execute(<<-CODE
'#{buffer_string_96k}' | #{output_cmdlet(ps_command, ps_args)}
        CODE
        )

      expect(result[:errormessage]).to eq(nil)
      expect(result[:exitcode]).to eq(0)
      expect(result[:stdout].length).to eq("#{buffer_string_96k}#{line_end}".length)
      expect(result[:stdout]).to eq("#{buffer_string_96k}#{line_end}")
    end

    it "should be able to write more than the 64k default buffer size to child process stdout without deadlocking the Ruby parent process" do
      # we add some additional bytes so it's not always on a 1KB boundary and forces pipe reading in different lengths, not always 1K chunks
      result = manager.execute(<<-CODE
$bytes_in_k = (1024 * 64) + 11
[Text.Encoding]::UTF8.GetString((New-Object Byte[] ($bytes_in_k))) | #{output_cmdlet(ps_command, ps_args)}
        CODE
        )

      expect(result[:errormessage]).to eq(nil)
      expect(result[:exitcode]).to eq(0)
      expected = "\x0" * (1024 * 64 + 11) + line_end
      expect(result[:stdout].length).to eq(expected.length)
      expect(result[:stdout]).to eq(expected)
    end

    it "should return a response with a timeout error if the execution timeout is exceeded" do
      timeout_ms = 100
      result = manager.execute('sleep 1', timeout_ms)
      msg = /Catastrophic failure\: PowerShell module timeout \(#{timeout_ms} ms\) exceeded while executing/
      expect(result[:errormessage]).to match(msg)
    end

    it "should return any available stdout / stderr prior to being terminated if a timeout error occurs" do
      timeout_ms = 1500
      command = '$debugPreference = "Continue"; Write-Output "200 OK Glenn"; Write-Debug "304 Not Modified James"; Write-Error "404 Craig Not Found"; sleep 10'
      result = manager.execute(command, timeout_ms)
      expect(result[:exitcode]).to eq(1)
      # starts with Write-Output and Write-Debug messages
      expect(result[:stdout]).to match(/200 OK Glenn/)
      expect(result[:stdout]).to match(/DEBUG: 304 Not Modified James/)
      # then command may have \r\n injected, so remove those for comparison
      expect(result[:stdout].gsub(/\r\n/, '')).to include(command)
      # and it should end with the Write-Error content
      expect(result[:stdout]).to match(/404 Craig Not Found/)
    end

    it "should use a default timeout of 300 seconds if the user specified a timeout of 0" do
      timeout_ms = 0
      command = 'return $true'
      code = manager.make_ps_code(command, timeout_ms)
      expect(code).to match(/TimeoutMilliseconds = 300000/)
    end

    it "Should use the correct correct timeout if a small value is specified" do

      # Zero timeout is not supported, and a timeout less than 50ms is not supported.
      # This test is to ensure that the code that inserts the default timeout when
      # the user specified zero, does not interfere with the other default of 50ms
      # if the user specifies a value less than that.

      timeout_ms = 20
      command = 'return $true'
      code = manager.make_ps_code(command, timeout_ms)
      expect(code).to match(/TimeoutMilliseconds = 50/)
    end

    it "should not deadlock and return a valid response given invalid unparseable PowerShell code" do
      result = manager.execute(<<-CODE
        {

        CODE
        )

      expect(result[:errormessage]).not_to be_empty
    end

    it "should error if working directory does not exist" do
      work_dir = 'C:/some/directory/that/does/not/exist'

      result = manager.execute('(Get-Location).Path',nil,work_dir)

      expect(result[:exitcode]).to_not eq(0)
      expect(result[:errormessage]).to match(/Working directory .+ does not exist/)
    end

    it "should allow forward slashes in working directory" do
      skip('Not on Windows platform') unless Puppet::Util::Platform.windows?
      # Backslashes only apply on Windows filesystems
      work_dir = ENV["WINDIR"]
      forward_work_dir = work_dir.gsub('\\','/')

      result = manager.execute('(Get-Location).Path',nil,forward_work_dir)[:stdout]

      expect(result).to eq("#{work_dir}#{line_end}")
    end

    it "should use a specific working directory if set" do
      work_dir = Puppet::Util::Platform.windows? ? ENV["WINDIR"] : ENV["HOME"]

      result = manager.execute('(Get-Location).Path',nil,work_dir)[:stdout]

      expect(result).to eq("#{work_dir}#{line_end}")
    end

    it "should not reuse the same working directory between runs" do
      work_dir = Puppet::Util::Platform.windows? ? ENV["WINDIR"] : ENV["HOME"]
      current_work_dir = Dir.getwd

      first_cwd = manager.execute('(Get-Location).Path',nil,work_dir)[:stdout]
      second_cwd = manager.execute('(Get-Location).Path')[:stdout]

      # Paths should be case insensitive
      expect(first_cwd.downcase).to eq("#{work_dir}#{line_end}".downcase)
      expect(second_cwd.downcase).to eq("#{current_work_dir}#{line_end}".downcase)
    end

    context "with runtime error" do
      it "should not refer to 'EndInvoke' or 'throw' for a runtime error" do
        result = manager.execute(powershell_runtime_error)

        expect(result[:exitcode]).to eq(1)
        expect(result[:errormessage]).not_to match(/EndInvoke/)
        expect(result[:errormessage]).not_to match(/throw/)
      end

      it "should display line and char information for a runtime error" do
        result = manager.execute(powershell_runtime_error)

        expect(result[:exitcode]).to eq(1)
        expect(result[:errormessage]).to match(/At line\:\d+ char\:\d+/)
      end
    end

    context "with ParseException error" do
      it "should not refer to 'EndInvoke' or 'throw' for a ParseException error" do
        result = manager.execute(powershell_parseexception_error)

        expect(result[:exitcode]).to eq(1)
        expect(result[:errormessage]).not_to match(/EndInvoke/)
        expect(result[:errormessage]).not_to match(/throw/)
      end

      it "should display line and char information for a ParseException error" do
        result = manager.execute(powershell_parseexception_error)

        expect(result[:exitcode]).to eq(1)
        expect(result[:errormessage]).to match(/At line\:\d+ char\:\d+/)
      end
    end

    context "with IncompleteParseException error" do
      it "should not refer to 'EndInvoke' or 'throw' for an IncompleteParseException error" do
        result = manager.execute(powershell_incompleteparseexception_error)

        expect(result[:exitcode]).to eq(1)
        expect(result[:errormessage]).not_to match(/EndInvoke/)
        expect(result[:errormessage]).not_to match(/throw/)
      end

      it "should not display line and char information for an IncompleteParseException error" do
        result = manager.execute(powershell_incompleteparseexception_error)

        expect(result[:exitcode]).to eq(1)
        expect(result[:errormessage]).not_to match(/At line\:\d+ char\:\d+/)
      end
    end
  end

  describe "when output is written to a PowerShell Stream" do
    it "should collect anything written to verbose stream" do
      msg = SecureRandom.uuid.to_s.gsub('-', '')
      result = manager.execute("$VerbosePreference = 'Continue';Write-Verbose '#{msg}'")

      expect(result[:stdout]).to match(/^VERBOSE\: #{msg}/)
      expect(result[:exitcode]).to eq(0)
    end

    it "should collect anything written to debug stream" do
      msg = SecureRandom.uuid.to_s.gsub('-', '')
      result = manager.execute("$debugPreference = 'Continue';Write-debug '#{msg}'")

      expect(result[:stdout]).to match(/^DEBUG: #{msg}/)
      expect(result[:exitcode]).to eq(0)
    end

    it "should collect anything written to Warning stream" do
      msg = SecureRandom.uuid.to_s.gsub('-', '')
      result = manager.execute("Write-Warning '#{msg}'")

      expect(result[:stdout]).to match(/^WARNING: #{msg}/)
      expect(result[:exitcode]).to eq(0)
    end

    it "should collect anything written to Error stream" do
      msg = SecureRandom.uuid.to_s.gsub('-', '')
      result = manager.execute("Write-Error '#{msg}'")

      expect(result[:stdout]).to match(/Write-Error '#{msg}' : #{msg}/)
      expect(result[:exitcode]).to eq(0)
    end

    it "should handle a Write-Error in the middle of code" do
      result = manager.execute('Write-Host "one" ;Write-Error "Hello"; Write-Host "two"')

      expect(result[:stdout]).not_to eq(nil)
      expect(result[:exitcode]).to eq(0)
    end

    it "should handle a Out-Default in the user code" do
      result = manager.execute('\'foo\' | Out-Default')

      expect(result[:stdout]).to eq("foo#{line_end}")
      expect(result[:exitcode]).to eq(0)
    end

    it "should handle lots of output from user code" do
      result = manager.execute('1..1000 | %{ (65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_} }')

      expect(result[:stdout]).not_to eq(nil)
      expect(result[:exitcode]).to eq(0)
    end

    it "should handle a larger return of output from user code" do
      result = manager.execute('1..1000 | %{ (65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_} } | %{ $f="" } { $f+=$_ } {$f }')

      expect(result[:stdout]).not_to eq(nil)
      expect(result[:exitcode]).to eq(0)
    end

    it "should handle shell redirection" do
      # the test here is to ensure that this doesn't break. because we merge the streams regardless
      # the opposite of this test shows the same thing
      result = manager.execute('function test-error{ ps;write-error \'foo\' }; test-error 2>&1')

      expect(result[:stdout]).not_to eq(nil)
      expect(result[:exitcode]).to eq(0)
    end
  end
end
end

describe "On Windows PowerShell" do
  before :each do
    skip unless Puppet::Util::Platform.windows? && PuppetX::PowerShell::PowerShellManager.supported?
  end

  it_should_behave_like "a PowerShellManager",
    Puppet::Type.type(:exec).provider(:powershell).command(:powershell),
    Puppet::Type.type(:exec).provider(:powershell).powershell_args
end

describe "On PowerShell Core" do
  before :each do
    skip unless PuppetX::PowerShell::PowerShellManager.supported_on_pwsh? && !Puppet::Type.type(:exec).provider(:pwsh).new().get_pwsh_command.nil?
  end

  it_should_behave_like "a PowerShellManager",
    Puppet::Type.type(:exec).provider(:pwsh).new().get_pwsh_command,
    Puppet::Type.type(:exec).provider(:pwsh).new().pwsh_args
end
