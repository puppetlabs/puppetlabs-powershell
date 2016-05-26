test_name 'PowerShell Module - should see environment variables set outside of session'
confine :to, :platform => 'windows'

envar_ext_test_pp = <<-MANIFEST
  exec{'TestPowershell':
    command   => "if ( \\$Env:ComputerName -ne 'Powershell' ) { exit 0 } else { exit 1 }",
    provider  => powershell,
  }
MANIFEST

# since code is in a manifest, just need to escape $
envar_ext_modify_and_read_pp = <<-MANIFEST
  exec{'TestPowershell':
    command   => "\\$Env:ComputerName = 'Powershell'; if ( \\$Env:ComputerName -eq 'Powershell' ) { exit 0 } else { exit 1 }",
    provider  => powershell,
  }
MANIFEST

agents.each do |agent|
  opts = {
    :expect_changes => true,
    :acceptable_exit_codes => [0, 2]
  }

  step 'should see external environment variable on first run'
  apply_manifest_on(agent, envar_ext_test_pp, opts)

  step 'can modify existing env var and see local changes'
  apply_manifest_on(agent, envar_ext_modify_and_read_pp, opts)

  step 'value of modified external environment variable should be restored on subsequent manifest applications'
  apply_manifest_on(agent, envar_ext_test_pp, opts)
end
