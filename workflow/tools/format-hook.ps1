# Claude Code PostToolUse hook: runs gdformat on a .gd file right after Claude edits it.
# Claude Code sends the tool call as JSON on stdin; we read tool_input.file_path.
# Exit 0 = fine. Exit 2 = formatting failed; stderr is shown to Claude so it can fix the file.

$ErrorActionPreference = 'Continue'
# Two levels up: workflow/tools -> repo root.
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try { $data = $raw | ConvertFrom-Json } catch { exit 0 }

$file = $data.tool_input.file_path
if (-not $file -or -not $file.EndsWith('.gd')) { exit 0 }
if (-not (Test-Path $file)) { exit 0 }

# Never touch third-party code: skip any file inside an addons folder,
# including the addons folder of a git worktree.
$full = (Resolve-Path $file).Path
if ($full -match '[\\/]addons[\\/]') { exit 0 }

# The venv is gitignored, so a git worktree has none. Use the main checkout's venv then.
$gdformat = Join-Path $root '.venv\Scripts\gdformat.exe'
if (-not (Test-Path $gdformat)) {
    $common = git -C $root rev-parse --path-format=absolute --git-common-dir 2>$null
    if ($common) { $gdformat = Join-Path (Split-Path -Parent $common) '.venv\Scripts\gdformat.exe' }
}

$out = & $gdformat $full 2>&1 | ForEach-Object { "$_" } | Out-String
if ($LASTEXITCODE -ne 0) {
    [Console]::Error.WriteLine("gdformat failed on ${file}:`n$out")
    exit 2
}
exit 0
