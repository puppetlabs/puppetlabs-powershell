require 'puppet/provider/exec'

Puppet::Type.type(:exec).provide :pwsh, :parent => Puppet::Provider::Exec do
  confine :operatingsystem  => [ :windows ]

  commands :pwsh =>
    if File.exists?("#{ENV['ProgramFiles']}\\PowerShell\\6\\pwsh.exe")
      "#{ENV['ProgramFiles']}\\PowerShell\\6\\pwsh.exe"
    elsif File.exists?("#{ENV['ProgramFiles(x86)']}\\PowerShell\\6\\pwsh.exe")
      "#{ENV['ProgramFiles(x86)']}\\PowerShell\\6\\pwsh.exe"
    else
      'pwsh.exe'
    end

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
    write_script(command) do |native_path|
      # Ideally, we could keep a handle open on the temp file in this
      # process (to prevent TOCTOU attacks), and execute powershell
      # with -File <path>. But powershell complains that it can't open
      # the file for exclusive access. If we close the handle, then an
      # attacker could modify the file before we invoke powershell. So
      # we redirect powershell's stdin to read from the file. Current
      # versions of Windows use per-user temp directories with strong
      # permissions, but I'd rather not make (poor) assumptions.
      return super("cmd.exe /c \"\"#{native_path(command(:pwsh))}\" #{legacy_args} -Command - < \"#{native_path}\"\"", check)
    end
  end

  def checkexe(command)
  end

  def validatecmd(command)
    true
  end

  private
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

  def legacy_args
    '-NoProfile -NonInteractive -NoLogo -ExecutionPolicy Bypass'
  end
end
