#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/util'
require 'fileutils'

class MockPowerShellManager
  def execute_resource(*_args)
    return "", ""
  end
end

describe Puppet::Type.type(:exec).provider(:pwsh) do
  # Override the run value so we can test the super call
  # There is no real good way to do this otherwise, previously we were
  # testing Puppet internals that changed in 3.4.0 and made the specs
  # no longer work the way they were originally specified.
  Puppet::Type::Exec::ProviderPwsh.instance_eval do
    alias_method :run_spec_override, :run
  end

  let(:command)  { '$(Get-CIMInstance Win32_Account -Filter "SID=\'S-1-5-18\'") | Format-List' }
  let(:args) { '-NoProfile -NonInteractive -NoLogo -ExecutionPolicy Bypass -Command -' }

  let(:resource) { Puppet::Type.type(:exec).new(:command => command, :provider => :pwsh) }
  let(:provider) { described_class.new(resource) }

  before :each do
    # Always assume the pwsh binary is available
    provider.stubs(:get_pwsh_command).returns('somepath/pwsh')
  end

  describe "#run" do
    before :each do
      Puppet::Provider::Exec.any_instance.stubs(:run)
      PuppetX::PowerShell::PowerShellManager.stubs(:instance).returns(MockPowerShellManager.new)
    end

    context 'when the powershell manager is not supported' do
      before :each do
        PuppetX::PowerShell::PowerShellManager.stubs(:supported_on_pwsh?).returns(false)
      end

      let(:shell_command) { Puppet.features.microsoft_windows? ? 'cmd.exe /c' : '/bin/sh -c' }

      it "should call exec run" do
        Puppet::Type::Exec::ProviderPwsh.any_instance.expects(:run)

        provider.run_spec_override(command)
      end

      it "should call shell command" do
        Puppet::Type::Exec::ProviderPwsh.any_instance.expects(:run)
          .with(regexp_matches(/#{shell_command}/), anything)

        provider.run_spec_override(command)
      end

      it "should quote the path to the temp file" do
        skip('Not on Windows platform') unless Puppet.features.microsoft_windows?
        # Path quoting is only required on Windows
        path = 'C:\Users\albert\AppData\Local\Temp\puppet-powershell20130715-788-1n66f2j.ps1'

        provider.expects(:write_script).with(command).yields(path)
        Puppet::Type::Exec::ProviderPwsh.any_instance.expects(:run).
          with(regexp_matches(/^#{shell_command} .* < "#{Regexp.escape(path)}"/), false)

        provider.run_spec_override(command)
      end

      it "should supply default arguments to supress user interaction" do
        Puppet::Type::Exec::ProviderPwsh.any_instance.expects(:run).
          with(regexp_matches(/^#{shell_command} .* #{args} < .*"/), false)

        provider.run_spec_override(command)
      end

      context 'when specifying a path' do
        let(:path) { Puppet::Util::Platform.windows? ? 'C:/pwsh-test' : '/pwsh-test' }
        let(:pwsh_path) { path + '/pwsh' }
        let(:native_pwsh_path) { Puppet::Util::Platform.windows? ? pwsh_path.gsub(File::SEPARATOR, File::ALT_SEPARATOR) : pwsh_path }
        let(:native_pwsh_path_regex) { /#{Regexp.escape(native_pwsh_path)}/ }

        let(:resource) { Puppet::Type.type(:exec).new(:command => command, :provider => :pwsh, :path => path) }

        it 'should prefer pwsh in the specified path' do
          # Pretend that only the test pwsh binary exists.
          FileTest.stubs(:file?).with() { |value| value == pwsh_path}.returns(true)
          FileTest.stubs(:file?).with() { |value| value != pwsh_path}.returns(false)
          FileTest.stubs(:executable?).with() { |value| value == pwsh_path}.returns(true)
          FileTest.stubs(:executable?).with() { |value| value != pwsh_path}.returns(false)
          # Remove the global stub here as we're testing this method
          provider.unstub(:get_pwsh_command)

          Puppet::Type::Exec::ProviderPwsh.any_instance.expects(:run).
            with(regexp_matches(native_pwsh_path_regex), false)

          provider.run_spec_override(command)
        end
      end
    end

    it "should only attempt to find pwsh once when pwsh exists" do
      # Need to unstub to force the 'only once' expectation. Otherwise the
      # previous stub takes over if it's called more than once.
      provider.unstub(:get_pwsh_command)
      provider.expects(:get_pwsh_command).once.returns('somepath/pwsh')

      provider.run_spec_override(command)
      provider.run_spec_override(command)
      provider.run_spec_override(command)
    end
  end

  describe "#checkexe" do
    it "should skip checking the exe" do
      expect(provider.checkexe(command)).to be_nil
    end
  end

  describe "#validatecmd" do
    it "should always successfully validate the command to execute" do
      expect(provider.validatecmd(command)).to eq(true)
    end
  end
end
