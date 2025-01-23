# frozen_string_literal: true

require 'puppet/provider/exec'

Puppet::Type.type(:exec).provide :powershell, parent: Puppet::Provider::Exec do
  confine 'os.name': :windows
  confine feature: :pwshlib

  desc <<-DESC
    Executes Powershell commands. One of the `onlyif`, `unless`, or `creates`
    parameters should be specified to ensure the command is idempotent.

    Example:
        # Rename the Guest account
        exec { 'rename-guest':
          command   => '$(Get-WMIObject Win32_UserAccount -Filter "Name='guest'").Rename("new-guest")',
          unless    => 'if (Get-WmiObject Win32_UserAccount -Filter "Name='guest'") { exit 1 }',
          provider  => powershell,
        }
  DESC

  POWERSHELL_MODULE_UPGRADE_MSG ||= <<-UPGRADE
  Currently, the PowerShell module has reduced v1 functionality on this agent
  due to one or more of the following conditions:

  - Puppet 3.x (non-x64 version)

    Puppet 3.x uses a Ruby version that requires a library to support a colored
    console. Unfortunately this library prevents the PowerShell module from
    using a shared PowerShell process to dramatically improve the performance of
    resource application.

  - PowerShell v2 with .NET Framework 2.0

    PowerShell v2 works with both .NET Framework 2.0 and .NET Framework 3.5.
    To be able to use the enhancements, we require .NET Framework 3.5.
    Typically you will only see this on a base Windows Server 2008 (and R2)
    install.

  To enable these improvements, it is suggested to upgrade to any x64 version of
  Puppet (including 3.x), or to a Puppet version newer than 3.x and ensure you
  have .NET Framework 3.5 installed.
  UPGRADE

  def self.upgrade_message
    Puppet.warning POWERSHELL_MODULE_UPGRADE_MSG unless @upgrade_warning_issued
    @upgrade_warning_issued = true
  end

  def ps_manager(pipe_timeout)
    debug_output = Puppet::Util::Log.level == :debug
    Pwsh::Manager.instance(Pwsh::Manager.powershell_path, Pwsh::Manager.powershell_args, debug: debug_output,
                                                                                         pipe_timeout: pipe_timeout)
  end

  def run(command, check = false)
    return execute_resource(command, resource) if Pwsh::Manager.windows_powershell_supported?

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
      return super("cmd.exe /c \"\"#{native_path(Pwsh::Manager.powershell_path)}\" #{legacy_args} -Command - < \"#{native_path}\"\"", check)
    end
  end

  def execute_resource(powershell_code, resource)
    working_dir = resource[:cwd]
    raise "Working directory '#{working_dir}' does not exist" if !working_dir.nil? && !File.directory?(working_dir)

    timeout_ms = resource[:timeout].nil? ? nil : resource[:timeout] * 1000
    environment_variables = resource[:environment].nil? ? [] : resource[:environment]

    result = ps_manager(resource[:timeout]).execute(powershell_code, timeout_ms, working_dir, environment_variables)
    stdout     = result[:stdout]
    native_out = result[:native_stdout]
    stderr     = result[:stderr]
    exit_code  = result[:exitcode]

    stderr&.each { |e| Puppet.debug "STDERR: #{e.chop}" unless e.empty? }

    Puppet.debug "STDERR: #{result[:errormessage]}" unless result[:errormessage].nil?

    output = Puppet::Util::Execution::ProcessOutput.new(stdout.to_s + native_out.to_s, exit_code)

    [output, output]
  end

  def checkexe(command); end

  def validatecmd(_command)
    true
  end

  private

  def write_script(content)
    Tempfile.open(['puppet-powershell', '.ps1']) do |file|
      file.puts(content)
      file.puts
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
