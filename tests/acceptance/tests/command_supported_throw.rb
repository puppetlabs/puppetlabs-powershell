test_name 'PowerShell Module - should catch and rethrow exceptions up to puppet'
confine :to, :platform => 'windows'

pexception = <<-MANIFEST
  exec{'PowershellException':
    provider  => powershell,
    command   => 'throw "We are writing an error"',
  }
MANIFEST

agents.each do |agent|
  opts = {
    :future_parser => (ENV['FUTURE_PARSER'] != 'false'),
    :expect_failures => true
  }

  apply_manifest_on(agent, pexception, opts)
end
