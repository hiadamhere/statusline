# Status line for Claude Code

A status line for Claude Code on Windows, installed with PowerShell.
It shows the model, reasoning effort, current folder, Git branch, and remaining
usage for the 5-hour and weekly limits.

Example output (values depend on your session):

```text
Opus | effort: high | my-project | git:main | 5h: 76% (reset 16:30) | week: 59% (reset Mon 09:00)
```

Remaining usage is green above 50%, yellow above 20%, and red otherwise.
Reset times use your local time zone. Day names follow your system's locale.

## Prerequisites

- Windows with Windows PowerShell 5.1 (`powershell.exe`).
- [Claude Code](https://code.claude.com/docs/en/setup) installed and configured.
- Git available in your `PATH` to display the branch (optional).
- An Internet connection to download the installer.

## Quick installation

Open **PowerShell** as your usual user, without administrator privileges, and paste:

```powershell
irm https://raw.githubusercontent.com/hiadamhere/statusline/main/setup-default.ps1 | iex
```

This command downloads and runs the script from the `main` branch.
To read the script before running it, use the local installation method below.

Then send a message in Claude Code. If the status line does not appear,
close and restart `claude`.

### Installing from a local file

Download [setup-default.ps1](./setup-default.ps1), or clone this repository,
then open PowerShell in the folder containing the file:

```powershell
Get-Content .\setup-default.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\setup-default.ps1
```

The `-ExecutionPolicy Bypass` option applies only to the process being launched;
it does not permanently change your account's execution policy.

## Files and settings changed

The installer uses `%USERPROFILE%\.claude`, or the folder specified by the
`CLAUDE_CONFIG_DIR` environment variable if it is set.

1. It creates the folder if needed and writes `statusline.ps1` into it.
2. If `settings.json` exists and can be read, it backs it up as
   `settings.json.bak-YYYYMMDD-HHMMSS` before modifying it.
3. It adds or replaces the `statusLine` setting while preserving other settings.
   JSON formatting may change.

Run the same command again to reinstall or update the status line.
The `statusline.ps1` file is overwritten without a backup, so keep a copy if
you have customized it. Any existing `statusLine` configuration is also replaced;
its previous value remains in the `settings.json` backup.

The script runs in a child PowerShell scope. Its
`$ErrorActionPreference = 'Stop'` stops installation on errors without changing
your session's preference, even when run through `irm ... | iex`.

To use a custom folder, set `CLAUDE_CONFIG_DIR` in the environment used by
**both** the installer and Claude Code. For example, in the same PowerShell window:

```powershell
$env:CLAUDE_CONFIG_DIR = 'C:\My folder\Claude'
irm https://raw.githubusercontent.com/hiadamhere/statusline/main/setup-default.ps1 | iex
claude
```

This environment variable assignment applies to the current session.

## Troubleshooting

- **Missing effort**: this field appears only when the model supports it and
  Claude Code supplies it.
- **Missing usage limits**: the 5-hour and 7-day windows apply to Claude Pro/Max
  subscriptions and become available after the first API response in the session.
  Either window may be absent independently.
- **Missing branch**: check that Git is installed and the current folder belongs
  to a Git repository. In detached HEAD mode, the short commit hash is shown.
- **`Invalid settings.json` error**: correct the JSON in the indicated file and
  rerun the installer. The settings file is not overwritten in this case.
- **Missing status line**: check the `statusLine` setting in the configuration
  folder used by Claude Code. Project settings can override your user settings.

See the [official status line documentation](https://code.claude.com/docs/en/statusline)
for available fields and troubleshooting details.

## Uninstalling or restoring your previous configuration

In the configuration folder used during installation:

1. Close Claude Code and open `settings.json`.
2. Remove the `statusLine` property to disable the status line, or restore its
   previous value from a `settings.json.bak-*` backup.
3. Delete `statusline.ps1` if you no longer use it, then restart Claude Code.

Restoring only `statusLine` preserves any other settings changed since installation.
