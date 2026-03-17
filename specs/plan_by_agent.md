# 実績システム 設計書

更新日: 2026-03-17

> 目次
> - [地図ファストトラベル](#地図ファストトラベル-設計書)

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
┌──────────────────────────┐    ┌──────────────────────┐
│  中央町                   │    │  学園町               │
│                           │    │  ○ 学園前駅          │
│  ○ 自宅                   │    └──────────┬───────────┘
│     │                     │               │
│  ○ 中央駅 ─────────────────┼───────────────┘
│     │                     │
│  ○ 小学校                 │
└────────────┬──────────────┘
             │
       ┌─────┴────────┐
       │  隣町         │
       │  ○ 中学校    │
       └──────────────┘
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
