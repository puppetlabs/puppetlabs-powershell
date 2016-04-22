require 'beaker/puppet_install_helper'

ENV['PUPPET_INSTALL_TYPE'] ||= 'agent'
ENV['FUTURE_PARSER'] ||= 'false'

run_puppet_install_helper
