param(
    [string]$GodotExe = "",
    [ValidateSet("main", "creator", "title", "save_slot")]
    [string]$Scene = "main",
    [string]$Stage = "room",
    [string]$Resolution = "",
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
    [string]$BagColor = "",
    [string]$FitStage = ""
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
$automationRoot = Join-Path $repoRoot "artifacts\godot-runtime"
$godotRoamingDir = Join-Path $automationRoot "AppData\Roaming"
$godotLocalDir = Join-Path $automationRoot "AppData\Local"
$godotTempDir = Join-Path $automationRoot "Temp"
$godotLogDir = Join-Path $automationRoot "logs"

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $repoRoot "artifacts\godot-captures"
}

if ([string]::IsNullOrWhiteSpace($Prefix)) {
    $Prefix = "smoke_$Scene"
}

$resolvedGodotExe = Resolve-GodotExe -PreferredPath $GodotExe
$safeLogPrefix = ($Prefix -replace '[<>:"/\\|?*]', '_')
$logTimestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFilePath = Join-Path $godotLogDir "$safeLogPrefix`_$logTimestamp.log"
Write-Host "USING_GODOT_EXE=$resolvedGodotExe"
Write-Host "USING_GODOT_LOG_FILE=$logFilePath"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
New-Item -ItemType Directory -Force -Path $godotRoamingDir | Out-Null
New-Item -ItemType Directory -Force -Path $godotLocalDir | Out-Null
New-Item -ItemType Directory -Force -Path $godotTempDir | Out-Null
New-Item -ItemType Directory -Force -Path $godotLogDir | Out-Null

$arguments = [System.Collections.Generic.List[string]]::new()
if (-not [string]::IsNullOrWhiteSpace($Resolution)) {
    $arguments.Add("--resolution")
    $arguments.Add($Resolution)
}
$arguments.AddRange([string[]]@(
    "--path", $projectPath,
    "--log-file", $logFilePath,
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
Add-OptionalArgument -ArgumentList $arguments -Key "fit-stage" -Value $FitStage

$originalEnv = @{
    "APPDATA" = $env:APPDATA
    "LOCALAPPDATA" = $env:LOCALAPPDATA
    "TEMP" = $env:TEMP
    "TMP" = $env:TMP
}

$env:APPDATA = $godotRoamingDir
$env:LOCALAPPDATA = $godotLocalDir
$env:TEMP = $godotTempDir
$env:TMP = $godotTempDir

$exitCode = 1
try {
    & $resolvedGodotExe @arguments
    $exitCode = $LASTEXITCODE
}
finally {
    foreach ($key in $originalEnv.Keys) {
        if ($null -eq $originalEnv[$key]) {
            Remove-Item -Path "Env:$key" -ErrorAction SilentlyContinue
        }
        else {
            Set-Item -Path "Env:$key" -Value $originalEnv[$key]
        }
    }
}

exit $exitCode
