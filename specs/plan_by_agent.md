# plan_by_agent.md — AIエージェントのメモ帳

更新日: 2026-03-15

---

## 残タスク

| 優先 | タスク | 規模 |
|---|---|---|
| ★★★ | デイリーガイド HUD（今日の目標表示） | 小 |
| ★★★ | ファストトラベル（ESCメニュー内地図） | 中 |

---

## ★★★ デイリーガイド（今日の目標表示）

### 目的

「今何をすればいいかわからない」を解消する。
**左下**に `Hint: [テキスト]` の形式で1行表示する。

### 表示仕様

| 条件 | 表示テキスト |
|---|---|
| `current_stage_id == "myroom"` かつ `actions_today == 0` | Hint: 朝だ。学校に向かおう |
| 学校系ステージ（`is_school_classroom_stage()` == true） | Hint: 授業を受けよう |
| `actions_today >= max_actions_per_day` かつ 学校外 | Hint: 夕方だ。家に帰ろう |
| `current_stage_id == "myroom"` かつ `actions_today >= max_actions_per_day` | Hint: ベッドで休もう |
| それ以外 | （非表示） |

### 実装方針

**ノード追加（`_setup_ui` 内、左下に配置）**

```gdscript
# MainScene.gd: _setup_ui() に追加
var daily_guide_label = Label.new()
daily_guide_label.name = "daily_guide_label"
daily_guide_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
daily_guide_label.offset_bottom = -8
daily_guide_label.offset_left = 8
ui_layer.add_child(daily_guide_label)
```

**更新関数**

```gdscript
# MainScene.gd: _update_daily_guide() を新規追加
func _update_daily_guide() -> void:
    var text := ""
    var stage := Global.current_stage_id
    var actions := int(Global.actions_today)
    var max_a := int(Global.max_actions_per_day)
    var in_school := StageBuilder.is_school_classroom_stage(stage)

    if stage == "myroom" and actions == 0:
        text = "⏰ 朝だ。学校に向かおう"
    elif in_school:
        text = "📚 授業を受けよう"
    elif actions >= max_a and stage != "myroom":
        text = "🌇 夕方だ。家に帰ろう"
    elif stage == "myroom" and actions >= max_a:
        text = "🛏 今日は終わり。ベッドで休もう"

    daily_guide_label.text = text
    daily_guide_panel.visible = text != ""
```

**呼び出し箇所**：`_update_ui()` の末尾に `_update_daily_guide()` を追記する。

### 変更ファイル

- `godot-project/scripts/MainScene.gd`
  - `_setup_ui()` にノード追加（約10行）
  - `_update_daily_guide()` 新規追加（約15行）
  - `_update_ui()` 末尾に1行追記

---

## ★★★ ファストトラベル（ESCメニュー内地図）

### 目的

「どこにいても行きたい場所に即ワープできる」機能。
ESCポーズメニューを左右に分割し、**右ペイン**に行ける場所リストを表示する。

### UI レイアウト

```
┌─────────────────────────────────────┐
│  ポーズメニュー                        │
│ ┌────────────┬──────────────────┐   │
│ │ 左ペイン    │ 右ペイン（地図）   │   │
│ │            │                  │   │
│ │ ゲームに戻る │ 📍 今いる場所     │   │
│ │ セーブする  │ ─────────────── │   │
│ │ タイトルへ  │ ✅ 自室           │   │
│ │ 終了する   │ ✅ 部屋           │   │
│ │            │ ✅ 屋外（街）      │   │
│ │            │ ✅ 学校（廊下）   │   │
│ │            │ 🔒 駅（ロック中） │   │
│ └────────────┴──────────────────┘   │
└─────────────────────────────────────┘
```

### ステージ表示リスト定義

```gdscript
# MainScene.gd 内に定数として定義
const FAST_TRAVEL_STAGES := [
    # [stage_id, 表示名]
    ["myroom",                  "🛏 自室"],
    ["room",                    "🏠 部屋（リビング）"],
    ["outdoor",                 "🌳 屋外（街）"],
    ["school_hallway",          "🏫 学校（廊下）"],   # _resolve_stage_id() で年齢補完
    ["station",                 "🚉 駅"],
    ["train",                   "🚃 電車"],
    ["adjacent_town",           "🏘 隣町"],
    ["gakuenmachi",             "🏙 学園街"],
]
```

※ `school_hallway` は `_resolve_stage_id()` で `school_hallway_elementary` / `_middle` / `_high` に解決される。

### ロック判定

既存の `_get_stage_lock_message(stage_id)` をそのまま使用。
- 空文字列 → 移動可能（ボタン有効）
- 非空文字列 → ボタンをグレーアウト、ホバー時にロック理由をツールチップ表示

### ファストトラベル実行仕様

| 項目 | 仕様 |
|---|---|
| アクション消費 | `actions_today += 1`（通常ドア遷移と同じ） |
| 現在地への移動 | ボタンを無効化（`current_stage_id` と一致する場合） |
| 実行後 | メニューを閉じ `_load_stage()` を呼ぶ |

### 実装方針

**`_setup_pause_menu()` の変更（MainScene.gd L1757付近）**

現在は `CenterContainer` で中央配置しているが、`HBoxContainer` に変更して左右分割する。

```gdscript
func _setup_pause_menu() -> void:
    # ... 既存の背景ColorRect ...

    var hbox = HBoxContainer.new()
    hbox.add_theme_constant_override("separation", 24)
    hbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

    # --- 左ペイン（既存ボタン群） ---
    var left_panel = VBoxContainer.new()
    left_panel.custom_minimum_size = Vector2(220, 0)
    # （既存ボタンをここに追加）
    hbox.add_child(left_panel)

    # --- 右ペイン（ファストトラベルリスト） ---
    var right_panel = VBoxContainer.new()
    right_panel.name = "fast_travel_panel"
    right_panel.custom_minimum_size = Vector2(240, 0)
    hbox.add_child(right_panel)
    _setup_fast_travel_panel(right_panel)

    pause_menu.add_child(hbox)
```

**`_setup_fast_travel_panel()` 新規追加**

```gdscript
func _setup_fast_travel_panel(parent: VBoxContainer) -> void:
    var title = Label.new()
    title.text = "📍 " + _get_stage_display_name(Global.current_stage_id)
    parent.add_child(title)

    var sep = HSeparator.new()
    parent.add_child(sep)

    for entry in FAST_TRAVEL_STAGES:
        var stage_id: String = _resolve_stage_id(entry[0])
        var label: String = entry[1]
        var btn = Button.new()
        btn.text = label
        var lock_msg = _get_stage_lock_message(stage_id)
        if lock_msg != "":
            btn.disabled = true
            btn.tooltip_text = lock_msg
        elif stage_id == Global.current_stage_id:
            btn.disabled = true
            btn.tooltip_text = "今いる場所"
        else:
            btn.pressed.connect(_on_fast_travel_pressed.bind(stage_id))
        parent.add_child(btn)
```

**`_on_fast_travel_pressed()` 新規追加**

```gdscript
func _on_fast_travel_pressed(stage_id: String) -> void:
    _toggle_pause()                       # メニューを閉じる
    Global.current_stage_id = stage_id
    Global.actions_today += 1
    _update_actions_hud()
    _load_stage()
```

**`_toggle_pause()` でリストを再構築**

ポーズを開くたびに現在地・ロック状態が変わるため、`_toggle_pause()` の「表示時」分岐で `_setup_fast_travel_panel()` を再呼び出しする（既存ノードをクリアしてから追加）。

### 変更ファイル

- `godot-project/scripts/MainScene.gd`
  - `FAST_TRAVEL_STAGES` 定数追加（5行）
  - `_setup_pause_menu()` を左右分割に変更（約20行の差分）
  - `_setup_fast_travel_panel()` 新規追加（約30行）
  - `_on_fast_travel_pressed()` 新規追加（約6行）
  - `_toggle_pause()` にパネル再構築を追加（約5行）

---

## 実装順

| Phase | 内容 | 規模 |
|---|---|---|
| **1** | デイリーガイド HUD | 小（独立タスク） |
| **2** | ファストトラベル（ESCメニュー分割 + リスト） | 中（独立タスク） |

Phase 1・2 は独立して実装可能。
