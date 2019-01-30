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
    pwsh = get_pwsh_command
    self.fail 'pwsh could not be found' if pwsh.nil?
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
        return super("cmd.exe /c \"\"#{native_path(pwsh)}\" #{legacy_args} -Command - < \"#{native_path}\"\"", check)
      else
        return super("/bin/sh -c \"#{native_path(pwsh)} #{legacy_args} -Command - < #{native_path}\"", check)
      end
    end
  end

  def checkexe(command)
  end

  def validatecmd(command)
    true
  end

  private

  def get_pwsh_command
    if @resource['path'].nil?
      pwsh = Puppet::Util.which('pwsh')
    else
      pwsh = which_with_custom_env('pwsh', @resource['path'])
    end
    return pwsh unless pwsh.nil?

    return nil unless Puppet::Util::Platform.windows?
    # These paths are Windows only
    pwsh = "#{ENV['ProgramFiles']}\\PowerShell\\6\\pwsh.exe"
    return pwsh if File.exists?(pwsh)
    pwsh = "#{ENV['ProgramFiles(x86)']}\\PowerShell\\6\\pwsh.exe"
    File.exists?(pwsh) ? pwsh : nil
  end

  # Based on which command from https://github.com/puppetlabs/puppet/blob/1c14d0a9fdfc31933603e571b616b6cd675e6b71/lib/puppet/util.rb#L241-L286
  # Resolve a path for an executable to the absolute path. This tries to behave
  # in the same manner as the unix `which` command and uses the `PATH`
  # environment variable.
  #
  # @api private
  # @param bin [String] the name of the executable to find.
  # @param custom_paths [String[]] the additional paths to look in first and then the PATH
  # @return [String] the absolute path to the found executable.
  def which_with_custom_env(bin, custom_paths = [])
    if absolute_path?(bin)
      return bin if FileTest.file? bin and FileTest.executable? bin
    else
      exts = Puppet::Util.get_env('PATHEXT')
      exts = exts ? exts.split(File::PATH_SEPARATOR) : %w[.COM .EXE .BAT .CMD]
      (custom_paths + Puppet::Util.get_env('PATH').split(File::PATH_SEPARATOR)).each do |dir|
        begin
          dest = File.expand_path(File.join(dir, bin))
        rescue ArgumentError => e
          # if the user's PATH contains a literal tilde (~) character and HOME is not set, we may get
          # an ArgumentError here.  Let's check to see if that is the case; if not, re-raise whatever error
          # was thrown.
          if e.to_s =~ /HOME/ and (Puppet::Util.get_env('HOME').nil? || Puppet::Util.get_env('HOME') == "")
            # if we get here they have a tilde in their PATH.  We'll issue a single warning about this and then
            # ignore this path element and carry on with our lives.
            #TRANSLATORS PATH and HOME are environment variables and should not be translated
            Puppet::Util::Warnings.warnonce(_("PATH contains a ~ character, and HOME is not set; ignoring PATH element '%{dir}'.") % { dir: dir })
          elsif e.to_s =~ /doesn't exist|can't find user/
            # ...otherwise, we just skip the non-existent entry, and do nothing.
            #TRANSLATORS PATH is an environment variable and should not be translated
            Puppet::Util::Warnings.warnonce(_("Couldn't expand PATH containing a ~ character; ignoring PATH element '%{dir}'.") % { dir: dir })
          else
            raise
          end
        else
          if Puppet::Util::Platform.windows? && File.extname(dest).empty?
            exts.each do |ext|
              destext = File.expand_path(dest + ext)
              return destext if FileTest.file? destext and FileTest.executable? destext
            end
          end
          return dest if FileTest.file? dest and FileTest.executable? dest
        end
      end
    end
    nil
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

  def legacy_args
    '-NoProfile -NonInteractive -NoLogo -ExecutionPolicy Bypass'
  end
end
