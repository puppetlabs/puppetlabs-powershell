test_name 'PowerShell Module - should support passing parameters to the ps1 file'
confine :to, :platform => 'windows'

outfile = 'C:\temp\svchostprocess.txt'
processName = 'svchost'
pp = <<-MANIFEST
  $process = '#{processName}'
  $outFile = '#{outfile}'
file{'c:/param_script.ps1':
  content => '#{File.open(File.join(File.dirname(__FILE__), '../../files/param_script.ps1')).read()}'
}
exec{'run this with param':
  provider => powershell,
  command  => "c:/param_script.ps1 -ProcessName '$process' -FileOut '$outFile'",
  require  => File['c:/param_script.ps1'],
}
MANIFEST

teardown do
  step 'Remove Test Artifacts'
  on(agents, "cmd.exe /c \"if exist #{outfile} del #{outfile}\"")
end

agents.each do |agent|
  opts = { :catch_failures => true }
  apply_manifest_on(agent, pp, opts)

  on(agent, "cmd.exe /c \"type #{outfile}\"") do |result|
    assert_match(/svchost/, result.stdout, "Unexpected result for host '#{agent}'")
  end
end
