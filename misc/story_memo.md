# 現在のストーリー・分岐メモ

このメモは、2026-03-13 時点の実装コードをもとに、

- 現在ゲーム内で何がストーリーとして存在しているか
- どの条件で何が起きるか
- どの分岐がパラメータやイベントに接続しているか
- どこが未完成、またはロジックだけ存在しているか

を整理したものです。

完全な企画書ではなく、あくまで「現コードで動いている物語層」の棚卸しです。

## 1. ゲーム全体の時間構造

- ゲームは `学期` 単位で進行する。
- 新規開始時の初期状態は `6歳 / 小学1年の開始相当`。
- 学期を終えて測定画面から次へ進むと `advance_term()` が呼ばれ、年齢・身長・履歴が更新される。
- 各学期の開始時には `semester_start` がキューされる。
- 1学期から2学期へ進むタイミングでは、夏休みイベントとして `summer_growth` がキューされ、追加で `+10cm` の急成長が入る。
- 新規開始直後は `entrance_ceremony` がキューされ、最初のモノローグが流れる。

現在の基本ループは以下です。

1. 新規開始または次学期開始
2. 節目モノローグまたは始業式
3. 学期の過ごし方を選ぶ
4. そのルートに応じた場所へ行く
5. その学期のホットスポットを体験する
6. 保健室で測定する
7. 次の学期へ進む

## 2. 現在の主要パラメータとストーリー管理フラグ

### 成長・進行

- `age`
  現在年齢。
- `term`
  現在学期番号。
- `prev_height`
  前回測定時の身長。
- `growth_history`
  測定履歴。グラフと履歴表示に使う。

### 人間関係・接触履歴

- `met_npcs`
  既に初対面イベントを見たコアNPCの記録。
- `haruka_invited_this_term`
  今学期、測定への誘いをすでに消化したかどうか。
- `haruka_following`
  測定イベントの追随処理用フラグ。
- `senior_gym_invited`
  バレー部先輩から体育館に誘われる導線を一度だけ出すためのフラグ。

### 感情

- `self_confidence`
  高身長を受け入れる方向の選択の累積。
- `self_complex`
  高身長をしんどく感じる方向の選択の累積。
- `stress`
  現在のしんどさ。0-100。

### 学期ルート

- `pending_term_choice`
  学期開始時に行き先選択を出す必要があるか。
- `current_term_plan`
  今学期の方針。現在は `home / school / station` の3つ。
- `term_hotspot_flags`
  今学期に体験済みのホットスポット一覧。
- `term_memory_note`
  今学期に印象的だった出来事のメモ。測定画面に表示される。

### バレー部ストーリー

- `vball_story_phase`
  バレー部ストーリーの進行度。
- `vball_joined`
  入部中かどうか。
- `is_leg_pain`
  脚の痛みフラグ。歩行や分岐に影響する。

## 3. イベントキューで動く自動ストーリー

現在、自動進行系の物語イベントは `pending_events` で管理されている。

### `entrance_ceremony`

- 新規ゲーム開始時にキューされる。
- `myroom` に入ったときのみ発火。
- 年齢に応じて以下のモノローグへ分岐する。
  - `entrance_elementary`
  - `entrance_middle`
  - `entrance_high`

### `semester_start`

- 毎学期開始時にキューされる。
- `school` に入ったときのみ発火。
- 先生の `semester_start` 会話が流れる。
- 初回のみ、追加で `gym_senior_invite` がキューされる。
- さらに `current_term_plan == "school"` のときは、先生の会話終了後に主人公の `term_school` 会話へ自動接続される。

### `gym_senior_invite`

- 初回の始業式導線から一度だけ発生する。
- `gymnasium` に入ったときのみ発火。
- バレー部先輩の `first_meet` を再生する。

### `summer_growth`

- 夏休み明けの学期更新で発生する。
- `room` に入ったときのみ発火。
- 通常は `player.summer_growth`。
- `vball_joined == true` かつ `vball_story_phase >= 2` の場合のみ `player.summer_growth_vball` を使う。
- バレー部ストーリーが `phase 2-5` にいる場合、再生後に `phase 6` へ進む。

### `term_home`

- 学期選択で `home` を選んだときだけキューされる。
- `room` に入ったときのみ発火。
- 主人公の `term_home` 会話が流れる。

### `term_station`

- 学期選択で `station` を選んだときだけキューされる。
- `station` に入ったときのみ発火。
- 主人公の `term_station` 会話が流れる。

### `vball_tell_senior`

- はるかへの脚痛相談で「先輩に伝えてもらう」を選ぶとキューされる。
- `gymnasium` に入ったときのみ発火。
- 先輩の `pain_concern` 会話が流れる。

## 4. 現在の学期ルート

### 4.1 家ルート

学期選択時の基本効果

- `stress -12`
- ステージを `room` に変更
- `term_home` を再生

導入会話 `term_home`

- 「今学期は家で過ごす時間を増やす」という独白。
- その後、以下の2択がある。
  - `ちゃんと休む`
    - `stress -6`
    - 会話先 `term_home_rest`
  - `背筋を伸ばしてみる`
    - `stress -3`
    - `self_confidence +1`
    - 会話先 `term_home_posture`

ホットスポット

- `washstand`
  - プロンプト: `鏡を見る`
  - 会話: `term_home_mirror`
  - `stress -4`
  - メモ追加: `洗面台の鏡の前で、自分の背丈を静かに見つめた。`
- `table` または `chair`
  - プロンプト: `食卓で一息つく`
  - 会話: `term_home_table`
  - 2択あり
    - `そのまま一緒に座る`
      - `stress -4`
      - `self_confidence +1`
      - メモ追加: `食卓で家族と一緒に座る時間を取れた。`
    - `やっぱり部屋に戻る`
      - `stress +2`
      - `self_complex +1`
      - メモ追加: `食卓の前で少しためらってから部屋に戻った。`

体験としての意味

- 家ルートは「落ち着く」「休む」「受け止め直す」方向の導線になっている。
- 最初の3ルートの中では、もっとも `stress` を下げやすい。

### 4.2 学校ルート

学期選択時の基本効果

- `stress +8`
- ステージを `school` に変更
- 専用イベントキューは積まない
- 代わりに始業式終了後、`term_school` が自動再生される

導入会話の流れ

1. `teacher.semester_start`
2. 学校ルートを選んでいた場合のみ `player.term_school`
3. `term_school` 内で以下の2択
   - `目立っても、ちゃんと通う`
     - `stress -4`
     - `self_confidence +1`
     - 会話先 `term_school_brave`
   - `やっぱり少ししんどい`
     - `stress +4`
     - `self_complex +1`
     - 会話先 `term_school_tired`

ホットスポット

- `desk_1 / desk_2 / student_chair_1 / student_chair_2`
  - プロンプト: `自分の席に座る`
  - 会話: `term_school_seat`
  - `stress +2`
  - メモ追加: `教室の自分の席に座り、視線の中で過ごす実感が残った。`
- `infirmary_desk`
  - プロンプト: `保健室で相談する`
  - 会話: `term_school_infirmary`
  - 2択あり
    - `しんどさを正直に話す`
      - `stress -6`
      - `self_confidence +1`
      - メモ追加: `保健室でしんどさを正直に話せた。`
    - `平気だと言って戻る`
      - `stress +3`
      - `self_complex +1`
      - メモ追加: `保健室でも平気なふりをしてしまった。`

体験としての意味

- 学校ルートは「人の視線の中で生活する」ことが中心。
- バレー部とは独立して、教室と保健室だけでもルートとして成立するようになっている。

### 4.3 駅前ルート

学期選択時の基本効果

- `stress +16`
- ステージを `station` に変更
- `term_station` を再生

導入会話 `term_station`

- 駅前では視線が多く、自分の大きさを意識するという内容。
- その後、以下の2択がある。
  - `この高さも自分の一部だ`
    - `stress -5`
    - `self_confidence +1`
    - 会話先 `term_station_bold`
  - `やっぱり早く帰りたい`
    - `stress +5`
    - `self_complex +1`
    - 会話先 `term_station_shy`

ホットスポット

- `station_bench`
  - プロンプト: `ベンチで一息つく`
  - 会話: `term_station_bench`
  - `stress -4`
  - メモ追加: `駅のベンチで一息つき、人の流れを少し離れて眺めた。`
- `station_vending`
  - プロンプト: `自販機の前で立ち止まる`
  - 会話: `term_station_vending`
  - `stress +3`
  - メモ追加: `駅の自販機の前で、立ち止まるだけでも目立つと感じた。`

体験としての意味

- 駅前ルートは「人目の多さ」を一番強く受ける外部ルート。
- 現在の3ルートの中では、最も `stress` が上がりやすい。

## 5. 測定画面と学期の振り返り

測定画面では、現在以下の情報が出る。

- 年齢と学期
- 同学年平均との差
- 身長コメント
- `current_term_plan`
- `stress`
- `term_memory_note`
- `self_confidence - self_complex` のバランスに応じた振り返り文

つまり現在の測定画面は、

- 成長確認
- 感情状態の確認
- 今学期に何があったかの簡易アルバム

を兼ねている。

## 6. NPC会話の選択ルール

プレイヤーが NPC に `E` で話しかけた時、会話キーは以下の順で決まる。

### 共通ルール

- 名前なしNPCは常に `generic` 扱い。
- 名前ありNPCは `met_npcs` に登録されるまで `first_meet` が優先される。
- その後はキャラ固有条件、最後に身長差による `huge / tall / default` が選ばれる。

### 身長差による反応

- `差 >= 35cm`
  `huge`
- `差 >= 15cm`
  `tall`
- それ未満
  `default`

このルールは主に `generic` や一部NPCで使われる。

### はるか

- 初対面なら `first_meet`
- `is_leg_pain == true` かつ `vball_story_phase == 3`
  `vball_pain_consult`
- それ以外で、今学期まだ誘っていない場合
  `measure_invite`
- その後は身長差で `huge / tall`

### 先輩

- 初対面なら `first_meet`
- `phase == 1`
  `join_invite`
- `phase == 2` かつ `vball_joined == true`
  `practice_first`
- `phase == 3` かつ `is_leg_pain == true`
  `pain_concern`
- `phase == 6`
  `senior_after_summer`
- それ以外は身長差で `huge`

### 母・父

- 初対面なら `first_meet`
- 以後は基本的に `check`

### generic

- その都度初対面扱い
- 身長差で `huge / tall / default`

## 7. 現在のキャラクター別ストーリー内容

### 7.1 主人公モノローグ

現在 `player` に入っている主なモノローグ群

- `new_semester`
  新学期の始まり。
- `entrance_elementary`
  小学校入学。
- `entrance_middle`
  中学校入学。
- `entrance_high`
  高校入学。
- `summer_growth`
  夏休み急成長の通常版。
- `summer_growth_vball`
  バレー部文脈付きの急成長版。
- `term_home / term_school / term_station`
  学期選択後の導入。
- 各ホットスポット会話
  - `term_home_mirror`
  - `term_home_table`
  - `term_school_seat`
  - `term_school_infirmary`
  - `term_station_bench`
  - `term_station_vending`

### 7.2 はるか

役割

- 学校の友人
- 主人公の気持ちを聞く役
- バレー部ルートでは相談役

現在ある会話

- `first_meet`
- `tall`
- `huge`
- `measure_invite`
  - `measure_invite_proud`
  - `measure_invite_shy`
  - `measure_invite_unsure`
- `measure_after`
- `vball_join_cheer`
- `vball_pain_consult`
  - `pain_tell_senior`
  - `pain_endure`
- `haruka_after_summer`

### 7.3 バレー部先輩

役割

- 中学以降の高身長の価値を「戦力」として見る人物
- バレー部ストーリーの主導役

現在ある会話

- `first_meet`
- `huge`
- `join_invite`
  - `join_accepted`
  - `join_think`
  - `join_decline`
- `practice_first`
- `pain_concern`
- `senior_after_summer`
  - `vball_return`
  - `vball_manager`
  - `vball_retire`

### 7.4 家族

母

- `first_meet`
- `check`

父

- `first_meet`
- `check`

現在の家族会話は、

- 帰宅時の一言
- 伸びすぎへの驚き
- 制服や生活サイズのズレ

が中心。

### 7.5 先生・保健の先生

先生

- `semester_start`
  始業式と、背が伸びた主人公を後ろの席に座らせる導線。

保健の先生

- `default`
  保健室の通常会話。

現在、保健の先生はホットスポット会話の中で実質的に出番が増えているが、
独立した長い分岐はまだない。

### 7.6 generic NPC

役割

- 街や廊下で「他人からどう見えるか」を反射する存在。

現在ある会話

- `first_meet`
- `huge`
- `tall`
- `default`

## 8. バレー部ストーリーの詳細

`vball_story_phase` の意味

- `0`
  未接触
- `1`
  先輩と出会った後
- `2`
  入部済み
- `3`
  脚痛発生中
- `4`
  先輩へ報告済みイベント待ち
- `5`
  休部状態
- `6`
  夏休み明け
- `7`
  復帰または別の関わり方を決めた後

### フロー

1. 始業式導線から一度だけ `gym_senior_invite` が積まれる。
2. 体育館に入ると先輩の `first_meet`。
3. 会話終了後、`phase 0 -> 1`。
4. 以後、先輩に話しかけると `join_invite`。
5. `入部する！` を選ぶと
   - `vball_joined = true`
   - `phase = 2`
6. その後、先輩に再度話しかけると `practice_first`。
7. 会話終了後
   - `is_leg_pain = true`
   - `phase = 3`
8. この状態ではるかに話しかけると `vball_pain_consult`。
9. `先輩に伝えてもらう` を選ぶと
   - `phase = 4`
   - `vball_tell_senior` をキュー
10. 体育館で `pain_concern` 発火。
11. 会話終了後
   - `is_leg_pain = false`
   - `vball_joined = false`
   - `phase = 5`
12. 夏休みをまたぐと `phase 2-5` は `phase 6` へ進む。
13. `phase 6` の先輩会話 `senior_after_summer` で最終選択。
14. `また頑張りたい！`
   - `vball_joined = true`
   - `is_leg_pain = false`
   - `phase = 7`
15. `マネージャーとして関わりたい`
   - `vball_joined = false`
   - `is_leg_pain = false`
   - `phase = 7`
16. `今は勉強に集中したい……`
   - 追加アクションなし
   - 現実装では `phase` が進まない

### 重要なニュアンス

- 夏休み明け専用モノローグ `summer_growth_vball` は `vball_joined == true` の時しか使われない。
- 休部ルートで `phase 5` に入っていた場合、夏休み明けでもモノローグは通常版になるが、`phase` 自体は `6` に進む。
- `vball_retire` はテキスト自体はあるが、状態更新が未実装のため、実質的に暫定分岐になっている。

## 9. ステージごとの物語導線

### `myroom`

- 新規開始時の入学モノローグ発火地点。
- 学期開始直後の拠点。

### `room`

- 家ルートの中心。
- 母・父がいる。
- `summer_growth` の発火地点。
- 洗面台、食卓などのホーム系ホットスポットがある。

### `school`

- 学校ルートの中心。
- はるかがいる。
- 先生の始業式後に学校ルートの導入会話へ接続する。
- 自分の席ホットスポットがある。

### `school_hallway`

- 先輩との通常接触地点。

### `infirmary`

- 保健の先生がいる。
- 保健室相談ホットスポットがある。
- `haruka_following` 中なら、はるかが身長計付近に出現する。

### `gymnasium`

- バレー部先輩のイベント消化地点。

### `station`

- 駅前ルートの中心。
- ベンチ、自販機のホットスポットがある。

## 10. 現在の未完成・注意点

### はるか関連

- `measure_invite` 終了後に追随開始する処理がある。
- 測定後は `haruka.measure_after` に接続する。
- 会話キーと NPC ID は `haruka` に統一済み。

### はるか の命名整理

- `haruka_invited_this_term` というフラグ名がある。
- 現在は会話キーと NPC ID も `haruka` に統一している。
- ここは将来的に整理した方がよい。

### バレー部引退分岐

- `vball_retire` のセリフはある。
- ただし `action` がないため、最終状態が確定しない。

### エンディング

- 現時点では明確な卒業エンド、進路エンド、総括エンドは未実装。
- 測定画面の振り返りが、暫定的な章末まとめの役割を担っている。

## 11. 現在の物語の核

いまの実装で中心になっている物語は、次の3本です。

- 学期ごとに「どこで過ごすか」を選び、その場所でのしんどさや受け止め方が変わる物語
- 高身長に対する気持ちが `self_confidence / self_complex / stress` として蓄積される物語
- 中学以降、バレー部ルートを通じて「高身長が武器にも負担にもなる」ことを描く物語

言い換えると、現在のゲームは

- 成長そのもの
- 周囲の視線
- 自分の受け止め方
- 学校生活の中での身体の扱われ方

を、学期単位の小さな分岐として積み上げる形になっている。
