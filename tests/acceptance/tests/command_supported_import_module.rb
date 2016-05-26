test_name 'PowerShell Module - Import-Module should work'
confine :to, :platform => 'windows'

pimport = <<-PS1
  $mods = Get-Module -ListAvailable | Sort
  if($mods.Length -lt 1) {
    Write-Error "Expected to get at least one module, but none were listed"
  }
  Import-Module $mods[0].Name
  if(-not (Get-Module $mods[0].Name)){
    Write-Error "Failed to import module ${mods[0].Name}"
  }
PS1

padmin = <<-MANIFEST
  exec{'no fail test':
    command  => '#{pimport}',
    provider => powershell,
  }
MANIFEST

agents.each do |agent|
  step 'should not fail'
  opts = {
    :catch_failures => true,
    :acceptable_exit_codes => [0, 2]
  }
  apply_manifest_on(agent, padmin, opts)
end
