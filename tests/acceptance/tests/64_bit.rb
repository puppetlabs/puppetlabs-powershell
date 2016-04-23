test_name 'PowerShell Module - should execute using 64 bit powershell'
confine :to, :platform => 'windows'

p3 = <<-MANIFEST
 $maxArchNumber = $::architecture? {
  /(?i)(i386|i686|x86)$/  => 4,
  /(?i)(x64|x86_64)/=> 8,
  default => 0
}
exec{'Test64bit':
  command => "if([IntPtr]::Size -eq $maxArchNumber) { exit 0 } else { Write-Error 'Architecture mismatch' }",
  provider => powershell
}
MANIFEST

agents.each do |agent|
  step 'should succeed'
  opts = {
    :catch_failures => true,
    :acceptable_exit_codes => [0, 2]
  }
  apply_manifest_on(agent, p3, opts)
end
