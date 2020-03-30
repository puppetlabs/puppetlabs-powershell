require 'spec_helper_acceptance'

def windows_platform?
  os[:family] == 'windows'
end

describe 'pwsh provider:' do
  def platform_string(windows, posix)
    windows_platform? ? windows : posix
  end

  context 'when pwsh is not installed' do
    before(:all) do
      uninstall_pwsh if pwsh_installed?
      raise 'failed to remove pwsh' if pwsh_installed?
    end

    let(:manifest) {
      <<-MANIFEST
        exec{'TestPowershell':
          command   => 'Get-Process > /process.txt',
          unless    => 'if(!(test-path "/process.txt")){exit 1}',
          provider  => pwsh,
        }
      MANIFEST
    }

    it 'errors because pwsh is not in the path' do
      fail 'pwsh not discovered in the path' unless pwsh_installed? == false
      apply_manifest(manifest, expect_failures: true) do |result|
        expect(result.stderr).to match(%r{Could not evaluate: No pwsh discovered!})
      end
    end
  end

  # Skip during localhost testing on Windows because of issues with
  # installing software and pathing during the same run.
  context 'when pwsh is installed', unless: localhost_windows? do
    before(:all) do
      install_pwsh unless pwsh_installed?
      raise 'failed to install pwsh' unless pwsh_installed?
    end

    shared_examples 'should fail' do |manifest, error_check|
      it 'should throw an error' do
        result = apply_manifest(manifest, expect_failures: true)
        unless error_check.nil?
          expect(result.stderr).to match(error_check)
        end
      end
    end
  
    shared_examples 'apply success' do |manifest|
      it 'should succeed' do
        apply_manifest(manifest, catch_failures: true)
      end
    end
  
    shared_examples 'standard exec' do |powershell_cmd|
      padmin = <<-MANIFEST
        exec{'no fail test':
          command  => '#{powershell_cmd}',
          provider => pwsh,
        }
      MANIFEST
      it 'should not fail' do
        apply_manifest(padmin, catch_failures: true)
      end
    end
  
    describe "should run successfully" do
      context "on #{os[:family]}" do
        let(:manifest) {
          if windows_platform?
            <<-MANIFEST
              exec{'TestPowershell':
                command   => 'Get-Process > c:/process.txt',
                unless    => 'if(!(test-path "c:/process.txt")){exit 1}',
                provider  => pwsh,
              }
            MANIFEST
          else
            <<-MANIFEST
              exec{'TestPowershell':
                command   => 'Get-Process > /tmp/process.txt',
                unless    => 'if(!(test-path "/tmp/process.txt")){exit 1}',
                provider  => pwsh,
              }
            MANIFEST
          end
        }
  
        it 'is idempotent' do
          idempotent_apply(manifest)
        end
      end
    end
  
    describe 'should handle a try/catch successfully' do
      context "on #{os[:family]}" do
        let(:try_successfile) { platform_string('C:\try_success.txt','/tmp/try_success.txt') }
        let(:try_failfile) { platform_string('C:\try_shouldntexist.txt','/tmp/try_shouldntexist.txt') }
        let(:catch_successfile) { platform_string('C:\catch_success.txt','/tmp/catch_success.txt') }
        let(:catch_failfile) { platform_string('C:\catch_shouldntexist.txt','/tmp/catch_shouldntexist.txt') }
        let(:try_content) { 'try_executed' }
        let(:catch_content) { 'catch_executed' }
  
        it 'should demonstrably execute PowerShell code inside a try block' do
          powershell_cmd = <<-CMD
          try {
          $foo = @(1, 2, 3).count
          "#{try_content}" | Out-File -FilePath "#{try_successfile}" -Encoding "ASCII"
          } catch {
          "catch_executed" | Out-File -FilePath "#{catch_failfile}" -Encoding "ASCII"
          }
          CMD
  
          manifest = <<-MANIFEST
          exec{'TestPowershell':
            command  => '#{powershell_cmd}',
            provider => pwsh,
          }
          MANIFEST
  
          apply_manifest(manifest, catch_failures: true)
  
          run_shell(platform_string("cmd.exe /c \"type #{try_successfile}\"","cat #{try_successfile}")) do |result|
            expect(result.stdout).to match(/#{try_content}/)
          end
  
          run_shell(platform_string("cmd.exe /c \"type #{catch_failfile}\"","cat #{catch_failfile}"), expect_failures: true) do |result|
            if windows_platform?
              expect(result.stderr).to match(/The system cannot find the file specified\./)
            else
              expect(result.stderr).to match(/No such file or directory/)
            end
          end
        end
  
        it 'should demonstrably execute PowerShell code inside a catch block' do
          powershell_cmd = <<-CMD
          try {
          throw "execute catch!"
          "try_executed" | Out-File -FilePath "#{try_failfile}" -Encoding "ASCII"
          } catch {
          "#{catch_content}" | Out-File -FilePath "#{catch_successfile}" -Encoding "ASCII"
          }
          CMD
  
          p1 = <<-MANIFEST
          exec{'TestPowershell':
            command  => '#{powershell_cmd}',
            provider => pwsh,
          }
          MANIFEST
  
          apply_manifest(p1, catch_failures: true)
  
          run_shell(platform_string("cmd.exe /c \"type #{catch_successfile}\"","cat #{catch_successfile}")) do |result|
            expect(result.stdout).to match(/#{catch_content}/)
          end
  
          run_shell(platform_string("cmd.exe /c \"type #{try_failfile}\"","cat #{try_failfile}"), expect_failures: true) do |result|
            if windows_platform?
              expect(result.stderr).to match(/The system cannot find the file specified\./)
            else
              expect(result.stderr).to match(/No such file or directory/)
            end
          end
        end
      end
    end
  
    describe 'should run commands that exit session' do
      let(:manifest) { <<-MANIFEST
        exec{'TestPowershell':
          command   => 'exit 0',
          provider  => pwsh,
        }
      MANIFEST
      }
  
      it 'should not error on first run' do
        apply_manifest(manifest, expect_changes: true)
      end
  
      it 'should run a second time' do
        apply_manifest(manifest, expect_changes: true)
      end
    end
  
    describe 'should run commands that break session' do
      let(:manifest) { <<-MANIFEST
        exec{'TestPowershell':
          command   => 'Break',
          provider  => pwsh,
        }
      MANIFEST
      }
  
      it 'should not error on first run' do
        apply_manifest(manifest, expect_changes: true)
      end
  
      it 'should run a second time' do
        apply_manifest(manifest, expect_changes: true)
      end
    end
  
    describe 'should run commands that return from session' do
      let(:manifest) { <<-MANIFEST
        exec{'TestPowershell':
          command   => 'return 0',
          provider  => pwsh,
        }
      MANIFEST
      }
  
      it 'should not error on first run' do
        apply_manifest(manifest, expect_changes: true)
      end
  
      it 'should run a second time' do
        apply_manifest(manifest, expect_changes: true)
      end
  
    end
  
    describe 'should not leak variables across calls to single session' do
      let(:var_leak_setup) { <<-MANIFEST
        exec{'TestPowershell':
          command   => '$special=1',
          provider  => pwsh,
        }
      MANIFEST
      }
  
      let(:var_leak_test) { <<-MANIFEST
        exec{'TestPowershell':
          command   => 'if ( $special -eq 1 ) { exit 1 } else { exit 0 }',
          provider  => pwsh,
        }
      MANIFEST
      }
  
      it 'should not see variable from previous run' do
        # Setup the variable
        apply_manifest(var_leak_setup, expect_changes: true)
  
        # Test to see if subsequent call sees the variable
        apply_manifest(var_leak_test, expect_changes: true)
      end
    end
  
    describe 'should not leak environment variables across calls to single session' do
      let(:envar_leak_setup) { <<-MANIFEST
        exec{'TestPowershell':
          command   => "\\$env:superspecial='1'",
          provider  => pwsh,
        }
      MANIFEST
      }
  
      let(:envar_leak_test) { <<-MANIFEST
        exec{'TestPowershell':
          command   => "if ( \\$env:superspecial -eq '1' ) { exit 1 } else { exit 0 }",
          provider  => pwsh,
        }
      MANIFEST
      }
  
      let(:envar_ext_test) { <<-MANIFEST
        exec{'TestPowershell':
          command   => "if ( \\$env:outside -eq '1' ) { exit 0 } else { exit 1 }",
          provider  => pwsh,
        }
      MANIFEST
      }
  
      after(:each) do
        # Due to https://tickets.puppetlabs.com/browse/BKR-1088, need to use different commands
        if windows_platform?
          run_shell(PuppetLitmus::Util.interpolate_powershell("Remove-Item Env:\\superspecial -ErrorAction Ignore;exit 0"))
          run_shell(PuppetLitmus::Util.interpolate_powershell("Remove-Item Env:\\outside -ErrorAction Ignore;exit 0"))
        else
          run_shell('unset superspecial')
          run_shell('unset outside')
        end
      end
  
      it 'should not see environment variable from previous run' do
        # Setup the environment variable
        apply_manifest(envar_leak_setup, expect_changes: true)
  
        # Test to see if subsequent call sees the environment variable
        apply_manifest(envar_leak_test, expect_changes: true)
      end
  
      it 'should see environment variables set outside of session' do
        # Setup the environment variable outside of Puppet
  
        # Due to https://tickets.puppetlabs.com/browse/BKR-1088, need to use different commands
        if windows_platform?
          run_shell(PuppetLitmus::Util.interpolate_powershell("\$env:outside='1'"))
        else
          run_shell('export outside=1')
        end
  
        # Test to see if initial run sees the environment variable
        apply_manifest(envar_leak_test, expect_changes: true)
  
        # Test to see if subsequent call sees the environment variable and environment purge
        apply_manifest(envar_leak_test, expect_changes: true)
      end
    end
  
    describe 'should allow exit from unless' do
      let(:unless_not_triggered) { <<-MANIFEST
        exec{'TestPowershell':
          command   => 'exit 0',
          unless    => 'exit 1',
          provider  => pwsh,
        }
      MANIFEST
      }
  
      let(:unless_triggered) { <<-MANIFEST
        exec{'TestPowershell':
          command   => 'exit 0',
          unless    => 'exit 0',
          provider  => pwsh,
        }
      MANIFEST
      }
  
      it 'should RUN command if unless is NOT triggered' do
        apply_manifest(unless_not_triggered, expect_changes: true)
      end
  
      it 'should NOT run command if unless IS triggered' do
        apply_manifest(unless_triggered, catch_changes: true)
      end
    end
  
    describe 'should allow exit from onlyif' do
      let(:onlyif_not_triggered) { <<-MANIFEST
        exec{'TestPowershell':
          command   => 'exit 0',
          onlyif    => 'exit 1',
          provider  => pwsh,
        }
      MANIFEST
      }
  
      let(:onlyif_triggered) { <<-MANIFEST
        exec{'TestPowershell':
          command   => 'exit 0',
          onlyif    => 'exit 0',
          provider  => pwsh,
        }
      MANIFEST
      }
  
      it 'should NOT run command if onlyif is NOT triggered' do
        apply_manifest(onlyif_not_triggered, catch_changes: true)
      end
  
      it 'should RUN command if onlyif IS triggered' do
        apply_manifest(onlyif_triggered, expect_changes: true)
      end
    end
  
    describe 'should be able to access the files after execution' do
      let(:manifest) { <<-MANIFEST
        exec{"TestPowershell":
          command   => ' "puppet" | Out-File -FilePath #{file_path} -Encoding UTF8',
          provider  => pwsh
        }
      MANIFEST
      }
  
      win_file = 'C:/services.txt'
      posix_file = '/tmp/services.txt'
  
      describe file(windows_platform? ? win_file : posix_file) do
        let(:file_path) { windows_platform? ? win_file : posix_file }
  
        it 'should apply the manifest' do
          apply_manifest(manifest, catch_failures: true)
        end
  
        it { should be_file() }
        its(:content) { should match /puppet/ }
      end
    end
  
    describe 'should catch and rethrow exceptions up to puppet' do
      pexception = <<-MANIFEST
        exec{'PowershellException':
          provider  => pwsh,
          command   => 'throw "We are writing an error"',
        }
      MANIFEST
      it_should_behave_like 'should fail', pexception, /We are writing an error/i
    end
  
    describe 'should error if timeout is exceeded' do
      ptimeoutexception = <<-MANIFEST
        exec{'PowershellException':
          command  => 'Write-Host "Going to sleep now..."; Start-Sleep 5',
          timeout  => 2,
          provider => pwsh,
        }
      MANIFEST
      it_should_behave_like 'should fail', ptimeoutexception
    end
  
    describe 'should be able to execute a ps1 file provided' do
      let(:manifest) { <<-MANIFEST
      file{'#{external_script}':
        content => '#{File.open(File.join(File.dirname(__FILE__), external_fixture)).read()}'
      }
      exec{"TestPowershellPS1":
        command   => '#{external_script}',
        provider  => pwsh,
        require   => File['#{external_script}']
      }
      MANIFEST
      }
  
      win_file = 'c:/temp/commands.csv'
      posix_file = '/tmp/commands.csv'
  
      describe file(windows_platform? ? win_file : posix_file) do
        let(:external_script) { windows_platform? ? 'c:/external-script.ps1' : '/tmp/external-script.ps1' }
        let(:external_fixture) { "files/get-command-#{platform_string('win', 'posix')}.ps1" }
  
        it 'should apply the manifest' do
          apply_manifest(manifest, catch_failures: true)
        end
  
        it { should be_file }
        its(:content) { should match /Get-Command/ }
      end
    end
  
    describe 'passing parameters to the ps1 file' do
      let(:manifest) { <<-MANIFEST
        $commandName = '#{commandName}'
        $outFile = '#{outfile}'
  
        file{'#{external_script}':
          content => '#{File.open(File.join(File.dirname(__FILE__), 'files/param_script-posix.ps1')).read()}'
        }
        exec{'run this with param':
          provider => pwsh,
          command	 => "#{external_script} -CommandName '$commandName' -FileOut '$outFile'",
          require  => File['#{external_script}'],
      }
      MANIFEST
      }
  
      win_file = 'c:/temp/params.csv'
      posix_file = '/tmp/params.csv'
  
      describe file(windows_platform? ? win_file : posix_file) do
        let(:external_script) { windows_platform? ? 'C:\\param_script.ps1' : '/tmp/param_script.ps1' }
        let(:outfile) { windows_platform? ? win_file : posix_file }
        let(:commandName) { 'Export-Csv' }
  
  
        it 'should apply the manifest' do
          apply_manifest(manifest, catch_failures: true)
        end
  
        it { should be_file }
        its(:content) { should match /#{commandName}/ }
      end
    end
  
    describe 'should execute using 64 bit powershell', if: windows_platform? do
      # Only applicable to Windows platforms
      p3 = <<-MANIFEST
       $maxArchNumber = $::architecture? {
        /(?i)(i386|i686|x86)$/	=> 4,
        /(?i)(x64|x86_64)/=> 8,
        default => 0
      }
      exec{'Test64bit':
        command => "if([IntPtr]::Size -eq $maxArchNumber) { exit 0 } else { Write-Error 'Architecture mismatch' }",
        provider => pwsh
      }
      MANIFEST
      it_should_behave_like 'apply success', p3
    end
  
    describe 'test admin rights', if: windows_platform? do
      # Only applicable to Windows platforms
      ps1 = <<-PS1
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $pr = New-Object Security.Principal.WindowsPrincipal $id
        if(!($pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))){Write-Error "Not in admin"}
      PS1
      it_should_behave_like 'standard exec', ps1
    end
  
    describe 'test import-module' do
      pimport = <<-PS1
        $mods = Get-Module -ListAvailable
        if($mods.Length -lt 1) {
          Write-Error "Expected to get at least one module, but none were listed"
        }
        Import-Module $mods[0].Name
        if(-not (Get-Module $mods[0].Name)){
          Write-Error "Failed to import module ${mods[0].Name}"
        }
      PS1
      it_should_behave_like 'standard exec', pimport
    end

    # TODO: For some reason, Puppet still sees the dependent module as available during
    # a localhost run, but not when testing against a remote target.
    describe 'without pwshlib available', unless: (ENV['TARGET_HOST'] == 'localhost') do
      before(:all) do
        remove_pwshlib
      end
      after(:all) do
        install_pwshlib
      end
    
      let(:manifest) {
        <<-MANIFEST
          exec{'TestPowershell':
            command   => 'Get-Process > /process.txt',
            unless    => 'if(!(test-path "/process.txt")){exit 1}',
            provider  => pwsh,
          }
        MANIFEST
      }
    
      it "Errors predictably" do
        apply_manifest(manifest, expect_failures: true) do |result|
          expect(result.stderr).to match(/Provider pwsh is not functional on this host/)
        end
      end
    end
  end
end
