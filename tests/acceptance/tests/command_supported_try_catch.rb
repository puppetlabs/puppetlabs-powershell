test_name 'PowerShell Module - should handle a try/catch successfully'
confine :to, :platform => 'windows'

outfile = 'C:\trysuccess.txt'

powershell_cmd = <<-CMD
try {
  "foo" | Out-Null;
  exit 0
} catch {
  exit 1
}
CMD

p1 = <<-MANIFEST
exec { "TestPowershell":
  command   => '"hi" | Out-File -FilePath \"#{outfile}\"',
  onlyif    => '#{powershell_cmd}',
  provider  => powershell,
}
MANIFEST

teardown do
  step 'Remove Test Artifacts'
  on(agents, "cmd.exe /c \"if exist #{outfile} del #{outfile}\"")
end

agents.each do |agent|
  opts = { :catch_failures => true, :future_parser => (ENV['FUTURE_PARSER'] != 'false') }
  apply_manifest_on(agent, p1, opts)

  on(agent, "cmd.exe /c \"type #{outfile}\"") do |result|
    assert_match(/hi/, result.stdout, "Unexpected result for host '#{agent}'")
  end
end
