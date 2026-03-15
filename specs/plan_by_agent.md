# plan_by_agent.md — AIエージェントのメモ帳

更新日: 2026-03-15

---

## 残タスク

| 優先 | タスク | 規模 |
|---|---|---|
| ★★★ | ステージ追加・接続修正（ホーム・学園前・学園街・隣町） | 大 |
| ★★★ | ゲーム進行システム見直し（日単位ループ・就寝・スキップ） | 大 |

---

## ★★★ ステージ追加・接続修正

### 確定仕様（ユーザ確認済み）

| 学校 | 所在地 | アクセス方法 |
|---|---|---|
| 小学校 | outdoor（街）から徒歩 | `outdoor` → Eキー → `school_hallway_elementary` |
| 中学校 | 隣町 | `outdoor` の右端まで歩く → `adjacent_town` → Eキー → `school_hallway_middle` |
| 高校 | 学園街 | `outdoor` → 電車 → `gakuenmae` → `gakuenmachi` → Eキー → `school_hallway_high` |

### 注意: IDの命名規則

`school_area` は `StageBuilder.is_school_classroom_stage()` が `school_.begins_with()` で拾うため**学校内部扱いになる**。
学園街（屋外の商店街）には `gakuenmachi` を使う。

| ステージID | 名前 | 種別 |
|---|---|---|
| `platform` | ホーム（地元側） | 屋外 |
| `gakuenmae` | 学園前駅 | 屋外 |
| `gakuenmachi` | 学園街 | 屋外（`school_` 非プレフィックス） |
| `adjacent_town` | 隣町 | 屋外 |

### 現状の問題

| 場所 | 現在の接続（誤り） | 問題 |
|---|---|---|
| `train` | → `school_hallway_high` | 電車から直接高校に入れる（中間ステージがない） |
| `outdoor` | → `school_hallway_*`（年齢解決） | 中高生も屋外から直接学校に入れる |

### 修正後のステージ接続マップ

```
myroom ↔ room ↔ outdoor ─（右端歩き）─→ adjacent_town
                  ↕                              ↕（Eキー）
              station                   school_hallway_middle
                  ↕（Eキー）
              platform ← ホーム（新設）
                  ↕（Eキー）
               train ← 電車内
                  ↓（Eキー）
            gakuenmae ← 学園前駅（新設）
                  ↓（Eキー）
           gakuenmachi ← 学園街（新設）
                  ↓（Eキー）
        school_hallway_high ← 高校
```

**小学校**: `outdoor → school_hallway_elementary`（Eキー・変更なし）

**中学**: `outdoor` 右端まで歩く → `adjacent_town` → Eキー → `school_hallway_middle`

**高校**: `outdoor` → `station` → `platform` → `train` → `gakuenmae` → `gakuenmachi` → Eキー → `school_hallway_high`

### StageBuilder.gd の変更点

#### 既存接続の変更

```gdscript
# train のドア定義（変更前 → 変更後）
{"id": "door_to_school_hallway_high", ...}  # ← 削除
{"id": "door_to_platform",    ...}          # 地元側ホームへ戻る（左出口）
{"id": "door_to_gakuenmae",   ...}          # 学園前駅へ（右出口）

# station のドア定義（変更前 → 変更後）
{"id": "door_to_train",    ...}   # ← 変更
{"id": "door_to_platform", ...}   # platform が train の手前に入る

# outdoor のドア定義
{"id": "door_to_school_hallway_elementary", ...}  # 小学生のみ残す（変更なし）
# 中高生の学校ルートを担っていた door_to_school_hallway は不要
# 右端の StaticBody2D 壁 → 削除（edge-walk 遷移に差し替え）
```

#### `_school_hallway_obstacles()` の entry_door 修正（StageBuilder.gd L3067-3071）

廊下に入るためのドアが参照するステージIDが変わるため修正が必要。

```gdscript
# 変更前
var entry_door = "door_to_outdoor"
if suffix == "middle":
    entry_door = "door_to_station"
elif suffix == "high":
    entry_door = "door_to_train"

# 変更後
var entry_door = "door_to_outdoor"
if suffix == "middle":
    entry_door = "door_to_adjacent_town"  # 隣町から入学
elif suffix == "high":
    entry_door = "door_to_gakuenmachi"    # 学園街から入学
```

#### 新ステージの build_stage() 分岐追加

```gdscript
"platform":
    # ホーム（屋根・柱・線路・黄色い点字ブロック）
    # ドア: door_to_station（左）, door_to_train（右）

"gakuenmae":
    # 学園前駅ホーム（小さな屋外ホーム、看板「学園前」）
    # ドア: door_to_train（左）, door_to_gakuenmachi（右）

"gakuenmachi":
    # 学園街（商店街・掲示板・制服の高校生が行き交う）
    # ドア: door_to_gakuenmae（左）, door_to_school_hallway_high（右）
    # ※ school_ プレフィックスを持たないため屋外扱いのまま

"adjacent_town":
    # 隣町（outdoor の右隣、中学校の校門がある）
    # 右端の StaticBody2D 壁はそのまま（行き止まり）
    # ドア: door_to_school_hallway_middle（Eキー）
    # 左端: edge-walk で outdoor に戻る
```

#### `_get_stage_lock_message()` について

`school_hallway_middle` および `school_hallway_high` のロックは**既存コード（MainScene.gd L613-643）で対応済み**のため追加不要。
新ステージ `gakuenmachi` / `adjacent_town` はロックなし（年齢制限を設けない）。

### 隣町（adjacent_town）edge-walk 遷移の実装方針

**outdoor の右端**と**adjacent_town の左端**にそれぞれ Area2D を置き、
プレイヤーが踏み込んだら自動でステージ遷移する。

#### StageBuilder.gd 側

```gdscript
# outdoor ステージ: 右端の StaticBody2D 壁の代わりに RightEdgeTrigger を生成
var edge_area = Area2D.new()
edge_area.name = "RightEdgeTrigger"
edge_area.set_meta("target_stage", "adjacent_town")
var col = CollisionShape2D.new()
var rect = RectangleShape2D.new()
rect.size = Vector2(20, 2000)
col.position = Vector2(stage_width_px, -500)
col.shape = rect
edge_area.add_child(col)
parent_node.add_child(edge_area)

# adjacent_town の左端にも同様（target_stage = "outdoor"、名前 = "LeftEdgeTrigger"）
```

#### MainScene.gd 側

```gdscript
# _load_stage() 後に RightEdgeTrigger / LeftEdgeTrigger を走査しシグナル接続
func _enter_edge_transition(target_stage: String) -> void:
    Global.current_stage_id = target_stage
    Global.actions_today += 1
    _update_actions_hud()
    _load_stage()
```

### 各ステージのビジュアル・NPC配置

| ステージ | 背景イメージ | NPC |
|---|---|---|
| `platform` | 駅ホーム（屋根・柱・線路）、右端に電車ドア | 通勤客（汎用） |
| `gakuenmae` | 小さな無人ホーム、看板「学園前」 | 高校生（汎用） |
| `gakuenmachi` | 商店街・掲示板 | 高校生・店員（汎用） |
| `adjacent_town` | outdoor と地続きの街並み、中学校の校門 | 中学生・住民（汎用） |

---

## ★★★ ゲーム進行システム見直し

### 確定仕様（ユーザ確認済み）

- 測定パネルの [E] は「次の学期へ」ではなく**「閉じる」**に変更
- `advance_term()` は**学期末強制測定時のみ**呼ぶ（任意測定・パネル閉じでは呼ばない）

### 現状（as-is）のループ

```
1. myroom でスタート
2. 自由に移動（ほぼ学校一択）
3. 保健室の身長計に触れて E → 測定パネル
4. 「次の学期へ」ボタン → advance_term() → myroom へ
5. 1 に戻る
```

問題: 1ターン=1学期で単調。受動的イベントが少ない。測定が「作業」になっている。

### 目標（to-be）のループ

```
[朝] myroom でスタート (actions_today = 0)
    ↓
[行動] ステージ移動・NPC・ホットスポット探索
    各ステージ遷移で actions_today++
    ↓
[上限到達] actions_today >= max_actions_per_day になると
    バブル: 「もう夕方だ。今日を終えよう。」（ソフトリミット: 遷移は引き続き可能）
    ↓ ベッドに近づいて E
[就寝メニュー]
    ├── 「今日を終える」         → day_in_term++, 翌朝へ
    └── 「学期末まで一気に進める」→ day_in_term = term_total_days, 測定イベント発火
    ↓
[学期末] day_in_term >= term_total_days になったとき
    → 「身体測定の日です」強制イベント
    → advance_term()（成長）→ 測定パネル表示（Eキーで閉じる） → 新学期へ
```

### 新規変数（Global.gd に追加）

```gdscript
var day_in_term: int = 1           # 学期内の経過日数（1 スタート）
var actions_today: int = 0         # 今日の行動済み回数
var max_actions_per_day: int = 3   # 1日の最大行動回数
var term_total_days: int = 30      # 1学期の日数
```

セーブ/ロード対象に追加（**save_settings / load_settings の両方**に追加する）：

```gdscript
# save_settings() に追加
config.set_value("Player", "day_in_term",   day_in_term)
config.set_value("Player", "actions_today", actions_today)

# load_settings() に追加
day_in_term   = int(config.get_value("Player", "day_in_term",   1))
actions_today = int(config.get_value("Player", "actions_today", 0))
```

save_slot / load_slot にも同様に追加：

```gdscript
# save_slot()
data["day_in_term"]   = day_in_term
data["actions_today"] = actions_today

# load_slot()
day_in_term   = data.get("day_in_term", 1)
actions_today = data.get("actions_today", 0)
```

`advance_term()` に追加：

```gdscript
day_in_term = 1
actions_today = 0
```

### 就寝ホットスポット（myroom の bed）

`TERM_HOTSPOTS` には追加しない（何度でも使えるため）。専用処理を設ける。

```gdscript
func _trigger_bed_interaction() -> void:
    var opts = ["今日を終える"]
    if day_in_term < term_total_days - 2:
        opts.append("学期末まで一気に進める")
    _show_sleep_menu(opts)

func _on_sleep_menu_selected(choice: String) -> void:
    match choice:
        "今日を終える":
            Global.day_in_term += 1
            Global.actions_today = 0
            _do_fade_to_myroom()
            if Global.day_in_term >= Global.term_total_days:
                Global.queue_event("term_end_measurement")
        "学期末まで一気に進める":
            Global.day_in_term = Global.term_total_days
            Global.actions_today = 0
            _do_fade_to_myroom()
            Global.queue_event("term_end_measurement")
```

### 学期末強制測定（`term_end_measurement`）

`_load_stage()` のイベント処理に追加：

```gdscript
"term_end_measurement":
    Global.advance_term()   # ここで1回だけ成長させる
    _show_measurement_result()
    # 測定パネルは E キーで「閉じる」だけ（advance_term() は呼ばない）
```

`_on_next_term_pressed()` の変更（MainScene.gd L2437）：

```gdscript
# 変更前: advance_term() を呼んでいた
# 変更後: 測定パネルを閉じるだけ（advance_term() は term_end_measurement で済んでいる）
func _on_close_measurement_pressed() -> void:
    _hide_measurement_panel()
    Global.current_stage_id = "myroom"
    _load_stage()
```

`DialogueDatabase.gd` に追加：

```gdscript
"nurse": {
    "measurement_notice": [
        {"speaker": "保健の先生", "text": "そろそろ身体測定の時期ね。保健室においで。"},
    ]
}
```

### アクション消費（MainScene.gd）

`_enter_transition_door()` に追加：

```gdscript
Global.actions_today += 1
_update_actions_hud()
```

行動上限 UI（**ソフトリミット**: 上限到達後もバブルを出すだけで遷移は禁止しない）：

```gdscript
func _update_actions_hud() -> void:
    action_label.text = "行動 %d/%d" % [Global.actions_today, Global.max_actions_per_day]
    if Global.actions_today >= Global.max_actions_per_day:
        _show_player_bubble("もう夕方だ。今日を終えよう。")
```

### 保健室任意測定の扱い

現在の「身長計に触れてEキー」はそのまま残す（確認用）。

- **任意測定**: `advance_term()` を呼ばない → 現在の身長を表示するだけ（成長なし）
- **学期末強制測定**: `advance_term()` を先に呼んで成長させてからパネルを表示

成長は学期末のみ発生。

### 実装フェーズ

| Phase | 内容 |
|---|---|
| **1** | ステージ追加・接続修正 |
| **2** | `day_in_term` 変数 + 就寝ホットスポット + スキップ機能 |
| **3** | アクション制限 + 行動上限 HUD + 夜バブル演出 |

Phase 1・2 は独立して実装可能。Phase 3 は 2 の後。
