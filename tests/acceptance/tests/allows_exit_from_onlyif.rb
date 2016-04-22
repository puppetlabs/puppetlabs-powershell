test_name 'PowerShell Module - should allow exit from onlyif'
confine :to, :platform => 'windows'

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

agents.each do |agent|
  step 'should NOT run command if onlyif is NOT triggered'
  opts = {
    :catch_changes => true,
    :future_parser => (ENV['FUTURE_PARSER'] != 'false'),
    :acceptable_exit_codes => [0, 2]
  }
  apply_manifest_on(agent, onlyif_not_triggered_pp, opts)

  step 'should RUN command if onlyif IS triggered'
  opts = {
    :expect_changes => true,
    :future_parser => (ENV['FUTURE_PARSER'] != 'false'),
    :acceptable_exit_codes => [0, 2]
  }
  apply_manifest_on(agent, onlyif_triggered_pp, opts)
end
