require 'spec_helper_acceptance'

describe 'powershell provider:' do #, :unless => UNSUPPORTED_PLATFORMS.include?(fact('osfamily')) do
  shared_examples 'should fail' do |manifest, error_check|
    it 'should throw an error' do
      expect { apply_manifest(manifest, :catch_failures => true, :future_parser => FUTURE_PARSER) }.to raise_error(error_check)
    end
  end

  shared_examples 'apply success' do |manifest|
    it 'should succeed' do
      apply_manifest(manifest, :catch_failures => true, :future_parser => FUTURE_PARSER)
    end
  end

  describe 'should run successfully' do

    p1 = <<-MANIFEST
      exec{'TestPowershell':
        command   => 'Get-Process > c:/process.txt',
        unless    => 'if(!(test-path "c:/process.txt")){exit 1}',
        provider  => powershell,
      }
    MANIFEST

    it 'should not error on first run' do
      # Run it twice and test for idempotency
      apply_manifest(p1, :catch_failures => true, :future_parser => FUTURE_PARSER)
    end

    it 'should be idempotent' do
      expect(apply_manifest(p1, :catch_failures => true, :future_parser => FUTURE_PARSER).exit_code).to be_zero
    end

  end

  describe 'should handle a try/catch successfully' do

    powershell_cmd = <<-CMD
try{
 $foo = ls
 $count = $foo.count
 $count
}catch{
 Write-Error "foo"
}
    CMD

    p1 = <<-MANIFEST
      exec{'TestPowershell':
        command  => '#{powershell_cmd}',
        provider  => powershell,
      }
    MANIFEST

    it 'should not error' do
      apply_manifest(p1, :expect_changes => true, :future_parser => FUTURE_PARSER)
    end

  end

  describe 'should run commands that exit session' do

    exit_pp = <<-MANIFEST
      exec{'TestPowershell':
        command   => 'exit 0',
        provider  => powershell,
      }
    MANIFEST

    it 'should not error on first run' do
      apply_manifest(exit_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)
    end

    it 'should run a second time' do
      apply_manifest(exit_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)
    end

  end

  describe 'should run commands that break session' do

    break_pp = <<-MANIFEST
      exec{'TestPowershell':
        command   => 'Break',
        provider  => powershell,
      }
    MANIFEST

    it 'should not error on first run' do
      apply_manifest(break_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)
    end

    it 'should run a second time' do
      apply_manifest(break_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)
    end

  end

  describe 'should run commands that return from session' do

    return_pp = <<-MANIFEST
      exec{'TestPowershell':
        command   => 'return 0',
        provider  => powershell,
      }
    MANIFEST

    it 'should not error on first run' do
      apply_manifest(return_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)
    end

    it 'should run a second time' do
      apply_manifest(return_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)
    end

  end

  describe 'should not leak variables across calls to single session' do

    var_leak_setup_pp = <<-MANIFEST
      exec{'TestPowershell':
        command   => '$special=1',
        provider  => powershell,
      }
    MANIFEST

    var_leak_test_pp = <<-MANIFEST
      exec{'TestPowershell':
        command   => 'if ( $special -eq 1 ) { exit 1 } else { exit 0 }',
        provider  => powershell,
      }
    MANIFEST

    it 'should not see variable from previous run' do
      # Setup the variable
      apply_manifest(var_leak_setup_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)

      # Test to see if subsequent call sees the variable
      apply_manifest(var_leak_test_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)
    end

  end

  describe 'should not leak environment variables across calls to single session' do

    envar_leak_setup_pp = <<-MANIFEST
      exec{'TestPowershell':
        command   => "\\$env:superspecial='1'",
        provider  => powershell,
      }
    MANIFEST

    envar_leak_test_pp = <<-MANIFEST
      exec{'TestPowershell':
        command   => "if ( \\$env:superspecial -eq '1' ) { exit 1 } else { exit 0 }",
        provider  => powershell,
      }
    MANIFEST

    envar_ext_test_pp = <<-MANIFEST
      exec{'TestPowershell':
        command   => "if ( \\$env:outside -eq '1' ) { exit 0 } else { exit 1 }",
        provider  => powershell,
      }
    MANIFEST

    after(:each) do
      on(default, powershell("'Remove-Item Env:\\superspecial -ErrorAction Ignore;exit 0'"))
      on(default, powershell("'Remove-Item Env:\\outside -ErrorAction Ignore;exit 0'"))
    end

    it 'should not see environment variable from previous run' do
      # Setup the environment variable
      apply_manifest(envar_leak_setup_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)

      # Test to see if subsequent call sees the environment variable
      apply_manifest(envar_leak_test_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)
    end

    it 'should see environment variables set outside of session' do
      # Setup the environment variable outside of Puppet
      on(default, powershell("\\$env:outside='1'"))

      # Test to see if initial run sees the environment variable
      apply_manifest(envar_leak_test_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)

      # Test to see if subsequent call sees the environment variable and environment purge
      apply_manifest(envar_leak_test_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)
    end
  end

  describe 'should allow exit from unless' do

    unless_not_triggered_pp = <<-MANIFEST
      exec{'TestPowershell':
        command   => 'exit 0',
        unless    => 'exit 1',
        provider  => powershell,
      }
    MANIFEST

    unless_triggered_pp = <<-MANIFEST
      exec{'TestPowershell':
        command   => 'exit 0',
        unless    => 'exit 0',
        provider  => powershell,
      }
    MANIFEST

    it 'should RUN command if unless is NOT triggered' do
      apply_manifest(unless_not_triggered_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)
    end

    it 'should NOT run command if unless IS triggered' do
      apply_manifest(unless_triggered_pp, :catch_changes => true, :future_parser => FUTURE_PARSER)
    end

  end

  describe 'should allow exit from onlyif' do

    onlyif_not_triggered_pp = <<-MANIFEST
      exec{'TestPowershell':
        command   => 'exit 0',
        onlyif    => 'exit 1',
        provider  => powershell,
      }
    MANIFEST

    onlyif_triggered_pp = <<-MANIFEST
      exec{'TestPowershell':
        command   => 'exit 0',
        onlyif    => 'exit 0',
        provider  => powershell,
      }
    MANIFEST

    it 'should NOT run command if onlyif is NOT triggered' do
      apply_manifest(onlyif_not_triggered_pp, :catch_changes => true, :future_parser => FUTURE_PARSER)
    end

    it 'should RUN command if onlyif IS triggered' do
      apply_manifest(onlyif_triggered_pp, :expect_changes => true, :future_parser => FUTURE_PARSER)
    end

  end

  describe 'should be able to access the files after execution' do

    p2 = <<-MANIFEST
      exec{"TestPowershell":
        command   => 'Get-Service *puppet* | Out-File -FilePath C:/services.txt -Encoding UTF8',
        provider  => powershell
      }
    MANIFEST

    describe file('c:/services.txt') do
      apply_manifest(p2, :catch_failures => true, :future_parser => FUTURE_PARSER)
      it { should be_file }
      its(:content) { should match /puppet/ }
    end
  end

  describe 'should catch and rethrow exceptions up to puppet' do
    pexception = <<-MANIFEST
      exec{'PowershellException':
        provider  => powershell,
        command   => 'throw "We are writing an error"',
      }
    MANIFEST
    it_should_behave_like 'should fail', pexception, /We are writing an error/i
  end

  describe 'should be able to execute a ps1 file provided' do
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
      apply_manifest(p2, :catch_failures => true, :future_parser => FUTURE_PARSER)
      it { should be_file }
      its(:content) { should match /puppet/ }
    end
  end

  describe 'passing parameters to the ps1 file' do
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
      apply_manifest(pp, :catch_failures => true, :future_parser => FUTURE_PARSER)
      it { should be_file }
      its(:content) { should match /svchost/ }
    end
  end

  describe 'should execute using 64 bit powershell' do
    p3 = <<-MANIFEST
     $maxArchNumber = $::architecture? {
      /(?i)(i386|i686|x86)$/	=> 4,
      /(?i)(x64|x86_64)/=> 8,
      default => 0
    }
    exec{'Test64bit':
      command => "if([IntPtr]::Size -eq $maxArchNumber) { exit 0 } else { Write-Error 'Architecture mismatch' }",
      provider => powershell
    }
    MANIFEST
    it_should_behave_like 'apply success', p3
  end

  shared_examples 'standard exec' do |powershell_cmd|
    padmin = <<-MANIFEST
      exec{'no fail test':
        command  => '#{powershell_cmd}',
        provider => powershell,
      }
    MANIFEST
    it 'should not fail' do
      apply_manifest(padmin, :catch_failures => true, :future_parser => FUTURE_PARSER)
    end
  end

  describe 'test admin rights' do
    ps1 = <<-PS1
      $id = [Security.Principal.WindowsIdentity]::GetCurrent()
      $pr = New-Object Security.Principal.WindowsPrincipal $id
      if(!($pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))){Write-Error "Not in admin"}
    PS1
    it_should_behave_like 'standard exec', ps1
  end

  describe 'test import-module' do
    pimport = <<-PS1
      $mods = Get-Module -ListAvailable | Sort
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
end
