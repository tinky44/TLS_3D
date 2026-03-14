
### コミット規約

```
feat: メッセージ（日本語）

Co-authored-by: chatgpt-codex-connector[bot] <199175422+chatgpt-codex-connector[bot]@users.noreply.github.com> to show.
```

- prefix: `feat` / `fix` / `refactor` / `docs` / `chore`


### Godotキャプチャ実行ルール

- `tools/run_godot_capture.ps1` を実行するときは、Godot 実行ファイルの自動探索を使わないこと。
- 必ず `-GodotExe` で Console 版の Godot 実行ファイルを明示すること。
- 理由: 自動探索に任せると、環境によってはメモリアクセス違反や不安定な起動が起きるため。
- 既定の実行ファイルは以下を使うこと。  
  `C:\Users\nnshi\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe`

端的には

```md
- `tools/run_godot_capture.ps1` 実行時は、必ず `-GodotExe 'C:\Users\nnshi\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe'` を付けること。自動探索は使わない。
```

例:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_godot_capture.ps1 `
  -GodotExe 'C:\Users\nnshi\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' `
  -Scene main `
  -Stage room `
  -Frames 24 `
  -Pose taiiku_suwari `
  -Facing side `
  -TopsType jumper_skirt `
  -BottomsType skirt `
  -OutputDir .\artifacts\godot-captures `
  -Prefix review_taiiku_side_fix
```

