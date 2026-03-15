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

### 現状の問題

| 場所 | 現在の接続（誤り） | 問題 |
|---|---|---|
| `train` | → `school_hallway_high` | 電車から直接高校に入れる（ホームがない） |
| `outdoor` | → `school_hallway_*`（年齢解決） | 中高生も屋外から直接学校に入れる |

### 追加するステージ一覧

| ステージID | 名前 | 説明 |
|---|---|---|
| `platform` | ホーム（地元側） | 地元の駅のホーム。`station` と `train` をつなぐ |
| `gakuenmae` | 学園前駅 | 学校側のホーム。`train` と `school_area` をつなぐ |
| `school_area` | 学園街 | 学校周辺の商店街。中高の学校へのエントランス |
| `adjacent_town` | 隣町 | 電車でさらに先の町。`train` の別方向出口から |

### 修正後のステージ接続マップ

```
myroom ↔ room ↔ outdoor
                  ↕
              station ← 地元の駅
                  ↕
              platform ← ホーム（新設）
                  ↕
               train ← 電車内
              ↙       ↘
        gakuenmae    adjacent_town
（学園前駅・新設）       （隣町・新設）
            ↕
        school_area
       （学園街・新設）
            ↕
     school_hallway_* ← 年齢で suffix 解決
```

**小学校**: `outdoor → school_hallway_elementary` のまま変更なし（徒歩圏内）

**中学・高校**: `outdoor → station → platform → train → gakuenmae → school_area → school_hallway_middle/high`

### StageBuilder.gd の変更点

#### 既存接続の変更

```gdscript
# train のドア定義
# 変更前
{"id": "door_to_school_hallway_high", ...}   # ← 削除
# 変更後
{"id": "door_to_platform",      ...}   # 地元側に戻る
{"id": "door_to_gakuenmae",     ...}   # 学園前駅へ（右出口）
{"id": "door_to_adjacent_town", ...}   # 隣町へ（さらに右）

# station のドア定義
# 変更前
{"id": "door_to_train", ...}
# 変更後
{"id": "door_to_platform", ...}   # ホームへ（platform が train の手前に入る）

# outdoor のドア定義
{"id": "door_to_school_hallway", ...}  # 中高生分を削除
# 中高生の学校ルートは電車経由に。小学生分だけ残す
```

#### 新ステージの build_stage() 分岐追加

```gdscript
"platform":
    # ホーム（屋根・柱・線路・黄色い点字ブロック）
    # ドア: door_to_station, door_to_train

"gakuenmae":
    # 学園前駅ホーム（シンプルな屋外ホーム、看板「学園前」）
    # ドア: door_to_train, door_to_school_area

"school_area":
    # 学園街（自販機・掲示板・制服の生徒が行き交う）
    # ドア: door_to_gakuenmae, door_to_school_hallway（_resolve_stage_id() で suffix 付与）

"adjacent_town":
    # 隣町（見知らぬ大人・洗練された商店）
    # ドア: door_to_train（帰る）
    # 高校生以降解放
```

#### `_get_stage_lock_message()` に追加

```gdscript
"adjacent_town":
    if global.age < 15:
        return "電車でもう少し先まで行くのは、高校生になってからにしよう。"
```

### 各ステージのビジュアル・NPC配置

| ステージ | 背景イメージ | NPC |
|---|---|---|
| `platform` | 駅ホーム（屋根・柱・線路）、右端に電車ドア | 通勤客（汎用） |
| `gakuenmae` | 小さな無人ホーム、看板「学園前」 | 生徒（汎用） |
| `school_area` | 商店街・掲示板 | 生徒・店員（汎用） |
| `adjacent_town` | 知らない街並み | 見知らぬ大人（汎用） |

---

## ★★★ ゲーム進行システム見直し

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
[夜] actions_today >= max_actions_per_day になると
    バブル: 「もう夕方だ。今日はどうする？」
    ↓ ベッドに近づいて E
[就寝メニュー]
    ├── 「今日を終える」         → day_in_term++, 翌朝へ
    └── 「学期末まで一気に進める」→ day_in_term = term_total_days, 測定イベント発火
    ↓
[学期末] day_in_term >= term_total_days になったとき
    → 「身体測定の日です」強制イベント
    → advance_term()（成長）→ 測定パネル表示 → 新学期へ
```

### 新規変数（Global.gd に追加）

```gdscript
var day_in_term: int = 1           # 学期内の経過日数（1 スタート）
var actions_today: int = 0         # 今日の行動済み回数
var max_actions_per_day: int = 3   # 1日の最大行動回数
var term_total_days: int = 30      # 1学期の日数
```

セーブ/ロード対象に追加：

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
    Global.advance_term()   # 先に成長させる
    if StageBuilder.resolve_stage_id("infirmary", Global.age) == Global.current_stage_id:
        _show_measurement_result()
    else:
        _start_dialogue("nurse", "measurement_notice")
        # 会話終了後に infirmary へ自動遷移
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

行動上限 UI：

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
