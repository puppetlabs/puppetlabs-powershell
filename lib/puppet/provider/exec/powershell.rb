require 'puppet/provider/exec'

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
      return super("cmd.exe /c \"\"#{native_path(command(:powershell))}\" #{args} -Command - < \"#{native_path}\"\"", check)
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
      file.write(content)
      file.flush
      yield native_path(file.path)
    end
  end

  def native_path(path)
    path.gsub(File::SEPARATOR, File::ALT_SEPARATOR)
  end

  def args
    '-NoProfile -NonInteractive -NoLogo -ExecutionPolicy Bypass'
  end
end
