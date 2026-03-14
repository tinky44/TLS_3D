# キャラクター発話トリガ調査メモ

更新日: 2026-03-15

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

## 5. 具体的な会話内容（実データ抜粋）
以下は `DialogueDatabase.gd` / `SkeletalNPC.gd` / `Global.gd` の実文言から抜粋。

### 5-1. NPCに `E` で話しかけた時（会話パネル）
- `haruka / measure_invite`:
  - 発火条件（判定順あり）:
    - `first_meet` 済みであること（未遭遇時は `first_meet` が優先）
    - `term_school_haruka_support` 条件に入っていないこと
    - `vball_pain_consult` 条件（`phase=3 && is_leg_pain`）に入っていないこと
    - `haruka_invited_this_term == false`
  - 発火時更新:
    - `haruka_invited_this_term = true`
  - はるか: 「ねえ……また背、伸びてない？」
  - はるか: 「保健室、行こうよ。…正直、最近どんな気持ち？」
  - 選択肢: 「ちょっと嬉しいかも」「目立つし、恥ずかしい……」「よくわからない」
- `senior / first_meet`:
  - 発火条件:
    - 体育館で `gym_senior_invite` イベントを消化した時、または `first_meet` 未遭遇で先輩に話しかけた時
  - 終了時更新:
    - `vball_story_phase: 0 -> 1`
  - バレー部先輩: 「君、ちょっといいかな？」
  - バレー部先輩: 「バレー部、興味ない？ 君なら無敵のアタッカーになれるよ。」
- `senior / pain_concern`:
  - 発火条件（2経路）:
    - 直接経路: `vball_story_phase == 3 && is_leg_pain == true` で先輩に `E`
    - キュー経路: `haruka / vball_pain_consult` で「先輩に伝えてもらう」選択後、`vball_tell_senior` が体育館で消化される
  - 終了時更新:
    - `is_leg_pain = false`
    - `vball_joined = false`
    - `vball_story_phase = 5`
  - バレー部先輩: 「はるかから聞いたよ。脚が痛いんだって？」
  - バレー部先輩: 「今は無理するな。しばらく休部して、ちゃんと診てもらえ。」
- `mother / check`:
  - お母さん: 「あら、また制服の丈が短くなったわね。」
  - お母さん: 「もうミニスカートどころじゃないわよ。」
- `father / check`:
  - お父さん: 「いつの間にか、お父さんより頭二つ分も大きいんだな。」
  - お父さん: 「天井の電球、替えてくれるかい？」

### 5-2. 学期ホットスポットで `E` を押した時（会話パネル）
- `term_home_mirror`（洗面台）:
  - 主人公: 「洗面台の鏡に、自分の姿がすっぽり映る。」
- `term_home_table`（食卓）:
  - 主人公: 「食卓の前で立ち止まる。どうしよう。」
  - 選択肢: 「そのまま一緒に座る」「やっぱり部屋に戻る」
- `term_school_seat`（教室の席）:
  - 主人公: 「自分の席に座る。机の高さは昔のままなのに、見える景色だけが少し変わっている。」
- `term_school_infirmary`（保健室）:
  - 保健の先生: 「顔色、少し固いわね。座って、ゆっくり話してみる？」
  - 選択肢: 「しんどさを正直に話す」「平気だと言って戻る」
- `term_station_bench`（駅ベンチ）:
  - 主人公: 「ベンチに腰を下ろす。人の流れを見ていると…」
- `term_station_vending`（駅自販機）:
  - 主人公: 「自販機の前で立ち止まる。ボタンは低いのに、なぜか視線だけは高いところまで届く気がした。」

### 5-3. イベントキュー起動の自動会話（会話パネル）
- `teacher / semester_start`:
  - 田中先生: 「起立、礼。着席。」
  - 田中先生: 「……あなた、また背が伸びたんですか。後ろの席に座ってください」
- `player / term_school`（`semester_start` 後に連鎖）:
  - 主人公: 「また後ろの席だ。みんなの視線が、少しだけ気になる。」
  - 選択肢: 「目立っても、ちゃんと通う」「やっぱり少ししんどい」
- `player / summer_growth`:
  - 主人公: 「……制服のボタン、止まらない。」
  - お母さん: 「夏休みだけで10センチ？ そんなことある？」
- `player / new_semester`:
  - 主人公: 「新学期か……。」
  - 主人公: 「また少し背が伸びた気がする。今学期も色々あるんだろうな。」
- `player / entrance_elementary`:
  - 主人公: 「今日は小学校の入学式だ。」
- `player / entrance_middle`:
  - 主人公: 「今日は中学校の入学式だ。」
- `player / entrance_high`:
  - 主人公: 「今日は高校の入学式だ。」

### 5-4. 計測UI由来の自動会話（会話パネル）
- `haruka / measure_after`（計測パネルを閉じた時、追随フラグあり）:
  - はるか: 「……やっぱり伸びてる。」
  - はるか: 「次の学期も、また測ろうね。抜け駆け禁止だよ！」

### 5-5. ストレス前置き（会話先頭に差し込まれる1行）
- `haruka / high`: 「かなりしんどそう。少し端で話そっか。」
- `senior / mid`: 「視線が気になる日か。呼吸だけでも合わせてみる？」
- `mother / low`: 「今日は少し楽そうな顔をしてるね。」

### 5-6. 頭上リアクション（`SkeletalNPC.gd`）
- 汎用NPC 受動発話例:
  - `school/huge`: 「掲示物、上の方まで見やすそう。」
  - `station/very_huge`: 「人波から頭ひとつ抜けてる……！」
  - `room/tall`: 「今日もすらっとしてるね。」
- 子ども汎用NPC:
  - 「背、高いね！」
  - 「すごい！ %dcm！？」
- コアNPC近接挨拶（`Global.core_npcs.greet_events`）:
  - はるか: 「ねえ、最近また伸びた？」
  - 先輩: 「お、今日も目立ってるな。」

### 5-7. 待機モノローグ（バブル）
- `home/high`: 「今日は人の目より、自分を休ませるほうを優先しよう。」
- `school/mid`: 「教室に入る前に、一度呼吸を整えたい。」
- `station/low`: 「外は落ち着かないけど、歩き方は自分で選べる。」

---

## 6. 補足（現状の実装観察）
- `TERM_CHOICES` 定義はあるが、`MainScene.gd` 内では `current_term_plan` を選択更新する処理が見当たらず、実質 `Global.DEFAULT_TERM_PLAN`（`school`）運用が中心。
- そのため、学期ホットスポットの `plan` 条件は現状だと `school` 系が主に有効になる設計。

---

## 7. フラグ遷移の全体像

### 7-1. 主要フラグの意味と更新箇所
- `vball_story_phase`（0〜7）:
  - 0: 未出会い
  - 1: 先輩遭遇済み（`senior/first_meet` 後）
  - 2: 入部済み（`join_invite` で `vball_join`）
  - 3: 脚痛フェーズ（`practice_first` 後）
  - 4: はるかへ相談済み（`vball_pain_report`）
  - 5: 休部確定（`pain_concern` 後）
  - 6: 夏休み後（`summer_growth` 消化時に 2〜5 から遷移）
  - 7: 継続方針決定（`vball_rejoin` / `vball_manager_role`）
- `vball_joined`: バレー部在籍フラグ
- `is_leg_pain`: 脚痛フラグ（歩行モーションにも影響）
- `haruka_invited_this_term`: 今学期の計測誘導を出したか
- `haruka_following`: はるか追随中か（計測完了会話のトリガ）
- `met_npcs`: 各名前付きNPCの初対面管理
- `term_hotspot_flags`: 今学期に実行済みのホットスポット
- `pending_events`: ステージ到達待ちを含むイベントキュー
- `senior_gym_invited`: `gym_senior_invite` の一回性ガード

### 7-2. バレー部関連の会話キーと条件
- `senior/join_invite`:
  - 条件: `vball_story_phase == 1`
  - 選択肢「入部する！」で `vball_joined=true`, `vball_story_phase=2`
- `senior/practice_first`:
  - 条件: `vball_story_phase == 2 && vball_joined == true`
  - 終了後: `is_leg_pain=true`, `vball_story_phase=3`
- `haruka/vball_pain_consult`:
  - 条件: `npc_id=haruka` 判定時、`is_leg_pain == true && vball_story_phase == 3`
  - 選択肢「先輩に伝えてもらう」で `vball_story_phase=4` + `queue_event("vball_tell_senior")`
  - 選択肢「しばらく自分で頑張る」ではフラグ更新なし（`phase=3` 維持）
- `senior/pain_concern`:
  - 条件:
    - `phase=3 && is_leg_pain=true` で直接会話
    - または `vball_tell_senior` イベント消化
  - 終了後: `is_leg_pain=false`, `vball_joined=false`, `phase=5`
- `senior/senior_after_summer`:
  - 条件: `vball_story_phase == 6`
  - 選択結果:
    - 「また頑張りたい！」 -> `vball_rejoin` -> `phase=7`, `vball_joined=true`
    - 「マネージャーとして関わりたい」 -> `vball_manager_role` -> `phase=7`, `vball_joined=false`
    - 「今は勉強に集中したい……」 -> フラグ更新なし（`phase=6` のまま）

### 7-3. `senior / pain_concern` 到達フロー（要望例の詳細）
1. 先輩初遭遇 (`first_meet`) で `phase=1`
2. `join_invite` で入部し `phase=2`
3. `practice_first` 後に `is_leg_pain=true`, `phase=3`
4. ここから分岐:
   - 直接先輩へ話す -> `pain_concern`
   - はるかへ相談して「先輩に伝えてもらう」 -> `phase=4` + `vball_tell_senior` キュー
5. `vball_tell_senior` が体育館ステージで消化され `pain_concern`
6. 会話終了で `phase=5`, `is_leg_pain=false`, `vball_joined=false`

### 7-4. `haruka` 会話キーの判定優先順（重要）
`_interact_with_npc` 内の実装順に依存し、先に当たった条件が採用される。

1. `first_meet` 未済なら `first_meet`
2. `current_term_plan=="school"` かつ教室ステージかつ `school_haruka_support` 未実施なら `term_school_haruka_support`
3. `is_leg_pain && phase==3` なら `vball_pain_consult`
4. `haruka_invited_this_term == false` なら `measure_invite`（同時に `haruka_invited_this_term=true`）
5. それ以外で身長差分岐（`huge` / `tall`）

### 7-5. 会話終了時フラグ更新（`_end_dialogue`）
- `haruka/measure_invite` 終了:
  - `haruka_following=true`（はるか追随開始）
- `senior/first_meet` 終了:
  - `phase==0` のとき `phase=1`
- `senior/practice_first` 終了:
  - `vball_joined==true` のとき `is_leg_pain=true`, `phase=3`
- `senior/pain_concern` 終了:
  - `is_leg_pain=false`, `vball_joined=false`, `phase=5`
- `teacher/semester_start` 終了:
  - `current_term_plan=="school"` のとき `player/term_school` を遅延開始

### 7-6. イベントキュー起動の詳細
- キュー投入:
  - 新規開始: `entrance_ceremony`
  - 学期進行: `semester_start`, （条件付き）`summer_growth`
  - 会話選択: `vball_tell_senior`
  - `semester_start` 処理内: `gym_senior_invite`（未招待時のみ）
- キュー消化:
  - `_load_stage()` で先頭1件だけ `pop_next_event`
  - ステージ条件不一致なら `push_front` で戻す
  - 結果として「該当ステージに入った時点で自動会話」が実現される

### 7-7. 学期ホットスポットの再実行制御
- 実行時に必ず `mark_term_hotspot_done(hotspot_id)`
- 同学期中は `has_term_hotspot_done` で再発火不可
- `advance_term()` で `term_hotspot_flags = {}` に戻る

### 7-8. 学期更新時の一括リセット
`advance_term()` で以下が毎学期更新/初期化される。
- `queue_event("semester_start")`
- 夏学期条件なら `queue_event("summer_growth")`
- `haruka_invited_this_term=false`
- `haruka_following=false`
- `pending_term_choice` 再計算
- `current_term_plan=DEFAULT_TERM_PLAN`
- `term_hotspot_flags={}`
- `term_memory_note=""`

### 7-9. セーブ/ロードの観点（現実装）
- `save_settings` / `save_slot` で保存される:
  - `pending_term_choice`, `current_term_plan`, `term_hotspot_flags`, `term_memory_note`, `stress` など
- 現コード上、保存対象に入っていない:
  - `met_npcs`
  - `haruka_invited_this_term`, `haruka_following`
  - `senior_gym_invited`
  - `vball_story_phase`, `vball_joined`, `is_leg_pain`
  - `pending_events`

このため、再起動を挟むと会話進行フラグとキューは初期値へ戻る挙動になる。

---

## 8. 条件式ベースの判定順（コード準拠・詳細）

### 8-1. NPC会話キー決定の実際の順序
判定元: `MainScene.gd::_interact_with_npc`（`1213` 行付近）

1. `npc_id == ""` なら `generic` 扱い
2. 名前付きNPCは `met_npcs` で初対面判定
3. `first_meet` 条件があれば最優先で `first_meet`
4. その後、NPCごとの専用分岐（`senior` / `haruka`）
5. どれにも当たらなければ身長差キー（`tall` / `huge` / `default`）

補足:
- `first_meet` は会話開始時点で `met_npcs` に即追加される（会話完了を待たない）
- 汎用NPCは `has_met=false` 固定のため、毎回初対面扱いのルートを通らず、身長差キーへ直行

### 8-2. `haruka` のキー選択（優先度で上書き）
判定元: `MainScene.gd` `1269`〜`1281` 行付近

1. `term_school_haruka_support`
  - 条件: `current_term_plan=="school"` かつ 教室ステージ かつ `school_haruka_support` 未実行
  - 副作用: 会話開始時に `mark_term_hotspot_done("school_haruka_support")`
2. `vball_pain_consult`
  - 条件: `is_leg_pain && vball_story_phase==3`
3. `measure_invite`
  - 条件: `haruka_invited_this_term==false`
  - 副作用: 会話開始時に `haruka_invited_this_term=true`
4. 身長差 `huge` / `tall`

重要:
- 同時に複数条件を満たしても、先に書かれた条件が採用される。
- 例: `phase=3 && is_leg_pain` の間は、`measure_invite` は発火しない。

### 8-3. `senior` のキー選択（フェーズ機械）
判定元: `MainScene.gd` `1257`〜`1267` 行付近

1. `phase==1` -> `join_invite`
2. `phase==2 && vball_joined` -> `practice_first`
3. `phase==3 && is_leg_pain` -> `pain_concern`
4. `phase==6` -> `senior_after_summer`
5. それ以外は身長差 `huge`（条件一致時）

補足:
- `phase==4` は専用分岐がないため、通常会話では `pain_concern` にならない。
- `phase==4` で `pain_concern` に到達する主経路は `vball_tell_senior` キュー消化。

### 8-4. 会話終了時に走る後処理の詳細
判定元: `MainScene.gd::_end_dialogue`（`1051` 行付近）

- `haruka/measure_invite`:
  - `haruka_following=true`
  - シーン上の `haruka` NPC の `follow_target=player`
- `senior/first_meet`:
  - `phase==0` の時だけ `phase=1`
- `senior/practice_first`:
  - `vball_joined==true` なら `is_leg_pain=true`, `phase=3`
- `senior/pain_concern`:
  - `is_leg_pain=false`, `vball_joined=false`, `phase=5`
- `teacher/semester_start`:
  - `current_term_plan=="school"` なら遅延で `player/term_school`

注意:
- `senior_after_summer` の選択肢「今は勉強に集中したい……」は `action` が無く、`phase=6` のまま据え置き。

### 8-5. 測定パネル連携でのフラグ変化
判定元:
- `MainScene.gd::_on_measurement_panel_closed`（`2361` 行付近）
- `Global.gd::advance_term`（`329` 行付近）

- `measure_invite` 後に測定パネルを閉じる:
  - `haruka_following==true` なら `haruka/measure_after`
  - 会話開始前に `haruka_following=false` へ戻す
- 次学期へ進む（`advance_term()`）:
  - `haruka_invited_this_term=false`
  - `haruka_following=false`
  - `term_hotspot_flags={}` へ初期化

---

## 9. `senior / pain_concern` 到達の時系列（操作ベース）

### 9-1. 直接到達ルート（`phase=3` で先輩に直接 `E`）
1. `senior/first_meet` 完了 -> `phase=1`
2. `senior/join_invite` で「入部する！」 -> `phase=2`, `vball_joined=true`
3. `senior/practice_first` 完了 -> `phase=3`, `is_leg_pain=true`
4. 先輩に再度 `E` -> `senior/pain_concern`
5. 会話終了 -> `phase=5`, `is_leg_pain=false`, `vball_joined=false`

セリフ（`pain_concern`）:
- バレー部先輩: 「はるかから聞いたよ。脚が痛いんだって？」
- バレー部先輩: 「今は無理するな。しばらく休部して、ちゃんと診てもらえ。」
- バレー部先輩: 「治ったらいつでも戻ってこい。待ってるから。」

### 9-2. 報告キュールート（はるか経由）
1. 前提は同じく `phase=3`, `is_leg_pain=true`
2. はるかに `E` -> `haruka/vball_pain_consult`
3. 選択肢「先輩に伝えてもらう」
  - 即時更新: `phase=4`
  - キュー追加: `pending_events += ["vball_tell_senior"]`
4. 体育館ステージをロードした時にキュー消化
  - `senior/pain_concern` 自動発火
5. 終了時は直接ルートと同じ更新（`phase=5` など）

### 9-3. 報告キューの詰まり方（到達待ち）
判定元: `MainScene.gd::_load_stage`（`1886` 行付近）

- `vball_tell_senior` は体育館以外だと `push_front` で先頭へ戻される。
- つまりキューは消えず、体育館へ入るまで保持される。
- 同関数は1回のステージロードで先頭1件しか処理しないため、前段イベントが詰まっていると後続イベントは待機する。

---

## 10. 会話キーごとの「前提フラグ -> 終了後フラグ」一覧

### 10-1. バレー部関連
| 会話キー | 主な前提 | 変更タイミング | 主な更新 |
|---|---|---|---|
| `senior/first_meet` | `not met_npcs.has("senior")` または `gym_senior_invite` | 終了時 | `phase:0->1` |
| `senior/join_invite` | `phase==1` | 選択時 (`vball_join`) | `vball_joined=true`, `phase=2` |
| `senior/practice_first` | `phase==2 && vball_joined` | 終了時 | `is_leg_pain=true`, `phase=3` |
| `haruka/vball_pain_consult` | `phase==3 && is_leg_pain` | 選択時 (`vball_pain_report`) | `phase=4`, `queue_event("vball_tell_senior")` |
| `senior/pain_concern` | `phase==3 && is_leg_pain` または `vball_tell_senior` 消化 | 終了時 | `is_leg_pain=false`, `vball_joined=false`, `phase=5` |
| `senior/senior_after_summer` | `phase==6` | 選択時 | `vball_rejoin` / `vball_manager_role` なら `phase=7` |

### 10-2. はるか計測関連
| 会話キー | 主な前提 | 変更タイミング | 主な更新 |
|---|---|---|---|
| `haruka/measure_invite` | `haruka_invited_this_term==false` かつ他優先条件不成立 | 会話開始時 | `haruka_invited_this_term=true` |
| `haruka/measure_invite` | 同上 | 終了時 | `haruka_following=true` |
| `haruka/measure_after` | 測定パネルを閉じる時 `haruka_following==true` | 会話開始直前 | `haruka_following=false` |

---

## 11. セーブ/ロードをまたぐときの実運用メモ

### 11-1. 保存されるため維持されるもの
- `current_term_plan`
- `pending_term_choice`
- `term_hotspot_flags`
- `term_memory_note`
- `stress`, `self_confidence`, `self_complex` など

### 11-2. 保存されず再起動で戻るもの
- `met_npcs`
- `haruka_invited_this_term`, `haruka_following`
- `senior_gym_invited`
- `vball_story_phase`, `vball_joined`, `is_leg_pain`
- `pending_events`

### 11-3. 仕様化上の注意点
- デバッグ時に「途中再起動 -> 会話分岐が戻る」の主因は上記非保存フラグ。
- とくに `vball_story_phase` と `pending_events` が保存されないため、`pain_concern` の到達経路検証は連続プレイ前提で確認する必要がある。
