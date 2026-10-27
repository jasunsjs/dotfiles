# --- Detect "real interactive terminal" vs redirected/non-interactive (Codex/Tasks) ---
$IsRedirected = $false
try {
    $IsRedirected = [Console]::IsOutputRedirected -or [Console]::IsErrorRedirected -or [Console]::IsInputRedirected
} catch {
    $IsRedirected = $true
}

$IsInteractive = $Host.Name -eq 'ConsoleHost' -and [Environment]::UserInteractive -and -not $IsRedirected
$SupportsVT = $false
try { $SupportsVT = $Host.UI -and $Host.UI.SupportsVirtualTerminal } catch { $SupportsVT = $false }

# --- Modules (interactive shells only; everything else loads on first use) ---
if ($IsInteractive) {
    Import-Module Terminal-Icons -ErrorAction SilentlyContinue
    Import-Module PSReadLine -ErrorAction SilentlyContinue
}

if ($env:ChocolateyInstall) {
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1" -ErrorAction SilentlyContinue
}

# --- PSReadLine (only enable fancy prediction UI when it will actually work) ---
if (Get-Module PSReadLine) {
    Set-PSReadLineOption -EditMode Windows

    # Tab completion handler is fine in interactive shells
    if ($IsInteractive) {
        Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
    }

    # These are the ones causing your errors in Codex:
    if ($IsInteractive -and $SupportsVT) {
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView
    }
}

# --- oh-my-posh (only initialize when interactive; otherwise it can be noisy/slow) ---
if ($IsInteractive) {
    try {
        oh-my-posh init pwsh --config "$HOME\.config\oh-my-posh\vityusha.omp.json" | Invoke-Expression
    } catch { }
}
