#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/util'

describe Puppet::Type.type(:exec).provider(:powershell), :if => Puppet.features.microsoft_windows? do
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

  describe "#run", :if => Puppet::Util.which('powershell.exe') do
    it "should quote powershell.exe path" do
      Puppet::Util::Execution.expects(:execute).
        with(regexp_matches(/^cmd.exe \/c ""#{Regexp.escape(powershell)}" .*"/), anything)
      provider.run(command)
    end

    it "should quote the path to the temp file" do
      path = 'C:\Users\albert\AppData\Local\Temp\puppet-powershell20130715-788-1n66f2j.ps1'

      provider.expects(:write_script).with(command).yields(path)
      Puppet::Util::Execution.expects(:execute).
        with(regexp_matches(/^cmd.exe \/c ".* < "#{Regexp.escape(path)}""/), anything)

      provider.run(command)
    end

    it "should supply default arguments to supress user interaction" do
      Puppet::Util::Execution.expects(:execute).
        with(regexp_matches(/^cmd.exe \/c ".* #{args} < .*"/), anything)

      provider.run(command)
    end

    it "returns the output and status" do
      output, status = provider.run(command)
      expect(output).to match(/SID\s+:\s+S-1-5-18/)
      expect(status).to be_kind_of(Process::Status)
      expect(status.exitstatus).to eq(0)
    end

    it "returns true if the `onlyif` check command succeeds" do
      resource[:onlyif] = command

      resource.parameter(:onlyif).check(command).should be_true
    end

    it "returns false if the `unless` check command succeeds" do
      resource[:unless] = command

      resource.parameter(:unless).check(command).should be_false
    end
  end

  describe "#checkexe" do
    it "should skip checking the exe" do
      provider.checkexe(command).should be_nil
    end
  end

  describe "#validatecmd" do
    it "should always successfully validate the command to execute" do
      provider.validatecmd(command).should be_true
    end
  end
end
