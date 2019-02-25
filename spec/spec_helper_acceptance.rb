require 'beaker-pe'
require 'beaker-puppet'
require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'beaker/puppet_install_helper'
require 'beaker/testmode_switcher/dsl'
require 'beaker/module_install_helper'

UNSUPPORTED_PLATFORMS = ['debian', 'ubuntu', 'Solaris']
FUTURE_PARSER = ENV['FUTURE_PARSER'] == 'true' || false

run_puppet_install_helper
configure_type_defaults_on(hosts)

unless ENV['MODULE_provision'] == 'no'
  # Due to a bug in beaker-puppet, passing in a hosts array with differing architectures does
  # weird things e.g. uses windows paths in linux.  Best to just pass in one host at a time.
  hosts.each do |host|
    install_module_on(host)
    install_module_dependencies_on(host)
  end

  # Install PowerShell on hosts that are not a Master, Dashboard or Database
  agents.each do |host|
    ps_version = host['powershell']
    if not_controller(host)
      case host.platform
      when "ubuntu-14.04-amd64"
        # Instructions for installing on Ubuntu 14 from
        # https://github.com/PowerShell/PowerShell/blob/master/docs/installation/linux.md#ubuntu-1404
        on(host,'curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -')
        on(host,'curl https://packages.microsoft.com/config/ubuntu/14.04/prod.list | sudo tee /etc/apt/sources.list.d/microsoft.list')
        on(host,'sudo apt-get update')
        # e.g. sudo apt-get install -y powershell=6.1.2-1.ubuntu.14.04
        apt_text = "=#{ps_version}-1.ubuntu.14.04" unless ps_version.nil?
        on(host,"sudo apt-get install -y powershell#{apt_text}")
      when "ubuntu-16.04-amd64"
        # Instructions for installing on Ubuntu 16 from
        # https://github.com/PowerShell/PowerShell/blob/master/docs/installation/linux.md#ubuntu-1604
        on(host,'curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -')
        on(host,'curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list | sudo tee /etc/apt/sources.list.d/microsoft.list')
        on(host,'sudo apt-get update')
        # e.g. sudo apt-get install -y powershell=6.1.2-1.ubuntu.16.04
        apt_text = "=#{ps_version}-1.ubuntu.16.04" unless ps_version.nil?
        on(host,"sudo apt-get install -y powershell#{apt_text}")
      when "el-7-x86_64"
        # Instructions for installing on CentOS 7, Oracle Linux7, RHEL 7 from
        # https://github.com/PowerShell/PowerShell/blob/master/docs/installation/linux.md#centos-7
        # sudo is not required and seems to throw errors when running under beaker `sudo: sorry, you must have a tty to run sudo`
        on(host,'curl https://packages.microsoft.com/config/rhel/7/prod.repo | tee /etc/yum.repos.d/microsoft.repo')
        # e.g. yum install -y powershell-6.1.2
        yum_text = "-#{ps_version}" unless ps_version.nil?
        on(host,"yum install -y powershell#{yum_text}")
      when /^windows/
        # Install PowerShell 6 if needed
        unless ps_version.nil?
          on(host,"powershell -NoLogo -NoProfile -Command \"[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri https://github.com/PowerShell/PowerShell/releases/download/v#{ps_version}/PowerShell-#{ps_version}-win-x64.msi -OutFile C:\\PSPkg.msi -UseBasicParsing\"")
          on(host,'msiexec.exe /i C:\\\\PSPkg.msi /qn ALLUSERS=1 /l*v C:\\\\PSPkg-install.log')
        end
      else
        raise("Unable to install PowerShell on host '#{host.name}' with platform '#{host.platform}'")
      end
    end
  end
end

RSpec.configure do |c|
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    shell("/bin/touch #{default['puppetpath']}/hiera.yaml")

    powershell_agents = agents.select { |a| not_controller(a) }
    posix_agents      = powershell_agents.select { |a| a.platform =~ /^(?!windows).*$/ }
    windows_agents    = powershell_agents.select { |a| a.platform =~ /^windows.*$/ }

    # Ensure test files don't exist before we run the test suite
    absent_files = 'file{["c:/services.txt","c:/process.txt","c:/try_success.txt","c:/catch_shouldntexist.txt","c:/try_shouldntexist.txt","c:/catch_success.txt"]: ensure => absent }'
    apply_manifest_on(windows_agents, absent_files, :catch_failures => true) if windows_agents.count > 0

    absent_files = 'file{["/services.txt","/process.txt","/try_success.txt","/catch_shouldntexist.txt","/try_shouldntexist.txt","/catch_success.txt"]: ensure => absent }'
    apply_manifest_on(posix_agents, absent_files, :catch_failures => true) if posix_agents.count > 0
  end
end
