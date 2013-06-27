#! /usr/bin/env ruby
require 'spec_helper'

describe Puppet::Type.type(:exec).provider(:powershell), :if => Puppet.features.microsoft_windows? do
  let(:command)  { '$(Get-WMIObject Win32_UserAccount -Filter "Name=\'Administrator\'")' }
  let(:args) { '-NoProfile -NonInteractive -NoLogo -ExecutionPolicy Bypass' }
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
    it "should be able to run powershell commands" do
      Puppet::Util::Execution.expects(:execute).with("\"#{powershell}\" #{args} -Command \"#{command}\"", anything)
      provider.run(command)
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
