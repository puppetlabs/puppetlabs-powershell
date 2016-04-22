test_name 'PowerShell Module - should allow exit from unless'
confine :to, :platform => 'windows'

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

agents.each do |agent|
  step 'should RUN command if unless is NOT triggered'
  opts = {
    :expect_changes => true,
    :future_parser => (ENV['FUTURE_PARSER'] != 'false'),
    :acceptable_exit_codes => [0, 2]
  }
  apply_manifest_on(agent, unless_not_triggered_pp, opts)

  step 'should NOT run command if unless IS triggered'
  opts = {
    :catch_changes => true,
    :future_parser => (ENV['FUTURE_PARSER'] != 'false'),
    :acceptable_exit_codes => [0, 2]
  }
  apply_manifest_on(agent, unless_triggered_pp, opts)
end
