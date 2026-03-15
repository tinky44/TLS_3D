# plan_by_agent.md — AIエージェントのメモ帳

更新日: 2026-03-15

---

## 残タスク（優先順）

| 優先 | タスク | 規模 |
|---|---|---|
| ★★★ | ステージ追加・接続修正（ホーム・学園前・学園街・隣町） | 大 |
| ★★★ | ゲーム進行システム見直し（日単位ループ・就寝・スキップ） | 大 |

> **既実装メモ**
> - `"chair_sit"` / `"taiiku_suwari"` ポーズ → `CharacterPoseCalculator.gd` 実装済み
> - NPC 頭上テキスト受動発話 → `SkeletalNPC.gd` 実装済み
> - `visited_stages` / `experienced_events` → `Global.gd` 実装済み

---

## ★★★ ステージ追加・接続修正

### 現状の問題

| 場所 | 現在の接続（誤り） | 問題 |
|---|---|---|
| `station` | → `train` | OK（駅→電車は正しい） |
| `train` | → `school_hallway_high` | 電車から直接高校に入れる（ホームがない） |
| `outdoor` | → `school_hallway_*`（年齢解決） | 中高生も屋外から直接学校に入れる |

### 追加するステージ一覧

| ステージID | 名前 | 説明 |
|---|---|---|
| `platform` | ホーム（地元側） | 地元の駅のホーム。`station` と `train` をつなぐ |
| `gakuenmae` | 学園前駅 | 学校側のホーム。`train` と `school_area` をつなぐ |
| `school_area` | 学園街 | 学校周辺の商店街。中高の学校へのエントランス |
| `adjacent_town` | 隣町 | 電車でさらに先の町。`train` の逆方向出口から |

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
# 変更前（train のドア定義）
{"id": "door_to_school_hallway_high", ...}   # ← 削除

# 変更後（train のドア定義）
{"id": "door_to_platform",    ...}   # 地元側に戻る
{"id": "door_to_gakuenmae",   ...}   # 学園前駅へ（右出口）
{"id": "door_to_adjacent_town", ...} # 隣町へ（電車の別方向出口・右端）
```

```gdscript
# 変更前（station のドア定義）
{"id": "door_to_train", ...}    # ← platform 経由に変更

# 変更後
{"id": "door_to_platform", ...} # ← ホームへ（platform が train の手前に入る）
```

```gdscript
# 変更前（outdoor のドア定義）
{"id": "door_to_school_hallway", ...}  # 中高生も直接入れた ← 削除

# 変更後: 中高生の school へのドアは school_area に移す
# outdoor は station のみに繋がる（中高生の学校ルートは電車経由）
```

#### 新ステージの build_stage() 分岐追加

`build_stage(stage_id)` の `match` 文に以下を追加：

```gdscript
"platform":
    # ホームの視覚的要素（屋根・柱・黄色い点字ブロック）
    # ドア: door_to_station（改札方向）, door_to_train（電車乗降口）

"gakuenmae":
    # 学園前駅ホーム（シンプルな屋外ホーム）
    # ドア: door_to_train, door_to_school_area

"school_area":
    # 学園街（自販機・NPC・掲示板など）
    # ドア: door_to_gakuenmae（駅方向）, door_to_school_hallway（学校）
    # school_hallway への接続は _resolve_stage_id() で suffix を付与

"adjacent_town":
    # 隣町（商店・見知らぬNPC）
    # ドア: door_to_train（帰る）
    # 高校生以降解放（_get_stage_lock_message() でアクセス制限）
```

#### `_get_stage_lock_message()` に追加

```gdscript
"adjacent_town":
    if global.age < 15:
        return "電車でもう少し先まで行くのは、高校生になってからにしよう。"
```

### 各ステージのビジュアル・NPC配置

| ステージ | 背景イメージ | 配置するNPC |
|---|---|---|
| `platform` | 駅ホーム（屋根・柱・線路）、電車ドアが右端 | 通勤客（汎用） |
| `gakuenmae` | 小さな無人ホーム風、看板「学園前」 | 生徒（汎用） |
| `school_area` | 商店街・掲示板・制服の生徒が行き交う | 生徒・店員（汎用） |
| `adjacent_town` | 知らない街並み、少し洗練された商店 | 見知らぬ大人（汎用） |

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
[朝] myroom でスタート (actions_today = 0, day表示リセット)
    ↓
[行動] ステージ移動・NPC・ホットスポット探索
    各ステージ遷移で actions_today++
    ↓
[夜] actions_today >= max_actions_per_day になると
    バブル: 「もう夕方だ。今日はどうする？」
    ↓ ベッドに近づいて E
[就寝メニュー]
    ├── 「今日を終える」　　　　 → day_in_term++, 翌朝へ
    └── 「学期末まで一気に進める」→ day_in_term = term_total_days, 測定イベント発火
    ↓
[学期末チェック] day_in_term >= term_total_days になったとき
    → 「身体測定の日です」強制イベント
    → 測定パネル表示（既存の演出を流用）
    → advance_term() → 新学期へ
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
data["day_in_term"]    = day_in_term
data["actions_today"]  = actions_today

# load_slot()
day_in_term   = data.get("day_in_term", 1)
actions_today = data.get("actions_today", 0)
```

`advance_term()` で以下を追加：

```gdscript
day_in_term = 1
actions_today = 0
```

### 就寝ホットスポット（myroom の bed）

`TERM_HOTSPOTS` に追加 **しない**（何度でも使えるため）。代わりに専用の処理を設ける。

`_trigger_bed_interaction()` を新規追加（MainScene.gd）：

```gdscript
func _trigger_bed_interaction() -> void:
    # 就寝メニューを表示
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
            # 学期末到達チェック
            if Global.day_in_term >= Global.term_total_days:
                Global.queue_event("term_end_measurement")
        "学期末まで一気に進める":
            Global.day_in_term = Global.term_total_days
            Global.actions_today = 0
            _do_fade_to_myroom()
            Global.queue_event("term_end_measurement")
```

### 学期末強制測定イベント（`term_end_measurement`）

`_load_stage()` のイベント処理に追加：

```gdscript
"term_end_measurement":
    if StageBuilder.resolve_stage_id("infirmary", Global.age) == Global.current_stage_id:
        # 保健室なら即発火
        _show_measurement_result()
    else:
        # 保健室以外なら誘導
        _start_dialogue("nurse", "measurement_notice")
        # dialogue 終了後に infirmary へ自動遷移
```

`DialogueDatabase.gd` に追加：

```gdscript
"nurse": {
    "measurement_notice": [
        {"speaker": "保健の先生", "text": "そろそろ身体測定の時期ね。保健室においで。"},
    ]
}
```

### アクション消費の実装（MainScene.gd）

`_enter_transition_door()` のステージ遷移時に追加：

```gdscript
func _enter_transition_door(door_id: String) -> void:
    ...
    # アクション消費
    Global.actions_today += 1
    _update_actions_hud()
    ...
```

行動上限 UI（HUD に追加）：

```gdscript
func _update_actions_hud() -> void:
    var remaining = Global.max_actions_per_day - Global.actions_today
    action_label.text = "行動 %d/%d" % [Global.actions_today, Global.max_actions_per_day]
    if remaining <= 0:
        # ベッドを強調 + バブル表示
        _show_player_bubble("もう夕方だ。今日を終えよう。")
```

### 実装フェーズ

| Phase | 内容 | 規模 |
|---|---|---|
| **1** | ステージ追加・接続修正（本セクション上部） | 大 |
| **2** | `day_in_term` 変数追加 + 就寝ホットスポット + スキップ機能 | 中 |
| **3** | アクション制限 + 行動上限 HUD + 夜バブル演出 | 中 |

Phase 1 と 2 は独立して実装可能。Phase 3 は 2 の後。

### 保健室任意測定の扱い

現在の「身長計に触れてEキー」は**そのまま残す**。
学期末より早く測りたい・確認したいプレイヤー向け。

- **任意測定**: `advance_term()` を呼ばない → 現在の身長をそのまま表示するだけ（学期中に身長が変わるのはおかしいため）
- **学期末強制測定** (`term_end_measurement`): `advance_term()` を呼んで**成長させてから**パネルを表示する → 成長はここでのみ発生

```gdscript
# term_end_measurement イベントの処理
"term_end_measurement":
    Global.advance_term()   # ← 先に成長させる
    _show_measurement_result()  # ← 成長後の身長を表示
```

---

## ★★★ セーブ/ロード非保存フラグ修正

`dialogue_trigger_spec.md:§11` 確認済み。再起動でフラグがリセットされ会話進行が壊れる。

### 前提確認（実装前に要確認）

- **スロットロード時** → `save_slot()` / `load_slot()` に追加すれば解決
- **アプリ再起動時** → 起動パスは `Global._ready() → load_settings()`。`settings.cfg` 側も整理が必要

両方対応するのが安全。

### 保存対象に追加する変数

| 変数 | 型 | 影響 |
|---|---|---|
| `met_npcs` | Dictionary | 初対面判定リセット → 毎回 `first_meet` 発火 |
| `haruka_invited_this_term` | bool | 計測誘導が毎起動で再発火 |
| `haruka_following` | bool | 計測後の追随挙動リセット |
| `senior_gym_invited` | bool | 体育館招待イベントが再発火 |
| `vball_story_phase` | int | バレー部ストーリーが最初から |
| `vball_joined` | bool | 入部状態リセット |
| `is_leg_pain` | bool | 脚痛フラグリセット |
| `pending_events` | Array | キュー済みイベント消失 |
| `visited_stages` | Dictionary | 初訪問判定リセット |
| `day_in_term` | int | 日数リセット |
| `actions_today` | int | 行動回数リセット |

```gdscript
# save_slot()
data["met_npcs"]                 = met_npcs
data["haruka_invited_this_term"] = haruka_invited_this_term
data["haruka_following"]         = haruka_following
data["senior_gym_invited"]       = senior_gym_invited
data["vball_story_phase"]        = vball_story_phase
data["vball_joined"]             = vball_joined
data["is_leg_pain"]              = is_leg_pain
data["pending_events"]           = pending_events.duplicate()
data["visited_stages"]           = visited_stages.duplicate()
data["day_in_term"]              = day_in_term
data["actions_today"]            = actions_today

# load_slot()
met_npcs                 = data.get("met_npcs", {})
haruka_invited_this_term = data.get("haruka_invited_this_term", false)
haruka_following         = data.get("haruka_following", false)
senior_gym_invited       = data.get("senior_gym_invited", false)
vball_story_phase        = data.get("vball_story_phase", 0)
vball_joined             = data.get("vball_joined", false)
is_leg_pain              = data.get("is_leg_pain", false)
pending_events           = data.get("pending_events", [])
visited_stages           = data.get("visited_stages", {})
day_in_term              = data.get("day_in_term", 1)
actions_today            = data.get("actions_today", 0)
```

---

## ★★☆ `current_term_plan` 削除 → 全ホットスポット常時解放

### 削除方針

- `term_home` / `term_station` イベント → デッドコード、削除
- `TERM_CHOICES` / `TERM_CHOICE_ORDER` → 丸ごと削除
- ホットスポット会話（`term_home_mirror`, `term_home_table` 等）→ `"plan"` キーを外すだけで再利用
- `current_term_plan` にぶら下がる表示文言・保存処理・スモーク初期化 → まとめて削除

### 削除・変更箇所（全ファイル）

**Global.gd:** `current_term_plan`, `DEFAULT_TERM_PLAN` を削除。`save_slot/load_slot/save_settings/load_settings` の保存処理も削除。

**MainScene.gd（参照11箇所）:**

| 行 | 処理 | 対応 |
|---|---|---|
| 675 | 初期化 `current_term_plan = DEFAULT_TERM_PLAN` | 削除 |
| 812,859 | `plan_id` でモノローグ・反省文取得 | 削除（`stress` 帯で代替） |
| 823 | `match current_term_plan` | 削除 |
| 882 | `TERM_HOTSPOTS` の `plan` フィルター | **この行を削除** |
| 1085,1102 | `plan == "school"` 判定 | ステージIDが教室かどうかで代替 |
| 1270 | はるかキー選択での `plan == "school"` 条件 | 同上 |
| 1827 | デバッグテキスト | 削除 |
| 2292,2293 | `TERM_CHOICES.get(plan)` | `TERM_CHOICES` ごと削除 |

**CharacterCreatorScene.gd / CodexSmokeRunner.gd:** それぞれの `current_term_plan` 初期化処理を削除。

---

## ★★☆ ホットスポットにポーズ変更を追加

### 設計

`TERM_HOTSPOTS` に `"pose"` フィールドを追加。`_trigger_term_hotspot()` でダイアログ前後にポーズを切り替える。

```gdscript
func _trigger_term_hotspot(hotspot_id: String) -> void:
    ...
    var pose_name: String = hotspot_data.get("pose", "")
    if pose_name != "" and player:
        player.pose = pose_name
    _start_dialogue(...)

func _end_dialogue() -> void:
    ...
    if player and player.pose != "normal":
        player.pose = "normal"
```

### ホットスポット別ポーズ

| ホットスポット | ポーズ | 備考 |
|---|---|---|
| `school_seat`, `home_table`, `station_bench` | `"chair_sit"` | 実装済みポーズ |
| `school_infirmary` | `"taiiku_suwari"` | 実装済みポーズ（代用） |
| `station_vending` | `"reach_low"` | **新規ポーズが必要** |
| `gymnasium_basket` | `"reach_up"` | **新規ポーズが必要** |

### 新規ポーズ（CharacterPoseCalculator.gd）

現行実装はローカル変数（`arm_r_angle` 等）を直接更新して返す構造。
**既存の `chair_sit` 分岐と同じ書き方**に合わせること（`d["key"] = ...` 形式ではない）。

- **`"reach_low"`**: 体直立、利き腕を斜め前下方（約-45度）に伸ばす。低いボタンに手を伸ばす違和感を表現。
- **`"reach_up"`**: 体直立、利き腕を真上（約+90度）に伸ばす。

### 新規ホットスポット候補

```gdscript
"station_vending": { "pose": "reach_low", "height_min": 0, "stage_id": "station", ... },
"gymnasium_basket": { "pose": "reach_up", "height_min": 185, "stage_id": "gymnasium", ... },
```

`"height_min"` 判定は `_trigger_term_hotspot()` で：

```gdscript
var height_min := float(hotspot_data.get("height_min", 0.0))
if height_min > 0.0 and Global.current_params["height"] < height_min:
    return
```

---

## ★★☆ NPC自動声かけ → 身長マイルストーンのみダイアログ格上げ

### 使い分け基準

| | 頭上テキスト（現状維持） | ダイアログパネル（今回追加） |
|---|---|---|
| 発火頻度 | 毎回近づくたびに | ゲーム全体で各1回のみ |
| ゲームへの介入 | 止まらない | 一時停止・Eキーで進める |
| ステータス変化 | なし | stress / confidence に影響 |
| 選択肢 | なし | あり |

**ダイアログ化するのは「身長マイルストーン初回突破」のみ**（170・180・190cm）。

### 実装上の注意点

**① `queue_event()` の位置**: `_load_stage()` は先に `pop_next_event()` を消化する。末尾で `queue_event()` すると次回のステージ遷移まで眠る。→ キュー投入は `pop_next_event()` より**前**に行う。

**② `is_first_visit()` の判定順**: `record_stage_visit()` を先に呼ぶと `is_first_visit()` が常に false になる。

```gdscript
var was_first_visit := Global.is_first_visit(stage_id)
Global.record_stage_visit(stage_id)
if was_first_visit:
    Global.queue_event("npc_firstvisit_" + stage_id)
```

**③ `StageBuilder.is_school_stage()` は存在しない**: 既存の `is_school_classroom_stage()` / `is_school_hallway_stage()` / `is_schoolyard_stage()` の OR で代替、または新規追加。

### トリガー条件

| イベントID | 条件 | ステージ |
|---|---|---|
| `"npc_talk_tall"` | 身長が初めて ≥ 170cm | 学校系 |
| `"npc_talk_huge"` | 身長が初めて ≥ 180cm | 駅・商店街等 |
| `"npc_talk_veryhuge"` | 身長が初めて ≥ 190cm | どこでも |
| `"npc_firstvisit_<stage_id>"` | ステージ初訪問 | ステージ固有 |

### 台詞（DialogueDatabase.gd に追加）

```gdscript
"npc_talk_tall": [
    {"speaker": "同級生", "text": "ねえ、バスケ部入ってるの？ 絶対向いてるって！"},
    {"speaker": "同級生", "text": "上の棚取ってくれる？", "action": "stress:-5"},
],
"npc_talk_huge": [
    {"speaker": "通行人", "text": "……モデルさんですか？"},
    {"speaker": "主人公", "text": "…（なんて答えればいいんだろう）",
     "choices": [
         {"label": "笑って「違います」と言う", "action": "confidence:+1"},
         {"label": "目をそらす",               "action": "stress:+5"},
     ]},
],
```

---

## ★★☆ 会話トーン改善

### DialogueDatabase.gd に追加

- `generic/tall`: 「背高いね。バスケ向いてそう！」「ちょっと棚の上の荷物取ってくれる？」
- `generic/huge`: 「モデルさんみたい！」「天井、頭届きそう？」
- `generic/default`: 「今日もすっきりしてるね。」

### SkeletalNPC.gd の受動発話テキストに追加

```gdscript
"school/tall":  ["一番後ろの席、ぴったりだね。", "掲示物、上まで見えていいな。"],
"station/huge": ["人波から頭ひとつ抜けてる！", "電車、立っても大丈夫？"],
```
