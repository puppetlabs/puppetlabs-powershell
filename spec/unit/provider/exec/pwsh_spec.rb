#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/util'
require 'fileutils'

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

  let(:pwsh) {
    if !Puppet::Util::Platform.windows?
      'pwsh'
    elsif File.exists?("#{ENV['ProgramFiles']}\\PowerShell\\6\\pwsh.exe")
      "#{ENV['ProgramFiles']}\\PowerShell\\6\\pwsh.exe"
    elsif File.exists?("#{ENV['ProgramFiles(x86)']}\\PowerShell\\6\\pwsh.exe")
      "#{ENV['ProgramFiles(x86)']}\\PowerShell\\6\\pwsh.exe"
    else
      'pwsh.exe'
    end
  }

  describe "#run" do
    context "stubbed calls" do
      before :each do
        Puppet::Provider::Exec.any_instance.stubs(:run)
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

      it "should quote the path to the temp file", :if => Puppet.features.microsoft_windows? do
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
    end

    context "actual runs" do
      # The usage of uname is a little fragile however there is basically nothing
      # which is universal across all Linux/Unix/Mac distributions; Unlike Well Known SIDS in Windows
      # The closest is the presence of the uname command and its generic text output
      let(:command) { Puppet.features.microsoft_windows? ?
        '$(Get-CIMInstance Win32_Account -Filter "SID=\'S-1-5-18\'") | Format-List' :
        '& uname' }
      let(:command_output_regex) { Puppet.features.microsoft_windows? ? /SID\s+:\s+S-1-5-18/ : /(Linux|Darwin)/ }

      it "returns the output and status" do
        output, status = provider.run(command)

        expect(output).to match(command_output_regex)
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

      it "runs commands properly that output to multiple streams" do
        command = Puppet.features.microsoft_windows? ?
          'echo "foo"; [System.Console]::Error.WriteLine("bar"); cmd.exe /c foo.exe' :
          'echo "foo"; [System.Console]::Error.WriteLine("bar"); & foo.exe'
        expected = Puppet.features.microsoft_windows? ?
          "foo\nbar\n'foo.exe' is not recognized as an internal or external command,\noperable program or batch file.\n" :
          "^foo\nbar\n.+The term \'foo\.exe\' is not recognized as the name of a cmdlet, function.+"

        output, status = provider.run(command)

        # Due to the different behaviour of uname across non-Windows platforms, must use a regex
        expect(output).to match(expected)
        expect(status.exitstatus).to eq(1)
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

  describe 'when specifying a working directory' do
    describe 'that does not exist' do
      let(:work_dir)  {
        if Puppet.features.microsoft_windows?
          "#{ENV['SYSTEMROOT']}\\some\\directory\\that\\does\\not\\exist"
        else
          '/some/directory/that/does/not/exist'
        end
      }
      let(:command)  { 'exit 0' }
      let(:resource) { Puppet::Type.type(:exec).new(:command => command, :provider => :pwsh, :cwd => work_dir) }
      let(:provider) { described_class.new(resource) }

      it 'emits an error when working directory does not exist' do
        expect { provider.run(command) }.to raise_error(/Working directory .+ does not exist/)
      end
    end
  end
end
