dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift File.join(dir, 'lib')

require 'puppet'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'pathname'
require 'rspec'

require 'tmpdir'
require 'fileutils'

if Puppet.features.microsoft_windows?
  require 'puppet/util/windows/security'

  def take_ownership(path)
    path = path.gsub('/', '\\')
    output = %x(takeown.exe /F #{path} /R /A /D Y 2>&1)
    if $? != 0 #check if the child process exited cleanly.
      puts "#{path} got error #{output}"
    end
  end

  def get_powershell_major_version()
    provider = Puppet::Type.type(:exec).provider(:powershell)
    powershell = provider.command(:powershell)
    
    begin
      psversion = `#{powershell} -NoProfile -NonInteractive -NoLogo -ExecutionPolicy Bypass -Command \"$PSVersionTable.PSVersion.Major.ToString()\"`.chomp!.to_i
      puts "PowerShell major version number is #{psversion}"
    rescue
      puts "Unable to determine PowerShell version"
      psversion = -1    
    end
    psversion
  end
end

RSpec.configure do |config|
  tmpdir = Dir.mktmpdir("rspecrun_powershell")
  oldtmpdir = Dir.tmpdir()
  ENV['TMPDIR'] = tmpdir

  if Puppet::Util::Platform.windows?
    config.output_stream = $stdout
    config.error_stream = $stderr
    config.formatters.each { |f| f.instance_variable_set(:@output, $stdout) }
  end

  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

  config.after :suite do
    # return to original tmpdir
    ENV['TMPDIR'] = oldtmpdir
    if Puppet::Util::Platform.windows?
      take_ownership(tmpdir)
    end
    FileUtils.rm_rf(tmpdir)
  end
end

# We need this because the RAL uses 'should' as a method.  This
# allows us the same behavior but with a different method name.
class Object
  alias :must :should
  alias :must_not :should_not
end
