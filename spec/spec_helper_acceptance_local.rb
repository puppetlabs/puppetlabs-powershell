require 'puppet_litmus'
require 'singleton'

class Helper
  include Singleton
  include PuppetLitmus
end

def install_pwsh
  script_folder = File.expand_path(File.join(File.dirname(__FILE__), 'fixtures/scripts/install_pwsh'))
  script_path = case os[:family]
                when 'ubuntu'
                  File.join(script_folder, "ubuntu_#{os[:release].to_f}.sh")
                when 'redhat'
                  File.join(script_folder, "rhel_#{os[:release].to_i}.sh")
                when 'debian'
                  File.join(script_folder, "debian_#{os[:release].to_i}.sh")
                when 'darwin'
                  File.join(script_folder, "darwin.sh")
                when 'windows'
                  File.join(script_folder, "windows.ps1")
                end
  Helper.instance.bolt_run_script(script_path)
end

def uninstall_pwsh
  command = case os[:family]
            when 'ubuntu', 'debian'
              'apt-get remove powershell -y'
            when 'redhat'
              'yum remove powershell -y'
            when 'darwin'
              'brew cask uninstall powershell'
            when 'windows'
              interpolate_powershell('Get-Command pwsh | Select-Object -ExpandProperty Source | ForEach-Object { Remove-Item -Path (Split-Path -Parent $_) -Recurse -Force }')
            end
  Helper.instance.run_shell(command)
end

def pwsh_installed?
  Helper.instance.run_shell('pwsh -v', expect_failures: true).exit_code == 0
end

def cleanup_files
  absent_files_manifest = if os[:family] == 'windows'
                            'file{["c:/services.txt","c:/process.txt","c:/try_success.txt","c:/catch_shouldntexist.txt","c:/try_shouldntexist.txt","c:/catch_success.txt"]: ensure => absent }'
                          else
                            'file{["/services.txt","/process.txt","/try_success.txt","/catch_shouldntexist.txt","/try_shouldntexist.txt","/catch_success.txt"]: ensure => absent }'
                          end
  Helper.instance.apply_manifest(absent_files_manifest, catch_failures: true)
end

def encode_command(command)
  Base64.strict_encode64(command.encode('UTF-16LE'))
end

def interpolate_powershell(command)
  "powershell.exe -NoProfile -EncodedCommand #{encode_command(command)}"
end

def localhost_windows?
  os[:family] == 'windows' && ENV['TARGET_HOST'] == 'localhost'
end

RSpec.configure do |c|
  c.before :suite do
    Helper.instance.run_shell('puppet module install puppetlabs/pwshlib')
    cleanup_files
  end
end