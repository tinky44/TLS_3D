# キャラクター発話トリガ調査メモ

更新日: 2026-03-14

## 対象スコープ
- ダイアログパネルで表示される会話 (`MainScene.gd` の `_start_dialogue`)
- 頭上ラベルのリアクション発話 (`SkeletalNPC.gd` の `_show_reaction_text`)
- 主人公の待機モノローグ（バブル表示）

## 発話の主要エントリーポイント
- `MainScene.gd::_start_dialogue(npc_id, key)`
  - 会話DB (`DialogueDatabase.DATA`) を参照し、会話パネルを開く。
- `SkeletalNPC.gd::_show_reaction_text(text, duration)`
  - NPC頭上の短文リアクションを表示する。
- `MainScene.gd::_update_bubble()`
  - 条件を満たすと主人公の待機モノローグをバブル表示する。

---

## 1. ダイアログパネル発話のトリガ

### 1-1. `E` キー入力経由（プレイヤー操作）
`MainScene.gd::_unhandled_input` の `KEY_E` 分岐で、次の優先順に処理される。

1. 会話中なら次行へ進める (`_advance_dialogue`)
2. 身長計測パネル表示中なら次学期へ (`_on_next_term_pressed`)
3. 学期ホットスポットが近いなら発火 (`_trigger_term_hotspot`)
4. ドア遷移
5. 身長計測オブジェクトなら計測表示 (`_show_measurement_result`)
6. 近くにNPCがいれば会話開始 (`_interact_with_npc`)

つまり「NPC会話」も「ホットスポット会話」も、基本は `E` キーが直接トリガ。

### 1-2. NPC会話トリガ（`_interact_with_npc`）
近距離NPCに対して `E` を押すと、条件に応じて会話キーが決まり `_start_dialogue` される。

- 共通:
  - 距離が遠い場合は会話しない（横距離チェックあり）。
  - `npc_id` / 身長差 / `Global` フラグ（初対面・部活進行・ストレス等）でキー選択。
- 代表的な分岐:
  - `generic`: 身長差で `default` / `tall` / `huge`
  - `haruka`: `term_school_haruka_support` / `vball_pain_consult` / `measure_invite` / `tall` / `huge`
  - `senior`: `first_meet` 後に `join_invite` / `practice_first` / `pain_concern` / `senior_after_summer` など
  - `mother` / `father`: 状態次第で `check`

### 1-3. 学期ホットスポット会話トリガ（`_trigger_term_hotspot`）
障害物付近で `E` を押し、ホットスポット条件を満たすと会話発火。

- 判定元: `TERM_HOTSPOTS` 定義
- 条件:
  - `current_term_plan` と一致
  - `current_stage_id` と一致（解決後ステージID）
  - 対象 `obs_id`（または `obs_ids`）一致
  - 未実行フラグ（`term_hotspot_flags`）であること
- 発火時:
  - `mark_term_hotspot_done`
  - 必要に応じて `stress_delta` / `memory_note` 反映
  - 対応する `dialogue_npc` + `dialogue_key` で `_start_dialogue`

定義済みホットスポット:
- `home_mirror`, `home_table`
- `school_seat`, `school_infirmary`
- `station_bench`, `station_vending`

### 1-4. ステージロード時の自動イベント会話（`_load_stage`）
`Global.pending_events` から `pop_next_event()` したイベントで、自動会話が発火。

- `semester_start`（教室ステージ時） -> `teacher / semester_start`
- `gym_senior_invite`（体育館時） -> `senior / first_meet`
- `term_home`（`room`） -> `player / term_home`
- `term_station`（`station`） -> `player / term_station`
- `summer_growth`（`room`） -> `player / summer_growth` または `summer_growth_vball`
- `vball_tell_senior`（体育館） -> `senior / pain_concern`
- `entrance_ceremony`（`myroom`） -> `player / entrance_*`

ステージ条件を満たさない場合は `pending_events` 先頭に戻され、後で再評価される。

### 1-5. 計測UIからの自動会話
- 計測パネルを閉じる時 (`_on_measurement_panel_closed`):
  - `Global.haruka_following == true` なら `haruka / measure_after`
- 次学期へ進める時 (`_on_next_term_pressed`):
  - 学期更新と演出後に `player / new_semester`（12歳・15歳は入学系キー）

### 1-6. 会話終了時の連鎖トリガ（`_end_dialogue`）
- `haruka / measure_invite` 終了時:
  - `haruka_following = true` になり、はるかが追随開始
- `teacher / semester_start` 終了時:
  - `current_term_plan == "school"` なら `player / term_school` を遅延起動
- `player / term_school` 終了後:
  - 条件成立時に `_run_school_day_transition()` 実行（演出遷移）
- 進級選択が必要な学期導入会話だった場合:
  - 進級選択パネル表示

### 1-7. 会話内容の前置きトリガ（ストレス差し込み）
`_build_dialogue_sequence` で、以下条件なら会話の先頭に1行追加される。

- `npc_id != "player"`
- キーが `STRESS_PREFIX_KEYS`（`default`, `tall`, `huge`, `check`）に含まれる
- `Global.stress` 帯 (`low` / `mid` / `high`) に応じた opener が定義されている

---

## 2. 頭上リアクション発話のトリガ（`SkeletalNPC.gd`）

### 2-1. 共通前提
- プレイヤーが `REACTION_DIST`（170px）以内に入ると処理開始
- 離れると近接状態をリセット

### 2-2. 汎用NPC（`npc_id == ""`）
- 身長差バケット変化時に即時リアクション（短文）
  - `tall` / `huge` / `very_huge` / `shorter` / `same`
- 近接継続で受動発話:
  - 1.8秒経過で1回発話（クールダウン6秒）
  - プレイヤー絶対身長で `tall`(>=170), `huge`(>=180), `very_huge`(>=190)
  - ステージ別文言セット + 子どもNPC専用文言あり

### 2-3. 名前付きNPC（`npc_id != ""`）
- `core_npcs.greet_events` がある場合:
  - 近接2.0秒で1回挨拶発話（クールダウン5秒）
  - 候補からランダム（直前文言の連続回避あり）

---

## 3. 主人公の待機モノローグ（バブル）
`MainScene.gd::_update_bubble` で、以下条件時に主人公バブルへ表示される。

- 近くにNPC・オブジェクト相互作用がない
- 会話中/計測中/進級選択中ではない
- `current_term_plan` と `stress` 帯に応じたモノローグが存在する

これは会話パネルではないが、見た目上は「主人公のセリフ表示」に該当。

---

## 4. トリガ状態を作る主なフラグ更新元
- `Global.gd::advance_term`
  - `summer_growth` / `semester_start` をキュー
  - 学期フラグ・ホットスポット実行フラグを初期化
- `CharacterCreatorScene.gd::_on_next_pressed`
  - 新規開始時に `entrance_ceremony` をキュー
- `MainScene.gd::_process_choice_action`
  - 会話選択肢で `vball_*` 状態更新、必要時 `vball_tell_senior` をキュー

---

## 補足（現状の実装観察）
- `TERM_CHOICES` 定義はあるが、`MainScene.gd` 内では `current_term_plan` を選択更新する処理が見当たらず、実質 `Global.DEFAULT_TERM_PLAN`（`school`）運用が中心。
- そのため、学期ホットスポットの `plan` 条件は現状だと `school` 系が主に有効になる設計。
