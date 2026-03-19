# パフォーマンス調査メモ（2026-03-20）

## 1. 結論
- 現状の重さは「Godotの限界」より「スクリプトと描画実装の積み重ね」が主因。
- とくに「屈み中」は毎フレーム追加計算が入り、通常時よりCPU負荷が増える実装。

## 2. 根拠（コード）
### 2.1 屈み時に同種の二分探索が1フレームで重複
- `SkeletalPlayer.gd:153-156` で `get_crouch_stride_ratio()` を毎フレーム実行。
- `SkeletalPlayer.gd:279` で `calculate_pose_data()` を毎フレーム実行。
- `CharacterPoseCalculator.gd:120-125` と `CharacterPoseCalculator.gd:262-267` は、どちらも 15 回の二分探索。
- つまり屈み中は 1 フレームあたり最低 30 回 `_eval_crouch_height()` が走る構成。

### 2.2 レイキャストを毎フレーム強制更新
- `SkeletalPlayer.gd:232-234`, `:256`, `:326-333`。
- auto crouch と天井判定で `force_raycast_update()` を複数回実行。

### 2.3 毎物理フレームで強制再描画
- `SkeletalPlayer.gd:182`
- `SkeletalNPC.gd:287`
- プレイヤー + NPC 全員が `queue_redraw()` を常時実行。

### 2.4 スカート（側面）描画の計算量が大きい
- `CharacterBodyDrawer.gd:434-521` で候補点生成・選別・多角形自己交差チェック（2重ループ）。
- `CharacterBodyDrawer.gd:548-562` でプリーツ線を追加描画。
- 屈み時は姿勢変化が大きく、これらを毎フレーム再計算しやすい。

### 2.5 MainScene の毎フレーム更新量が多い
- `MainScene.gd:1814-1827` で UI/吹き出し/ミニマップ等を毎フレーム更新。
- `MainScene.gd:1918`, `:1940`, `:1981` で `get_children()` 走査を複数回。
- `MainScene.gd:2000` + `StageBuilder.gd:3692-3983` で障害物コメント文字列を都度生成。

## 3. ステージ構成の実測（簡易）
Godot headless で `StageBuilder.build_stage()` 後のノード数を計測。

- `train`: total 233 / canvas 233 / Control 174 / ColorRect 154
- `station`: total 191 / canvas 191 / Control 165 / ColorRect 154
- `room`: total 180 / canvas 180 / Control 90 / ColorRect 60 / Line2D 53

補足:
- MainScene 直下の stage object（直接子）は最大 24 程度で、探索ループだけが主犯ではない。
- 一方、描画対象ノード総数は多く、再描画頻度の高さと合わさると負荷が出やすい。

## 4. 判定
- 「Godotの限界」ではなく、現実装の CPU/GDScript 計算 + 再描画頻度 + ノード構成の組み合わせがボトルネック。
- 屈み時の重さは、追加計算（姿勢逆算・レイ更新・衣装追従）が増えるため実装上説明可能。

## 5. 優先改善案（効果順）
1. 屈み二分探索の重複解消
- 同フレーム内で crouch パラメータをキャッシュし、stride 計算と pose 計算で共有する。

2. `queue_redraw` の間引き
- 角度/姿勢差が閾値以下なら再描画しない。
- 非表示・画面外 NPC は更新頻度を下げる。

3. UI更新の低頻度化
- `_update_ui` / `_update_actions_hud` / 吹き出し文字列更新を 0.1〜0.2 秒間隔または状態変化時のみ実行。

4. ワールド表現の軽量化
- 多数の `ColorRect`（Control）を段階的に軽量な描画構成へ置換。

5. 実機プロファイルで確認
- Godot Profiler で `SkeletalPlayer._physics_process` / `CharacterBodyDrawer.draw_skirt` / `MainScene._process` のCPU時間を確認する。
