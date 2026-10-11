<# : batch part, PowerShell reads everything up to the closing mark as a comment
@echo off
setlocal
set "TF2CONFIG_BAT=%~f0"
set "TF2CONFIG_ARG=%~1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((Get-Content -LiteralPath $env:TF2CONFIG_BAT -Raw)))"
set "code=%errorlevel%"
pause
exit /b %code%
#>

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ZipUrl = '@ZIP_URL@'
$Summary = '@SUMMARY@'
$TfProcesses = @('tf_win64', 'tf', 'hl2')
$WaitSecondsMax = 120

function Get-SteamRoots {
    $roots = @()
    foreach ($key in 'HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam', 'HKLM:\SOFTWARE\Valve\Steam') {
        $item = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
        if ($item.SteamPath) { $roots += $item.SteamPath }
        if ($item.InstallPath) { $roots += $item.InstallPath }
    }
    $roots += Join-Path ${env:ProgramFiles(x86)} 'Steam'
    $roots | ForEach-Object { $_ -replace '/', '\' } | Select-Object -Unique
}

function Get-LibraryRoots([string[]] $steamRoots) {
    $libraries = @()
    foreach ($root in $steamRoots) {
        $libraries += $root
        $vdf = Join-Path $root 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            foreach ($match in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) {
                $libraries += $match.Groups[1].Value -replace '\\\\', '\'
            }
        }
    }
    foreach ($drive in Get-PSDrive -PSProvider FileSystem) {
        $libraries += Join-Path $drive.Root 'SteamLibrary'
        $libraries += Join-Path $drive.Root 'Steam'
    }
    $libraries | Select-Object -Unique
}

function Find-TfDirectory {
    if ($env:TF2CONFIG_ARG) {
        foreach ($candidate in $env:TF2CONFIG_ARG, (Join-Path $env:TF2CONFIG_ARG 'tf')) {
            if (Test-Path -LiteralPath (Join-Path $candidate 'gameinfo.txt')) { return (Resolve-Path -LiteralPath $candidate).Path }
        }
        throw "No TF2 at $env:TF2CONFIG_ARG. Give the 'Team Fortress 2' folder or its 'tf' folder."
    }
    foreach ($library in Get-LibraryRoots (Get-SteamRoots)) {
        $tf = Join-Path $library 'steamapps\common\Team Fortress 2\tf'
        if (Test-Path -LiteralPath (Join-Path $tf 'gameinfo.txt')) { return $tf }
    }
    $typed = Read-Host "TF2 not found. Paste the path of the 'Team Fortress 2' folder"
    $tf = Join-Path $typed.Trim('"') 'tf'
    if (-not (Test-Path -LiteralPath (Join-Path $tf 'gameinfo.txt'))) { throw "No TF2 at $typed." }
    $tf
}

function Wait-TfClosed {
    for ($second = 0; $second -lt $WaitSecondsMax; $second++) {
        if (-not (Get-Process -Name $TfProcesses -ErrorAction SilentlyContinue)) { return }
        if ($second -eq 0) { Write-Host 'TF2 is running. Close it, the install continues by itself.' }
        Start-Sleep -Seconds 1
    }
    throw "TF2 is still running after $WaitSecondsMax s."
}

function Get-Zip([string] $workDirectory) {
    $local = Join-Path (Split-Path -Parent $env:TF2CONFIG_BAT) 'budhud.zip'
    if (Test-Path -LiteralPath $local) {
        Write-Host "Using $local"
        return $local
    }
    $zip = Join-Path $workDirectory 'budhud.zip'
    Write-Host "Downloading $ZipUrl"
    Invoke-WebRequest -Uri $ZipUrl -OutFile $zip -UseBasicParsing
    $zip
}

function Test-Hud([string] $directory) {
    $info = Join-Path $directory 'info.vdf'
    (Test-Path -LiteralPath $info) -and ((Get-Content -LiteralPath $info -Raw) -match 'ui_version')
}

function Move-ToBackup([string] $path, [string] $backup) {
    New-Item -ItemType Directory -Force -Path $backup | Out-Null
    Move-Item -LiteralPath $path -Destination $backup
    Write-Host "  moved $(Split-Path -Leaf $path) to the backup"
}

function Clear-OldInstall([string] $tf, [string] $backup) {
    $custom = Join-Path $tf 'custom'
    if (Test-Path -LiteralPath $custom) {
        Get-ChildItem -LiteralPath $custom -Directory | Where-Object { Test-Hud $_.FullName } |
            ForEach-Object { Move-ToBackup $_.FullName (Join-Path $backup 'custom') }
        Get-ChildItem -LiteralPath $custom -Filter 'mastercomfig*.vpk' |
            ForEach-Object { Move-ToBackup $_.FullName (Join-Path $backup 'custom') }
    }
    $overrides = Join-Path $tf 'cfg\overrides'
    if (Test-Path -LiteralPath $overrides) { Move-ToBackup $overrides (Join-Path $backup 'cfg') }
}

function Restore-UserConfig([string] $tf, [string] $backup) {
    $userCfg = Join-Path $tf 'cfg\overrides\user.cfg'
    $candidates = @(
        (Join-Path $backup 'cfg\overrides\user.cfg'),
        (Join-Path $backup 'cfg\overrides\autoexec.cfg'),
        (Join-Path $tf 'cfg\autoexec.cfg')
    )
    foreach ($candidate in $candidates) {
        if ((Test-Path -LiteralPath $candidate) -and -not ((Get-Content -LiteralPath $candidate -Raw) -match 'Written by tf2-config')) {
            Copy-Item -LiteralPath $candidate -Destination $userCfg
            Write-Host "  kept your settings from $candidate in cfg\overrides\user.cfg"
            return
        }
    }
    New-Item -ItemType File -Path $userCfg | Out-Null
}

Write-Host $Summary
$tf = Find-TfDirectory
Write-Host "TF2: $tf"
Wait-TfClosed

$work = Join-Path ([IO.Path]::GetTempPath()) ("tf2-config-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $work | Out-Null
try {
    $zip = Get-Zip $work
    Expand-Archive -LiteralPath $zip -DestinationPath (Join-Path $work 'zip')
    $source = Join-Path $work 'zip\tf'
    if (-not (Test-Path -LiteralPath (Join-Path $source 'custom\budhud\info.vdf'))) { throw "$zip is not a tf2-config zip." }

    $backup = Join-Path (Split-Path -Parent $tf) ('tf2-config-backup\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    Clear-OldInstall $tf $backup
    Copy-Item -Path (Join-Path $source '*') -Destination $tf -Recurse -Force
    Restore-UserConfig $tf $backup
} finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}

if (Test-Path -LiteralPath $backup) { Write-Host "Old files: $backup" }
Write-Host ''
Write-Host 'Installed. Steam launch options for TF2:'
Write-Host '  -novid -nojoy -nosteamcontroller -nohltv -particles 1 -precachefontchars'
