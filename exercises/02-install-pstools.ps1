# Your execution policy might be set to "Restricted". Let's check...
Get-ExecutionPolicy

# If your execution policy is "Restricted" you can change it for the current
# process with...
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process

# Or change it for the whole machine from an elevated terminal with...
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine

# Execution policy is like a gun safety. It's not a security feature. It helps
# keep non-technical users from shooting themselves in the foot.

# This will attempt to install MilestonePSTools from
# https://www.powershellgallery.com

Install-Module MilestonePSTools

# If that failed, try this. It will add TLS 1.2 to the supported TLS protocols
# for this session.
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
Install-Module MilestonePSTools

# If it's still not working, run install.ps1 - it will address the most common
# install issues
