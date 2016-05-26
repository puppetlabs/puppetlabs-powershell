test_name 'PowerShell Module - should not leak variables across calls to single session'
confine :to, :platform => 'windows'

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

agents.each do |agent|
  opts = {
    :expect_changes => true,
    :acceptable_exit_codes => [0, 2]
  }

  step 'should set a variable in a run'
  apply_manifest_on(agent, var_leak_setup_pp, opts)

  step 'should not see variable from previous run'
  apply_manifest_on(agent, var_leak_test_pp, opts)
end
