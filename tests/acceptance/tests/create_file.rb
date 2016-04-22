test_name 'PowerShell Module - should be able to access the files after execution'
confine :to, :platform => 'windows'

outfile = 'c:\services.txt'

p2 = <<-MANIFEST
  exec{"TestPowershell":
    command   => 'Get-Service *puppet* | Out-File -FilePath #{outfile} -Encoding UTF8',
    unless    => 'if(!(test-path \"#{outfile}\")){exit 1}',
    provider  => powershell
  }
MANIFEST

teardown do
  step 'Remove Test Artifacts'
  on(agents, "cmd.exe /c \"if exist #{outfile} del #{outfile}\"")
end

agents.each do |agent|
  opts = {
    :catch_failures => true,
    :future_parser => (ENV['FUTURE_PARSER'] != 'false'),
    :acceptable_exit_codes => [0, 2]
  }
  apply_manifest_on(agent, p2, opts)

  on(agent, "cmd.exe /c \"type #{outfile}\"") do |result|
    assert_match(/puppet/, result.stdout, "Unexpected result for host '#{agent}'")
  end
end
