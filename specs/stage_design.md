# ステージ設計（現行実装ベース）

このドキュメントは `godot-project/scripts/StageBuilder.gd` と `godot-project/scripts/MainScene.gd` の現行実装を基準に整理したものです。  
特に、以下を実装準拠でまとめ直しています。

- どの時点でアクセス可能か
- どのステージとどうつながっているか
- 身長比較の対象になる主なオブジェクト
- `E` キーでインタラクトできる対象
- 各ステージにいる NPC の特徴

## 1. 共通ルール

### 1-1. 年齢で解決されるベースステージ ID

学校系の一部ステージは、内部ではベース ID を年齢で実ステージ ID に解決します。

| ベースID | 11歳以下 | 12〜14歳 | 15歳以上 |
| --- | --- | --- | --- |
| `school_hallway` | `school_hallway_elementary` | `school_hallway_middle` | `school_hallway_high` |
| `school` | `school_elementary` | `school_middle` | `school_high` |
| `schoolyard` | `schoolyard_elementary` | `schoolyard_middle` | `schoolyard_high` |
| `infirmary` | `infirmary_elementary` | `infirmary_middle` | `infirmary_high` |
| `gymnasium` | `gymnasium_elementary` | `gymnasium_middle` | `gymnasium_high` |

### 1-2. 移動と進行

- `door_to_*` のドア移動は 1 行動消費する
- 画面端移動は現在 `outdoor -> adjacent_town` と `adjacent_town -> outdoor` のみで、これも 1 行動消費する
- `myroom` の `bed` は特別インタラクトで、その日の終了か学期末までスキップを選べる
- `height_scale` に触れると身体測定結果パネルを開く
- NPC 会話、term hotspot、身体測定そのものは現状では行動消費しない
- `actions_today >= max_actions_per_day(=3)` になると警告は出るが、移動自体は止まらない

### 1-3. ロックの考え方

年齢制限は主に `MainScene.gd` のドアロックで管理されています。

| 対象 | 実装上のアクセス条件 |
| --- | --- |
| `school_hallway_elementary`, `school_elementary` | 11歳以下のみ |
| `school_hallway_middle`, `school_middle`, `schoolyard_middle`, `infirmary_middle`, `gymnasium_middle` | 12〜14歳のみ |
| `school_hallway_high`, `school_high` | 15歳以上のみ |
| `schoolyard_elementary`, `infirmary_elementary`, `gymnasium_elementary` | 明示ロックはないが、小学校廊下経由なので実質 11歳以下 |
| `schoolyard_high`, `infirmary_high`, `gymnasium_high` | 明示ロックはないが、高校廊下経由なので実質 15歳以上 |

### 1-4. インタラクトの種類

| 種類 | 対象 | 内容 |
| --- | --- | --- |
| ドア移動 | `door_to_*` | ステージ移動。ロック時はメッセージのみ表示 |
| 画面端移動 | edge trigger | `outdoor` と `adjacent_town` の相互移動 |
| 休む | `myroom` の `bed` | 日送り / 学期末送り |
| 身体測定 | `height_scale` | 測定結果パネルを開く |
| term hotspot | 特定障害物 | 学期ごとの一回イベント |
| NPC 会話 | NPC | 固有会話か汎用会話を再生 |

## 2. 全体接続

### 2-1. ワールド全体の導線

```text
myroom
  ↕
room
  ↕
outdoor ──↔ station ──↔ platform ──↔ train ──↔ gakuenmae ──↔ gakuenmachi ──→ school_hallway_high
  │                                                        （15歳未満は高校廊下でロック）
  ├──→ school_hallway_elementary
  │   （12歳以降はロック）
  └── 右端 ↔ adjacent_town ──→ school_hallway_middle
      （12〜14歳のみ中学廊下へ入れる）
```

### 2-2. 学校内部の導線

すべての学校ルートは以下の構造です。

```text
school_hallway_* ↔ school_*
school_hallway_* ↔ schoolyard_*
school_hallway_* ↔ infirmary_*
school_hallway_* ↔ gymnasium_*
```

学校の入口だけが年齢で変わります。

- 小学校: `outdoor -> school_hallway_elementary`
- 中学校: `adjacent_town -> school_hallway_middle`
- 高校: `gakuenmachi -> school_hallway_high`

### 2-3. 年齢ごとの実質アクセス範囲

| 年齢帯 | 学校入口 | 通学ルート | 備考 |
| --- | --- | --- | --- |
| 11歳以下 | `school_hallway_elementary` | `outdoor` から直接入る | `adjacent_town` と `gakuenmachi` 自体は見に行けるが学校ドアは通れない |
| 12〜14歳 | `school_hallway_middle` | `outdoor` 右端 -> `adjacent_town` | 小学校入口はロックされる |
| 15歳以上 | `school_hallway_high` | `station -> platform -> train -> gakuenmae -> gakuenmachi` | 中学校入口はロックされる |

## 3. ステージ詳細

### 3-1. 家まわり

| Stage ID | 表示名 | アクセス可能時期 | 主な接続 | 主な比較対象（ドア以外） | `E` でできること | NPC |
| --- | --- | --- | --- | --- | --- | --- |
| `myroom` | 自分の部屋 | 常時 | `door_to_room` | `bed`, `window_myroom`, `bookshelf`, `desk_myroom`, `randoseru` | `bed` で休む、ドア移動 | なし |
| `room` | 家の中 | 常時 | `door_to_outdoor`, `door_to_myroom` | `ceiling_light`, `refrigerator`, `kitchen_cabinet`, `kitchen_counter`, `range_hood`, `table`, `window_1`, `washstand`, `bathtub`, `shower_nozzle` | ドア移動、term hotspot (`washstand`, `table`, `chair`)、母・父と会話 | `mother`, `father` |
| `outdoor` | 屋外 | 常時 | `door_to_room`, `door_to_station`, `door_to_school_hallway_elementary`, 右端で `adjacent_town` | `mailbox`, `traffic_signal`, `vending_machine`, `car`, `bus_stop_sign` | ドア移動、右端移動、汎用NPCと会話 | 通行人1人、子ども1人 |

補足:

- `myroom` の `bed` だけが進行システムに直結する特別インタラクト
- `room` の `washstand` と `table/chair` は学期ごとに一度だけ触れられる hotspot
- `outdoor` の `door_to_school_hallway_elementary` は 12歳以降ロックされる

### 3-2. 駅・移動系

| Stage ID | 表示名 | アクセス可能時期 | 主な接続 | 主な比較対象（ドア以外） | `E` でできること | NPC |
| --- | --- | --- | --- | --- | --- | --- |
| `station` | 駅 | 常時 | `door_to_outdoor`, `door_to_platform` | `ticket_gate`, `station_bench`, `timetable`, `station_vending` | ドア移動、term hotspot (`station_bench`, `station_vending`) | なし |
| `platform` | ホーム | 常時 | `door_to_station`, `door_to_train` | `platform_column_1`, `platform_bench`, `platform_column_2` | ドア移動 | 汎用NPC 1人 |
| `train` | 電車の中 | 常時 | `door_to_platform`, `door_to_gakuenmae` | `train_seat_1..3`, `strap_1..10` | ドア移動 | なし |
| `gakuenmae` | 学園前駅 | 常時 | `door_to_train`, `door_to_gakuenmachi` | `station_sign_gakuenmae`, `platform_bench_small` | ドア移動 | 高校生風の汎用NPC 1人 |
| `gakuenmachi` | 学園街 | 常時 | `door_to_gakuenmae`, `door_to_school_hallway_high` | `shop_awning`, `notice_board_town`, `school_gate_high` | ドア移動。高校廊下へのドアは 15歳未満ロック | 高校生風の汎用NPC 1人、街の住人風NPC 1人 |
| `adjacent_town` | 隣町 | 常時 | 左端で `outdoor`, `door_to_school_hallway_middle` | `town_tree`, `town_bench`, `school_gate_middle` | 左端移動、ドア移動。中学廊下へのドアは 12〜14歳のみ | 中学生風の汎用NPC 1人、住人風NPC 1人 |

補足:

- `station -> train` の直通はなくなり、必ず `platform` を経由する
- 高校ルートは `train -> gakuenmae -> gakuenmachi -> school_hallway_high`
- 中学校ルートは駅経由ではなく、`outdoor` 右端から `adjacent_town` を経由する
- `adjacent_town` と `gakuenmachi` 自体には年齢制限がない

### 3-3. 小学校ルート（11歳以下）

| Stage ID | 表示名 | 主な接続 | 主な比較対象（ドア以外） | `E` でできること | NPC |
| --- | --- | --- | --- | --- | --- |
| `school_hallway_elementary` | 小学校の廊下 | `door_to_outdoor`, `door_to_school_elementary`, `door_to_schoolyard_elementary`, `door_to_infirmary_elementary`, `door_to_gymnasium_elementary` | `shoes_locker`, `bulletin_board`, `fire_hydrant` | 各部屋へ移動、会話 | 汎用生徒 1人、`haruka` |
| `school_elementary` | 小学校 | `door_to_school_hallway_elementary` | `blackboard`, `teacher_desk`, `display_board`, `desk_1`, `desk_2`, `student_chair_1`, `student_chair_2` | 教室出入り、term hotspot (`desk_*`, `student_chair_*`)、会話 | `haruka`, 汎用クラスメイト 1人 |
| `schoolyard_elementary` | 小学校の校庭 | `door_to_school_hallway_elementary` | `horizontal_bar_low`, `horizontal_bar_high`, `jungle_gym`, `basketball_hoop`, `soccer_goal_post` | 廊下へ戻る | なし |
| `infirmary_elementary` | 小学校の保健室 | `door_to_school_hallway_elementary` | `medicine_cabinet`, `height_scale`, `weight_scale`, `infirmary_desk`, `infirmary_bed`, `infirmary_curtain` | 廊下へ戻る、身体測定、term hotspot (`infirmary_bed`)、会話 | `nurse`、状況次第で `haruka` |
| `gymnasium_elementary` | 小学校の体育館 | `door_to_school_hallway_elementary` | `gym_storage`, `volleyball_net`, `gym_bench`, `gym_window_1`, `gym_window_2`, `basketball_board` | 廊下へ戻る、term hotspot (`basketball_board`, 身長185cm以上)、会話 | `senior` |

補足:

- 小学校教室の比較物は `display_board` が特徴
- 校庭は遊具がもっとも多く、身長比較用の見せ場が強い
- `senior` は現状 `gymnasium_*` 全域に配置されている

### 3-4. 中学校ルート（12〜14歳）

| Stage ID | 表示名 | 主な接続 | 主な比較対象（ドア以外） | `E` でできること | NPC |
| --- | --- | --- | --- | --- | --- |
| `school_hallway_middle` | 中学校の廊下 | `door_to_adjacent_town`, `door_to_school_middle`, `door_to_schoolyard_middle`, `door_to_infirmary_middle`, `door_to_gymnasium_middle` | `shoes_locker`, `bulletin_board`, `fire_hydrant` | 各部屋へ移動、会話 | 汎用生徒 1人、`haruka` |
| `school_middle` | 中学校 | `door_to_school_hallway_middle` | `blackboard`, `teacher_desk`, `locker`, `desk_1`, `desk_2`, `student_chair_1`, `student_chair_2` | 教室出入り、term hotspot (`desk_*`, `student_chair_*`)、会話 | `haruka`, 汎用クラスメイト 1人 |
| `schoolyard_middle` | 中学校の校庭 | `door_to_school_hallway_middle` | `horizontal_bar_high`, `basketball_hoop`, `soccer_goal_post` | 廊下へ戻る | なし |
| `infirmary_middle` | 中学校の保健室 | `door_to_school_hallway_middle` | `medicine_cabinet`, `height_scale`, `weight_scale`, `infirmary_desk`, `infirmary_bed`, `infirmary_curtain` | 廊下へ戻る、身体測定、term hotspot (`infirmary_bed`)、会話 | `nurse`、状況次第で `haruka` |
| `gymnasium_middle` | 中学校の体育館 | `door_to_school_hallway_middle` | `gym_storage`, `volleyball_net`, `gym_bench`, `gym_window_1`, `gym_window_2`, `basketball_board` | 廊下へ戻る、term hotspot (`basketball_board`, 身長185cm以上)、会話 | `senior` |

補足:

- 中学校教室は `locker` が小学校との差分
- 中学校校庭は `jungle_gym` がなくなり、比較対象が絞られる
- 中学校ルートの入口は `adjacent_town` 固定

### 3-5. 高校ルート（15歳以上）

| Stage ID | 表示名 | 主な接続 | 主な比較対象（ドア以外） | `E` でできること | NPC |
| --- | --- | --- | --- | --- | --- |
| `school_hallway_high` | 高校の廊下 | `door_to_gakuenmachi`, `door_to_school_high`, `door_to_schoolyard_high`, `door_to_infirmary_high`, `door_to_gymnasium_high` | `shoes_locker`, `bulletin_board`, `fire_hydrant` | 各部屋へ移動、会話 | 汎用生徒 1人、`haruka`, `senior` |
| `school_high` | 高校 | `door_to_school_hallway_high` | `blackboard`, `teacher_desk`, `locker_high`, `desk_1`, `desk_2`, `student_chair_1`, `student_chair_2`, `window_back` | 教室出入り、term hotspot (`desk_*`, `student_chair_*`)、会話 | `haruka`, 汎用クラスメイト 1人, `senior` |
| `schoolyard_high` | 高校の校庭 | `door_to_school_hallway_high` | `gym_bench`, `basketball_hoop`, `soccer_goal_post` | 廊下へ戻る | なし |
| `infirmary_high` | 高校の保健室 | `door_to_school_hallway_high` | `medicine_cabinet`, `height_scale`, `weight_scale`, `infirmary_desk`, `infirmary_bed`, `infirmary_curtain` | 廊下へ戻る、身体測定、term hotspot (`infirmary_bed`)、会話 | `nurse`、状況次第で `haruka` |
| `gymnasium_high` | 高校の体育館 | `door_to_school_hallway_high` | `gym_storage`, `volleyball_net`, `gym_bench`, `gym_window_1`, `gym_window_2`, `basketball_board` | 廊下へ戻る、term hotspot (`basketball_board`, 身長185cm以上)、会話 | `senior` |

補足:

- 高校教室は `locker_high` と `window_back` が追加差分
- 高校廊下と高校教室には `senior` が常駐し、バレー部まわりの会話導線が発生する
- 高校ルートへ入るには `gakuenmachi` を経由する

## 4. 学期イベント hotspot 一覧

学期 hotspot は 1 学期に 1 回だけ発火する、障害物ベースのイベントです。

| hotspot ID | 実際の設置ステージ | 対象オブジェクト | 条件 | 内容 |
| --- | --- | --- | --- | --- |
| `home_mirror` | `room` | `washstand` | なし | 鏡を見る。ストレス軽減 |
| `home_table` | `room` | `table`, `chair` | なし | 食卓で一息つく |
| `school_seat` | `school_*` | `desk_1`, `desk_2`, `student_chair_1`, `student_chair_2` | なし | 自分の席に座る |
| `school_infirmary` | `infirmary_*` | `infirmary_bed` | なし | 保健室で相談する |
| `station_bench` | `station` | `station_bench` | なし | ベンチで一息つく |
| `station_vending` | `station` | `station_vending` | なし | 自販機の前で立ち止まる |
| `gymnasium_basket` | `gymnasium_*` | `basketball_board` | 身長 185cm 以上 | バスケゴールに手を伸ばす |

補足:

- `school_*`, `infirmary_*`, `gymnasium_*` は現在年齢に応じた実ステージへ解決される
- hotspot は会話とメモ追記に寄っており、移動とは別レイヤーの進行要素

## 5. NPC の特徴まとめ

### 5-1. 固有 NPC

| NPC ID | 主な出現場所 | 役割 / 特徴 |
| --- | --- | --- |
| `mother` | `room` | 家で話せる保護者。ストレス状態に応じた反応がある |
| `father` | `room` | 家で話せる保護者。`check` 分岐あり |
| `haruka` | `school_hallway_*`, `school_*`, 条件次第で `infirmary_*` | 学校導線の中心人物。初対面、支援、測定への誘導、脚の痛み相談などの分岐を持つ |
| `nurse` | `infirmary_*` | 保健室の先生。測定・相談まわりの会話担当 |
| `senior` | `school_hallway_high`, `school_high`, `gymnasium_*` | バレー部まわりの先輩。加入誘導や痛みイベントの分岐を持つ |

### 5-2. 汎用 NPC

固有 ID を持たない NPC は `generic` 扱いです。

- `outdoor`: 大人 1 人、子ども 1 人
- `adjacent_town`: 中学生風の通行人 1 人、住人風 1 人
- `platform`: 通勤客風 1 人
- `gakuenmae`: 高校生風 1 人
- `gakuenmachi`: 高校生風 1 人、街の住人風 1 人
- `school_hallway_*`: 制服姿の生徒 1 人
- `school_*`: クラスメイト 1 人

汎用 NPC の会話仕様:

- 毎回「初対面扱い」で話す
- プレイヤーとの身長差で `default / tall / huge` の会話に分岐する
- ステージごとに服装・髪型だけ変えて、世界観の役割を表現している

## 6. 現行実装の注意点

- `adjacent_town` と `gakuenmachi` はハブとして常時入れるが、その先の学校ドアに年齢ロックがある
- 中学校導線は「駅から学校へ」ではなく、`outdoor` の右端スクロールで入る
- 高校導線は `station -> platform -> train -> gakuenmae -> gakuenmachi` と段階的に長くなっている
- `station`, `train`, `schoolyard_*` には現状固有 NPC がいない
- `myroom` は生活進行専用の部屋で、比較物は少ないが進行上の重要度は高い
