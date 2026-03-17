# 実績システム 設計書

更新日: 2026-03-17

> 目次
> - [実績システム](#実績システム-設計書)
> - [地図ファストトラベル](#地図ファストトラベル-設計書)

---

## 概要

ゲーム内のイベント・選択・行動に紐づく「実績」を管理するシステム。
- イベントフラグ成立時に **右下ポップアップ** で即時通知
- 自室の本棚をインタラクトすると **実績一覧パネル** を表示
- 未解除の実績は「名前は見える・説明は???」でネタバレを防ぐ
- hidden 実績は「名前は見える・説明は???」で存在を示しつつネタバレを防ぐ

---

## アーキテクチャ概観

```
[Global.gd]
  achievements_unlocked: Array   ← 解除済みIDリスト（セーブ対象）

[AchievementDatabase.gd]（新規）
  const ACHIEVEMENTS: Dictionary ← 全実績の定義

[Global.gd の set_story_flag() / advance_term() / 感情変化処理]
  → _check_achievements_for_flag(flag_id)
  → _check_achievements_for_params()
  → _check_achievements_for_phase(story_id)
  → _check_achievements_for_age()

[AchievementPopup] シーン（新規）
  MainScene に CanvasLayer として常駐
  解除キューを処理し、右下でアニメーション表示

[AchievementViewer] パネル（新規）
  自室の本棚インタラクト → MainScene が表示
```

---

## データ定義（AchievementDatabase.gd）

### トリガー種別一覧

| trigger 値       | チェック対象                                   |
|-----------------|-----------------------------------------------|
| `story_flag`    | `Global.story_flags[key] == true`             |
| `experienced`   | `Global.experienced_events.has(key)`          |
| `bool_var`      | `Global.get(key) == true`                     |
| `threshold`     | `Global.get(param) >= value`                  |
| `story_phase`   | `Global.get_story_phase(story_id) >= phase`   |
| `age`           | `Global.age >= value`                         |

### 実績定義全リスト

```gdscript
# godot-project/scripts/AchievementDatabase.gd
extends Node

const ACHIEVEMENTS: Dictionary = {

    # ===== 身長マイルストーン =====
    "height_180": {
        "name":     "180cmの壁",
        "desc":     "身長が180cmを超えた。",
        "icon":     "ruler",
        "hidden":   false,
        "trigger":  "threshold",
        "param":    "height",
        "value":    180,
    },
    "height_200": {
        "name":     "200cmの扉",
        "desc":     "身長が200cmを超えた。",
        "icon":     "ruler",
        "hidden":   false,
        "trigger":  "threshold",
        "param":    "height",
        "value":    200,
    },
    "height_230": {
        "name":     "空に近い場所",
        "desc":     "身長が230cmを超えた。",
        "icon":     "ruler",
        "hidden":   false,
        "trigger":  "threshold",
        "param":    "height",
        "value":    230,
    },
    "height_250": {
        "name":     "250cmの景色",
        "desc":     "身長が250cmを超えた。",
        "icon":     "ruler",
        "hidden":   false,
        "trigger":  "threshold",
        "param":    "height",
        "value":    250,
    },
    "height_270": {
        "name":     "270cm、人外の領域",
        "desc":     "身長が270cmを超えた。",
        "icon":     "ruler",
        "hidden":   false,
        "trigger":  "threshold",
        "param":    "height",
        "value":    270,
    },
    "height_300": {
        "name":     "3メートル",
        "desc":     "身長が300cmを超えた。",
        "icon":     "ruler",
        "hidden":   false,
        "trigger":  "threshold",
        "param":    "height",
        "value":    300,
    },

    # ===== 学年マイルストーン =====
    "entrance_elem": {
        "name":     "小学生になった",
        "desc":     "小学校の入学式を迎えた。",
        "icon":     "school",
        "hidden":   false,
        "trigger":  "age",
        "value":    6,
    },
    "elem_grade4": {
        "name":     "もう高学年",
        "desc":     "小学4年生まで成長した。",
        "icon":     "school",
        "hidden":   false,
        "trigger":  "age",
        "value":    9,
    },
    "entrance_middle": {
        "name":     "中学生になった",
        "desc":     "中学校の入学式を迎えた。",
        "icon":     "school",
        "hidden":   false,
        "trigger":  "age",
        "value":    12,
    },
    "entrance_high": {
        "name":     "高校生になった",
        "desc":     "高校の入学式を迎えた。",
        "icon":     "school",
        "hidden":   false,
        "trigger":  "age",
        "value":    15,
    },

    # ===== 成長イベント =====
    "growth_spurt": {
        "name":     "成長期",
        "desc":     "急に背が伸びた。",
        "icon":     "arrow_up",
        "hidden":   false,
        "trigger":  "experienced",
        "key":      "growth_spurt",
    },
    "summer_growth": {
        "name":     "夏休みの成長",
        "desc":     "夏休みの間に大きく伸びた。",
        "icon":     "arrow_up",
        "hidden":   false,
        "trigger":  "experienced",
        "key":      "summer_growth",
    },
    "vball_pain": {
        "name":     "成長痛",
        "desc":     "バレー部の練習中、脚が痛み始めた。",
        "icon":     "heart",
        "hidden":   false,
        "trigger":  "story_phase",
        "story_id": "vball_story",
        "phase":    3,
    },

    # ===== 出会い =====
    "meet_haruka": {
        "name":     "はるかとの出会い",
        "desc":     "クラスメートのはるかに声をかけてもらった。",
        "icon":     "heart",
        "hidden":   false,
        "trigger":  "story_flag",
        "key":      "met_haruka",
    },
    "meet_senior": {
        "name":     "先輩との出会い",
        "desc":     "廊下でバレー部の先輩に声をかけられた。",
        "icon":     "volleyball",
        "hidden":   false,
        "trigger":  "story_phase",
        "story_id": "vball_story",
        "phase":    1,
    },

    # ===== バレー部ルート =====
    "join_volleyball": {
        "name":     "ネットの向こうへ",
        "desc":     "バレー部に参加した。",
        "icon":     "volleyball",
        "hidden":   false,
        "trigger":  "bool_var",
        "key":      "vball_joined",
    },
    "vball_pain_tell": {
        "name":     "正直に話せた",
        "desc":     "脚の痛みを先輩に打ち明けた。",
        "icon":     "heart",
        "hidden":   false,
        "trigger":  "story_phase",
        "story_id": "vball_story",
        "phase":    4,
    },
    "vball_return": {
        "name":     "もう一度コートへ",
        "desc":     "夏休み後にバレー部に復帰した。",
        "icon":     "volleyball",
        "hidden":   false,
        "trigger":  "story_flag",
        "key":      "vball_returned",
    },
    "vball_retire": {
        "name":     "幕を引く",
        "desc":     "バレー部を引退した。",
        "icon":     "volleyball",
        "hidden":   true,
        "trigger":  "story_flag",
        "key":      "vball_retired",
    },

    # ===== 日常のできごと =====
    "bookshelf_found": {
        "name":     "本の虫",
        "desc":     "自室の本棚を調べた。",
        "icon":     "book",
        "hidden":   false,
        "trigger":  "story_flag",
        "key":      "bookshelf_checked",
    },
    "mirror_check": {
        "name":     "今日の自分",
        "desc":     "洗面台の鏡で自分の姿を確認した。",
        "icon":     "star",
        "hidden":   false,
        "trigger":  "story_flag",
        "key":      "home_mirror_checked",
    },
    "station_bench": {
        "name":     "駅のベンチ",
        "desc":     "駅のベンチでひと息ついた。",
        "icon":     "star",
        "hidden":   false,
        "trigger":  "story_flag",
        "key":      "station_bench_rested",
    },
    "basket_reach": {
        "name":     "バスケットゴール",
        "desc":     "バスケットゴールに手が届いた。",
        "icon":     "star",
        "hidden":   false,
        "trigger":  "story_flag",
        "key":      "basket_reached",
    },
    "randoseru_farewell": {
        "name":     "ランドセルとの別れ",
        "desc":     "もう入らないランドセルを見つめた。",
        "icon":     "book",
        "hidden":   false,
        "trigger":  "story_flag",
        "key":      "randoseru_farewell_done",
    },
    "elem_tease": {
        "name":     "ひやかし",
        "desc":     "男子に「背高くない？」とからかわれた。",
        "icon":     "heart",
        "hidden":   false,
        "trigger":  "story_flag",
        "key":      "elem_tease_seen",
    },
    "middle_boys_growth": {
        "name":     "俺、5cm伸びた",
        "desc":     "廊下で男子の成長自慢を聞いた。",
        "icon":     "arrow_up",
        "hidden":   false,
        "trigger":  "experienced",
        "key":      "middle_boys_growth_talk",
    },
    "high_scout": {
        "name":     "スカウト",
        "desc":     "スポーツクラブから勧誘を受けた。",
        "icon":     "star",
        "hidden":   false,
        "trigger":  "experienced",
        "key":      "high_scout_contact",
    },

    # ===== 感情・自己認識 =====
    "confidence_high": {
        "name":     "自分らしく",
        "desc":     "背の高さを前向きに受け入れてきた。",
        "icon":     "star",
        "hidden":   false,
        "trigger":  "threshold",
        "param":    "self_confidence",
        "value":    10,
    },
    "haruka_open": {
        "name":     "打ち明けられた",
        "desc":     "はるかにしんどさを正直に話せた。",
        "icon":     "heart",
        "hidden":   false,
        "trigger":  "story_flag",
        "key":      "haruka_confided",
    },
    "infirmary_open": {
        "name":     "保健室で話した",
        "desc":     "保健室の先生に正直に打ち明けた。",
        "icon":     "heart",
        "hidden":   false,
        "trigger":  "story_flag",
        "key":      "infirmary_opened",
    },
}
```

---

## Global.gd への追加

```gdscript
# --- 実績 ---
var achievements_unlocked: Array = []

signal achievement_unlocked(id: String)

func unlock_achievement(id: String) -> bool:
    if id in achievements_unlocked:
        return false
    achievements_unlocked.append(id)
    emit_signal("achievement_unlocked", id)
    return true

# story_flag セット時のフック
func set_story_flag(flag_id: String, value: bool = true) -> void:
    story_flags[flag_id] = value
    if value:
        _check_achievements_for_flag(flag_id)

func _check_achievements_for_flag(flag_id: String) -> void:
    for id in AchievementDatabase.ACHIEVEMENTS:
        var def = AchievementDatabase.ACHIEVEMENTS[id]
        if def["trigger"] == "story_flag" and def["key"] == flag_id:
            unlock_achievement(id)

# bool変数チェック（vball_joined など）
func _check_achievements_for_bool(key: String) -> void:
    for id in AchievementDatabase.ACHIEVEMENTS:
        var def = AchievementDatabase.ACHIEVEMENTS[id]
        if def["trigger"] == "bool_var" and def["key"] == key:
            if get(key) == true:
                unlock_achievement(id)

# 数値閾値チェック（身長・感情値）
func _check_achievements_for_params() -> void:
    for id in AchievementDatabase.ACHIEVEMENTS:
        var def = AchievementDatabase.ACHIEVEMENTS[id]
        if def["trigger"] == "threshold":
            var current = get(def["param"])
            if current >= def["value"]:
                unlock_achievement(id)

# ストーリーフェーズチェック
func _check_achievements_for_phase(story_id: String) -> void:
    var current_phase = get_story_phase(story_id)
    for id in AchievementDatabase.ACHIEVEMENTS:
        var def = AchievementDatabase.ACHIEVEMENTS[id]
        if def["trigger"] == "story_phase" and def["story_id"] == story_id:
            if current_phase >= def["phase"]:
                unlock_achievement(id)

# 年齢チェック（advance_term() 後に呼ぶ）
func _check_achievements_for_age() -> void:
    for id in AchievementDatabase.ACHIEVEMENTS:
        var def = AchievementDatabase.ACHIEVEMENTS[id]
        if def["trigger"] == "age":
            if age >= def["value"]:
                unlock_achievement(id)

# experienced_events チェック（record_event() 後に呼ぶ）
func _check_achievements_for_event(event_id: String) -> void:
    for id in AchievementDatabase.ACHIEVEMENTS:
        var def = AchievementDatabase.ACHIEVEMENTS[id]
        if def["trigger"] == "experienced" and def["key"] == event_id:
            unlock_achievement(id)
```

### セーブ/ロードへの追記

```gdscript
# save_slot() 内
cfg.set_value("progress", "achievements_unlocked", achievements_unlocked)

# load_slot() 内
achievements_unlocked = cfg.get_value("progress", "achievements_unlocked", [])
```

### 既存処理への呼び出し追加

| 呼び出し元 | タイミング | 呼ぶ関数 |
|---|---|---|
| `advance_term()` | age 更新後 | `_check_achievements_for_age()` |
| `advance_term()` | 身長更新後 | `_check_achievements_for_params()` |
| `record_event(event_id)` | 末尾 | `_check_achievements_for_event(event_id)` |
| `set_story_phase()` | 末尾 | `_check_achievements_for_phase(story_id)` |
| MainScene.gd: `vball_join` action | 後 | `global._check_achievements_for_bool("vball_joined")` |
| MainScene.gd: 感情値変化後 | 後 | `global._check_achievements_for_params()` |

---

## AchievementPopup シーン（新規）

### シーン構成

```
AchievementPopup (CanvasLayer, layer=10)
└── PopupContainer (Control, アンカー: 右下, margin: 16px)
    ├── AnimationPlayer
    └── PanelContainer
        └── HBoxContainer (separation=8)
            ├── IconLabel (Label, 24x24 相当)
            └── VBoxContainer
                ├── TitleLabel ("実績解除！" 小文字)
                └── NameLabel  (実績名)
```

### スクリプト（AchievementPopup.gd）

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
    $AnimationPlayer.play("show")

# AnimationPlayer の "show" アニメーション終了時に呼ぶ
func _on_animation_finished(_anim_name: String) -> void:
    _show_next()
```

### アニメーション（AnimationPlayer "show"）

| 時刻 | alpha |
|------|-------|
| 0.0s | 0.0（非表示） |
| 0.3s | 1.0（フェードイン完了） |
| 2.3s | 1.0（表示維持） |
| 2.6s | 0.0（フェードアウト完了 → `_on_animation_finished`） |

---

## 本棚インタラクト → AchievementViewer

### StageBuilder.gd の myroom ホットスポットに追加

```gdscript
{
    "id":      "bookshelf",
    "label":   "本棚を調べる",
    "action":  "open_achievements",
    "x_ratio": 0.15,   # 要調整
}
```

### MainScene.gd のホットスポット処理に追加

```gdscript
"open_achievements":
    global.set_story_flag("bookshelf_checked")
    _show_achievement_viewer()
```

---

## AchievementViewer パネル（新規）

### 表示ルール

| 状態          | name 表示 | desc 表示 |
|--------------|-----------|-----------|
| 解除済み      | 実名       | 本文       |
| 未解除        | 実名       | ???       |
| hidden かつ未解除 | 実名  | ???       |

### スクリプト概要（AchievementViewer.gd）

```gdscript
func refresh() -> void:
    for child in $Grid.get_children():
        child.queue_free()
    for id in AchievementDatabase.ACHIEVEMENTS:
        var def = AchievementDatabase.ACHIEVEMENTS[id]
        var unlocked: bool = id in Global.achievements_unlocked
        var card = AchievementCard.instantiate()
        var show_desc = def["desc"] if unlocked else "???"
        card.setup(def["icon"], def["name"], show_desc, unlocked)
        $Grid.add_child(card)
```

---

## 実装ステップ（推奨順）

1. **AchievementDatabase.gd** 新規作成（実績定義）
2. **Global.gd** に `achievements_unlocked`・シグナル・チェック関数群追加
3. **Global.gd** の既存処理（`set_story_flag`, `record_event`, `advance_term`, `set_story_phase`）に呼び出し追加
4. **AchievementPopup** シーン + スクリプト作成、MainScene に CanvasLayer として追加
5. **StageBuilder.gd** の `myroom` に `bookshelf` ホットスポット追加
6. **MainScene.gd** に `open_achievements` アクション + `_show_achievement_viewer()` 追加
7. **AchievementViewer** シーン + スクリプト作成
8. セーブ/ロードに `achievements_unlocked` 追加

---

## 未決事項

- アイコンの実装方法（絵文字 Label / 独自描画 / 画像）
- 実績の並び順（カテゴリ別 or 解除順 or 定義順）
- 実績総数が増えた際のスクロール対応（ScrollContainer で対応済み想定）

---

---

# 地図ファストトラベル 設計書

更新日: 2026-03-17

---

## 概要

現在のボタンリスト型ファストトラベル（`pause_fast_travel_panel: VBoxContainer`）を、エリアマップ型UIに刷新する。

- エリア（区）ごとに背景パネルで視覚的にグループ化
- 場所（ノード）をクリックするとそのステージへ移動
- ノード間を線で接続して「地理的なつながり」を表現
- 現在の年齢で行けない場所はグレーアウト（disabled）表示するが、ノードは常に表示する
- 学校は年齢解決済みID（`school_elementary` / `school_middle` / `school_high`）を直接使用し、全て地図上に表示

---

## マップ構成

### エリア・ノード・エッジ定義

```
┌────────────────────────────────────────────────────────┐
│  中央町                                                 │
│   ○ 自宅                                               │
│      │                                                 │
│   ○ 中央駅 ──────────────────────────── ○ 学園前駅    │  学園町
│      │                                                 │
│   ○ 小学校                                             │
└────────────────────────────────────────────────────────┘
       │
    ○ 中学校   ← 隣町
```

### エリア定義（MAP_AREAS）

| id | 名称 | 含むノード |
|---|---|---|
| `chuo` | 中央町 | 自宅、中央駅、小学校 |
| `tonari` | 隣町 | 中学校 |
| `gakuen` | 学園町 | 学園前駅 |

### ノード定義（MAP_NODES）

| ノードID | ラベル | stage_id | エリア |
|---|---|---|---|
| `myroom` | 自宅 | `myroom` | chuo |
| `station` | 中央駅 | `station` | chuo |
| `school_elementary` | 小学校 | `school_elementary` | chuo |
| `school_middle` | 中学校 | `school_middle` | tonari |
| `gakuenmae` | 学園前駅 | `gakuenmae` | gakuen |

### エッジ定義（MAP_EDGES）

```
myroom ─── station
station ─── school_elementary
station ─── school_middle
station ─── gakuenmae
```

---

## データ定数（MapTravelPanel.gd 内）

```gdscript
const MAP_AREAS: Array[Dictionary] = [
    {
        "id":    "chuo",
        "name":  "中央町",
        "color": Color(0.82, 0.91, 1.0, 0.45),
        "rect":  Rect2(20, 40, 360, 340),
    },
    {
        "id":    "tonari",
        "name":  "隣町",
        "color": Color(0.82, 1.0, 0.84, 0.45),
        "rect":  Rect2(20, 410, 200, 110),
    },
    {
        "id":    "gakuen",
        "name":  "学園町",
        "color": Color(1.0, 0.92, 0.82, 0.45),
        "rect":  Rect2(410, 40, 210, 110),
    },
]

const MAP_NODES: Dictionary = {
    "myroom": {
        "label":    "自宅",
        "stage_id": "myroom",
        "pos":      Vector2(130, 130),
    },
    "station": {
        "label":    "中央駅",
        "stage_id": "station",
        "pos":      Vector2(200, 240),
    },
    "school_elementary": {
        "label":    "小学校",
        "stage_id": "school_elementary",
        "pos":      Vector2(90, 330),
    },
    "school_middle": {
        "label":    "中学校",
        "stage_id": "school_middle",
        "pos":      Vector2(110, 455),
    },
    "gakuenmae": {
        "label":    "学園前駅",
        "stage_id": "gakuenmae",
        "pos":      Vector2(480, 100),
    },
}

const MAP_EDGES: Array = [
    ["myroom",            "station"],
    ["station",           "school_elementary"],
    ["station",           "school_middle"],
    ["station",           "gakuenmae"],
]
```

---

## シーン構成

```
MapTravelPanel (Control, サイズ 640×560)
├── TitleLabel       (Label  "── 地図 ──")
├── CurrentLabel     (Label  "現在地: ○○")
├── MapCanvas        (Control, サイズ 640×520)
│    ├── _draw() でエリア背景・エッジ線・ノード円を描画
│    └── [動的生成] MapNodeButton (Button 透明, 40×40) × ノード数
│         └── NodeLabel (Label ノード名)
└── CloseButton      (Button "閉じる")
```

- `MapCanvas` が描画とクリック判定を担う
- `MapNodeButton` はノード位置に中心を合わせて配置（40×40 の透明ボタン）
- `NodeLabel` はボタン下部に配置

---

## スクリプト概要（MapTravelPanel.gd）

```gdscript
extends Control

signal travel_requested(stage_id: String)

const NODE_RADIUS  := 14.0
const EDGE_COLOR   := Color(0.5, 0.5, 0.6, 0.8)
const EDGE_WIDTH   := 2.0
const NODE_DEFAULT := Color(0.3, 0.55, 0.9)
const NODE_CURRENT := Color(0.2, 0.75, 0.3)   # 現在地
const NODE_LOCKED  := Color(0.55, 0.55, 0.55)  # disabled

func _ready() -> void:
    _build_map()

func _build_map() -> void:
    # 既存の MapNodeButton を削除して再生成
    for child in $MapCanvas.get_children():
        child.queue_free()
    $MapCanvas.queue_redraw()

    var global = get_node_or_null("/root/Global")
    for node_id in MAP_NODES:
        var def      := MAP_NODES[node_id]
        var stage_id: String = def["stage_id"]
        var locked: bool = _is_locked(stage_id, global)
        var current: bool = (global and global.current_stage_id == stage_id)

        var btn := Button.new()
        btn.custom_minimum_size = Vector2(40, 40)
        btn.position = def["pos"] - Vector2(20, 20)
        btn.flat = true
        btn.disabled = locked or current
        if not btn.disabled:
            btn.pressed.connect(_on_node_pressed.bind(stage_id))

        var lbl := Label.new()
        lbl.text = def["label"]
        lbl.position = Vector2(0, 32)
        btn.add_child(lbl)

        $MapCanvas.add_child(btn)

# MapCanvas の _draw() に相当する処理を MapCanvas 側に委譲するか、
# このスクリプトで MapCanvas の draw_* を使う（draw_* は _draw() 内限定のため
# MapCanvas を extends Control したスクリプトに分離するのが実践的）
```

### _draw() で描画する内容

1. **エリア背景**：`MAP_AREAS` の `rect` を角丸矩形で塗りつぶし、名前ラベルを左上に描画
2. **エッジ線**：`MAP_EDGES` のペアのノード `pos` 間を `EDGE_COLOR` で直線描画
3. **ノード円**：各ノードの `pos` に半径 `NODE_RADIUS` の円を描画
   - 現在地 → `NODE_CURRENT`（緑）
   - disabled → `NODE_LOCKED`（グレー）
   - 通常 → `NODE_DEFAULT`（青）

### ロック判定

既存の `MainScene._get_stage_lock_message()` のロジックを流用する。
戻り値が空文字列でなければ `locked = true`。

```gdscript
func _is_locked(stage_id: String, global) -> bool:
    # _get_stage_lock_message() と同じロジックを MapTravelPanel 内に複製 or 共通化
    if not global:
        return false
    var age: int = int(global.age)
    match stage_id:
        "school_elementary":
            return age > 11
        "school_middle":
            return age < 12 or age > 14
        "school_high":
            return age < 15
    return false
```

> ロジック重複を避けるため、将来的には `StageBuilder` か `Global` に `is_stage_locked(stage_id, age)` 関数として切り出すことを推奨。

---

## 既存コードとの統合

### MainScene.gd の変更点

| 変更箇所 | 内容 |
|---|---|
| `pause_fast_travel_panel: VBoxContainer` | `MapTravelPanel` のインスタンスに置き換え |
| `_rebuild_fast_travel_panel()` | `_build_map()` 呼び出しに変更 |
| `FAST_TRAVEL_STAGES` 定数 | `MapTravelPanel.MAP_NODES` に移動（MainScene 側は不要に） |
| `_on_fast_travel_pressed()` | `MapTravelPanel.travel_requested` シグナルを受け取る形に変更 |

### 変更しない既存処理

- `_get_stage_lock_message()` — MapTravelPanel 側でロジックを参照（当面は複製）
- `_load_stage()` — そのまま利用
- `_toggle_pause()` — 移動時に呼び出す

---

## 実装ステップ（推奨順）

1. `MapCanvas.gd`（extends Control）を新規作成 — `_draw()` でエリア・エッジ・ノードを描画
2. `MapTravelPanel.gd` を新規作成 — データ定数、ボタン動的生成、`travel_requested` シグナル
3. `MapTravelPanel.tscn` を新規作成（構成は上記シーン構成に従う）
4. `MainScene.gd` の `pause_fast_travel_panel` を `MapTravelPanel` に差し替え
5. `MainScene.gd` の `_rebuild_fast_travel_panel()` → `map_panel._build_map()` 呼び出しに変更
6. `travel_requested` シグナルを `_on_fast_travel_pressed` と接続して移動処理を再利用
7. 動作確認・ポーズメニューのレイアウト調整

---

## 未決事項

- マップキャンバスの最終サイズ（ポーズメニュー全体のレイアウト次第）
- ノードアイコン（絵文字 Label / 独自描画 / 画像）
- 高校・その他施設ノードの追加タイミングと配置
- エッジ線の形状（直線 / 折れ線 / カーブ）
- ロックノードのツールチップ（理由文の表示方法）
