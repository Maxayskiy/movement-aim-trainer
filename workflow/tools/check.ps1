# One command that checks everything: format, lint, complexity, types, tests.
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
$reinstallHint = 'Run: py -3 -m venv .venv; .venv\Scripts\python -m pip install -r workflow/tools/requirements.txt'
if (-not (Test-Path "$venv\gdformat.exe")) { Write-Host "gdtoolkit missing. $reinstallHint"; Fail 'setup' }

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

# 3. Complexity: fail on any function or class in src/ graded C or worse (score 11+).
#    gdradon has no threshold flag and always exits 0 on high grades, so parse its
#    output. Its line numbers are wrong, so print file, name, grade and score only.
#    It also exits 0 when it can't process a file (e.g. a Python keyword used as a
#    name) and only says so on stderr, so any stderr text fails the step too.
Step 'Complexity (gdradon, src/)'
if (Test-Path 'src') {
    if (-not (Test-Path "$venv\gdradon.exe")) { Write-Host "gdradon not found at $venv\gdradon.exe. $reinstallHint"; Fail 'complexity' }
    # 2>&1 merges the streams; stderr lines arrive as ErrorRecord objects.
    $radon = @(& "$venv\gdradon.exe" cc src 2>&1)
    $code = $LASTEXITCODE
    $file = ''
    $problems = @()
    foreach ($line in $radon) {
        if ($line -is [Management.Automation.ErrorRecord]) {
            # .Exception.Message, because ToString() names the exception type on blank lines.
            $text = $line.Exception.Message
            if ($text -match "^Cannot process file '(.+)' due to exception: (.+)$") {
                $problems += "$($Matches[1] -replace '\\', '/'): not graded (gdradon: $($Matches[2]))"
            } elseif ($text.Trim()) { $problems += $text }
            continue
        }
        if ($line -match '^\S') { $file = $line.Trim() -replace '\\', '/'; continue }
        if ($line -match '^\s+\w+\s+\d+:\d+\s+(\S+)\s+-\s+([A-F])\s+\((\d+)\)') {
            if ('CDEF'.Contains($Matches[2])) { $problems += "${file}: $($Matches[1]) $($Matches[2]) ($($Matches[3]))" }
        }
    }
    if ($problems.Count -gt 0) { Write-Host ($problems -join "`n") }
    if ($problems.Count -gt 0 -or $code -ne 0) { Fail 'complexity' }
}

# 4. Import: refresh Godot's cache so class_name scripts resolve.
Step 'Import (godot --import)'
& $godot --headless --path $root --import --quiet
if ($LASTEXITCODE -ne 0) { Fail 'import' }

# 5. Types: compile every script, untested ones too. Untyped code is an error
#    (project setting debug/gdscript/warnings/untyped_declaration = Error), and so are
#    unused variables, unused private members, unreachable code and shadowed variables.
#    One Godot process loads every script (workflow/tools/typecheck_all.gd) instead of
#    one --check-only process per script: same errors, about 2 s instead of 20.
#    Loading a script runs its _static_init(), which can kill the process with exit
#    code 0, so the step also needs the DONE line with the full count.
Step "Typecheck ($($gdFiles.Count) scripts, one Godot process)"
$listFile = Join-Path $root '.godot\typecheck-list.txt'
$resPaths = @($gdFiles | ForEach-Object { 'res://' + ($_.Substring($root.Length + 1) -replace '\\', '/') })
[IO.File]::WriteAllLines($listFile, [string[]]$resPaths)
$probe = Join-Path $PSScriptRoot 'typecheck_all.gd'
# Stdout is echoed as it comes and kept; Godot's error lines (stderr) print directly.
$out = @(& $godot --headless --path $root -s $probe -- $listFile | ForEach-Object { Write-Host $_; $_ })
$code = $LASTEXITCODE
$bad = @($out | Where-Object { $_ -match '^TYPECHECK BAD (\S+)' } | ForEach-Object { $_ -replace '^TYPECHECK BAD ', '' })
$done = @($out | Where-Object { $_ -match '^TYPECHECK DONE checked=(\d+)' })
if ($done.Count -eq 0) { Write-Host 'Typecheck stopped early: no summary'; Fail 'typecheck' }
$checked = [int]($done[-1] -replace '^TYPECHECK DONE checked=(\d+).*', '$1')
if ($checked -ne $gdFiles.Count) { Write-Host "Typecheck stopped early: checked $checked of $($gdFiles.Count)"; Fail 'typecheck' }
if ($bad.Count -gt 0) { Write-Host ("Errors in:`n  " + ($bad -join "`n  ")); Fail 'typecheck' }
if ($code -ne 0) { Write-Host "Typecheck: Godot exit code $code"; Fail 'typecheck' }

# 6. Tests (GUT), in two runs.
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
