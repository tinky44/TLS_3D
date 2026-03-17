# 実績システム 設計書

更新日: 2026-03-17

---

## 概要

ゲーム内のイベント・選択・行動に紐づく「実績」を管理するシステム。
- イベントフラグ成立時に **右下ポップアップ** で即時通知
- 自室の本棚をインタラクトすると **実績一覧パネル** を表示
- 未解除の実績は「???」で存在をほのめかす（完全非表示の hidden 実績も可）

---

## アーキテクチャ概観

```
[Global.gd]
  achievements_unlocked: Array   ← 解除済みIDリスト（セーブ対象）

[AchievementDatabase.gd]（新規）
  const ACHIEVEMENTS: Dictionary ← 全実績の定義

[MainScene.gd]
  set_story_flag() の後 → _try_unlock_achievements() を呼ぶ
  またはイベント処理後の共通フック

[AchievementPopup] シーン（新規）
  MainScene に CanvasLayer として常駐
  解除キューを処理し、右下でアニメーション表示

[AchievementViewer] パネル（新規 or 既存 history_panel と同構造）
  自室の本棚インタラクト → MainScene が表示
```

---

## データ定義（AchievementDatabase.gd）

```gdscript
# godot-project/scripts/AchievementDatabase.gd
extends Node

const ACHIEVEMENTS: Dictionary = {
    # --- id: 実績定義 ---
    "first_measurement": {
        "name":    "初めての身長測定",
        "desc":    "保健室で身長を計ってもらった。",
        "icon":    "ruler",       # アイコン種別（後述）
        "hidden":  false,         # false = 存在は見える、true = ???のみ
        "trigger": "story_flag",  # 解除トリガー種別
        "key":     "measured_at_infirmary",  # story_flags のキー
    },
    "join_volleyball": {
        "name":    "ネットの向こうへ",
        "desc":    "バレー部に参加した。",
        "icon":    "volleyball",
        "hidden":  false,
        "trigger": "story_flag",
        "key":     "vball_joined",
    },
    "bookshelf_found": {
        "name":    "本の虫",
        "desc":    "自室の本棚を調べた。",
        "icon":    "book",
        "hidden":  false,
        "trigger": "story_flag",
        "key":     "bookshelf_checked",
    },
    "confidence_high": {
        "name":    "自分らしく",
        "desc":    "自信値が 10 を超えた。",
        "icon":    "star",
        "hidden":  false,
        "trigger": "threshold",   # パラメータ閾値トリガー
        "param":   "self_confidence",
        "value":   10,
    },
    # hidden 実績の例（存在も「???」で伏せる）
    "secret_ending": {
        "name":    "???",
        "desc":    "???",
        "icon":    "question",
        "hidden":  true,
        "trigger": "story_flag",
        "key":     "true_ending_reached",
    },
}
```

### アイコン種別（icon フィールド）

描画は CharacterDrawUtils.gd の新規関数か、TextureRect で画像を使う想定。
まずはテキスト絵文字または単色の図形でよい。

| icon 値      | 外見イメージ       |
|--------------|--------------------|
| `ruler`      | 定規               |
| `volleyball` | ○（ボール）         |
| `book`       | 本の形（矩形）     |
| `star`       | 星形               |
| `question`   | ？マーク           |
| `heart`      | ハート             |

---

## Global.gd への追加

```gdscript
# --- 実績 ---
var achievements_unlocked: Array = []   # 解除済み実績ID

func unlock_achievement(id: String) -> bool:
    if id in achievements_unlocked:
        return false   # すでに解除済み
    achievements_unlocked.append(id)
    emit_signal("achievement_unlocked", id)   # ← ポップアップがこれを受け取る
    return true

signal achievement_unlocked(id: String)
```

### セーブ/ロードへの追記（save_slot / load_slot）

```gdscript
# save_slot() 内
cfg.set_value("progress", "achievements_unlocked", achievements_unlocked)

# load_slot() 内
achievements_unlocked = cfg.get_value("progress", "achievements_unlocked", [])
```

---

## 解除チェックロジック（MainScene.gd or Global.gd）

### set_story_flag() のフックで自動チェック（推奨）

`Global.gd` の `set_story_flag()` 末尾に追記することで、
フラグをセットするだけで実績チェックが走る。

```gdscript
func set_story_flag(flag_id: String, value: bool = true) -> void:
    story_flags[flag_id] = value
    _check_achievements_for_flag(flag_id)   # ← 追加

func _check_achievements_for_flag(flag_id: String) -> void:
    for id in AchievementDatabase.ACHIEVEMENTS:
        var def = AchievementDatabase.ACHIEVEMENTS[id]
        if def["trigger"] == "story_flag" and def["key"] == flag_id:
            if story_flags.get(flag_id, false):
                unlock_achievement(id)
```

### パラメータ閾値トリガー

感情値が変化した後（MainScene.gd の変化処理の直後）に呼ぶ。

```gdscript
func _check_achievements_for_params() -> void:
    for id in AchievementDatabase.ACHIEVEMENTS:
        var def = AchievementDatabase.ACHIEVEMENTS[id]
        if def["trigger"] == "threshold":
            var current = global.get(def["param"])
            if current >= def["value"]:
                global.unlock_achievement(id)
```

---

## AchievementPopup シーン

### シーン構成

```
AchievementPopup (CanvasLayer, layer=10)
└── PopupContainer (Control, アンカー: 右下)
    ├── AnimationPlayer
    ├── PanelContainer ("achievement_panel")
    │   ├── HBoxContainer
    │   │   ├── IconRect (TextureRect or Control)  ← アイコン
    │   │   └── VBoxContainer
    │   │       ├── TitleLabel ("実績解除！")
    │   │       └── NameLabel  (実績名)
```

### スクリプト概要（AchievementPopup.gd）

```gdscript
extends CanvasLayer

var _queue: Array = []
var _showing: bool = false

func _ready():
    Global.achievement_unlocked.connect(_on_achievement_unlocked)
    $PopupContainer.modulate.a = 0.0

func _on_achievement_unlocked(id: String) -> void:
    _queue.append(id)
    if not _showing:
        _show_next()

func _show_next() -> void:
    if _queue.is_empty():
        _showing = false
        return
    _showing = true
    var id: String = _queue.pop_front()
    var def = AchievementDatabase.ACHIEVEMENTS[id]
    $PopupContainer/PanelContainer/HBoxContainer/VBoxContainer/NameLabel.text = def["name"]
    # アニメーション: フェードイン → 2秒待機 → フェードアウト → _show_next()
    $AnimationPlayer.play("show")
```

### アニメーション仕様（AnimationPlayer）

| キー名 | 内容                                        |
|--------|---------------------------------------------|
| `show` | 0秒: alpha=0, 0.3秒: alpha=1, 2.3秒: alpha=1, 2.6秒: alpha=0 → `_show_next()` |

---

## 本棚インタラクト → 実績一覧パネル

### 自室ステージ（myroom）への追加

`StageBuilder.gd` の `myroom` ステージ定義に本棚ホットスポットを追加：

```gdscript
# stage_data["myroom"]["hotspots"] に追加
{
    "id": "bookshelf",
    "label": "本棚を調べる",
    "action": "open_achievements",
    "x_ratio": 0.15,   # ステージ左寄りに配置（要調整）
}
```

`MainScene.gd` のホットスポット処理に追記：

```gdscript
"open_achievements":
    global.set_story_flag("bookshelf_checked")   # 実績トリガー兼用
    _show_achievement_viewer()
```

---

## AchievementViewer パネル

### シーン構成

既存の `history_panel` と同構造で作成する。

```
AchievementViewer (Control, 全画面オーバーレイ)
├── PanelContainer
│   ├── VBoxContainer
│   │   ├── TitleLabel ("実績一覧")
│   │   ├── ScrollContainer
│   │   │   └── GridContainer (columns=2, AchievementCard × N)
│   │   └── CloseButton
```

### 表示ロジック（AchievementViewer.gd）

```gdscript
func refresh() -> void:
    for child in $Grid.get_children():
        child.queue_free()

    for id in AchievementDatabase.ACHIEVEMENTS:
        var def = AchievementDatabase.ACHIEVEMENTS[id]
        var unlocked: bool = id in Global.achievements_unlocked

        var card = AchievementCard.new()
        if unlocked:
            card.setup(def["icon"], def["name"], def["desc"])
        elif def["hidden"]:
            card.setup("question", "???", "???")          # hidden = 完全非表示
        else:
            card.setup("question", def["name"], "未解除")  # 存在は見せる
        $Grid.add_child(card)
```

---

## 実装ステップ（推奨順）

1. **Global.gd** に `achievements_unlocked`, `unlock_achievement()`, `achievement_unlocked` シグナル追加
2. **AchievementDatabase.gd** 新規作成、実績定義を記述
3. **Global.gd** の `set_story_flag()` に `_check_achievements_for_flag()` フック追加
4. **AchievementPopup** シーン + スクリプト作成、MainScene に CanvasLayer として追加
5. **StageBuilder.gd** の `myroom` に `bookshelf` ホットスポット追加
6. **MainScene.gd** に `open_achievements` アクション + `_show_achievement_viewer()` 追加
7. **AchievementViewer** シーン + スクリプト作成
8. セーブ/ロードへの `achievements_unlocked` 永続化追加

---

## 未決事項・検討ポイント

- アイコンは TextureRect（画像）か GDScript 描画か → 最初は Label で絵文字で代替も可
- 実績の総数・内容はユーザと別途詰める
- hidden 実績の「存在を完全に隠す」か「???で示す」かはユーザの好み次第
- ポップアップ表示中に別の実績が解除された場合はキューで順次表示
