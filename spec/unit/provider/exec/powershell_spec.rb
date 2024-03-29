#!/usr/bin/env ruby
# frozen_string_literal: true

require 'spec_helper'
require 'puppet/util'
require 'fileutils'

describe Puppet::Type.type(:exec).provider(:powershell) do
  # Override the run value so we can test the super call
  # There is no real good way to do this otherwise, previously we were
  # testing Puppet internals that changed in 3.4.0 and made the specs
  # no longer work the way they were originally specified.
  Puppet::Type::Exec::ProviderPowershell.instance_eval do
    alias_method :run_spec_override, :run
  end

  subject(:provider) do
    described_class.new(resource)
  end

  let(:command) { '$(Get-WMIObject Win32_Account -Filter "SID=\'S-1-5-18\'") | Format-List' }
  let(:args) do
    if Puppet.features.microsoft_windows?
      '-NoProfile -NonInteractive -NoLogo -ExecutionPolicy Bypass -Command -'
    else
      '-NoProfile -NonInteractive -NoLogo -Command -'
    end
  end
  # Due to https://github.com/PowerShell/PowerShell/issues/1794 the HOME directory must be passed in the environment explicitly
  let(:resource) do
    Puppet::Type.type(:exec).new(command: command, provider: :powershell, environment: "HOME=#{Dir.home}")
  end

  let(:powershell) do
    if File.exist?("#{ENV.fetch('SYSTEMROOT', nil)}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe")
      "#{ENV.fetch('SYSTEMROOT', nil)}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe"
    elsif File.exist?("#{ENV.fetch('SYSTEMROOT', nil)}\\system32\\WindowsPowershell\\v1.0\\powershell.exe")
      "#{ENV.fetch('SYSTEMROOT', nil)}\\system32\\WindowsPowershell\\v1.0\\powershell.exe"
    else
      'powershell.exe'
    end
  end

  describe '#run' do
    context 'with stubbed calls' do
      before do
        require 'ruby-pwsh'
        allow(Pwsh::Manager).to receive(:windows_powershell_supported?).and_return(false)
        allow_any_instance_of(Puppet::Provider::Exec).to receive(:run)
      end

      it 'calls exec run' do
        expect(provider).to receive(:run)

        provider.run_spec_override(command)
      end

      context 'when on windows', if: Puppet.features.microsoft_windows? do
        it 'calls cmd.exe /c' do
          expect(provider).to receive(:run)
            .with(%r{^cmd.exe /c}, anything)

          provider.run_spec_override(command)
        end

        it 'quotes powershell.exe path' do
          expect(provider).to receive(:run)
            .with(/"#{Regexp.escape(powershell)}"/, false)

          provider.run_spec_override(command)
        end

        it 'quotes the path to the temp file' do
          path = 'C:\Users\albert\AppData\Local\Temp\puppet-powershell20130715-788-1n66f2j.ps1'

          expect(provider).to receive(:write_script).with(command).and_yield(path)
          expect(provider).to receive(:run)
            .with(%r{^cmd.exe /c ".* < "#{Regexp.escape(path)}""}, false)

          provider.run_spec_override(command)
        end

        it 'supplies default arguments to supress user interaction' do
          expect(provider).to receive(:run)
            .with(%r{^cmd.exe /c ".* #{args} < .*"}, false)

          provider.run_spec_override(command)
        end
      end
    end

    context 'with actual runs' do
      context 'when on Windows', if: Puppet.features.microsoft_windows? do
        it 'returns the output and status' do
          output, status = provider.run(command)

          expect(output).to match(/SID\s+:\s+S-1-5-18/)
          expect(status.exitstatus).to eq(0)
        end

        it 'returns true if the `onlyif` check command succeeds' do
          resource[:onlyif] = command

          expect(resource.parameter(:onlyif).check(command)).to be(true)
        end

        it 'returns false if the `unless` check command succeeds' do
          resource[:unless] = command

          expect(resource.parameter(:unless).check(command)).to be(false)
        end

        it 'runs commands properly that output to multiple streams' do
          command = 'echo "foo"; [System.Console]::Error.WriteLine("bar"); cmd.exe /c foo.exe'
          output, status = provider.run(command)

          expected = if Pwsh::Manager.windows_powershell_supported?
                       "foo\r\n"
                     else
                       # when PowerShellManager is not used, the v1 style module collected
                       # all streams inside of a single output string
                       [
                         "foo\n",
                         "bar\n'",
                         "foo.exe' is not recognized as an internal or external command,\n",
                         "operable program or batch file.\n"
                       ].join
                     end

          expect(output).to eq(expected)
          expect(status.exitstatus).to eq(1)
        end
      end
    end
  end

  describe '#checkexe' do
    it 'skips checking the exe' do
      expect(provider.checkexe(command)).to be_nil
    end
  end

  describe '#validatecmd' do
    it 'alwayses successfully validate the command to execute' do
      expect(provider.validatecmd(command)).to be(true)
    end
  end

  describe 'when specifying a working directory' do
    describe 'that does not exist on Windows' do
      before do
        skip('Not on Windows platform') unless Puppet.features.microsoft_windows?
      end

      # This working directory error is specific to the PowerShell manager on Windows.
      let(:work_dir) { "#{ENV.fetch('SYSTEMROOT', nil)}\\some\\directory\\that\\does\\not\\exist" }
      let(:command)  { 'exit 0' }
      let(:resource) { Puppet::Type.type(:exec).new(command: command, provider: :powershell, cwd: work_dir) }
      let(:provider) { described_class.new(resource) }

      it 'emits an error when working directory does not exist' do
        expect { provider.run(command) }.to raise_error(/Working directory .+ does not exist/)
      end
    end
  end

  describe 'when applying a catalog' do
    let(:manifest) do
      <<-MANIFEST
      exec { 'PS':
        command   => 'exit 0',
        provider  => powershell,
      }
      MANIFEST
    end
    let(:tmpdir) { Dir.mktmpdir('statetmp').encode!(Encoding::UTF_8) }

    before do
      skip('Not on Windows platform') unless Puppet.features.microsoft_windows?
      # a statedir setting must now exist per the new transactionstore code
      # introduced in Puppet 4.6 for corrective changes, as a new YAML file
      # called transactionstore.yaml will be written under this path
      # which defaults to c:\dev\null when not set on Windows
      Puppet[:statedir] = tmpdir
    end

    after do
      FileUtils.rm_rf(tmpdir)
    end

    def compile_to_catalog(string, node = Puppet::Node.new('foonode'))
      Puppet[:code] = string

      # see lib/puppet/indirector/catalog/compiler.rb#filter
      Puppet::Parser::Compiler.compile(node).filter(&:virtual?)
    end

    def compile_to_ral(manifest)
      catalog = compile_to_catalog(manifest)
      ral = catalog.to_ral
      ral.finalize
      ral
    end

    def apply_compiled_manifest(manifest)
      catalog = compile_to_ral(manifest)

      # ensure compilation works from Puppet 3.0.0 forward
      args = [catalog, Puppet::Transaction::Report.new('apply')]
      args << Puppet::Graph::SequentialPrioritizer.new if defined?(Puppet::Graph)
      transaction = Puppet::Transaction.new(*args)
      transaction.evaluate
      transaction.report.finalize_report

      transaction
    end

    it 'does not emit a warning message when PowerShellManager is usable in a Windows environment' do
      allow(Pwsh::Manager).to receive(:win32console_enabled?).and_return(false)

      expect(Pwsh::Manager.windows_powershell_supported?).to be(true)

      # given PowerShellManager is supported, never emit an upgrade message
      expect(provider).not_to receive(:upgrade_message)

      apply_compiled_manifest(manifest)
    end

    it 'emits a warning message when PowerShellManager cannot be used in a Windows environment' do
      # pretend we're Ruby 1.9.3 / Puppet 3.x x86
      allow(Pwsh::Manager).to receive(:win32console_enabled?).and_return(true)

      expect(Pwsh::Manager.windows_powershell_supported?).to be(false)

      # given PowerShellManager is NOT supported, emit an upgrade message
      expect(Puppet::Type::Exec::ProviderPowershell).to receive(:upgrade_message).once

      apply_compiled_manifest(manifest)
    end
  end
end
