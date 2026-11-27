# One command that checks everything: format, lint, types, tests.
# Run from anywhere:
#   powershell -NoProfile -ExecutionPolicy Bypass -File workflow/tools/check.ps1
# Exits 0 when all checks pass, 1 on the first failure.

# 'Continue': Godot prints errors to stderr; we judge each step by its exit code.
$ErrorActionPreference = 'Continue'
# Two levels up: workflow/tools -> repo root.
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $root

$godot = $env:GODOT
if (-not $godot) { $godot = 'C:\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' }
$venv = Join-Path $root '.venv\Scripts'
# The venv is gitignored, so a git worktree has none. Use the main checkout's venv then
# (same fallback as format-hook.ps1).
if (-not (Test-Path "$venv\gdformat.exe")) {
    $common = git -C $root rev-parse --path-format=absolute --git-common-dir 2>$null
    if ($common) { $venv = Join-Path (Split-Path -Parent $common) '.venv\Scripts' }
}
$codeDirs = @('src', 'tests')

function Fail([string]$step) {
    Write-Host "`nFAILED: $step" -ForegroundColor Red
    exit 1
}

function Step([string]$name) {
    Write-Host "`n== $name ==" -ForegroundColor Cyan
}

if (-not (Test-Path $godot)) { Write-Host "Godot not found at $godot (set `$env:GODOT)"; Fail 'setup' }
if (-not (Test-Path "$venv\gdformat.exe")) { Write-Host 'gdtoolkit missing. Run: py -3 -m venv .venv; .venv\Scripts\python -m pip install -r workflow/tools/requirements.txt'; Fail 'setup' }

$gdFiles = @(Get-ChildItem $codeDirs -Recurse -Filter *.gd -File | ForEach-Object { $_.FullName })

# 1. Format: code must already be formatted (the edit hook does this).
Step 'Format (gdformat --check)'
if ($gdFiles.Count -gt 0) {
    & "$venv\gdformat.exe" --check $codeDirs
    if ($LASTEXITCODE -ne 0) { Fail 'format' }
}

# 2. Lint.
Step 'Lint (gdlint)'
if ($gdFiles.Count -gt 0) {
    & "$venv\gdlint.exe" $codeDirs
    if ($LASTEXITCODE -ne 0) { Fail 'lint' }
}

# 3. Import: refresh Godot's cache so class_name scripts resolve.
Step 'Import (godot --import)'
& $godot --headless --path $root --import --quiet
if ($LASTEXITCODE -ne 0) { Fail 'import' }

# 4. Types: parse every script, untested ones too. Untyped code is an error
#    (project setting debug/gdscript/warnings/untyped_declaration = Error).
Step "Typecheck ($($gdFiles.Count) scripts, godot --check-only)"
$bad = @()
foreach ($f in $gdFiles) {
    $res = 'res://' + ($f.Substring($root.Length + 1) -replace '\\', '/')
    & $godot --headless --path $root --check-only --script $res --quiet
    if ($LASTEXITCODE -ne 0) { $bad += $res }
}
if ($bad.Count -gt 0) { Write-Host ("Errors in:`n  " + ($bad -join "`n  ")); Fail 'typecheck' }

# 5. Tests (GUT), in two runs.
# Most tests only count physics frames, so they run with --fixed-fps: Godot steps
# physics as fast as it can instead of in real time (about 15x faster).
# The files below measure wall-clock time (fades, timers, sounds) and fail under
# --fixed-fps, so they run in real time. GUT has no exclude flag, so the fixed-fps
# run gets an explicit file list.
# Changing this list is a test change: it needs the owner's approval (AGENTS.md).
$realTimeTests = @(
    'res://tests/debug/test_debug_overlay.gd',
    'res://tests/debug/test_hit_markers.gd',
    'res://tests/ui/test_hit_feedback.gd'
)
$fixedFps = 128
if (-not (Test-Path 'addons/gut/gut_cmdln.gd')) { Write-Host 'GUT not installed in addons/gut'; Fail 'tests' }
$allTests = @(
    Get-ChildItem tests -Recurse -Filter 'test_*.gd' -File |
        ForEach-Object { 'res://' + ($_.FullName.Substring($root.Length + 1) -replace '\\', '/') }
)
foreach ($t in $realTimeTests) {
    if ($allTests -notcontains $t) { Write-Host "Real-time test not found: $t"; Fail 'tests' }
}
$fastTests = @($allTests | Where-Object { $realTimeTests -notcontains $_ })

Step "Tests (GUT, --fixed-fps $fixedFps, $($fastTests.Count) files)"
& $godot --headless --fixed-fps $fixedFps --path $root -s res://addons/gut/gut_cmdln.gd "-gtest=$($fastTests -join ',')" -gexit
if ($LASTEXITCODE -ne 0) { Fail 'tests (fixed fps)' }

Step "Tests (GUT, real time, $($realTimeTests.Count) files)"
& $godot --headless --path $root -s res://addons/gut/gut_cmdln.gd "-gtest=$($realTimeTests -join ',')" -gexit
if ($LASTEXITCODE -ne 0) { Fail 'tests (real time)' }

Write-Host "`nALL CHECKS PASSED" -ForegroundColor Green
exit 0
