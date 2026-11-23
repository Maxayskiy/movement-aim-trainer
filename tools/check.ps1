# One command that checks everything: format, lint, types, tests.
# Run from anywhere:
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools/check.ps1
# Exits 0 when all checks pass, 1 on the first failure.

# 'Continue': Godot prints errors to stderr; we judge each step by its exit code.
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$godot = $env:GODOT
if (-not $godot) { $godot = 'C:\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' }
$venv = Join-Path $root '.venv\Scripts'
$codeDirs = @('src', 'tests')

function Fail([string]$step) {
    Write-Host "`nFAILED: $step" -ForegroundColor Red
    exit 1
}

function Step([string]$name) {
    Write-Host "`n== $name ==" -ForegroundColor Cyan
}

if (-not (Test-Path $godot)) { Write-Host "Godot not found at $godot (set `$env:GODOT)"; Fail 'setup' }
if (-not (Test-Path "$venv\gdformat.exe")) { Write-Host 'gdtoolkit missing. Run: py -3 -m venv .venv; .venv\Scripts\python -m pip install -r tools/requirements.txt'; Fail 'setup' }

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

# 5. Tests (GUT): exit code is non-zero if any test fails.
Step 'Tests (GUT)'
if (-not (Test-Path 'addons/gut/gut_cmdln.gd')) { Write-Host 'GUT not installed in addons/gut'; Fail 'tests' }
& $godot --headless --path $root -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
if ($LASTEXITCODE -ne 0) { Fail 'tests' }

Write-Host "`nALL CHECKS PASSED" -ForegroundColor Green
exit 0
