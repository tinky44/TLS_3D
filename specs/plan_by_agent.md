# plan_by_agent.md — AIエージェントのメモ帳

更新日: 2026-03-15

---

## 残タスク（優先順）

| 優先 | タスク | 規模 |
|---|---|---|
| ★★★ | セーブ/ロード非保存フラグ修正 | 小〜中 |
| ★★☆ | `current_term_plan` 削除 → 全ホットスポット常時解放 | 中 |
| ★★☆ | ホットスポットにポーズ変更を追加（椅子・バスケゴール等） | 中 |
| ★★☆ | NPC自動声かけ → ダイアログパネル発火＋ステータス影響 | 中 |
| ★★☆ | 会話トーン改善（ポジティブ台詞追加） | 小 |

> **既実装メモ**
> - `"chair_sit"` / `"taiiku_suwari"` ポーズ → `CharacterPoseCalculator.gd` に実装済み。`player.pose` に文字列を代入するだけで切り替わる。
> - NPC 頭上テキスト受動発話 → `SkeletalNPC.gd` 実装済み。未実装はダイアログパネルへの格上げ。
> - 授業暗転 → `school_hallway` 遷移 → `_run_school_day_transition()`（MainScene.gd:1147）実装済み。

---

## ★★★ セーブ/ロード非保存フラグ修正

`dialogue_trigger_spec.md:§11` 確認済み。再起動でフラグがリセットされ会話進行が壊れる。

### 保存対象に追加する変数（`Global.gd` の `save_slot()` / `load_slot()`）

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
| `visited_stages` | Dictionary | 初訪問判定リセット（NPC自動声かけ実装後） |

### 実装（save_slot / load_slot に追記）

```gdscript
# save_slot() の data dict に追加
data["met_npcs"]                 = met_npcs
data["haruka_invited_this_term"] = haruka_invited_this_term
data["haruka_following"]         = haruka_following
data["senior_gym_invited"]       = senior_gym_invited
data["vball_story_phase"]        = vball_story_phase
data["vball_joined"]             = vball_joined
data["is_leg_pain"]              = is_leg_pain
data["pending_events"]           = pending_events.duplicate()
data["visited_stages"]           = visited_stages.duplicate()

# load_slot() に追加
met_npcs                 = data.get("met_npcs", {})
haruka_invited_this_term = data.get("haruka_invited_this_term", false)
haruka_following         = data.get("haruka_following", false)
senior_gym_invited       = data.get("senior_gym_invited", false)
vball_story_phase        = data.get("vball_story_phase", 0)
vball_joined             = data.get("vball_joined", false)
is_leg_pain              = data.get("is_leg_pain", false)
pending_events           = data.get("pending_events", [])
visited_stages           = data.get("visited_stages", {})
```

---

## ★★☆ `current_term_plan` 削除 → 全ホットスポット常時解放

### 背景

ルート選択（学校・家・駅）は「今学期の過ごし方」を選ぶ UI だったが、ゲームとしてルーティーン化するため廃止。
どのステージにいても全ホットスポットがインタラクション可能になる。

### 削除・変更箇所

**Global.gd:**
- `var current_term_plan: String` を削除
- `var DEFAULT_TERM_PLAN: String` を削除
- `save_slot()` / `load_slot()` の `current_term_plan` 保存処理を削除

**MainScene.gd（`current_term_plan` の参照は11箇所）:**

| 行 | 処理 | 対応 |
|---|---|---|
| 675 | 初期化 `current_term_plan = DEFAULT_TERM_PLAN` | 削除 |
| 812,859 | `plan_id` でモノローグ・反省文取得 | `plan_id` 参照を削除 or `stress` 帯で代替 |
| 823 | ステータステキスト中の `match current_term_plan` | 削除 |
| 882 | `TERM_HOTSPOTS` の `plan` フィルター | **この行を削除**（フィルターをなくす） |
| 1085,1102 | 授業遷移・はるか会話の `plan == "school"` 判定 | 削除（常に実行 or ステージ判定に変更） |
| 1270 | はるかキー選択での `plan == "school"` 条件 | ステージIDが教室かどうかで代替 |
| 1827 | デバッグテキスト | 削除 |
| 2292,2293 | `TERM_CHOICES.get(plan)` | `TERM_CHOICES` ごと削除 |

**TERM_HOTSPOTS の `"plan"` キー:**
各ホットスポット定義から `"plan": "..."` を削除するだけで、全プランで有効になる。

### ホットスポットの条件代替案

プラン削除後、「このホットスポットはいつ出るか」の差別化として `stress` 帯を使う。

```gdscript
# TERM_HOTSPOTS に "stress_min" / "stress_max" を追加（任意）
"home_mirror": {
    "stage_id": "room",
    "stress_min": 30,    # ストレスがある程度溜まっている時だけ出る
    ...
}
```

ただし複雑化を避けるなら、条件なしで常時表示でも十分。

---

## ★★☆ ホットスポットにポーズ変更を追加

### 現状

`_trigger_term_hotspot()` はストレス更新 → ダイアログ開始のみ。ポーズ変更なし。

### 設計

`TERM_HOTSPOTS` に `"pose"` フィールドを追加。ダイアログ前後でポーズを切り替える。

```gdscript
# TERM_HOTSPOTS 定義に "pose" を追加する例
"school_seat": {
    "stage_id": "school",
    "obs_ids": ["desk_1", "student_chair_1", ...],
    "pose": "chair_sit",    # ← 追加
    ...
}
```

`_trigger_term_hotspot()` への変更：

```gdscript
func _trigger_term_hotspot(hotspot_id: String) -> void:
    ...
    # ダイアログ開始前にポーズ変更
    var pose_name: String = hotspot_data.get("pose", "")
    if pose_name != "" and player:
        player.pose = pose_name

    _start_dialogue(...)

# _end_dialogue() にポーズ戻しを追加
func _end_dialogue() -> void:
    ...
    if player and player.pose != "normal":
        player.pose = "normal"
```

### 各ホットスポットのポーズ対応表

| ホットスポット | オブジェクト | ポーズ | 備考 |
|---|---|---|---|
| `school_seat` | 教室の椅子 | `"chair_sit"` | 実装済みポーズ |
| `home_table` | 食卓の椅子 | `"chair_sit"` | 実装済みポーズ |
| `school_infirmary` | 保健室のベッド | `"taiiku_suwari"` | 実装済みポーズ（代用） |
| `station_bench` | 駅ベンチ | `"chair_sit"` | 実装済みポーズ |
| `station_vending` | 自販機 | `"reach_low"` | **新規ポーズが必要** |
| `gymnasium_basket` | バスケゴール | `"reach_up"` | **新規ポーズが必要** |

### 新規ポーズの追加（CharacterPoseCalculator.gd）

**`"reach_low"`（自販機・低いボタンに手を伸ばす）**
- 体は直立
- 利き腕を斜め前下方（約-45度）に伸ばす
- 「大きい体で低いボタンに手を伸ばす」違和感を表現

```gdscript
# CharacterPoseCalculator.gd の calculate_pose_data() に追加
elif pose == "reach_low":
    d["arm_r_angle"] = -45.0   # 右腕を斜め前下に
    d["arm_l_angle"] = 10.0    # 左腕は自然に
    d["waist_angle"] = deg_to_rad(5.0)   # わずかに前傾
```

**`"reach_up"`（バスケゴールに手を伸ばす）**
- 体は直立〜わずかに爪先立ち
- 利き腕を真上に伸ばす（約+90度）

```gdscript
elif pose == "reach_up":
    d["arm_r_angle"] = 90.0    # 右腕を真上に
    d["arm_l_angle"] = 20.0    # 左腕は少し上
```

### 新規干渉ホットスポット候補

既存の `TERM_HOTSPOTS` に追加する定義：

```gdscript
"station_vending": {
    "stage_id": "station",
    "obs_id": "station_vending",
    "pose": "reach_low",
    "prompt": "自販機の前に立つ",
    "dialogue_npc": "player",
    "dialogue_key": "term_station_vending",
    "stress_delta": 3,
    "memory_note": "ボタンが低くて少し腰をかがめないといけなかった。"
},
"gymnasium_basket": {
    "stage_id": "gymnasium",
    "obs_id": "basket_goal",
    "pose": "reach_up",
    "height_min": 185,   # ← 新フィールド：身長条件（MainSceneで判定）
    "prompt": "バスケゴールに手を伸ばす",
    "dialogue_npc": "player",
    "dialogue_key": "gymnasium_basket_reach",
    "stress_delta": -5,
    "memory_note": "ゴールのリングに、指先が触れそうになった。"
},
```

`"height_min"` の判定は `_trigger_term_hotspot()` か `_check_nearby_hotspot()` で追加：

```gdscript
var height_min: float = float(hotspot_data.get("height_min", 0.0))
if height_min > 0.0 and Global.current_params["height"] < height_min:
    return  # 身長不足なら発火しない
```

---

## ★★☆ NPC自動声かけ → ダイアログパネル発火（新設計）

### 現状 vs 目標

| 現状 | 目標 |
|---|---|
| NPC頭上テキスト（SkeletalNPC.gd）。E キー不要、ステータス変化なし | ダイアログパネルを自動で開いてストレス等に影響、ストーリーフラグにもなりうる |

### 設計方針

`pending_events` キュー方式（既存の `semester_start` と同じ仕組み）で「NPC が話しかけてくる」を実現。

#### トリガー条件（`_load_stage()` で身長チェック、1学期に1回）

| イベントID | 条件 | ステージ |
|---|---|---|
| `"npc_talk_tall"` | 身長 ≥ 170cm、未実行 | 学校系ステージ |
| `"npc_talk_huge"` | 身長 ≥ 180cm、未実行 | 駅・ショッピングモール等 |
| `"npc_talk_veryhuge"` | 身長 ≥ 190cm、未実行 | どのステージでも |
| `"npc_firstvisit_<stage_id>"` | ステージ初訪問（`visited_stages` 利用） | ステージ固有 |

```gdscript
# _load_stage() 末尾に追加
func _check_height_npc_events(stage_id: String) -> void:
    var h := Global.current_params["height"] as float
    if h >= 170 and StageBuilder.is_school_stage(stage_id) \
            and not Global.has_term_hotspot_done("npc_talk_tall"):
        Global.queue_event("npc_talk_tall")
    if h >= 180 and stage_id == "station" \
            and not Global.has_term_hotspot_done("npc_talk_huge"):
        Global.queue_event("npc_talk_huge")
    if Global.is_first_visit(stage_id):
        Global.record_stage_visit(stage_id)
        Global.queue_event("npc_firstvisit_" + stage_id)
```

#### `_load_stage()` のイベント処理に追加（既存の `semester_start` パターン流用）

```gdscript
"npc_talk_tall":
    Global.mark_term_hotspot_done("npc_talk_tall")
    _start_dialogue("generic", "npc_talk_tall")
"npc_talk_huge":
    Global.mark_term_hotspot_done("npc_talk_huge")
    _start_dialogue("generic", "npc_talk_huge")
"npc_firstvisit_gymnasium_middle":
    _start_dialogue("generic", "npc_firstvisit_gymnasium")
```

#### `DialogueDatabase.gd` に台詞を追加

```gdscript
"generic": {
    "npc_talk_tall": [
        {"speaker": "同級生", "text": "ねえ、バスケ部入ってるの？ 絶対向いてるって！"},
        {"speaker": "同級生", "text": "上の棚取ってくれる？",
         "action": "stress:-5"},
    ],
    "npc_talk_huge": [
        {"speaker": "通行人", "text": "……モデルさんですか？"},
        {"speaker": "主人公", "text": "…（なんて答えればいいんだろう）",
         "choices": [
             {"label": "笑って「違います」と言う", "action": "confidence:+1"},
             {"label": "目をそらす",               "action": "stress:+5"},
         ]},
    ],
    "npc_firstvisit_gymnasium": [
        {"speaker": "体育教師", "text": "おっ、新しい顔か。君、バレー部に向いてそうだな。"},
    ],
}
```

---

## ★★☆ 会話トーン改善

### 追加対象

`DialogueDatabase.gd` の以下キーにポジティブ・ユーモラスなバリエーションを追加。

#### `generic / tall`（170〜179cm帯）
- 「背高いね。バスケ向いてそう！」
- 「ちょっと棚の上の荷物取ってくれる？」

#### `generic / huge`（180〜189cm帯）
- 「モデルさんみたい！」
- 「天井、頭届きそう？」

#### `generic / default`（身長差なし）
- 「今日もすっきりしてるね。」

#### `SkeletalNPC.gd` の受動発話テキストに追加

```gdscript
"school/tall":  ["一番後ろの席、ぴったりだね。", "掲示物、上まで見えていいな。"],
"station/huge": ["人波から頭ひとつ抜けてる！", "電車、立っても大丈夫？"],
```

---

## 補足：`visited_stages` 追加（NPC自動声かけと同時実装推奨）

`Global.gd` に追加：

```gdscript
var visited_stages: Dictionary = {}

func record_stage_visit(stage_id: String) -> void:
    visited_stages[stage_id] = true

func is_first_visit(stage_id: String) -> bool:
    return not visited_stages.has(stage_id)
```

セーブ/ロード対象にも追加（セーブ修正タスクと同時実施推奨）。
