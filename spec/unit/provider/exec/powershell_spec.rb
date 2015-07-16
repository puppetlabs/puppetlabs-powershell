#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/util'

describe Puppet::Type.type(:exec).provider(:powershell) do

  # Override the run value so we can test the super call
  # There is no real good way to do this otherwise, previously we were
  # testing Puppet internals that changed in 3.4.0 and made the specs
  # no longer work the way they were originally specified.
  Puppet::Type::Exec::ProviderPowershell.instance_eval do
    alias_method :run_spec_override, :run
  end

  let(:command)  { '$(Get-WMIObject Win32_Account -Filter "SID=\'S-1-5-18\'") | Format-List' }
  let(:args) { '-NoProfile -NonInteractive -NoLogo -ExecutionPolicy Bypass -Command -' }
  let(:resource) { Puppet::Type.type(:exec).new(:command => command, :provider => :powershell) }
  let(:provider) { described_class.new(resource) }

  let(:powershell) {
    if File.exists?("#{ENV['SYSTEMROOT']}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe")
      "#{ENV['SYSTEMROOT']}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe"
    elsif File.exists?("#{ENV['SYSTEMROOT']}\\system32\\WindowsPowershell\\v1.0\\powershell.exe")
      "#{ENV['SYSTEMROOT']}\\system32\\WindowsPowershell\\v1.0\\powershell.exe"
    else
      'powershell.exe'
    end
  }

  describe "#run" do
    context "stubbed calls" do
      before :each do
        Puppet::Provider::Exec.any_instance.stubs(:run)
      end

      it "should call exec run" do
        Puppet::Type::Exec::ProviderPowershell.any_instance.expects(:run)

        provider.run_spec_override(command)
      end

      it "should call cmd.exe /c" do
        Puppet::Type::Exec::ProviderPowershell.any_instance.expects(:run)
          .with(regexp_matches(/^cmd.exe \/c/), anything)

        provider.run_spec_override(command)
      end

      it "should quote powershell.exe path", :if => Puppet.features.microsoft_windows? do
        Puppet::Type::Exec::ProviderPowershell.any_instance.expects(:run).
          with(regexp_matches(/"#{Regexp.escape(powershell)}"/), false)

        provider.run_spec_override(command)
      end

      it "should quote the path to the temp file" do
        path = 'C:\Users\albert\AppData\Local\Temp\puppet-powershell20130715-788-1n66f2j.ps1'

        provider.expects(:write_script).with(command).yields(path)
        Puppet::Type::Exec::ProviderPowershell.any_instance.expects(:run).
          with(regexp_matches(/^cmd.exe \/c ".* < "#{Regexp.escape(path)}""/), false)

        provider.run_spec_override(command)
      end

      it "should supply default arguments to supress user interaction" do
        Puppet::Type::Exec::ProviderPowershell.any_instance.expects(:run).
          with(regexp_matches(/^cmd.exe \/c ".* #{args} < .*"/), false)

        provider.run_spec_override(command)
      end
    end

    context "actual runs", :if => Puppet.features.microsoft_windows? do
      it "returns the output and status" do
        output, status = provider.run(command)

        expect(output).to match(/SID\s+:\s+S-1-5-18/)
        expect(status.exitstatus).to eq(0)
      end

      it "returns true if the `onlyif` check command succeeds" do
        resource[:onlyif] = command

        expect(resource.parameter(:onlyif).check(command)).to eq(true)
      end

      it "returns false if the `unless` check command succeeds" do
        resource[:unless] = command

        expect(resource.parameter(:unless).check(command)).to eq(false)
      end
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
