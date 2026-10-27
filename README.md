# dotfiles
non-negotiable cuz i need my configs.

My git and terminal setup for Windows (PowerShell 7, Windows Terminal, oh-my-posh) and Linux (dev containers, Codespaces).

## What's here

| File | Installed to | Used on |
|---|---|---|
| `git/config` | `~/.gitconfig` | Windows, Linux |
| `git/ignore` | `~/.config/git/ignore` (global gitignore) | Windows, Linux |
| `oh-my-posh/vityusha.omp.json` | `~/.config/oh-my-posh/vityusha.omp.json` | Windows, Linux |
| `powershell/profile.ps1` | `$PROFILE` | Windows |
| `windows-terminal/settings.json` | Windows Terminal's `LocalState\settings.json` | Windows |
| `vscode/machine-settings.json` | `~/.vscode-remote/data/Machine/settings.json` or `~/.vscode-server/data/Machine/settings.json` | Linux |
| `act/actrc` | `~/.actrc` | Windows, Linux |
| `packages/winget.json` | Package list read by `install.ps1` (also works with `winget import`) | Windows |

`install.ps1` (Windows) and `setup.sh` (Linux) do the same steps in the same order. They install missing tools, then **copy** each file above into place. Nothing on the machine points back at the repo.

## Install

### Windows

Needs PowerShell 7 (`winget install Microsoft.PowerShell`).

```powershell
git clone https://github.com/jasunsjs/dotfiles.git
cd dotfiles
./install.ps1
```

### Linux, dev containers and Codespaces

Dev containers and Codespaces run `setup.sh` automatically once this repo is set as your dotfiles repo:
