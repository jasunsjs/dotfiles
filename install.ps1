#Requires -Version 7.0
<#
.SYNOPSIS
    Set up this Windows PC from the dotfiles repo.
    Windows counterpart of setup.sh (same steps, same order).

.DESCRIPTION
    Installs any tools from packages/winget.json that are missing (never upgrades installed ones),
    then copies each config file to the place its program reads it. Anything already there is
    backed up to ~/.dotfiles-backup/<timestamp>/ first. Safe to re-run.

.EXAMPLE
    ./install.ps1 -WhatIf   # list what would change, without changing anything
#>
[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'
$Dotfiles = $PSScriptRoot
$BackupDir = Join-Path $HOME ".dotfiles-backup\$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$GitConfigDir = if ($env:XDG_CONFIG_HOME) { Join-Path $env:XDG_CONFIG_HOME 'git' } else { "$HOME\.config\git" }

# Copy a repo file to a target path, backing up whatever was there first.
function Install-Dotfile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string] $Source,
        [Parameter(Mandatory)] [string] $Target
    )
    $from = Join-Path $Dotfiles $Source
    $exists = Test-Path $Target
    if ($exists -and (Get-FileHash $from).Hash -eq (Get-FileHash $Target).Hash) {
        Write-Host "up to date  $Target"
        return
    }
    $action = if ($exists) { "Replace with $Source (old file backed up)" } else { "Create from $Source" }
    if (-not $PSCmdlet.ShouldProcess($Target, $action)) { return }
    if ($exists) {
        $backup = Join-Path $BackupDir ([IO.Path]::GetRelativePath($HOME, $Target))
        New-Item -ItemType Directory -Force (Split-Path $backup) | Out-Null
        Copy-Item $Target $backup
    }
    New-Item -ItemType Directory -Force (Split-Path $Target) | Out-Null
    Copy-Item $from $Target -Force
    Write-Host "installed   $Target"
}

# 1. Tools
$packages = (Get-Content (Join-Path $Dotfiles 'packages\winget.json') -Raw | ConvertFrom-Json).Sources.Packages.PackageIdentifier
# winget's --id lookup misses some installed packages (PowerShell, for one), so also search the full list.
$installed = (winget list --accept-source-agreements --disable-interactivity 2>$null) -join "`n"
foreach ($id in $packages) {
    $found = $installed -match "\s$([regex]::Escape($id))\s"
    if (-not $found) {
        winget list --id $id --exact --disable-interactivity *> $null
        $found = $LASTEXITCODE -eq 0
    }
    if ($found) {
        Write-Host "up to date  $id"
    } elseif ($PSCmdlet.ShouldProcess($id, 'winget install')) {
        winget install --id $id --exact --accept-package-agreements --accept-source-agreements --disable-interactivity
    }
}
# Pick up anything winget just added to PATH.
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')

if (Get-Module -ListAvailable Terminal-Icons) {
    Write-Host "up to date  Terminal-Icons"
} elseif ($PSCmdlet.ShouldProcess('Terminal-Icons', 'Install-Module -Scope CurrentUser')) {
    Install-Module Terminal-Icons -Scope CurrentUser -Force
}

# 2. Font (skipped when any CaskaydiaCove font exists, so two fonts never share a name)
$fontKeys = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts', 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
$hasFont = foreach ($key in $fontKeys) { if (Test-Path $key) { (Get-Item $key).Property -like 'Caskaydia*' } }
if ($hasFont) {
    Write-Host "up to date  CaskaydiaCove Nerd Font"
} elseif ($PSCmdlet.ShouldProcess('CaskaydiaCove Nerd Font', 'oh-my-posh font install CascadiaCode')) {
    oh-my-posh font install CascadiaCode
}

# 3. Git
Install-Dotfile 'git\config' "$HOME\.gitconfig"
Install-Dotfile 'git\ignore' "$GitConfigDir\ignore"

# 4. Shell
Install-Dotfile 'oh-my-posh\vityusha.omp.json' "$HOME\.config\oh-my-posh\vityusha.omp.json"
Install-Dotfile 'powershell\profile.ps1' $PROFILE.CurrentUserCurrentHost

# 5. Terminal
$wt = Get-ChildItem "$env:LOCALAPPDATA\Packages" -Directory -Filter 'Microsoft.WindowsTerminal_*' -ErrorAction SilentlyContinue |
    Select-Object -First 1
if ($wt) {
    Install-Dotfile 'windows-terminal\settings.json' (Join-Path $wt.FullName 'LocalState\settings.json')
} else {
    Write-Host "skipping    Windows Terminal settings (Windows Terminal not installed)"
}

# 6. act
Install-Dotfile 'act\actrc' "$HOME\.actrc"

# 7. Node tools
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Host "skipping    npm-check-updates (npm not found)"
} elseif (Get-Command ncu -ErrorAction SilentlyContinue) {
    Write-Host "up to date  npm-check-updates"
} elseif ($PSCmdlet.ShouldProcess('npm-check-updates', 'npm install --global')) {
    npm install --global npm-check-updates
}
