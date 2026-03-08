# AI 検討メモ (plan_by_agent)

このファイルは、分析ドキュメント（`misc/` 以下のリサーチ結果）に基づき、本作を「高身長シミュレーター」として面白くするための具体的な戦略と実装計画を書き溜める場所ですわ。

---

## 💎 コア戦略：高身長体験の「フェティシズム」と「リアリティ」
分析の結果、本作が優先すべき「面白さ（快感・フック）」は以下の4点に集約されますわ。

1. **数値の執着**: cm単位の変化、平均との比較、成長ログ。
2. **日常の摩擦**: ドアをくぐる、低い洗面台を使う、頭上の障害物を避ける不便さ。
3. **視線の格差**: 普通の人々（NPC）を「見下ろす」視線の快感と、相手からの「驚き」の視線。
4. **ライフステージの変遷**: 成長に伴って、同じ世界（家・学校）が「小さくなっていく」体験。

---

## 🛠️ 現在のステータス（2026-03-08 深夜）

### 完了済み ✅
- **基盤**: 骨格描画、二段階屈みシステム、NPC配置、ステージ遷移（保健室・校庭・駅追加済み） ✅
- **成長システム**: 学期進行、身長計インタラクト、成長履歴（平均身長差・前回差）の保存 ✅
- **UI/UX**: 成長ログの履歴表示・簡易グラフ化、キャラメイクでの開始年齢・成長タイプ設定 ✅
- **物理・演出**: 頭の衝突判定、カメラシェイク、衝突信号（`head_bump`）の実装 ✅
- **不便さの視覚化**: 自動屈み機能による「低い設備への干渉（前傾姿勢）」の表現 ✅

---

## 🚀 次のアクションプラン (Next Actions)

### ✅ フェーズ1：ゲームストーリー基盤（現在着手中）

ゲームが「能動操作のみ」になっている根本問題を解決する。

#### 1-A. ダイアログシステム（基盤・最優先）⭐⭐⭐
**課題**: NPCに話しかけられない。物語が進まない。吹き出しのみで会話が成立しない。
**実装ファイル**: `MainScene.gd`（新規関数追加のみ）

- **UI**: 画面下部に固定パネル（ビジュアルノベル形式）
  - 話者名ラベル（上段）+ セリフラベル（下段）+ 「Eキーで次へ」ヒント
- **制御変数**: `_in_dialogue: bool`, `_dialogue_lines: Array`, `_dialogue_index: int`
- **関数**: `_setup_dialogue_panel()`, `_start_dialogue(npc_id, key)`, `_advance_dialogue()`
- **セリフデータ**: スクリプト内辞書で管理（将来JSON移行可）

```gdscript
# セリフデータ構造（MainScene.gd 先頭）
const DIALOGUES = {
    "haruka": {
        "first_meet": [
            {"speaker": "はるか", "text": "うわ、背高っ！"},
            {"speaker": "はるか", "text": "ねえ、何年生？私と同じ？"},
        ]
    },
    "teacher": {
        "semester_start": [
            {"speaker": "田中先生", "text": "起立、礼。着席。"},
            {"speaker": "田中先生", "text": "新学期が始まりましたね。"},
            {"speaker": "田中先生", "text": "……また背が伸びたんですか。後ろの席に座ってください"},
        ]
    }
}
```

#### 1-B. NPCインタラクション（1-Aに依存）⭐⭐⭐
**課題**: EキーがNPC対応していない。`_update_bubble()`がNPCを無視している。
**実装ファイル**: `SkeletalNPC.gd`（変数2行追加）+ `MainScene.gd`（バブル・Eキー修正）

- `SkeletalNPC.gd`に `var npc_id: String = ""`, `var dialogue_key: String = "default"` 追加
- `_update_bubble()`に NPC近接検知を追加（既存の60px判定ロジックを流用）
- Eキー処理に `elif _nearby_npc: _start_dialogue(...)` を追加
- `_spawn_npcs()` でコアNPC「はるか」に `npc_id = "haruka"` を設定

#### 1-C. 測定演出の儀式化⭐⭐⭐
**課題**: 測定後に即テキスト表示→ボタンでスキップ。成長の感動がない。
**実装ファイル**: `MainScene.gd`（`_show_measurement_result()` 改修のみ）

演出フロー:
1. フェードイン（0.5秒）
2. 前回身長 → 現在身長へカウントアップ（Tween, 1.5秒）
3. `+X.X cm` がスケールアップしてポップ表示（0.3秒）
4. 主人公の独白テキストをフェードイン
5. 「次の学期へ」ボタン表示

```gdscript
# 追加するTweenアニメ（既存パネル・ラベルをそのまま活用）
tween.tween_method(_update_height_counter, prev_h, h, 1.5)
tween.tween_property(diff_label, "scale", Vector2(1.4, 1.4), 0.15)
```

#### 1-D. イベントキュー＋始業式イベント⭐⭐
**課題**: 学期が切り替わっても演出なしで即次の世界が始まる。受動的ストーリーがない。
**実装ファイル**: `Global.gd`（5行追加）+ `MainScene.gd`（_load_stage末尾に処理追加）

```gdscript
# Global.gd に追加
var pending_events: Array = []
func queue_event(id: String) -> void: pending_events.append(id)
func pop_next_event() -> String:
    if pending_events.is_empty(): return ""
    return pending_events.pop_front()

# advance_term() 末尾に追加
queue_event("semester_start")

# MainScene._load_stage() 末尾に追加
var ev = global.pop_next_event()
if ev == "semester_start":
    _start_dialogue("teacher", "semester_start")
```

---

### フェーズ2（フェーズ1完了後）

#### 2-A. コアNPC「はるか」の深化
- 身長差に応じたセリフ分岐（`tall` / `huge` / `same` で異なるセリフセット）
- 学期が進むにつれて変化するセリフ（term番号で分岐）

#### 2-B. 物理的摩擦の視認強化（ツンツルテン・システム）
- `CharacterDrawer.gd`: 身長 > 170cm で袖・裾が相対的に短くなる描画ロジック
- 「ゴン！」時の主人公モノローグ追加

#### 2-C. 受動的ストレスイベント
- 体育祭・旗手イベント（semester_start と同じキュー機構を利用）
- 集合写真の見切れ演出（フォトモード連動）

---

## 📓 実装メモ（テクニカル）

- **CharacterDrawer 改修案**:
    - `arm_length_factor` を導入し、基準身長（160cm等）より高い場合に「服の袖の長さ」を相対的に減算する。
- **センサー拡張**:
    - つり革（overhead判定）が「顔（目の位置）」の高さにある場合、回避アニメーションを優先。
- **ダイアログデータ管理**:
    - 現状は `MainScene.gd` の `const DIALOGUES` で管理。将来的に `res://data/dialogues.json` へ分離可。
- **NPC識別**:
    - `npc_id` を `SkeletalNPC.gd` に追加し、`_spawn_npcs()` でコアNPCに設定する方式。匿名NPCは空文字のまま。

---
*Co-Authored-By: gemini <218195315+gemini-cli@users.noreply.github.com>*
