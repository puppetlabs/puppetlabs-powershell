#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/util'
require 'fileutils'

# Helper function to determine if PowerShell Core (pwsh) is available in the PATH.
$pwsh_path_exist = nil
def pwsh_exist?
  return $pwsh_path_exist unless $pwsh_path_exist.nil?

  name = Puppet.features.microsoft_windows? ? 'pwsh.exe' : 'pwsh'
  result = ENV['PATH'].split(File::PATH_SEPARATOR).map {|p| File.join(p, name)}.find {|f| File.executable?(f)}

  $pwsh_path_exist = !result.nil?
end

describe Puppet::Type.type(:exec).provider(:pwsh) do
  let(:command)  { '$(Get-CIMInstance Win32_Account -Filter "SID=\'S-1-5-18\'") | Format-List' }
  let(:args) { '-NoProfile -NonInteractive -NoLogo -ExecutionPolicy Bypass -Command -' }

  let(:resource) { Puppet::Type.type(:exec).new(:command => command, :provider => :pwsh) }
  let(:provider) { described_class.new(resource) }

  describe "#run" do
    # The usage of uname is a little fragile however there is basically nothing
    # which is universal across all Linux/Unix/Mac distributions; Unlike Well Known SIDS in Windows
    # The closest is the presence of the uname command and its generic text output
    let(:command) { Puppet.features.microsoft_windows? ?
      '$(Get-CIMInstance Win32_Account -Filter "SID=\'S-1-5-18\'") | Format-List' :
      '& uname' }
    let(:command_output_regex) { Puppet.features.microsoft_windows? ? /SID\s+:\s+S-1-5-18/ : /(Linux|Darwin)/ }

    it "returns the output and status" do
      skip('Could not locate pwsh binary') unless pwsh_exist?
      output, status = provider.run(command)

      expect(output).to match(command_output_regex)
      expect(status.exitstatus).to eq(0)
    end

    it "returns true if the `onlyif` check command succeeds" do
      skip('Could not locate pwsh binary') unless pwsh_exist?
      resource[:onlyif] = command

      expect(resource.parameter(:onlyif).check(command)).to eq(true)
    end

    it "returns false if the `unless` check command succeeds" do
      skip('Could not locate pwsh binary') unless pwsh_exist?
      resource[:unless] = command

      expect(resource.parameter(:unless).check(command)).to eq(false)
    end

    it "runs commands properly that output to multiple streams" do
      skip('Could not locate pwsh binary') unless pwsh_exist?
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
