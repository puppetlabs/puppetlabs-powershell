Facter.add("psversion") do
  setcode 'powershell.exe -Command "$PSVersionTable.PSVersion.ToString()"'
end