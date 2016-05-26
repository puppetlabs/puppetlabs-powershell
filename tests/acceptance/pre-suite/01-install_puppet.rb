test_name 'MODULES-3285 - Install Puppet Agent'

require 'beaker/puppet_install_helper'

ENV['PUPPET_INSTALL_TYPE'] ||= 'agent'

run_puppet_install_helper
