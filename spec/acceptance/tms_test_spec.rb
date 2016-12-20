require 'spec_helper_acceptance'

describe 'powershell provider:' do #, :unless => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do
  windows_agents = agents.select { |a| a.platform =~ /windows/ }

  describe 'should run successfully' do

    pp = <<-MANIFEST
      exec{'TestPowershell':
        command   => 'Get-Process > c:/process.txt',
        unless    => 'if(!(test-path "c:/process.txt")){exit 1}',
        provider  => powershell,
      }
    MANIFEST

    it '[POC] TMS - puppet agent run on default' do
      execute_manifest(pp, :catch_failures => true, :acceptable_exit_codes => [0]) do |r|
        expect(r.stderror).not_to match(/error/i)
      end
    end

    it '[POC] TMS - puppet agent run on windows agents' do
      execute_manifest_on(windows_agents, pp, :catch_failures => true, :acceptable_exit_codes => [0]) do |r|
        expect(r.stderror).not_to match(/error/i)
      end
    end
  end
end

