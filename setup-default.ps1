# Install the Claude Code status line:
#   model | effort | folder | Git branch | remaining 5-hour / weekly usage
#
# Usage (Windows):
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\setup-default.ps1
#
# Use CLAUDE_CONFIG_DIR if set, otherwise %USERPROFILE%\.claude.
# Back up settings.json before editing. Replace statusline.ps1 on each run.

# The child scope preserves the calling session's variables and preferences,
# including when run through irm ... | iex and when an error occurs.
& {
    $ErrorActionPreference = 'Stop'

    $configDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE '.claude' }
    New-Item -ItemType Directory -Force -Path $configDir | Out-Null

    $scriptPath   = Join-Path $configDir 'statusline.ps1'
    $settingsPath = Join-Path $configDir 'settings.json'
    $utf8NoBom    = New-Object System.Text.UTF8Encoding($false)

    # --- 1. Status line script ------------------------------------------------
    $statusline = @'
# Claude Code status line: model | effort | folder | Git branch | remaining 5-hour / weekly usage
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$data = [Console]::In.ReadToEnd() | ConvertFrom-Json

$e      = [char]27
$reset  = "$e[0m"
$dim    = "$e[2m"
$cyan   = "$e[36m"
$mag    = "$e[35m"
$blue   = "$e[34m"
$green  = "$e[32m"
$yellow = "$e[33m"
$red    = "$e[31m"
$sep    = " $dim|$reset "

$parts = @()

# Model
$parts += "$cyan$($data.model.display_name)$reset"

# Reasoning effort (absent if the model does not support it)
if ($data.effort -and $data.effort.level) {
    $parts += "${mag}effort: $($data.effort.level)$reset"
}

# Current folder
$dir = $data.workspace.current_dir
if (-not $dir) { $dir = $data.cwd }
$parts += "$blue$(Split-Path $dir -Leaf)$reset"

# Git branch (works with GitLab, GitHub, etc.)
if (Get-Command git -ErrorAction SilentlyContinue) {
    $branch = git -C "$dir" --no-optional-locks rev-parse --abbrev-ref HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and $branch) {
        if ($branch -eq 'HEAD') {
            $branch = git -C "$dir" --no-optional-locks rev-parse --short HEAD 2>$null
        }
        $parts += "${green}git:$branch$reset"
    }
}

# Remaining 5-hour and weekly usage (Pro/Max, after the first response)
function Format-Limit($label, $window, $timeFormat) {
    if ($null -eq $window -or $null -eq $window.used_percentage) { return $null }
    $left = [math]::Max(0, [math]::Round(100 - [double]$window.used_percentage))
    $color = if ($left -gt 50) { $green } elseif ($left -gt 20) { $yellow } else { $red }
    $text = "$label ${color}$left%$reset"
    if ($window.resets_at) {
        $at = [DateTimeOffset]::FromUnixTimeSeconds([int64]$window.resets_at).LocalDateTime
        $text += " $dim(reset $($at.ToString($timeFormat)))$reset"
    }
    return $text
}

$rl = $data.rate_limits
if ($rl) {
    $five = Format-Limit '5h:' $rl.five_hour 'HH:mm'
    $week = Format-Limit 'week:' $rl.seven_day 'ddd HH:mm'
    if ($five) { $parts += $five }
    if ($week) { $parts += $week }
}

[Console]::Out.Write(($parts -join $sep))
'@

    [System.IO.File]::WriteAllText($scriptPath, $statusline, $utf8NoBom)
    Write-Host "Script written: $scriptPath"

    # --- 2. Merge into settings.json -------------------------------------------
    $settings = $null
    if (Test-Path $settingsPath) {
        $raw = [System.IO.File]::ReadAllText($settingsPath)
        if ($raw.Trim()) {
            try {
                $settings = $raw | ConvertFrom-Json
            } catch {
                throw "Invalid settings.json ($settingsPath): fix it and rerun the installer. Details: $($_.Exception.Message)"
            }
        }
        $backup = "$settingsPath.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $settingsPath $backup
        Write-Host "Backup created: $backup"
    }
    if ($null -eq $settings) { $settings = New-Object PSObject }

    # Forward slashes work in Git Bash and PowerShell; quotes protect paths with spaces.
    $command = 'powershell -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f ($scriptPath -replace '\\', '/')
    $statusLine = [PSCustomObject]@{ type = 'command'; command = $command }
    $settings | Add-Member -NotePropertyName 'statusLine' -NotePropertyValue $statusLine -Force

    [System.IO.File]::WriteAllText($settingsPath, ($settings | ConvertTo-Json -Depth 32), $utf8NoBom)
    Write-Host "Settings updated: $settingsPath"
    Write-Host ""
    Write-Host "Done. The status line will appear after your next message (or after restarting 'claude')."
}
