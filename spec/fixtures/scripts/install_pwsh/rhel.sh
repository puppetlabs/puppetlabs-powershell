# Register the Microsoft RedHat repository
curl https://packages.microsoft.com/config/rhel/7/prod.repo | tee /etc/yum.repos.d/microsoft.repo

# Install PowerShell
yum install -y powershell

# List version
pwsh -v
