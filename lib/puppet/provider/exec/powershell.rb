require 'puppet/provider/exec'
require File.join(File.dirname(__FILE__), '../../../puppet_x/puppetlabs/powershell/powershell_manager')

Puppet::Type.type(:exec).provide :powershell, :parent => Puppet::Provider::Exec do
  confine :operatingsystem => :windows

  commands :powershell =>
    if File.exists?("#{ENV['SYSTEMROOT']}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe")
      "#{ENV['SYSTEMROOT']}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe"
    elsif File.exists?("#{ENV['SYSTEMROOT']}\\system32\\WindowsPowershell\\v1.0\\powershell.exe")
      "#{ENV['SYSTEMROOT']}\\system32\\WindowsPowershell\\v1.0\\powershell.exe"
    else
      'powershell.exe'
    end

  desc <<-EOT
    Executes Powershell commands. One of the `onlyif`, `unless`, or `creates`
    parameters should be specified to ensure the command is idempotent.

    Example:
        # Rename the Guest account
        exec { 'rename-guest':
          command   => '$(Get-WMIObject Win32_UserAccount -Filter "Name=\'guest\'").Rename("new-guest")',
          unless    => 'if (Get-WmiObject Win32_UserAccount -Filter "Name=\'guest\'") { exit 1 }',
          provider  => powershell,
        }
  EOT

  POWERSHELL_UPGRADE_MSG = <<-UPGRADE
  The current Puppet version is outdated and uses a library that was
  previously necessary on the current Ruby verison to support a colored console.

  Unfortunately this library prevents the PowerShell module from using a shared
  PowerShell process to dramatically improve the performance of resource
  application.

  To enable these improvements, it is suggested to upgrade to any x64 version of
  Puppet (including 3.x), or to a Puppet version newer than 3.x.
  UPGRADE

  def self.upgrade_message
    Puppet.warning POWERSHELL_UPGRADE_MSG if !@upgrade_warning_issued
    @upgrade_warning_issued = true
  end

  def self.powershell_args
    ps_args = ['-NoProfile', '-NonInteractive', '-NoLogo', '-ExecutionPolicy', 'Bypass', '-Command']
    ps_args << '-' if PuppetX::PowerShell::PowerShellManager.supported?
    ps_args
  end

  def ps_manager
    PuppetX::PowerShell::PowerShellManager.instance("#{command(:powershell)} #{self.class.powershell_args.join(' ')}")
  end

  def run(command, check = false)
    if !PuppetX::PowerShell::PowerShellManager.supported?
      self.class.upgrade_message
      write_script(command) do |native_path|
        # Ideally, we could keep a handle open on the temp file in this
        # process (to prevent TOCTOU attacks), and execute powershell
        # with -File <path>. But powershell complains that it can't open
        # the file for exclusive access. If we close the handle, then an
        # attacker could modify the file before we invoke powershell. So
        # we redirect powershell's stdin to read from the file. Current
        # versions of Windows use per-user temp directories with strong
        # permissions, but I'd rather not make (poor) assumptions.
        return super("cmd.exe /c \"\"#{native_path(command(:powershell))}\" #{legacy_args} -Command - < \"#{native_path}\"\"", check)
      end
    else
      result = ps_manager.execute(command)

      stdout      = result[:stdout]
      stderr      = result[:stderr]
      exit_code   = result[:exitcode]

      unless stderr.nil?
        stderr.each do |er|
          er.each { |e| Puppet.debug "STDERR: #{e.chop}" } unless er.empty?
        end
      end

      Puppet.debug "STDERR: #{result[:errormessage]}" unless result[:errormessage].nil?

      output = Puppet::Util::Execution::ProcessOutput.new(stdout.to_s || '', exit_code)

      return output, output
    end
  end

  def checkexe(command)
  end

  def validatecmd(command)
    true
  end

  private
  def write_script(content, &block)
    Tempfile.open(['puppet-powershell', '.ps1']) do |file|
      file.puts(content)
      file.puts()
      file.flush
      yield native_path(file.path)
    end
  end

  def native_path(path)
    if Puppet::Util::Platform.windows?
      path.gsub(File::SEPARATOR, File::ALT_SEPARATOR)
    else
      path
    end
  end

  def legacy_args
    '-NoProfile -NonInteractive -NoLogo -ExecutionPolicy Bypass'
  end
end
