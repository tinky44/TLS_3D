param(
    [string]$GodotExe = "",
    [ValidateSet("main", "creator", "title", "save_slot")]
    [string]$Scene = "main",
    [string]$Stage = "room",
    [int]$Frames = 12,
    [double]$DelaySec = 0.15,
    [string]$OutputDir = "",
    [string]$Prefix = "",
    [string]$Age = "",
    [string]$Term = "",
    [string]$Height = "",
    [string]$Stress = "",
    [string]$Pose = "",
    [string]$Facing = "",
    [string]$Dir = "",
    [string]$AutoCrouch = "",
    [string]$TargetCrouchCm = "",
    [string]$LookHeadAngle = "",
    [string]$LookPitch = "",
    [string]$TopsType = "",
    [string]$TopsColor = "",
    [string]$BottomsType = "",
    [string]$BottomsColor = "",
    [string]$HairStyle = "",
    [string]$HairColor = "",
    [string]$HatType = "",
    [string]$HatColor = "",
    [string]$BagType = "",
    [string]$BagColor = ""
)

function Add-OptionalArgument {
    param(
        [System.Collections.Generic.List[string]]$ArgumentList,
        [string]$Key,
        [string]$Value
    )

    if (-not [string]::IsNullOrWhiteSpace($Value)) {
        $ArgumentList.Add("--$Key=$Value")
    }
}

function Resolve-ExeCandidate {
    param(
        [string]$CandidatePath
    )

    if ([string]::IsNullOrWhiteSpace($CandidatePath)) {
        return $null
    }

    try {
        $item = Get-Item -LiteralPath $CandidatePath -ErrorAction Stop
    }
    catch {
        return $null
    }

    if ($item -is [System.IO.FileInfo] -and $item.Extension -ieq ".exe") {
        return $item.FullName
    }

    return $null
}

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

        $consoleMatches = Get-ChildItem -Path $root -Filter "Godot*_console.exe" -File -Recurse -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty FullName
        if ($consoleMatches) {
            $candidates += $consoleMatches
        }

        $guiMatches = Get-ChildItem -Path $root -Filter "Godot*.exe" -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notlike "*_console.exe" } |
            Select-Object -ExpandProperty FullName
        if ($guiMatches) {
            $candidates += $guiMatches
        }
    }

    foreach ($candidate in $candidates | Select-Object -Unique) {
        $resolvedCandidate = Resolve-ExeCandidate -CandidatePath $candidate
        if (-not [string]::IsNullOrWhiteSpace($resolvedCandidate)) {
            return $resolvedCandidate
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
Write-Host "USING_GODOT_EXE=$resolvedGodotExe"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$arguments = [System.Collections.Generic.List[string]]::new()
$arguments.AddRange([string[]]@(
    "--path", $projectPath,
    "--",
    "--codex-smoke",
    "--scene=$Scene",
    "--frames=$Frames",
    "--delay-sec=$DelaySec",
    "--stage=$Stage",
    "--output-dir=$OutputDir",
    "--prefix=$Prefix"
))

Add-OptionalArgument -ArgumentList $arguments -Key "age" -Value $Age
Add-OptionalArgument -ArgumentList $arguments -Key "term" -Value $Term
Add-OptionalArgument -ArgumentList $arguments -Key "height" -Value $Height
Add-OptionalArgument -ArgumentList $arguments -Key "stress" -Value $Stress
Add-OptionalArgument -ArgumentList $arguments -Key "pose" -Value $Pose
Add-OptionalArgument -ArgumentList $arguments -Key "facing" -Value $Facing
Add-OptionalArgument -ArgumentList $arguments -Key "dir" -Value $Dir
Add-OptionalArgument -ArgumentList $arguments -Key "auto-crouch" -Value $AutoCrouch
Add-OptionalArgument -ArgumentList $arguments -Key "target-crouch-cm" -Value $TargetCrouchCm
Add-OptionalArgument -ArgumentList $arguments -Key "look-head-angle" -Value $LookHeadAngle
Add-OptionalArgument -ArgumentList $arguments -Key "look-pitch" -Value $LookPitch
Add-OptionalArgument -ArgumentList $arguments -Key "tops-type" -Value $TopsType
Add-OptionalArgument -ArgumentList $arguments -Key "tops-color" -Value $TopsColor
Add-OptionalArgument -ArgumentList $arguments -Key "bottoms-type" -Value $BottomsType
Add-OptionalArgument -ArgumentList $arguments -Key "bottoms-color" -Value $BottomsColor
Add-OptionalArgument -ArgumentList $arguments -Key "hair-style" -Value $HairStyle
Add-OptionalArgument -ArgumentList $arguments -Key "hair-color" -Value $HairColor
Add-OptionalArgument -ArgumentList $arguments -Key "hat-type" -Value $HatType
Add-OptionalArgument -ArgumentList $arguments -Key "hat-color" -Value $HatColor
Add-OptionalArgument -ArgumentList $arguments -Key "bag-type" -Value $BagType
Add-OptionalArgument -ArgumentList $arguments -Key "bag-color" -Value $BagColor

& $resolvedGodotExe @arguments
exit $LASTEXITCODE
