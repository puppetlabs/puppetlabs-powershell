require 'spec_helper'
require 'puppet/type'
require 'puppet_x/puppetlabs/powershell/powershell_manager'

module PuppetX
  module PowerShell
    class PowerShellManager; end
  end
end

describe PuppetX::PowerShell::PowerShellManager,
  :if => Puppet::Util::Platform.windows? && PuppetX::PowerShell::PowerShellManager.supported? do

  let (:manager) {
    provider = Puppet::Type.type(:exec).provider(:powershell)
    powershell = provider.command(:powershell)
    powershell_args = provider.powershell_args
    PuppetX::PowerShell::PowerShellManager.instance("#{powershell} #{powershell_args.join(' ')}")
  }

  describe "when provided powershell commands" do
    it "shows ps version" do
      result = manager.execute('$psversiontable')
      puts result[:stdout]
    end

    it "should return simple output" do
      result = manager.execute('write-output foo')

      # STDERR is interpolating the newlines thus it's \n instead of the usual Windows \r\n
      expect(result[:stdout]).to eq("foo\r\n")
      expect(result[:exitcode]).to eq(0)
    end

    it "should return the exitcode specified" do
      result = manager.execute('write-output foo; exit 55')

      # STDERR is interpolating the newlines thus it's \n instead of the usual Windows \r\n
      expect(result[:stdout]).to eq("foo\r\n")
      expect(result[:exitcode]).to eq(55)
    end

    it "should return the exitcode 1 when exception is thrown" do
      result = manager.execute('throw "foo"')

      expect(result[:stdout]).to eq(nil)
      expect(result[:exitcode]).to eq(1)
    end

    it "should collect anything written to stderr" do
      result = manager.execute('[System.Console]::Error.WriteLine("foo")')

      # STDERR is interpolating the newlines thus it's \n instead of the usual Windows \r\n
      expect(result[:stderr][0][0]).to eq("foo\n")
      expect(result[:exitcode]).to eq(0)
    end

    it "should handle writting to stdout and stderr" do
      result = manager.execute('ps;[System.Console]::Error.WriteLine("foo")')

      expect(result[:stdout]).not_to eq(nil)
      expect(result[:stderr]).not_to eq(nil)
      expect(result[:exitcode]).to eq(0)
    end

    it "should execute cmdlets" do
      result = manager.execute('ls')

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

      expect(result[:stdout]).to eq("False\r\n")
    end

    it "should be able to write more than the 64k default buffer size to child process stdout without deadlocking the Ruby parent process" do
      result = manager.execute(<<-CODE
$bytes_in_k = (1024 * 64) + 1
[Text.Encoding]::UTF8.GetString((New-Object Byte[] ($bytes_in_k))) | Write-Output
        CODE
        )

      expect(result[:errormessage]).to eq(nil)
      expect(result[:exitcode]).to eq(0)
      expect(result[:stdout]).not_to eq(nil)
    end

    it "should return a response with a timeout error if the execution timeout is exceeded" do
      timeout_ms = 100
      result = manager.execute('sleep 1', timeout_ms)
      # TODO What is the real message now?
      msg = /Catastrophic failure\: PowerShell module timeout \(#{timeout_ms} ms\) exceeded while executing\r\n/
      expect(result[:errormessage]).to match(msg)
    end

    it "should not deadlock and return a valid response given invalid unparseable PowerShell code" do
      result = manager.execute(<<-CODE
        {

        CODE
        )

      expect(result[:errormessage]).not_to be_empty
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

      expect(result[:stdout]).to eq("Write-Error '#{msg}' : #{msg}\r\n    + CategoryInfo          : NotSpecified: (:) [Write-Error], WriteErrorException\r\n    + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException\r\n \r\n")
      expect(result[:exitcode]).to eq(0)
    end

    it "should handle a Write-Error in the middle of code" do
      result = manager.execute('ls;Write-Error "Hello";ps')

      expect(result[:stdout]).not_to eq(nil)
      expect(result[:exitcode]).to eq(0)
    end

    it "should handle a Out-Default in the user code" do
      result = manager.execute('\'foo\' | Out-Default')

      expect(result[:stdout]).to eq("foo\r\n")
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
      result = manager.execute('function test-warning{ ps;write-warning \'foo\' }; test-warning 3>&1')

      expect(result[:stdout]).not_to eq(nil)
      expect(result[:exitcode]).to eq(0)
    end
  end

end
