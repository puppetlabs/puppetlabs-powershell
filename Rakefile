require 'puppetlabs_spec_helper/rake_tasks'
require 'rspec/core/rake_task'

task :default => :unit

desc "Unit tests"
RSpec::Core::RakeTask.new(:unit) do |t,args|
  t.pattern     = 'spec/unit'
  t.rspec_opts  = '--color'
  t.verbose     = true
end

