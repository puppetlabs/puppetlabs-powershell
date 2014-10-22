require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'


UNSUPPORTED_PLATFORMS = ['debian', 'ubuntu', 'Solaris']
FUTURE_PARSER = ENV['FUTURE_PARSER'] == 'true' || false

unless ENV['RS_PROVISION'] == 'no' or ENV['BEAKER_provision'] == 'no'
  is_foss = (ENV['IS_PE'] == 'no' || ENV['IS_PE'] == 'false') ? true : false
  if hosts.first.is_pe? && !is_foss
    install_pe
  else
    version = ENV['PUPPET_VERSION'] || '3.7.1'
    download_url = ENV['WIN_DOWNLOAD_URL'] || 'http://downloads.puppetlabs.com/windows/'
    hosts.each do |host|
      if host['platform'] =~ /windows/i
        install_puppet_from_msi(host,
                                {
                                    :win_download_url => download_url,
                                    :version => version
                                })
      end
    end
  end

  step "Install Powershell to default host"
  on default, "mkdir -p #{default['distmoduledir']}/powershell"
  result = on default, "echo #{default['distmoduledir']}/powershell"
  target = result.raw_output.chomp
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  %w(lib metadata.json).each do |file|
    scp_to default, "#{proj_root}/#{file}", target
  end
end

RSpec.configure do |c|
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    shell("/bin/touch #{default['puppetpath']}/hiera.yaml")
  end
  c.after :suite do
    absent_files = 'file{["c:/services.txt","c:/process.txt"]: ensure => absent }'
    apply_manifest(absent_files)
  end
end

