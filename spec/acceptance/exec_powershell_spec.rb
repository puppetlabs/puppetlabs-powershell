require 'spec_helper_acceptance'

describe 'powershell provider:' do

  powershell_agents = agents.select { |a| not_controller(a) }
  posix_agents      = powershell_agents.select { |a| a.platform =~ /^(?!windows).*$/ }
  windows_agents    = powershell_agents.select { |a| a.platform =~ /^windows.*$/ }

  # Due to https://github.com/PowerShell/PowerShell/issues/1794 the HOME directory must be passed in the environment explicitly
  # In this case, it just needs a HOME that has a valid directory, no files get stored there
  # HOME is not used on Windows so it is safe to apply hosts, no matter its platform
  let (:ps_environment) { "environment => ['HOME=/tmp']," }
  ps_environment = "environment => ['HOME=/tmp'],"

  def windows_platform?(host)
    !((host.platform =~ /^windows.*$/).nil?)
  end

  def platform_string(host, windows, posix)
    if windows_platform?(host)
      windows
    else
      posix
    end
  end

  shared_examples 'should fail' do |manifest, error_check|
    it 'should throw an error' do
      expect { apply_manifest_on(powershell_agents, manifest, :catch_failures => true, :future_parser => FUTURE_PARSER) }.to raise_error(error_check)
    end
  end

  shared_examples 'apply success' do |manifest|
    it 'should succeed' do
      apply_manifest_on(powershell_agents, manifest, :catch_failures => true, :future_parser => FUTURE_PARSER)
    end
  end

  shared_examples 'standard exec' do |powershell_cmd, host_list|
    padmin = <<-MANIFEST
      exec{'no fail test':
        command  => '#{powershell_cmd}',
        #{ps_environment}
        provider => powershell,
      }
    MANIFEST
    it 'should not fail' do
      apply_manifest_on(host_list, padmin, :catch_failures => true, :future_parser => FUTURE_PARSER)
    end
  end

  describe "should run successfully" do
    powershell_agents.each do |host|
      context "on host with platform #{host.platform}" do
        let(:manifest) {
          if windows_platform?(host)
            <<-MANIFEST
              exec{'TestPowershell':
                command   => 'Get-Process > c:/process.txt',
                unless    => 'if(!(test-path "c:/process.txt")){exit 1}',
                provider  => powershell,
              }
            MANIFEST
          else
            <<-MANIFEST
              exec{'TestPowershell':
                command   => 'Get-Process > /process.txt',
                unless    => 'if(!(test-path "/process.txt")){exit 1}',
                #{ps_environment}
                provider  => powershell,
              }
            MANIFEST
          end
        }
        
        it 'should not error on first run' do
          # Run it twice and test for idempotency
          apply_manifest_on(host, manifest, :catch_failures => true, :future_parser => FUTURE_PARSER)
        end

        it 'should be idempotent' do
          apply_manifest_on(host, manifest, :catch_failures => true, :future_parser => FUTURE_PARSER, :acceptable_exit_codes => [0])
        end
      end
    end
  end

  describe 'should handle a try/catch successfully' do
    powershell_agents.each do |host|
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

          p1 = <<-MANIFEST
          exec{'TestPowershell':
            command  => '#{powershell_cmd}',
            #{ps_environment}
            provider => powershell,
          }
          MANIFEST

          apply_manifest_on(host, p1, :catch_failures => true, :future_parser => FUTURE_PARSER)

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
            #{ps_environment}
            provider => powershell,
          }
          MANIFEST

          apply_manifest_on(host, p1, :catch_failures => true, :future_parser => FUTURE_PARSER)

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

    let(:exit_pp) { <<-MANIFEST
      exec{'TestPowershell':
        command   => 'exit 0',
        #{ps_environment}
        provider  => powershell,
      }
    MANIFEST
    }

    it 'should not error on first run' do
      apply_manifest_on(powershell_agents, exit_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)
    end

    it 'should run a second time' do
      apply_manifest_on(powershell_agents, exit_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)
    end

  end

  describe 'should run commands that break session' do

    let(:break_pp) { <<-MANIFEST
      exec{'TestPowershell':
        command   => 'Break',
        #{ps_environment}
        provider  => powershell,
      }
    MANIFEST
    }

    it 'should not error on first run' do
      apply_manifest_on(powershell_agents, break_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)
    end

    it 'should run a second time' do
      apply_manifest_on(powershell_agents, break_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)
    end

  end

  describe 'should run commands that return from session' do

    let(:return_pp) { <<-MANIFEST
      exec{'TestPowershell':
        command   => 'return 0',
        #{ps_environment}
        provider  => powershell,
      }
    MANIFEST
    }

    it 'should not error on first run' do
      apply_manifest_on(powershell_agents, return_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)
    end

    it 'should run a second time' do
      apply_manifest_on(powershell_agents, return_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)
    end

  end

  describe 'should not leak variables across calls to single session' do

    let(:var_leak_setup_pp) { <<-MANIFEST
      exec{'TestPowershell':
        command   => '$special=1',
        #{ps_environment}
        provider  => powershell,
      }
    MANIFEST
    }

    let(:var_leak_test_pp) { <<-MANIFEST
      exec{'TestPowershell':
        command   => 'if ( $special -eq 1 ) { exit 1 } else { exit 0 }',
        #{ps_environment}
        provider  => powershell,
      }
    MANIFEST
    }

    it 'should not see variable from previous run' do
      # Setup the variable
      apply_manifest_on(powershell_agents, var_leak_setup_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)

      # Test to see if subsequent call sees the variable
      apply_manifest_on(powershell_agents, var_leak_test_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)
    end

  end

  describe 'should not leak environment variables across calls to single session' do

    let(:envar_leak_setup_pp) { <<-MANIFEST
      exec{'TestPowershell':
        command   => "\\$env:superspecial='1'",
        #{ps_environment}
        provider  => powershell,
      }
    MANIFEST
    }

    let(:envar_leak_test_pp) { <<-MANIFEST
      exec{'TestPowershell':
        command   => "if ( \\$env:superspecial -eq '1' ) { exit 1 } else { exit 0 }",
        #{ps_environment}
        provider  => powershell,
      }
    MANIFEST
    }

    let(:envar_ext_test_pp) { <<-MANIFEST
      exec{'TestPowershell':
        command   => "if ( \\$env:outside -eq '1' ) { exit 0 } else { exit 1 }",
        #{ps_environment}
        provider  => powershell,
      }
    MANIFEST
    }

    after(:each) do
      # Due to https://tickets.puppetlabs.com/browse/BKR-1088, need to use different commands
      powershell_agents.each do |host|
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
      apply_manifest_on(powershell_agents, envar_leak_setup_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)

      # Test to see if subsequent call sees the environment variable
      apply_manifest_on(powershell_agents, envar_leak_test_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)
    end

    it 'should see environment variables set outside of session' do
      # Setup the environment variable outside of Puppet

      powershell_agents.each do |host|
        # Due to https://tickets.puppetlabs.com/browse/BKR-1088, need to use different commands
        if windows_platform?(host)
          on(host, powershell("\\$env:outside='1'"))
        else
          on(host, 'export outside=1')
        end
      end

      # Test to see if initial run sees the environment variable
      apply_manifest_on(powershell_agents, envar_leak_test_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)

      # Test to see if subsequent call sees the environment variable and environment purge
      apply_manifest_on(powershell_agents, envar_leak_test_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)
    end
  end

  describe 'should allow exit from unless' do

    let(:unless_not_triggered_pp) { <<-MANIFEST
      exec{'TestPowershell':
        command   => 'exit 0',
        unless    => 'exit 1',
        #{ps_environment}
        provider  => powershell,
      }
    MANIFEST
    }

    let(:unless_triggered_pp) { <<-MANIFEST
      exec{'TestPowershell':
        command   => 'exit 0',
        unless    => 'exit 0',
        #{ps_environment}
        provider  => powershell,
      }
    MANIFEST
    }

    it 'should RUN command if unless is NOT triggered' do
      apply_manifest_on(powershell_agents, unless_not_triggered_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)
    end

    it 'should NOT run command if unless IS triggered' do
      apply_manifest_on(powershell_agents, unless_triggered_pp, :catch_changes => true, :future_parser => FUTURE_PARSER)
    end

  end

  describe 'should allow exit from onlyif' do

    let(:onlyif_not_triggered_pp) { <<-MANIFEST
      exec{'TestPowershell':
        command   => 'exit 0',
        onlyif    => 'exit 1',
        #{ps_environment}
        provider  => powershell,
      }
    MANIFEST
    }

    let(:onlyif_triggered_pp) { <<-MANIFEST
      exec{'TestPowershell':
        command   => 'exit 0',
        onlyif    => 'exit 0',
        #{ps_environment}
        provider  => powershell,
      }
    MANIFEST
    }

    it 'should NOT run command if onlyif is NOT triggered' do
      apply_manifest_on(powershell_agents, onlyif_not_triggered_pp, :catch_changes => true, :future_parser => FUTURE_PARSER)
    end

    it 'should RUN command if onlyif IS triggered' do
      apply_manifest_on(powershell_agents, onlyif_triggered_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)
    end

  end

  describe 'should be able to access the files after execution' do
    let(:p2) { <<-MANIFEST
      exec{"TestPowershell":
        command   => ' "puppet" | Out-File -FilePath #{file_path} -Encoding UTF8',
        #{ps_environment}
        provider  => powershell
      }
    MANIFEST
    }

    describe file('c:/services.txt'), :if => windows_agents.count > 0 do
      let(:file_path) { 'C:/services.txt' }

      it 'should apply the manifest' do
        apply_manifest_on(windows_agents, p2, :catch_failures => true, :future_parser => FUTURE_PARSER)
      end

      it { should be_file }
      its(:content) { should match /puppet/ }
    end

    describe file('/services.txt'), :if => posix_agents.count > 0 do
      let(:file_path) { '/services.txt' }

      it 'should apply the manifest' do
        apply_manifest_on(posix_agents, p2, :catch_failures => true, :future_parser => FUTURE_PARSER)
      end

      it { should be_file }
      its(:content) { should match /puppet/ }
    end
  end

  describe 'should catch and rethrow exceptions up to puppet' do
    pexception = <<-MANIFEST
      exec{'PowershellException':
        provider  => powershell,
        #{ps_environment}
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
        #{ps_environment}
        provider => powershell,
      }
    MANIFEST
    it_should_behave_like 'should fail', ptimeoutexception
  end

  describe 'should be able to execute a ps1 file provided' do
    context 'on Windows platforms', :if => windows_agents.count > 0 do
      p2 = <<-MANIFEST
      file{'c:/services.ps1':
        content => '#{File.open(File.join(File.dirname(__FILE__), 'files/services.ps1')).read()}'
      }
      exec{"TestPowershellPS1":
        command   => 'c:/services.ps1',
        provider  => powershell,
        require   => File['c:/services.ps1']
      }
      MANIFEST
      describe file('c:/temp/services.csv') do
        apply_manifest_on(windows_agents, p2, :catch_failures => true, :future_parser => FUTURE_PARSER)
        it { should be_file }
        its(:content) { should match /puppet/ }
      end
    end
    
    context 'on POSIX platforms', :if => posix_agents.count > 0 do
      p2 = <<-MANIFEST
      file{'/external-script.ps1':
        content => '#{File.open(File.join(File.dirname(__FILE__), 'files/get-command-posix.ps1')).read()}'
      }
      exec{"TestPowershellPS1":
        command   => '/external-script.ps1',
        #{ps_environment}
        provider  => powershell,
        require   => File['/external-script.ps1']
      }
      MANIFEST

      describe file('/tmp/commands.csv') do
        apply_manifest_on(posix_agents, p2, :catch_failures => true, :future_parser => FUTURE_PARSER)
        it { should be_file }
        its(:content) { should match /Get-Command/ }
      end
    end
  end

  describe 'passing parameters to the ps1 file' do
    context 'on Windows platforms', :if => windows_agents.count > 0 do
      outfile = 'C:/temp/svchostprocess.txt'
      processName = 'svchost'
      pp = <<-MANIFEST
        $process = '#{processName}'
        $outFile = '#{outfile}'
      file{'c:/param_script.ps1':
        content => '#{File.open(File.join(File.dirname(__FILE__), 'files/param_script.ps1')).read()}'
      }
      exec{'run this with param':
        provider => powershell,
        command	 => "c:/param_script.ps1 -ProcessName '$process' -FileOut '$outFile'",
        require  => File['c:/param_script.ps1'],
      }
      MANIFEST
      describe file(outfile) do
        apply_manifest_on(windows_agents, pp, :catch_failures => true, :future_parser => FUTURE_PARSER)
        it { should be_file }
        its(:content) { should match /svchost/ }
      end
    end

    context 'on POSIX platforms', :if => posix_agents.count > 0 do
      outfile = '/tmp/export-command.txt'
      commandName = 'Export-Csv'
      pp = <<-MANIFEST
        $commandName = '#{commandName}'
        $outFile = '#{outfile}'

        file{'/param_script.ps1':
          content => '#{File.open(File.join(File.dirname(__FILE__), 'files/param_script-posix.ps1')).read()}'
        }
        exec{'run this with param':
          provider => powershell,
          #{ps_environment}
          command	 => "/param_script.ps1 -CommandName '$commandName' -FileOut '$outFile'",
          require  => File['/param_script.ps1'],
      }
      MANIFEST
      describe file(outfile) do
        apply_manifest_on(posix_agents, pp, :catch_failures => true, :future_parser => FUTURE_PARSER)
        it { should be_file }
        its(:content) { should match /Export-Csv/ }
      end
    end
  end

  describe 'should execute using 64 bit powershell', :if => windows_agents.count > 0 do
    # Only applicable to Windows platforms
    p3 = <<-MANIFEST
     $maxArchNumber = $::architecture? {
      /(?i)(i386|i686|x86)$/	=> 4,
      /(?i)(x64|x86_64)/=> 8,
      default => 0
    }
    exec{'Test64bit':
      command => "if([IntPtr]::Size -eq $maxArchNumber) { exit 0 } else { Write-Error 'Architecture mismatch' }",
      #{ps_environment}
      provider => powershell
    }
    MANIFEST
    it_should_behave_like 'apply success', p3, windows_agents
  end

  describe 'test admin rights', :if => windows_agents.count > 0 do
    # Only applicable to Windows platforms
    ps1 = <<-PS1
      $id = [Security.Principal.WindowsIdentity]::GetCurrent()
      $pr = New-Object Security.Principal.WindowsPrincipal $id
      if(!($pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))){Write-Error "Not in admin"}
    PS1
    it_should_behave_like 'standard exec', ps1, windows_agents
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
    it_should_behave_like 'standard exec', pimport, powershell_agents
  end
end
