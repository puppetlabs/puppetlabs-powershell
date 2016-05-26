test_name 'PowerShell Module - should be able to execute a ps1 file provided'
confine :to, :platform => 'windows'

outfile = 'c:\temp\services.csv'

p2 = <<-MANIFEST
file{'c:/services.ps1':
  content => '#{File.open(File.join(File.dirname(__FILE__), '../../files/services.ps1')).read()}'
}
exec{"TestPowershellPS1":
  command   => 'c:/services.ps1',
  provider  => powershell,
  require   => File['c:/services.ps1']
}
MANIFEST

teardown do
  step 'Remove Test Artifacts'
  on(agents, "cmd.exe /c \"if exist #{outfile} del #{outfile}\"")
end

agents.each do |agent|
  opts = { :catch_failures => true }
  apply_manifest_on(agent, p2, opts)

  on(agent, "cmd.exe /c \"type #{outfile}\"") do |result|
    assert_match(/puppet/, result.stdout, "Unexpected result for host '#{agent}'")
  end
end
