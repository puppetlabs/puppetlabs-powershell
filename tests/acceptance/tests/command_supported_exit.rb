test_name 'PowerShell Module - should run commands that exit session'
confine :to, :platform => 'windows'

exit_pp = <<-MANIFEST
  exec{'TestPowershell':
    command   => 'exit 0',
    provider  => powershell,
  }
MANIFEST

agents.each do |agent|
  opts = {
    :expect_changes => true,
    :future_parser => (ENV['FUTURE_PARSER'] != 'false'),
    :acceptable_exit_codes => [0, 2]
  }

  step 'should not error on first run'
  apply_manifest_on(agent, exit_pp, opts)

  step 'should run a second time'
  apply_manifest_on(agent, exit_pp, opts)
end
