Facter.add("psmodulepath") do
  confine :osfamily => 'windows'
  setcode Facter::Util::Resolution.exec('powershell.exe -Command "(gci ENV:\PSModulepath).Value"').split(';')
end