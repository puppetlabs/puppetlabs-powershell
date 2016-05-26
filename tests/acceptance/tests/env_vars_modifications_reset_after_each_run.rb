test_name 'PowerShell Module - should not leak environment variables across calls to single session'
confine :to, :platform => 'windows'

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

teardown do
  step 'Clear Env Vars'
  on(agents, powershell("'Remove-Item Env:\\superspecial -ErrorAction Ignore;exit 0'"))
end

agents.each do |agent|
  opts = {
    :expect_changes => true,
    :acceptable_exit_codes => [0, 2]
  }

  step 'should setup a environment variable in a run'
  apply_manifest_on(agent, envar_leak_setup_pp, opts)

  step 'should not see environment variable from previous run'
  apply_manifest_on(agent, envar_leak_test_pp, opts)
end
