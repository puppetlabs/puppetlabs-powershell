require 'spec_helper_acceptance'

def windows_platform?(host)
  !((host.platform =~ /^windows.*$/).nil?)
end

powershell6_agents = hosts.select { |h| !(h['powershell'].nil?) }
posix6_agents      = powershell6_agents.select { |a| !windows_platform?(a) }
windows6_agents    = powershell6_agents.select { |a| windows_platform?(a) }

describe 'pwsh provider:', :if => powershell6_agents.count > 0 do
  def platform_string(host, windows, posix)
    if windows_platform?(host)
      windows
    else
      posix
    end
  end

  shared_examples 'should fail' do |manifest, error_check|
    it 'should throw an error' do
      powershell6_agents.each do |hut|
        result = execute_manifest_on(hut, manifest, :expect_failures => true)
        unless error_check.nil?
          expect(result.stderr).to match(error_check)
        end
      end
    end
  end

  shared_examples 'apply success' do |manifest|
    it 'should succeed' do
      execute_manifest_on(powershell6_agents, manifest, :catch_failures => true)
    end
  end

  shared_examples 'standard exec' do |powershell_cmd, hosts|
    padmin = <<-MANIFEST
      exec{'no fail test':
        command  => '#{powershell_cmd}',
        provider => pwsh,
      }
    MANIFEST
    it 'should not fail' do
      execute_manifest_on(hosts, padmin, :catch_failures => true)
    end
  end

  describe "should run successfully" do
    powershell6_agents.each do |host|
      context "on host with platform #{host.platform}" do
        let(:manifest) {
          if windows_platform?(host)
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
                command   => 'Get-Process > /process.txt',
                unless    => 'if(!(test-path "/process.txt")){exit 1}',
                provider  => pwsh,
              }
            MANIFEST
          end
        }

        it 'should not error on first run' do
          # Run it twice and test for idempotency
          execute_manifest_on(host, manifest, :catch_failures => true)
        end

        it 'should be idempotent' do
          execute_manifest_on(host, manifest, :catch_chages => true)
        end
      end
    end
  end

  describe 'should handle a try/catch successfully' do
    powershell6_agents.each do |host|
      context "on host with platform #{host.platform}" do
        let(:try_successfile) { platform_string(host,'C:\try_success.txt','/try_success.txt') }
        let(:try_failfile) { platform_string(host,'C:\try_shouldntexist.txt','/try_shouldntexist.txt') }
        let(:catch_successfile) { platform_string(host,'C:\catch_success.txt','/catch_success.txt') }
        let(:catch_failfile) { platform_string(host,'C:\catch_shouldntexist.txt','/catch_shouldntexist.txt') }
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

          execute_manifest_on(host, manifest, :catch_failures => true)

          on(host, platform_string(host,"cmd.exe /c \"type #{try_successfile}\"","cat #{try_successfile}")) do |result|
            assert_match(/#{try_content}/, result.stdout, "Unexpected result for host '#{host}'")
          end

          on(host, platform_string(host,"cmd.exe /c \"type #{catch_failfile}\"","cat #{catch_failfile}"), :acceptable_exit_codes => [1]) do |result|
            if windows_platform?(host)
              assert_match(/^The system cannot find the file specified\./, result.stderr, "Unexpected file content #{result.stdout} on host '#{host}'")
            else
              assert_match(/No such file or directory/, result.stderr, "Unexpected file content #{result.stdout} on host '#{host}'")
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

          execute_manifest_on(host, p1, :catch_failures => true)

          on(host, platform_string(host,"cmd.exe /c \"type #{catch_successfile}\"","cat #{catch_successfile}")) do |result|
            assert_match(/#{catch_content}/, result.stdout, "Unexpected result for host '#{host}'")
          end

          on(host, platform_string(host,"cmd.exe /c \"type #{try_failfile}\"","cat #{try_failfile}"), :acceptable_exit_codes => [1]) do |result|
            if windows_platform?(host)
              assert_match(/^The system cannot find the file specified\./, result.stderr, "Unexpected file content #{result.stdout} on host '#{host}'")
            else
              assert_match(/No such file or directory/, result.stderr, "Unexpected file content #{result.stdout} on host '#{host}'")
            end
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
      execute_manifest_on(powershell6_agents, manifest, :expect_changes => true)
    end

    it 'should run a second time' do
      execute_manifest_on(powershell6_agents, manifest, :expect_changes => true)
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
      execute_manifest_on(powershell6_agents, manifest, :expect_changes => true)
    end

    it 'should run a second time' do
      execute_manifest_on(powershell6_agents, manifest, :expect_changes => true)
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
      execute_manifest_on(powershell6_agents, manifest, :expect_changes => true)
    end

    it 'should run a second time' do
      execute_manifest_on(powershell6_agents, manifest, :expect_changes => true)
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
      execute_manifest_on(powershell6_agents, var_leak_setup, :expect_changes => true)

      # Test to see if subsequent call sees the variable
      execute_manifest_on(powershell6_agents, var_leak_test, :expect_changes => true)
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
      powershell6_agents.each do |host|
        if windows_platform?(host)
          on(host, powershell("'Remove-Item Env:\\superspecial -ErrorAction Ignore;exit 0'"))
          on(host, powershell("'Remove-Item Env:\\outside -ErrorAction Ignore;exit 0'"))
        else
          on(host, 'unset superspecial')
          on(host, 'unset outside')
        end
      end
    end

    it 'should not see environment variable from previous run' do
      # Setup the environment variable
      execute_manifest_on(powershell6_agents, envar_leak_setup, :expect_changes => true)

      # Test to see if subsequent call sees the environment variable
      execute_manifest_on(powershell6_agents, envar_leak_test, :expect_changes => true)
    end

    it 'should see environment variables set outside of session' do
      # Setup the environment variable outside of Puppet

      powershell6_agents.each do |host|
        # Due to https://tickets.puppetlabs.com/browse/BKR-1088, need to use different commands
        if windows_platform?(host)
          on(host, powershell("\\$env:outside='1'"))
        else
          on(host, 'export outside=1')
        end
      end

      # Test to see if initial run sees the environment variable
      execute_manifest_on(powershell6_agents, envar_leak_test, :expect_changes => true)

      # Test to see if subsequent call sees the environment variable and environment purge
      execute_manifest_on(powershell6_agents, envar_leak_test, :expect_changes => true)
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
      execute_manifest_on(powershell6_agents, unless_not_triggered, :expect_changes => true)
    end

    it 'should NOT run command if unless IS triggered' do
      execute_manifest_on(powershell6_agents, unless_triggered, :catch_changes => true)
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
      execute_manifest_on(powershell6_agents, onlyif_not_triggered, :catch_changes => true)
    end

    it 'should RUN command if onlyif IS triggered' do
      execute_manifest_on(powershell6_agents, onlyif_triggered, :expect_changes => true)
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
    posix_file = '/services.txt'

    powershell6_agents.each do |node|
      describe file(windows_platform?(node) ? win_file : posix_file), :node => node do
        let(:file_path) { windows_platform?(node) ? win_file : posix_file }

        it 'should apply the manifest' do
          execute_manifest_on(node, manifest, :catch_failures => true)
        end

        it { should be_file() }
        its(:content) { should match /puppet/ }
      end
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

    powershell6_agents.each do |node|
      describe file(windows_platform?(node) ? win_file : posix_file), :node => node do
        let(:external_script) { windows_platform?(node) ? 'c:/external-script.ps1' : '/external-script.ps1' }
        let(:external_fixture) { "files/get-command-#{platform_string(node, 'win', 'posix')}.ps1" }

        it 'should apply the manifest' do
          execute_manifest_on(node, manifest, :catch_failures => true)
        end

        it { should be_file }
        its(:content) { should match /Get-Command/ }
      end
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

    powershell6_agents.each do |node|
      describe file(windows_platform?(node) ? win_file : posix_file), :node => node do
        let(:external_script) { windows_platform?(node) ? 'C:\\param_script.ps1' : '/param_script.ps1' }
        let(:outfile) { windows_platform?(node) ? win_file : posix_file }
        let(:commandName) { 'Export-Csv' }


        it 'should apply the manifest' do
          execute_manifest_on(node, manifest, :catch_failures => true)
        end

        it { should be_file }
        its(:content) { should match /#{commandName}/ }
      end
    end
  end

  describe 'should execute using 64 bit powershell', :if => windows6_agents.count > 0 do
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
    it_should_behave_like 'apply success', p3, windows6_agents
  end

  describe 'test admin rights', :if => windows6_agents.count > 0 do
    # Only applicable to Windows platforms
    ps1 = <<-PS1
      $id = [Security.Principal.WindowsIdentity]::GetCurrent()
      $pr = New-Object Security.Principal.WindowsPrincipal $id
      if(!($pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))){Write-Error "Not in admin"}
    PS1
    it_should_behave_like 'standard exec', ps1, windows6_agents
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
    it_should_behave_like 'standard exec', pimport, powershell6_agents
  end
end
