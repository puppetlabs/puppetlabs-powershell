require 'beaker-rspec'
require 'rspec'

RSpec.configure do |c|
  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    hosts.each do |host|
      shell("/bin/touch #{default['puppetpath']}/hiera.yaml")
    end
  end
  c.after :suite do
    absent_files = 'file{["c:/services.txt","c:/process.txt"]: ensure => absent }'
    apply_manifest(absent_files)
  end
end

UNSUPPORTED_PLATFORMS = [ 'debian','ubuntu', 'Solaris' ]

unless ENV['RS_PROVISION'] == 'no' or ENV['BEAKER_provision'] == 'no'
  if hosts.first.is_pe?
    install_pe
  else
    install_puppet
  end
  hosts.each do |host|
    on hosts, "mkdir -p #{host['distmoduledir']}"
  end
end


