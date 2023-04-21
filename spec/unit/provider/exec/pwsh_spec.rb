#!/usr/bin/env ruby
# frozen_string_literal: true

require 'spec_helper'
require 'puppet/util'
require 'ruby-pwsh'

describe Puppet::Type.type(:exec).provider(:pwsh) do
  # Override the run value so we can test the super call
  # There is no real good way to do this otherwise, previously we were
  # testing Puppet internals that changed in 3.4.0 and made the specs
  # no longer work the way they were originally specified.
  Puppet::Type::Exec::ProviderPwsh.instance_eval do
    alias_method :run_spec_override, :run
  end

  subject(:provider) do
    described_class.new(resource)
  end

  let(:command) { '$(Get-CIMInstance Win32_Account -Filter "SID=\'S-1-5-18\'") | Format-List' }
  let(:args) { '-NoProfile -NonInteractive -NoLogo -ExecutionPolicy Bypass -Command -' }

  let(:resource) { Puppet::Type.type(:exec).new(:command => command, :provider => :pwsh) }

  before do
    # Always assume the pwsh binary is available
    allow(Pwsh::Manager).to receive(:pwsh_path).and_return('somepath/pwsh')
  end

  describe "#run" do
    before do
      allow_any_instance_of(Puppet::Provider::Exec).to receive(:run)
      allow(provider).to receive(:execute_resource).and_return('', '')
    end

    context 'when the powershell manager is not supported' do
      before do
        Pwsh::Manager.stub(:pwsh_supported?).and_return(false)
      end

      let(:shell_command) { Puppet.features.microsoft_windows? ? 'cmd.exe /c' : '/bin/sh -c' }

      it "calls exec run" do
        expect(provider).to receive(:run)
        provider.run_spec_override(command)
      end

      it "calls shell command" do
        expect(provider).to receive(:run).with(/#{shell_command}/, anything)
        provider.run_spec_override(command)
      end

      it "supplies default arguments to supress user interaction" do
        expect(provider).to receive(:run).with(/#{shell_command} .* #{args} < .*/, false)
        provider.run_spec_override(command)
      end

      it "quotes the path to the temp file" do
        skip('Not on Windows platform') unless Puppet.features.microsoft_windows?
        # Path quoting is only required on Windows
        path = 'C:\Users\albert\AppData\Local\Temp\puppet-powershell20130715-788-1n66f2j.ps1'

        expect(provider).to receive(:write_script).with(command).and_yield(path)
        expect(provider).to receive(:run).with(/#{shell_command} .* #{args} < .*/, false)

        provider.run_spec_override(command)
      end

      context 'when specifying a path' do
        let(:path) { Puppet::Util::Platform.windows? ? 'C:/pwsh-test' : '/pwsh-test' }
        let(:pwsh_path) { Puppet::Util::Platform.windows? ? path + '/pwsh.exe' : path + '/pwsh' }
        let(:native_pwsh_path) { Puppet::Util::Platform.windows? ? pwsh_path.gsub(File::SEPARATOR, File::ALT_SEPARATOR) : pwsh_path }
        let(:native_pwsh_path_regex) { /#{Regexp.escape(native_pwsh_path)}/ }

        let(:resource) { Puppet::Type.type(:exec).new(:command => command, :provider => :pwsh, :path => path) }

        it 'prefers pwsh in the specified path' do
          # Pretend that only the test pwsh binary exists.
          allow(File).to receive(:exist?).and_return(true)
          # Remove the global stub here as we're testing this method
          allow(Pwsh::Manager).to receive(:pwsh_path).and_call_original

          expect(provider).to receive(:run).with(native_pwsh_path_regex, false)
          provider.run_spec_override(command)
        end
      end
    end

    it "onlies attempt to find pwsh once when pwsh exists" do
      # Need to unstub to force the 'only once' expectation. Otherwise the
      # previous stub takes over if it's called more than once.
      allow(Pwsh::Manager).to receive(:pwsh_path).and_call_original
      expect(Pwsh::Manager).to receive(:pwsh_path).once.and_return('somepath/pwsh')

      provider.run_spec_override(command)
      provider.run_spec_override(command)
      provider.run_spec_override(command)
    end
  end

  describe "#checkexe" do
    it "skips checking the exe" do
      expect(provider.checkexe(command)).to be_nil
    end
  end

  describe "#validatecmd" do
    it "alwayses successfully validate the command to execute" do
      expect(provider.validatecmd(command)).to be(true)
    end
  end
end
