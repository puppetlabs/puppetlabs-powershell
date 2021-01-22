# frozen_string_literal: true

require 'puppet/provider/exec'

Puppet::Type.type(:exec).provide :pwsh, :parent => Puppet::Provider::Exec do
  confine :feature => :pwshlib
  
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
    if Pwsh::Manager.pwsh_supported?
      return execute_resource(command, resource)
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
    # If the resource specifies a search path use that. Otherwise use the default
    # PATH from the environment.
    @resource.nil? || @resource['path'].nil? ?
      Pwsh::Manager.pwsh_path :
      Pwsh::Manager.pwsh_path(resource[:path])
  end

  def pwsh_args
    ['-NoProfile', '-NonInteractive', '-NoLogo', '-ExecutionPolicy', 'Bypass']
  end

  private

  # Retrieves the PowerShell manager specific to our pwsh binary in this resource
  #
  # @api private
  # @return [Pwsh::Manager] The PowerShell manager for this resource
  def ps_manager(pipe_timeout)
    debug_output = Puppet::Util::Log.level == :debug
    Pwsh::Manager.instance(@pwsh, pwsh_args, debug: debug_output, pipe_timeout: pipe_timeout)
  end

  def execute_resource(powershell_code, resource)
    working_dir = resource[:cwd]
    if (!working_dir.nil?)
      fail "Working directory '#{working_dir}' does not exist" unless File.directory?(working_dir)
    end
    timeout_ms = resource[:timeout].nil? ? nil : resource[:timeout] * 1000
    environment_variables = resource[:environment].nil? ? [] : resource[:environment]

    result = ps_manager(resource[:timeout]).execute(powershell_code, timeout_ms, working_dir, environment_variables)
    stdout     = result[:stdout]
    native_out = result[:native_stdout]
    stderr     = result[:stderr]
    exit_code  = result[:exitcode]

    unless stderr.nil?
      stderr.each { |e| Puppet.debug "STDERR: #{e.chop}" unless e.empty? }
    end

    Puppet.debug "STDERR: #{result[:errormessage]}" unless result[:errormessage].nil?

    output = Puppet::Util::Execution::ProcessOutput.new(stdout.to_s + native_out.to_s, exit_code)

    return output, output
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
