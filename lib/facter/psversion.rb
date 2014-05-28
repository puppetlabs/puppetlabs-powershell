Facter.add("psversion") do
  confine :osfamily => 'windows'
  setcode 'powershell.exe -Command "$PSVersionTable.PSVersion.ToString()"'
end