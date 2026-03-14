# Godot capture workflow

`F12` saves the current viewport to a PNG file.

- Default save location: `user://screenshots`
- File name format: `<scene_name>_YYYY-MM-DD_HH-MM-SS.png`

Codex can also run an automated smoke capture from PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\run_godot_capture.ps1
```

Useful options:

- `-Scene main`
- `-Scene creator`
- `-Stage room`
- `-Frames 12`
- `-OutputDir .\artifacts\godot-captures`
- `-GodotExe C:\path\to\Godot_v4.x_console.exe`
- `-Pose taiiku_suwari`
- `-Facing front`
- `-TopsType jumper_skirt`
- `-BottomsType skirt`
- `-HairStyle long`

The wrapper launches Godot with a Codex-only smoke mode, waits a few frames, saves a PNG, prints the saved path, and exits with a non-zero code on failure.

Example: capture `main` with gym-sit pose and jumper skirt styling.

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\run_godot_capture.ps1 `
  -Scene main `
  -Stage room `
  -Frames 24 `
  -Pose taiiku_suwari `
  -Facing front `
  -TopsType jumper_skirt `
  -BottomsType skirt `
  -OutputDir .\artifacts\godot-captures `
  -Prefix smoke_main_taiiku_jumper
```
