$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$dist = Join-Path $root "dist"
$zipPath = Join-Path $dist "RTVToolKit.zip"
$vmzPath = Join-Path $dist "RTVToolKit.vmz"

New-Item -ItemType Directory -Force -Path $dist | Out-Null
Remove-Item -Force -ErrorAction SilentlyContinue $zipPath, $vmzPath

# bsdtar writes slash-normalized zip entries, which the mod loader expects.
tar.exe -a -cf $zipPath -C $root mod.txt README.md RTVToolKit

Move-Item -Force $zipPath $vmzPath
Write-Host "Built $vmzPath"
