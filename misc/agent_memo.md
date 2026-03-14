# 2026-03-15 plan_by_agent.md レビュー

対象: `specs/plan_by_agent.md`

## 指摘

1. `npc_talk_*` の自動イベントは、計画書どおり `_load_stage()` の末尾で `queue_event()` すると、その場では発火しない。
   根拠:
   `MainScene.gd` は `_load_stage()` 内で先に `global.pop_next_event()` を処理している。
   そのため、同じ `_load_stage()` の後半で積んだイベントは次回のステージ遷移まで寝る。
   対応案:
   イベント投入を `pop_next_event()` より前に移すか、投入直後にその場で処理する導線を作る。

2. `npc_firstvisit_<stage_id>` 案は、現行の `record_stage_visit()` の呼び順だと初回判定が潰れる。
   根拠:
   `_load_stage()` 冒頭で `global.record_stage_visit(stage_id)` を先に呼んでいる。
   その後に `Global.is_first_visit(stage_id)` を見ても、常に false になる。
   対応案:
   `was_first_visit` を先に変数へ退避してから記録するか、記録タイミングを後ろへ移す。

3. `current_term_plan` 削除タスクの参照一覧に取りこぼしがある。
   未記載の主な参照:
   - `Global.gd` の `load_settings()` / `save_settings()`
   - `CharacterCreatorScene.gd`
   - `CodexSmokeRunner.gd`
   補足:
   `save_slot()` / `load_slot()` だけ消すと、再起動時やスモーク時に古い参照が残る。

4. 「再起動でフラグがリセットされる」問題は、`save_slot()` / `load_slot()` だけ直しても解決しない可能性がある。
   根拠:
   アプリ起動時の読み込み口は `Global._ready() -> load_settings()`。
   もし症状が「ゲーム再起動後の継続」で起きているなら、`settings.cfg` 側の保存対象も整理が必要。
   要確認:
   問題が出るのは「スロットロード時」か「アプリ再起動時」か。

5. `reach_low` / `reach_up` のサンプルコードは、現行 `CharacterPoseCalculator.gd` にそのままは貼れない。
   根拠:
   計画書では `d["arm_r_angle"] = ...` のように書いているが、現行実装はローカル変数を更新して最後に Dictionary を返す構造。
   対応案:
   サンプルも `arm_r_angle`, `arm_l_angle`, `waist_angle` をその分岐で直接更新する書き方に合わせる。

6. `StageBuilder.is_school_stage()` は現行コードに存在しない。
   既存 helper:
   - `is_school_classroom_stage()`
   - `is_school_hallway_stage()`
   - `is_schoolyard_stage()`
   対応案:
   新 helper を追加するか、対象ステージを明示列挙する。

## 確認したいこと

1. `npc_talk_huge` は自動発火イベントでも選択肢つき会話にしたいか。
   現状の受動イベント方針と揃えるなら、まずは選択肢なしの短い会話でもよさそう。

   →選択肢付きにする。そうでないと、受動とは言えない

2. `current_term_plan` 削除後、既存の `term_home` / `term_station` / `TERM_CHOICES` は削除するか。
   ホットスポット専用モノローグとして再利用するなら、消す範囲が変わる。

   →デッドコードはすべて削除してよい。

## 削除方針メモ

- `term_home` / `term_station` は、現状の通常導線では発火元が見当たらないため削除対象。
- `TERM_CHOICES` は表示用参照を外したあとで丸ごと削除してよい。
- `TERM_CHOICE_ORDER` も未使用のため削除してよい。
- `current_term_plan` にぶら下がる表示文言、保存処理、スモーク初期化、キャラメイク初期化もまとめて削除対象。
- ただし `term_home_mirror` / `term_home_table` / `term_station_bench` / `term_station_vending` など、ホットスポット会話として現役化できるものは「デッドコード」ではなく再利用対象として残す。

## メモ

- `visited_stages` と `experienced_events` は現行 `Global.gd` にすでに追加済み。
- `IntroScene` / `EndingScene` まわりの前回レビュー指摘は、今回の版では概ね整理されている。
