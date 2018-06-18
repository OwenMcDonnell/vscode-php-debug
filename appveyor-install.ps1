$ErrorActionPreference = "Stop"

$client = New-Object System.Net.WebClient



# Install Node
Write-Output 'Installing Node'
Install-Product node 4.1.1 x64
npm install -g typings

# Install dependencies
Write-Output 'Installing dependencies'
npm install
typings install
