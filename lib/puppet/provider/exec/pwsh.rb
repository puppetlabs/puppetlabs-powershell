require 'puppet/provider/exec'

Puppet::Type.type(:exec).provide :pwsh, :parent => Puppet::Provider::Exec do
  desc <<-EOT
    Executes PowerShell Core commands. One of the `onlyif`, `unless`, or `creates`
    parameters should be specified to ensure the command is idempotent.

    Example:
        # Rename the Guest account
        exec { 'rename-guest':
          command   => '$(Get-CIMInstance Win32_UserAccount -Filter "Name=\'guest\'").Rename("new-guest")',
          unless    => 'if (Get-CIMInstance Win32_UserAccount -Filter "Name=\'guest\'") { exit 1 }',
          provider  => pwsh,
        }
  EOT

  def run(command, check = false)
    @pwsh ||= get_pwsh_command
    self.fail 'pwsh could not be found' if @pwsh.nil?
    if PuppetX::PowerShell::PowerShellManager.supported_on_pwsh?
      return ps_manager.execute_resource(command, resource)
    else
      write_script(command) do |native_path|
        # Ideally, we could keep a handle open on the temp file in this
        # process (to prevent TOCTOU attacks), and execute powershell
        # with -File <path>. But powershell complains that it can't open
        # the file for exclusive access. If we close the handle, then an
        # attacker could modify the file before we invoke powershell. So
        # we redirect powershell's stdin to read from the file. Current
        # versions of Windows use per-user temp directories with strong
        # permissions, but I'd rather not make (poor) assumptions.
        if Puppet::Util::Platform.windows?
          return super("cmd.exe /c \"\"#{native_path(@pwsh)}\" #{pwsh_args.join(' ')} -Command - < \"#{native_path}\"\"", check)
        else
          return super("/bin/sh -c \"#{native_path(@pwsh)} #{pwsh_args.join(' ')} -Command - < #{native_path}\"", check)
        end
      end
    end
  end

  def checkexe(command)
  end

  def validatecmd(command)
    true
  end

  # Retrieves the absolute path to pwsh
  #
  # @return [String] the absolute path to the found pwsh executable.  Returns nil when it does not exist
  def get_pwsh_command
    if Puppet::Util::Platform.windows?
      # Environment variables on Windows are not case sensitive however ruby hash keys are.
      # Convert all the key names to upcase so we can be sure to find PATH etc.
      # Also while ruby can have difficulty changing the case of some UTF8 characters, we're
      # only going to use plain ASCII names so this is safe.
      current_env = Hash[Puppet::Util.get_environment.map {|k, v| [k.upcase, v] }]
    else
      # We don't force a case change on non-Windows platforms because it is perfectly
      # ok to have 'Path' and 'PATH'
      current_env = Puppet::Util.get_environment
    end
    # If the resource specifies a search path use that. Otherwise use the default
    # PATH from the environment.
    search_paths = @resource.nil? || @resource['path'].nil? ?
      current_env['PATH'] :
      resource[:path].join(File::PATH_SEPARATOR)

    # If we're on Windows, try the default installation locations as a last resort.
    # https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows?view=powershell-6#msi
    if Puppet::Util::Platform.windows?
      search_paths += ";#{current_env['PROGRAMFILES']}\\PowerShell\\6" +
        ";#{current_env['PROGRAMFILES(X86)']}\\PowerShell\\6"
    end

    # Note that just like when we run the command in Puppet::Provider::Exec, the
    # resource[:path] replaces the PATH, it doesn't add to it.
    Puppet::Util.withenv({'PATH' => search_paths}, Puppet::Util.default_env) do
      return Puppet::Util.which('pwsh')
    end
  end

  def pwsh_args
    ['-NoProfile', '-NonInteractive', '-NoLogo', '-ExecutionPolicy', 'Bypass']
  end

  private

  # Retrieves the PowerShell manager specific to our pwsh binary in this resource
  #
  # @api private
  # @return [PuppetX::PowerShell::PowerShellManager] The PowerShell manager for this resource
  def ps_manager
    debug_output = Puppet::Util::Log.level == :debug
    PuppetX::PowerShell::PowerShellManager.instance(@pwsh, pwsh_args, debug: debug_output)
  end

  def write_script(content, &block)
    Tempfile.open(['puppet-pwsh', '.ps1']) do |file|
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
end
