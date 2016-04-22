test_name 'PowerShell Module - should be able to execute as Admin'
confine :to, :platform => 'windows'

ps1 = <<-PS1
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $pr = New-Object Security.Principal.WindowsPrincipal $id
    if(!($pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))){Write-Error "Not in admin"}
PS1

padmin = <<-MANIFEST
  exec{'no fail test':
    command  => '#{ps1}',
    provider => powershell,
  }
MANIFEST

agents.each do |agent|
  step 'should not fail'
  opts = {
    :catch_failures => true,
    :future_parser => (ENV['FUTURE_PARSER'] != 'false'),
    :acceptable_exit_codes => [0, 2]
  }
  apply_manifest_on(agent, padmin, opts)
end
