# プロジェクト仕様書

このドキュメントは **Tall Life Simulator** の現行実装に対応した高レベル仕様です。  
詳細なステージ構成や NPC 反応の一覧は、別ドキュメントを参照してください。

## 関連ドキュメント

- ステージ構成・接続・NPC配置: [stage_design.md](stage_design.md)
- キャラクター描画: [character_drawing_system.md](character_drawing_system.md)
- ポーズと姿勢: [character_pose_spec.md](character_pose_spec.md)
- 髪描画: [hair_drawing_system.md](hair_drawing_system.md)
- 服装・髪のロジック: [clothing_and_hair_logic.md](clothing_and_hair_logic.md)
- 物語・会話仕様: [story_doalogue.md/dialogue_trigger_spec.md](story_doalogue.md/dialogue_trigger_spec.md), [story_doalogue.md/game_story_spec.md](story_doalogue.md/game_story_spec.md)

## 1. ゲーム概要

本作は、高身長の少女が成長しながら日常空間と学校生活を過ごすシミュレーションゲームです。

- 身長の伸びによって、同じ場所や同じ物体の見え方・使いにくさが変わる
- 学校、家、駅、通学路での体験が、ストレスや自己認識に影響する
- NPC との会話、学期イベント、身体測定を通して物語が進む
- キャラクターの見た目は 2D 手描きベースで、正面・側面・ポーズ変化に対応する

## 2. 現行のゲーム進行仕様

### 2-1. 進行単位

旧仕様の「1ターン = 1学期」は廃止されています。  
現行実装では、**学期 > 日 > 行動** の3段階で進行します。

| 単位 | 現行仕様 |
| --- | --- |
| 学期 | `term` で管理。進級・進学・成長の基準単位 |
| 日 | `day_in_term` で管理。1学期は `term_total_days = 30` 日 |
| 行動 | `actions_today` で管理。1日の目安は `max_actions_per_day = 3` |

### 2-2. 1日の進み方

- ドア移動 `door_to_*` は 1 行動消費する
- 画面端移動は現在 `outdoor -> adjacent_town` と `adjacent_town -> outdoor` のみ実装されており、これも 1 行動消費する
- NPC との会話、term hotspot、身体測定そのものは現状では行動消費しない
- `actions_today >= max_actions_per_day` になると HUD 上で「今日はもう夕方だ」という警告が出る
- ただし現状はソフト制限であり、行動そのものは強制停止しない

### 2-3. 日送り

日送りは `myroom` の `bed` から行います。

- `今日を終える`: `day_in_term += 1`
- `学期末まで一気に進める`: `day_in_term = term_total_days`
- 日送り時に `actions_today` は 0 に戻る
- 日送り後はフェード演出を挟み、`myroom` に戻る

### 2-4. 学期末と身体測定

`day_in_term >= term_total_days` になると、`term_end_measurement` イベントが予約されます。

- 学期末イベントは `myroom` で消化される
- 学期末イベントの消化時に `Global.advance_term()` が呼ばれる
- 学期進行後に身体測定結果パネルを表示する
- 身体測定パネルを閉じると `myroom` に戻る

このため、現行実装では **「学期末に測定して次の学期へ進む」** 流れになっています。

### 2-5. 学校内の時間進行

教室で学期イベント会話 `term_school` を消化すると、放課後演出を経て廊下へ移ります。

- 教室で会話
- 「放課後になった。」の演出
- `school_hallway_*` へ移動
- 帰り道や寄り道のフェーズへ移行

### 2-6. 成長処理

学期進行時には以下がまとめて更新されます。

- `term` の増加
- `age` の再計算
- `current_params["height"]` の成長
- 頭身比 `ratio` の自動更新
- 学校段階が変わった場合の制服更新
- `haruka_invited_this_term` など学期内フラグのリセット
- `term_hotspot_flags` と `term_memory_note` のリセット
- `semester_start` イベントの予約

夏休み区間では急成長ボーナスも入ります。

### 2-7. 感情・記録

進行と並行して、以下の状態が蓄積されます。

- `stress`: 今学期のしんどさ
- `self_confidence`: 自己肯定寄りの蓄積
- `self_complex`: コンプレックス寄りの蓄積
- `term_hotspot_flags`: 今学期に触れたイベント地点
- `term_memory_note`: 今学期の印象的な出来事メモ
- `visited_stages`, `experienced_events`: 通算ログ

## 3. ステージ仕様

ステージは `StageBuilder.gd` が構築します。  
学校系ステージは年齢に応じて実ステージ ID に解決されます。

| ベースID | 11歳以下 | 12〜14歳 | 15歳以上 |
| --- | --- | --- | --- |
| `school_hallway` | `school_hallway_elementary` | `school_hallway_middle` | `school_hallway_high` |
| `school` | `school_elementary` | `school_middle` | `school_high` |
| `schoolyard` | `schoolyard_elementary` | `schoolyard_middle` | `schoolyard_high` |
| `infirmary` | `infirmary_elementary` | `infirmary_middle` | `infirmary_high` |
| `gymnasium` | `gymnasium_elementary` | `gymnasium_middle` | `gymnasium_high` |

現行ルートの要点は以下です。

- 家まわり: `myroom <-> room <-> outdoor`
- 中学ルート: `outdoor` 右端 `-> adjacent_town -> school_hallway_middle`
- 高校ルート: `station -> platform -> train -> gakuenmae -> gakuenmachi -> school_hallway_high`
- 小学校ルート: `outdoor -> school_hallway_elementary`

ステージごとの接続、比較対象オブジェクト、インタラクト対象、NPC 反応の詳細は [stage_design.md](stage_design.md) を参照してください。

## 4. NPC と会話

NPC システムは主に `MainScene.gd`、`DialogueDatabase.gd`、`SkeletalNPC.gd` を中心に構成されています。

- 固有 NPC: `haruka`, `nurse`, `senior`, `mother`, `father`
- 汎用 NPC: `generic` として扱う
- 身長差やストーリーフラグに応じて会話キーを切り替える
- 一部 NPC は学期内フラグや部活ストーリー段階に依存して分岐する

NPC の出現場所や反応傾向は [stage_design.md](stage_design.md) を参照してください。

## 5. 主要システムと対応ファイル

| 系統 | 主なファイル | 役割 |
| --- | --- | --- |
| グローバル状態管理 | `godot-project/scripts/Global.gd` | 成長、学期進行、感情値、保存データの管理 |
| メインシーン進行 | `godot-project/scripts/MainScene.gd` | UI、移動、会話、日送り、学期末処理、測定表示 |
| ステージ構築 | `godot-project/scripts/StageBuilder.gd` | ステージ背景、障害物、接続、年齢別学校解決 |
| 会話データ | `godot-project/scripts/DialogueDatabase.gd` | NPC・プレイヤー会話定義 |
| プレイヤー描画 | `godot-project/scripts/CharacterDrawer.gd` ほか | 正面・側面・髪・服装・体型描画 |
| プレイヤー姿勢 | `godot-project/scripts/CharacterPoseCalculator.gd`, `godot-project/scripts/SkeletalPlayer.gd` | しゃがみ、頭ぶつけ、姿勢制御 |
| NPC 表示 | `godot-project/scripts/SkeletalNPC.gd` | NPC の見た目と基本挙動 |

## 6. UI 仕様の要点

現行のメイン画面では以下の情報を常時表示します。

- 左上: `Q: ステータス設定`
- 上中央: 現在のステージ名
- 右上: `◯日目 行動 x/y`
- 右下: 現在その場で可能な操作ヒント
- 左上付近: ミニマップバー

補助 UI として以下があります。

- ポーズメニュー
- 日送り用スリープメニュー
- 身体測定結果パネル
- 進級時の続行 / 終了選択パネル

## 7. 保存仕様

保存は `ConfigFile` ベースで行います。

| 種類 | パス | 内容 |
| --- | --- | --- |
| 設定保存 | `user://settings.cfg` | 現在のプレイヤー状態、感情値、学期フラグ、見た目、システム設定 |
| セーブスロット | `user://save_slots.cfg` | スロット別のプレイ状況保存 |

保存対象の主な内容:

- 身長、頭身、脚比率、性別
- 見た目設定
- `current_stage_id`
- `age`, `term`, `day_in_term`, `actions_today`
- 成長履歴
- `stress`, `self_confidence`, `self_complex`
- 学期フラグ、部活フラグ、同行フラグ
- 訪問済みステージ、体験済みイベント

## 8. 現行仕様として明記しておく点

- 旧仕様の「1ターン = 1学期」は現行実装では採用していない
- 現在は **1学期 = 30日**, **1日 = 複数行動**, **ベッドで日送り** の構造
- 学期末の身体測定は `myroom` に戻ってから処理される
- ステージ構成は駅ルートと隣町ルートを含む複数ハブ型になっている
- ステージ詳細や NPC 反応は [stage_design.md](stage_design.md) を正とする
