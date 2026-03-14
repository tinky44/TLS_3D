# 実装計画メモ（AI用）

更新日: 2026-03-14
ブランチ: `feat/add-story-stage-npcReaction`

---

## スコープ

| # | 内容 | 関連issue |
|---|---|---|
| A | 学校ステージの小中高分岐（背景・配置物） | #43 |
| B | コアNPCの制服を学年連動させる | #43 |
| C | ポニーテール・サイドテール追加 | #29 |
| D | 靴の場所自動切り替え | #39 |
| E | NPCの動き（パトロール）+ 会話バランス | #43, #39 |

---

## A. 学校ステージの小中高分岐

### 現状
- `school` / `school_hallway` は単一ステージID、`age` で色・机サイズのみ変わる
- 小学生：`outdoor` → `school_hallway`（直接）
- 中学以上：`outdoor` の学校ドアが消え、`station` → `school_hallway`（同じIDのまま）
- 小中高が同じ場所を共有 → 小学校が中学生になると消えてしまう

### 目標ナビゲーション構造

```
outdoor ──→ [小学校] ※常に存在（中学生・高校生でも消えない）
               └─ 中が現役でない場合は「懐かしいな」とだけ言って通過不可でもOK
                  （将来的に改善可）

station ──→ [中学校廊下]  ← 中学生以上で出現

train（2番ドア）──→ [高校廊下]  ← 高校生以上で出現
```

### 新規・変更するステージID

| 旧ID | 新ID | 用途 |
|---|---|---|
| `school_hallway`（小学用） | `school_hallway_elementary` | 小学校廊下（常時accessible） |
| `school`（小学用） | `school_elementary` | 小学校教室（age≤11のみ入れる） |
| `school_hallway`（中学用） | `school_hallway_middle` | 中学校廊下（station経由） |
| `school`（中学用） | `school_middle` | 中学校教室（age 12-14） |
| *(新規)* | `school_hallway_high` | 高校廊下（train 2番ドア経由） |
| *(新規)* | `school_high` | 高校教室（age 15+） |

> 段階的実装でもOK：まず `school_elementary_hallway` を `outdoor` に常時残す修正だけ先にやり、中高の分離は後回しにしてもよい。

### 修正箇所

**`StageBuilder.gd`**：
- 上記6ステージのビルド関数を追加（各 `_build_***()` 関数）
- 既存の `school` / `school_hallway` の age 分岐を除去し、ステージID で完全分離
- 各ステージの配置物・テキストの差異：

| 要素 | 小学（0/1） | 中学（2） | 高校（3） |
|---|---|---|---|
| 黒板メッセージ | 「がんばろう！」 | 「今日の目標」 | 「〇日 センター試験」 |
| 掲示エリア | 暖色・図工作品 | 習字・理科ポスター | 大学ポスター |
| 机のサイズ（幅） | 60 | 70 | 70 |

**`MainScene.gd`** のドア接続・age 分岐部分：
- `outdoor` → `school_hallway_elementary` 常に接続（age 問わず）
  - age > 11 のとき、ドアに触れると「懐かしいな…」メッセージのみ表示、遷移なし
- `station` → `school_hallway_middle`（age ≥ 12 で有効化）
- `train` の2番ドア（`door_2`）→ `door_to_school_hallway_high` にリネーム（age ≥ 15 で有効化）

**`train` ステージ**（`StageBuilder.gd`）：
- 現在4枚のドアが描画済み（door_to_station / door_2 / door_3 / door_4）
- `door_2`（x:580-760）を `door_to_school_hallway_high` にリネームするだけで接続完了
  - 命名規則「door_to_XXX → XXXステージへ遷移」を利用
  - age ≥ 15 のとき有効化、それ以外はインタラクト不可（age 分岐は MainScene 側で制御）

**`MainScene.gd`** の `_spawn_npcs()`：
- NPC配置を stage_id で完全分離
  - `school_hallway_elementary` / `school_elementary`：小学生NPC + はるか（小学制服）
  - `school_hallway_middle` / `school_middle`：中学生NPC + はるか（中学制服）
  - `school_hallway_high` / `school_high`：高校生NPC + はるか + 先輩（高校制服）

**schoolyard / infirmary / gymnasium も学校段階ごとに分離**：
- `schoolyard_elementary` / `schoolyard_middle` / `schoolyard_high`
- `infirmary_elementary` / `infirmary_middle` / `infirmary_high`
- `gymnasium_elementary` / `gymnasium_middle` / `gymnasium_high`
- 内容の差異（掲示・備品等）は学校段階に応じて変える
- 各 `school_hallway_*` から対応する学校段階の子ステージへ接続

> **将来タスク（今回対象外）**: station → train の間にホームステージ（`platform`）を挟む
> 現状は station から直接 train 内部に入る構造で不自然だが、今回のスコープ外とする

---

## B. コアNPCの制服を学年連動させる

### 現状
- `SkeletalNPC.gd` の `_ready()` で `Global.core_npcs[npc_id].appearance` をそのまま適用
- はるか・先輩などの制服はハードコードで固定、進級しても変わらない

### 目標
- コアNPCのうち「学校関係者（生徒）」は、プレイヤーと同じ `get_school_uniform(age)` で制服を上書きする

### 修正箇所
**`SkeletalNPC.gd`** の `_ready()` 内、appearance 適用後に以下を追加：
```gdscript
# 学生キャラは学年に合わせた制服を適用
if npc_data.get("is_student", false):
    var uniform = Global.get_school_uniform(Global.age)
    for key in uniform:
        appearance[key] = uniform[key]
```

**`Global.gd`** の `core_npcs` 定義に `"is_student": true` を追加：
- `haruka` → `is_student: true`
- `senior` → `is_student: true`
- `mother` / `father` → 追加しない（大人なので）

**`Global.gd`** の `advance_term()` 内で学年が変わったとき、シーン上のNPCにも通知する仕組みが必要：
- `SceneTree` を使って `SkeletalNPC` 全インスタンスに `update_uniform()` シグナルを送るか、
- NPCが `_process` で毎フレーム `Global.age` を監視して差異があれば更新する（シンプル）

→ **シンプル案採用**: `SkeletalNPC._ready()` で初回のみ適用。進級時は MainScene がステージ再構築するタイミングでNPCも再スポーンされるため、自動的に反映される想定。要確認。

---

## C. ポニーテール・サイドテールの追加

### 現状
- `CharacterHairDrawer.gd` に `short` / `long` のみ

### 追加する髪型
- `ponytail` — 後頭部でひとまとめ、尾が背中に垂れる
- `side_tail` — 片側（右）でまとめる、尾が肩前方に垂れる

### 修正箇所
**`CharacterHairDrawer.gd`**:
- `draw_hair_base_layer()` に `ponytail` / `side_tail` 分岐を追加
  - ベース部分は `short` と同じ（まとめた根元）
  - 尾部分を別ポリゴンで描画（紡錘形 or 細長い多角形）
- `draw_hair()` の正面・側面・背面それぞれに分岐追加
  - 正面：サイドにまとめ点 + 尾が下に流れる
  - 側面：後頭部のまとめ点から後方へ流れる弧
  - 背面：尾が垂れ下がる

**`Global.gd`** の `core_npcs` 更新：
- はるか → `hair_style: "ponytail"` に変更（バリエーションとして）
- 廊下の名無し女子 → `side_tail`（MainScene.gd の _spawn_npcs で指定）

---

## D. 靴の場所自動切り替え

### 現状
- 靴の概念なし

### 目標
場所（ステージ）に応じて靴を自動切り替え：
- 部屋（room, myroom）→ 靴下のみ
- 学校内（school_elementary / school_middle / school_high / school_hallway_* / infirmary / gymnasium）→ 上履き
- 屋外・電車・駅 → ローファー

### 修正箇所
**`Global.gd`** に `get_shoes_for_stage(stage_id: String) -> String` を追加：
```gdscript
func get_shoes_for_stage(stage_id: String) -> String:
    var indoor_school = [
        "school_elementary", "school_middle", "school_high",
        "school_hallway_elementary", "school_hallway_middle", "school_hallway_high",
        "infirmary", "gymnasium"
    ]
    var room_stages = ["room", "myroom"]
    if stage_id in indoor_school:
        return "uwabaki"
    elif stage_id in room_stages:
        return "socks"
    else:
        return "loafer"
```

**`MainScene.gd`** のステージ切り替え時（`_change_stage()` 相当）で `current_appearance.shoes_type` を更新。

**`CharacterBodyDrawer.gd`** or `CharacterDrawFront.gd` に靴の描画を追加：
- `uwabaki`：足先に白い台形 + 先端に赤いライン
- `loafer`：足先に濃いグレーの台形
- `socks`：足先の色をスキントーンより薄い白系に

---

## E. NPCの動き（パトロール）+ 会話バランス

### 現状
- NPCは立ち止まっているだけ（後ずさりのみ）
- 会話イベントがネガティブ寄り

### NPCパトロール
**`SkeletalNPC.gd`** に簡易パトロールを追加：
- `patrol_range: float = 80.0` — スポーン位置から左右に動く距離
- `patrol_dir: int = 1` — 現在の移動方向（1 or -1）
- `_process(delta)` で `position.x += patrol_speed * patrol_dir * delta` して、端まで来たら反転
- プレイヤーが近づいたら（REACTION_DIST以内）パトロール停止 → 振り向き → 反応

### 受動的な会話イベント（NPCから話しかける）
**`SkeletalNPC.gd`** に新しい会話トリガーを追加：
- プレイヤーが近づいて一定時間（2秒）経過したら、NPCが先に声をかける
- コアNPCのみ。名無しNPCは後ずさりのみで話しかけない

話しかけの会話内容は `SkeletalNPC.gd` の `npc_data` に `"greet_events"` 配列として持つ：
```gdscript
"haruka": {
    "greet_events": [
        "ねえ、最近また伸びた？",
        "一緒に歩くと目立つよねえ",
        "体育で並ぶとき、いつも端っこだね",
    ]
}
```

### 会話バランス調整
- **現状**: 全体的にネガティブなセリフが多い
- **方針**: コアNPCはポジティブ〜中立に、名無しNPCは驚き系（ネガティブ含む）で住み分け
- **修正箇所**: MainScene.gd または StageBuilder.gd 内の会話テキスト定義部分を精査してバランス調整

---

## 実装順序（推奨）

1. **B（NPC制服連動）** — 小さな修正、すぐ効果が出る
2. **C（ポニーテール・サイドテール）** — CharacterHairDrawer.gd のみ、独立して実装できる
3. **D（靴）** — Global.gd + 描画系、比較的独立
4. **A（学校ステージ分岐）** — StageBuilder + MainScene、やや大きい
5. **E（NPC動き・会話）** — SkeletalNPC.gd、最後に

---

## 未解決の確認事項

- [ ] 進級時にNPCが再スポーンされるか（ステージ再構築のタイミング）確認
- [ ] `CharacterBodyDrawer.gd` に靴描画を追加する箇所が既存の足描画とどう合わさるか確認
- [ ] `side_tail` の左右対称 → 正面向きのとき、向きをどちらに固定するか決める
