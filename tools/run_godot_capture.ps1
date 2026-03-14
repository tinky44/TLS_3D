param(
    [string]$GodotExe = "",
    [ValidateSet("main", "creator", "title", "save_slot")]
    [string]$Scene = "main",
    [string]$Stage = "room",
    [int]$Frames = 12,
    [double]$DelaySec = 0.15,
    [string]$OutputDir = "",
    [string]$Prefix = ""
)

function Resolve-GodotExe {
    param(
        [string]$PreferredPath
    )

    $candidates = @()

    if (-not [string]::IsNullOrWhiteSpace($PreferredPath)) {
        $candidates += $PreferredPath
    }

    if (-not [string]::IsNullOrWhiteSpace($env:GODOT_EXE)) {
        $candidates += $env:GODOT_EXE
    }

    $searchRoots = @(
        (Join-Path $env:USERPROFILE "Downloads"),
        (Join-Path $env:USERPROFILE "Desktop"),
        "C:\Program Files",
        "C:\Program Files (x86)"
    )

    foreach ($root in $searchRoots) {
        if (-not (Test-Path $root)) {
            continue
        }

        $consoleMatches = Get-ChildItem -Path $root -Filter "Godot*_console.exe" -Recurse -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty FullName
        if ($consoleMatches) {
            $candidates += $consoleMatches
        }

        $guiMatches = Get-ChildItem -Path $root -Filter "Godot*.exe" -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notlike "*_console.exe" } |
            Select-Object -ExpandProperty FullName
        if ($guiMatches) {
            $candidates += $guiMatches
        }
    }

    foreach ($candidate in $candidates | Select-Object -Unique) {
        if (Test-Path $candidate) {
            return (Resolve-Path $candidate).Path
        }
    }

    throw "Godot executable was not found. Set -GodotExe or GODOT_EXE."
}

$repoRoot = Split-Path $PSScriptRoot -Parent
$projectPath = Join-Path $repoRoot "godot-project"

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $repoRoot "artifacts\godot-captures"
}

if ([string]::IsNullOrWhiteSpace($Prefix)) {
    $Prefix = "smoke_$Scene"
}

$resolvedGodotExe = Resolve-GodotExe -PreferredPath $GodotExe
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$arguments = @(
    "--path", $projectPath,
    "--",
    "--codex-smoke",
    "--scene=$Scene",
    "--frames=$Frames",
    "--delay-sec=$DelaySec",
    "--stage=$Stage",
    "--output-dir=$OutputDir",
    "--prefix=$Prefix"
)

& $resolvedGodotExe @arguments
exit $LASTEXITCODE
