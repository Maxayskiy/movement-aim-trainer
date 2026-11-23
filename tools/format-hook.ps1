# Claude Code PostToolUse hook: runs gdformat on a .gd file right after Claude edits it.
# Claude Code sends the tool call as JSON on stdin; we read tool_input.file_path.
# Exit 0 = fine. Exit 2 = formatting failed; stderr is shown to Claude so it can fix the file.

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try { $data = $raw | ConvertFrom-Json } catch { exit 0 }

$file = $data.tool_input.file_path
if (-not $file -or -not $file.EndsWith('.gd')) { exit 0 }
if (-not (Test-Path $file)) { exit 0 }

# Never touch third-party code.
$full = (Resolve-Path $file).Path
if ($full -like (Join-Path $root 'addons\*')) { exit 0 }

$out = & (Join-Path $root '.venv\Scripts\gdformat.exe') $full 2>&1 | ForEach-Object { "$_" } | Out-String
if ($LASTEXITCODE -ne 0) {
    [Console]::Error.WriteLine("gdformat failed on ${file}:`n$out")
    exit 2
}
exit 0
