# Download the Microsoft repository GPG keys
wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb

# Register the Microsoft repository GPG keys
dpkg -i packages-microsoft-prod.deb

# Make sure apt-get update works
apt-get install -y apt-transport-https

# Update the list of products
apt-get update

# Install PowerShell
apt-get install -y powershell

# List version
pwsh -v
