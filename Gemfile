source "https://rubygems.org"

def location_for(place, fake_version = nil)
  if place =~ /^(git:[^#]*)#(.*)/
    [fake_version, { :git => $1, :branch => $2, :require => false }].compact
  elsif place =~ /^file:\/\/(.*)/
    ['>= 0', { :path => File.expand_path($1), :require => false }]
  else
    [place, { :require => false }]
  end
end

gem "puppet", *location_for(ENV['PUPPET_LOCATION'] || '~> 3.2.3')
gem "facter", *location_for(ENV['FACTER_LOCATION'] || '~> 1.6')
gem "hiera", *location_for(ENV['HIERA_LOCATION'] || '~> 1.0')

group :development, :test do
  gem 'rspec', "~> 2.11.0"
  gem 'mocha', "~> 0.10.5"
  gem 'puppetlabs_spec_helper'
end

# see http://projects.puppetlabs.com/issues/21698
platforms :mswin, :mingw do
  gem "sys-admin", "~> 1.5.6", :require => false
  gem "win32-dir", "~> 0.3.7", :require => false
  gem "win32-eventlog", "~> 0.5.3", :require => false
  gem "win32-process", "~> 0.6.5", :require => false
  gem "win32-security", "~> 0.1.4", :require => false
  gem "win32-service", "~> 0.7.2", :require => false
  gem "win32-taskscheduler", "~> 0.2.2", :require => false
  gem "win32console", "~> 1.3.2", :require => false
  gem "minitar", "~> 0.5.4", :require => false
end

if File.exists? "#{__FILE__}.local"
  eval(File.read("#{__FILE__}.local"), binding)
end

