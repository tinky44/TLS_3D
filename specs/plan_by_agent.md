# plan_by_agent.md — AIエージェントのメモ帳

更新日: 2026-03-15

---

## 残タスク（優先順）

| 優先 | タスク | 規模 |
|---|---|---|
| ★★★ | セーブ/ロード非保存フラグ修正 | 小〜中 |
| ★★☆ | #47 進級選択ダイアログ（`current_term_plan` 選択UI） | 中 |
| ★★☆ | NPC自動声かけ → ダイアログパネル発火＋ステータス影響 | 中 |
| ★★☆ | 会話トーン改善（ポジティブ台詞追加） | 小 |
| ★☆☆ | 干渉表現（椅子・バスケゴール等） | 中 |

> **注**: 「授業暗転 → school_hallway 遷移」`_run_school_day_transition()`（MainScene.gd:1147）は実装済み。
> NPC の頭上テキスト受動発話（`SkeletalNPC.gd`）も実装済み。未実装なのはダイアログパネルへの格上げとステータス反映。

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

### 実装（save_slot / load_slot に追記）

```gdscript
# save_slot() の data dict に追加
data["met_npcs"]                = met_npcs
data["haruka_invited_this_term"]= haruka_invited_this_term
data["haruka_following"]        = haruka_following
data["senior_gym_invited"]      = senior_gym_invited
data["vball_story_phase"]       = vball_story_phase
data["vball_joined"]            = vball_joined
data["is_leg_pain"]             = is_leg_pain
data["pending_events"]          = pending_events.duplicate()

# load_slot() に追加
met_npcs                 = data.get("met_npcs", {})
haruka_invited_this_term = data.get("haruka_invited_this_term", false)
haruka_following         = data.get("haruka_following", false)
senior_gym_invited       = data.get("senior_gym_invited", false)
vball_story_phase        = data.get("vball_story_phase", 0)
vball_joined             = data.get("vball_joined", false)
is_leg_pain              = data.get("is_leg_pain", false)
pending_events           = data.get("pending_events", [])
```

---

## ★★☆ NPC自動声かけ → ダイアログパネル発火（新設計）

### 現状 vs 目標

| 現状 | 目標 |
|---|---|
| NPC頭上テキスト（SkeletalNPC.gd）。E キー不要、ステータス変化なし | ダイアログパネルを自動で開いてストレス等に影響、フラグにもなる |

### 設計方針

「NPC が主人公に話しかけてくる」イベントを **`pending_events` キュー方式**（既存仕組みを流用）で実現する。

#### トリガー条件

| 条件 | キュー投入タイミング | イベントID |
|---|---|---|
| 中学以降、身長 ≥ 170cm で学校ステージに初めて入る | `_load_stage()` で身長チェック | `"npc_talk_tall"` |
| 身長 ≥ 180cm で駅ステージに初めて入る | 同上 | `"npc_talk_huge"` |
| 身長 ≥ 190cm でどのステージにも | 同上 | `"npc_talk_veryhuge"` |
| 特定ステージ初訪問（体育館等） | `record_stage_visit()` と連動 | `"npc_firstvisit_<stage_id>"` |

これらは **1学期に1回** 発火（`term_hotspot_flags` か専用フラグで重複防止）。

#### 実装箇所

1. **`_load_stage()` に身長チェックを追加**（MainScene.gd:1850〜）

```gdscript
func _check_height_npc_events() -> void:
    var h = Global.current_params["height"]
    var sid = Global.current_stage_id
    if h >= 170 and StageBuilder.is_school_stage(sid) \
            and not Global.has_term_hotspot_done("npc_talk_tall"):
        Global.queue_event("npc_talk_tall")
    elif h >= 180 and sid == "station" \
            and not Global.has_term_hotspot_done("npc_talk_huge"):
        Global.queue_event("npc_talk_huge")
    # ...
```

2. **`_load_stage()` のイベント処理分岐に追加**（既存の `semester_start` と同じパターン）

```gdscript
"npc_talk_tall":
    Global.mark_term_hotspot_done("npc_talk_tall")
    _start_dialogue("generic", "npc_talk_tall")
"npc_talk_huge":
    Global.mark_term_hotspot_done("npc_talk_huge")
    _start_dialogue("generic", "npc_talk_huge")
```

3. **`DialogueDatabase.gd` に台詞を追加**

```gdscript
"generic": {
    "npc_talk_tall": [
        {"speaker": "同級生", "text": "ねえ、バスケ部入ってるの？ 絶対向いてるって！"},
        {"speaker": "同級生", "text": "上の棚、ちょっと取ってもらっていい？",
         "action": "stress:-5"},   # ポジティブ → ストレス微減
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

#### ストレス反映

`_process_choice_action()` で既に `stress` / `confidence` の加減算が実装済み。
台詞の `"action"` フィールドに `"stress:-5"` の形式で記述するだけで流用できる。

---

## ★★☆ #47 進級選択ダイアログ

### 現状

`TERM_CHOICES` 定義はあるが選択 UI がなく、`current_term_plan = "school"` 固定運用（`dialogue_trigger_spec.md:§6`）。

### 実装案

`_on_next_term_pressed`（学期更新後）に選択パネルを表示。

```
┌──────────────────────────────┐
│ 今学期、どう過ごす？          │
│                              │
│  [学校中心にする]            │ → current_term_plan = "school"
│  [家でゆっくり過ごす]        │ → current_term_plan = "home"
│  [外（駅・街）に出る]        │ → current_term_plan = "station"
└──────────────────────────────┘
```

選択によって有効になるホットスポット（`dialogue_trigger_spec.md:§1-3`）:
- `school`: `school_seat`, `school_infirmary`, `term_school_haruka_support`
- `home`: `home_mirror`, `home_table`
- `station`: `station_bench`, `station_vending`

---

## ★★☆ 会話トーン改善

### 追加対象

`DialogueDatabase.gd` の以下キーにバリエーションを追加。

#### `generic / tall`（170〜179cm帯）

```gdscript
{"speaker": "同級生", "text": "背高いね。バスケ向いてそう！"},
{"speaker": "同級生", "text": "ちょっと棚の上の荷物取ってくれる？"},
```

#### `generic / huge`（180〜189cm帯）

```gdscript
{"speaker": "通行人", "text": "モデルさんみたい！"},
{"speaker": "同級生", "text": "天井、頭届きそう？"},
```

#### `generic / default`（身長差なし）

```gdscript
{"speaker": "同級生", "text": "今日もすっきりしてるね。"},
```

### SkeletalNPC.gd の受動発話に追加

`_stage_reaction_texts` 相当の定数辞書に追記：

```gdscript
"school/tall":  ["一番後ろの席、ぴったりだね。", "掲示物、上まで見えていいな。"],
"station/huge": ["人波から頭ひとつ抜けてる！", "電車、立っても大丈夫？"],
```

---

## ★☆☆ 干渉表現（椅子・バスケゴール等）

### 設計方針

「ルートが school 固定で発生場所が限られる」問題を逆手に取り、学校ステージに絞った干渉イベントを追加する。

### 候補イベント（ホットスポット方式で追加）

| オブジェクト | ステージ | 身長条件 | 演出 |
|---|---|---|---|
| 教室の机 | `school_*` | ≥175cm | 「脚が机の下に収まらない。体育座りが無理だ。」→ stress:+5 |
| バスケゴール | `gymnasium_*` | ≥190cm | 「手を伸ばしたら、リングに届きそうな気がした。」→ confidence:+2 |
| 電車のつり革 | `train` | ≥175cm | 「つり革が低い。軽く腕を曲げないと持てない。」 |
| 下駄箱 | `school_hallway_*` | ≥180cm | 「下駄箱の上の棚に、自分のゾーンが割り振られていた。」 |

### 実装方針

`TERM_HOTSPOTS` 定義（MainScene.gd）に上記を追加。既存の `term_school_seat` と同じパターンで実装可能。

---

## 補足：`visited_stages` の追加（NPC自動声かけと同時実装推奨）

`Global.gd` に追加：

```gdscript
var visited_stages: Dictionary = {}

func record_stage_visit(stage_id: String) -> void:
    visited_stages[stage_id] = true

func is_first_visit(stage_id: String) -> bool:
    return not visited_stages.has(stage_id)
```

セーブ/ロード対象にも追加（`fix/save-flags` と同ブランチで実施推奨）。
