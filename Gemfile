source ENV['GEM_SOURCE'] || "https://rubygems.org"

def location_for(place, fake_version = nil)
  if place =~ /^(git:[^#]*)#(.*)/
    [fake_version, { :git => $1, :branch => $2, :require => false }].compact
  elsif place =~ /^file:\/\/(.*)/
    ['>= 0', { :path => File.expand_path($1), :require => false }]
  else
    [place, { :require => false }]
  end
end

group :development do
  gem 'rspec', '~>3.0',          :require => false
  gem 'puppetlabs_spec_helper',  :require => false
  gem 'puppet_facts',            :require => false
  gem 'mocha', '~>0.10.5',       :require => false
end
group :system_tests do
  if beaker_version = ENV['BEAKER_VERSION']
    gem 'beaker', *location_for(beaker_version)
  end
  if beaker_rspec_version = ENV['BEAKER_RSPEC_VERSION']
    gem 'beaker-rspec', *location_for(beaker_rspec_version)
  else
    gem 'beaker-rspec',  :require => false
  end
  gem 'beaker-puppet_install_helper', :require => false
  gem 'serverspec',    :require => false
end


platforms :mswin, :mingw, :x64_mingw do
  gem "ffi", "~> 1.9", :require => false
  gem "win32console", "~> 1.3", :require => false
  gem "minitar", "~> 0.5", :require => false
  gem "win32-dir", "~> 0.3", :require => false
  gem "win32-eventlog", "~> 0.6", :require => false
  gem "win32-process", "~> 0.6", :require => false
  gem "win32-security", "~> 0.2", :require => false
  gem "win32-service", "~> 0.8", :require => false
end

if facterversion = ENV['FACTER_GEM_VERSION']
  gem 'facter', *location_for(facterversion)
else
  gem 'facter', :require => false
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', *location_for(puppetversion)
else
  gem 'puppet', :require => false
end

if File.exists? "#{__FILE__}.local"
  eval(File.read("#{__FILE__}.local"), binding)
end
# vim:ft=ruby
