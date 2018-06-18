$ErrorActionPreference = "Stop"

# Install PHP
function Download-File ([string] $Url, [string] $Target) {
    $client = New-Object System.Net.WebClient
    $client.Headers.Add('User-Agent', "AppVeyor CI PowerShell $($PSVersionTable.PSVersion) $([Environment]::OSVersion.VersionString)")
    Write-Output "Downloading $Url"
    $client.DownloadFile($Url, $Target)
}
$phpTarget = Join-Path $PWD 'php.zip'
try {
    Download-File "http://windows.php.net/downloads/releases/php-$env:PHP_VERSION-nts-Win32-VC$env:VC_VERSION-x86.zip" $phpTarget
}
catch [System.Net.WebException] {
    if ($_.Exception.Response.StatusCode.Value__ -eq 404) {
        # Older releases get moved to archives/
        Download-File "http://windows.php.net/downloads/releases/archives/php-$env:PHP_VERSION-nts-Win32-VC$env:VC_VERSION-x86.zip" $phpTarget
        Write-Warning "PHP $env:PHP_VERSION is outdated and was moved to archives"
    }
    else {
        throw $_
    }
}
7z e php.zip -ophp
if ($LASTEXITCODE -ne 0) {
    Get-Content php.zip
    throw "7zip exited with $LASTEXITCODE"
}
Rename-Item .\php\php.ini-development php.ini
$env:PATH += ';' + (Join-Path $PWD 'php')

# Install XDebug
$phpMinorVersion = $env:PHP_VERSION -replace '\.\d+$'
$xdebugUrl = "https://xdebug.org/files/php_xdebug-$env:XDEBUG_VERSION-$phpMinorVersion-vc$env:VC_VERSION-nts.dll"
$xdebugPath = Join-Path $PWD 'php\ext\xdebug.dll'
Download-File $xdebugUrl $xdebugPath
Add-Content .\php\php.ini @"
extension_dir=ext
zend_extension=$xdebugPath
xdebug.remote_enable=1
xdebug.remote_autostart=1
"@
$?
$LastExitCode

# Install Node
Write-Output 'Installing Node'
cmd /c powershell Install-Product node $env:NODE_VERSION
$?
$LastExitCode
Write-Output 'Node Installed'
npm install -g "npm@$env:NPM_VERSION" --depth 0
$?
$LastExitCode
npm config -g set progress=false
$?
$LastExitCode
npm config -g set unicode=false
$?
$LastExitCode

# Install dependencies
Write-Output 'Installing dependencies'
npm ci
