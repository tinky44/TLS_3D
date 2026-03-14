# plan_by_agent.md — AIエージェントのメモ帳

更新日: 2026-03-15

---

## 残タスク（優先順）

| 優先 | タスク | 規模 |
|---|---|---|
| ★★★ | セーブ/ロード非保存フラグ修正 | 小〜中 |
| ★★☆ | `current_term_plan` 削除 → 全ホットスポット常時解放 | 中 |
| ★★☆ | ホットスポットにポーズ変更を追加（椅子・バスケゴール等） | 中 |
| ★★☆ | NPC自動声かけ → 身長マイルストーンのみダイアログ格上げ | 中 |
| ★★☆ | 会話トーン改善（ポジティブ台詞追加） | 小 |

> **既実装メモ**
> - `"chair_sit"` / `"taiiku_suwari"` ポーズ → `CharacterPoseCalculator.gd` に実装済み。`player.pose` に文字列を代入するだけで切り替わる。
> - NPC 頭上テキスト受動発話 → `SkeletalNPC.gd` 実装済み。未実装はダイアログパネルへの格上げ。
> - `visited_stages` / `experienced_events` → `Global.gd` に実装済み。

---

## ★★★ セーブ/ロード非保存フラグ修正

`dialogue_trigger_spec.md:§11` 確認済み。再起動でフラグがリセットされ会話進行が壊れる。

### 前提確認（実装前に要確認）

問題が「スロットロード時」に起きているか「アプリ再起動時（タイトルから再起動）」に起きているかで修正箇所が変わる。

- **スロットロード時** → `save_slot()` / `load_slot()` に追加すれば解決
- **アプリ再起動時** → 起動パスは `Global._ready() → load_settings()`。`settings.cfg` 側の保存対象も整理が必要

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

ルート選択（学校・家・駅）はゲームとしてルーティーン化するため廃止。
どのステージにいても全ホットスポットがインタラクション可能になる。

### 削除方針

- `term_home` / `term_station` イベント → 発火元がないためデッドコード、削除
- `TERM_CHOICES` / `TERM_CHOICE_ORDER` → 丸ごと削除
- ホットスポット会話（`term_home_mirror`, `term_home_table`, `term_station_bench`, `term_station_vending` 等）→ **再利用対象として残す**（`"plan"` キーを外すだけ）
- `current_term_plan` にぶら下がる表示文言・保存処理・スモーク初期化・キャラメイク初期化 → まとめて削除

### 削除・変更箇所（全ファイル）

**Global.gd:**
- `var current_term_plan: String` を削除
- `var DEFAULT_TERM_PLAN: String` を削除
- `save_slot()` / `load_slot()` の `current_term_plan` 保存処理を削除
- `save_settings()` / `load_settings()` の `current_term_plan` 保存処理を削除

**MainScene.gd（参照11箇所）:**

| 行 | 処理 | 対応 |
|---|---|---|
| 675 | 初期化 `current_term_plan = DEFAULT_TERM_PLAN` | 削除 |
| 812,859 | `plan_id` でモノローグ・反省文取得 | 削除（`stress` 帯で代替） |
| 823 | `match current_term_plan` | 削除 |
| 882 | `TERM_HOTSPOTS` の `plan` フィルター | **この行を削除**（フィルターをなくす） |
| 1085,1102 | `plan == "school"` 判定 | ステージIDが教室かどうかで代替 |
| 1270 | はるかキー選択での `plan == "school"` 条件 | 同上 |
| 1827 | デバッグテキスト | 削除 |
| 2292,2293 | `TERM_CHOICES.get(plan)` | `TERM_CHOICES` ごと削除 |

**CharacterCreatorScene.gd:**
- `current_term_plan` の初期化処理を削除

**CodexSmokeRunner.gd:**
- `current_term_plan` のスモーク初期化処理を削除

**TERM_HOTSPOTS の `"plan"` キー:**
各ホットスポット定義から `"plan": "..."` を削除するだけで全プランで有効になる。

### ホットスポットの条件代替（任意）

プラン削除後、`stress` 帯を使って差別化できる（複雑化を避けるなら条件なしでも十分）。

```gdscript
"home_mirror": {
    "stage_id": "room",
    "stress_min": 30,    # ストレスがある程度溜まっている時だけ出る
    ...
}
```

---

## ★★☆ ホットスポットにポーズ変更を追加

### 現状

`_trigger_term_hotspot()` はストレス更新 → ダイアログ開始のみ。ポーズ変更なし。

### 設計

`TERM_HOTSPOTS` に `"pose"` フィールドを追加し、`_trigger_term_hotspot()` でダイアログ前後にポーズを切り替える。

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

現行実装は `calculate_pose_data()` 内でローカル変数（`arm_r_angle` 等）を直接更新して最後に Dictionary を返す構造。
`d["arm_r_angle"] = ...` のような直接代入ではなく、**既存の他ポーズ分岐（`chair_sit` 等）と同じ書き方**に合わせること。

**`"reach_low"`（自販機・低いボタンに手を伸ばす）**
- 体は直立、わずかに前傾
- 利き腕を斜め前下方（約-45度）に伸ばす
- 「大きい体で低いボタンに手を伸ばす」違和感を表現

**`"reach_up"`（バスケゴールに手を伸ばす）**
- 体は直立〜わずかに爪先立ち
- 利き腕を真上（約+90度）に伸ばす

### 新規干渉ホットスポット候補

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
    "height_min": 185,
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

## ★★☆ NPC自動声かけ → 身長マイルストーンのみダイアログ格上げ

### 声かけの2種類を使い分ける

**全ての自動声かけをダイアログ化するわけではない。** 以下の基準で使い分ける。

| | 頭上テキスト（現状維持） | ダイアログパネル（今回追加） |
|---|---|---|
| 発火頻度 | 毎回近づくたびに | ゲーム全体でそれぞれ1回だけ |
| ゲームへの介入 | 歩きながら読める・止まらない | 一時停止・Eキーで進める |
| ステータス変化 | なし | stress / confidence に影響 |
| 選択肢 | なし | あり |
| 意味 | 環境リアクション（背景音的） | 記憶に残る出来事（節目） |

**ダイアログ化するのは「身長マイルストーン初回突破」のみ。**
170cm・180cm・190cm を初めて超えた際の1回限りのイベント。
通常の近接リアクション（「背高いね」等）は頭上テキストのまま。

### 設計方針

`pending_events` キュー方式（既存の `semester_start` と同じ仕組み）で実現。

#### トリガー条件（ゲーム全体で各1回）

| イベントID | 条件 | ステージ |
|---|---|---|
| `"npc_talk_tall"` | 身長が初めて ≥ 170cm に達した学期 | 学校系ステージ |
| `"npc_talk_huge"` | 身長が初めて ≥ 180cm に達した学期 | 駅・ショッピングモール等 |
| `"npc_talk_veryhuge"` | 身長が初めて ≥ 190cm に達した学期 | どのステージでも |
| `"npc_firstvisit_<stage_id>"` | ステージ初訪問 | ステージ固有 |

#### 実装上の注意点

**① `queue_event()` の位置（重要）**

`_load_stage()` は先に `pop_next_event()` でキューを消化してからステージを構築する。
末尾で `queue_event()` しても**その場では発火せず、次回ステージ遷移まで眠る**。

対応案: 身長チェックと `queue_event()` を `pop_next_event()` の処理より**前に**行うか、投入後に即処理する導線を作る。

**② `is_first_visit()` の判定順（重要）**

`_load_stage()` の冒頭ですでに `record_stage_visit()` が呼ばれている場合、
その後に `is_first_visit()` を呼ぶと常に `false` になる。

対応: `is_first_visit()` の結果を先に変数へ退避してから `record_stage_visit()` を呼ぶ。

```gdscript
# 正しい実装
var was_first_visit := Global.is_first_visit(stage_id)
Global.record_stage_visit(stage_id)   # ← ここで記録
if was_first_visit:
    Global.queue_event("npc_firstvisit_" + stage_id)
```

**③ `StageBuilder.is_school_stage()` は存在しない**

既存の helper を使うか、新しく追加する。

```
既存:
  StageBuilder.is_school_classroom_stage(id)
  StageBuilder.is_school_hallway_stage(id)
  StageBuilder.is_schoolyard_stage(id)

対応案A: 上記3つの OR で判定する
対応案B: StageBuilder に is_school_stage() を新規追加する
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
