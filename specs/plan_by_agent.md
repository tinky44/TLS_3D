# plan_by_agent.md — AIエージェントのメモ帳

---

## アクション計画（2026-03-14）

### 対象ブランチ: `feat/add-story-stage-npcReaction`

---

## #52 髪型改善 [In Progress]

### 残タスク
- [ ] ロング髪：口が髪の上に描画されてしまうバグを修正
- [ ] ロング髪：重力が強すぎるので弾性を持たせる

---

### タスク①：ロング髪の口描画順バグ

**問題の場所**
- `godot-project/scripts/CharacterDrawFront.gd` 113-114行
  - `if facing == "front" and hair_style == "long"` → 口を先に、髪を後に描画（正しい順序）
- `godot-project/scripts/CharacterDrawSide.gd` 106-107行
  - `if hair_style == "long"` → 同様

**調査ポイント**
- 条件 `facing == "front"` が意図通りに評価されているか確認
- "front" 以外の向き（背面 `"back"` など）でも口が髪に被っていないか
- `facing` 変数がどこで設定されるか確認（`CharacterDrawer.gd` → `CharacterDrawFront.gd` への受け渡し）

**修正方針**
- 条件分岐のロジックを確認し、すべての描画パスで「ロング髪の口は髪より先に描画」が保証されるよう修正
- `facing == "back"` のケースにも同様の条件を追加する必要がある可能性

---

### タスク②：ロング髪の重力（弾性追加）

**問題の場所**
- `godot-project/scripts/CharacterHairDrawer.gd` 156-162行付近

```gdscript
# 現在（重力に完全従属）
if hair_style == "long":
    hair_down_dir = gravity_dir  # Vector2(0, 1) 固定
```

**修正方針**
- 頭の向きと重力を lerp して弾性を表現する
- 数値は動作確認しながら調整（0.7〜0.85 程度から試す）

```gdscript
# 修正案（弾性あり）
if hair_style == "long":
    hair_down_dir = down_dir.lerp(gravity_dir, 0.8)  # 0.8 は要調整
```

- `hair_bottom_len`（`hr * 3.5`）はそのままでよい（長さは変えない）

---

## #47 進級システムの実装 [In Progress]

### 残タスク
- [ ] 高校生でも中学校に入れるバグを修正
- [ ] 進級/エンディング選択ダイアログの実装

---

### タスク①：高校生が中学校に入れるバグ（簡易fix）

**問題の場所**
- `godot-project/scripts/MainScene.gd` の `_get_stage_lock_message()` (605-625行)

**原因**
`school_hallway_middle` など中学校関連ステージに `age > 14` の入場制限がない。
現在ロックされているのは以下のみ：

| ステージ | 条件 |
|---|---|
| `school_hallway_elementary`, `school_elementary` | age > 11 |
| `school_middle` | age < 12 または age > 14 |
| `school_high` | age < 15 |
| `school_hallway_high` | age < 15 |

**抜けているケース（中学校系で `age > 14` のガードがない）**
- `school_hallway_middle`
- `infirmary_middle`
- `gymnasium_middle`
- `schoolyard_middle`

**修正方針**
`_get_stage_lock_message()` に以下を追加：

```gdscript
"school_hallway_middle":
    if age_value < 12:
        return "まだこの廊下に入る時期じゃない。"
    if age_value > 14:
        return "今はもう、この廊下には入れない。"
"infirmary_middle":
    if age_value < 12:
        return "まだこの保健室に入る時期じゃない。"
    if age_value > 14:
        return "今はもう、この保健室には入れない。"
"gymnasium_middle":
    if age_value < 12:
        return "まだこの体育館に入る時期じゃない。"
    if age_value > 14:
        return "今はもう、この体育館には入れない。"
"schoolyard_middle":
    if age_value < 12:
        return "まだここには入れない。"
    if age_value > 14:
        return "今はもう、この校庭には入れない。"
```

---

### タスク②：進級選択ダイアログ（大きめの変更）

**背景**
- 現在: `Global.gd` の `advance_term()` が自動で進級（手動選択なし）
- 改善要望: 小3→4, 小6→中, 中3→高 の学校段階切り替え時に「続ける/エンディングへ」を選択させる

**検討ポイント**
- `_school_level_from_age(age) != _school_level_from_age(prev_age)` の条件はすでに `advance_term()` にある（`Global.gd` 304行）
- このタイミングで `MainScene.gd` 側にシグナルを飛ばし、選択UIを出す設計が自然
- エンディング実装（#49）と密接に関係するため、#49 の設計が固まってから本格実装推奨

**現ブランチとの関係**
- `feat/add-story-stage-npcReaction` は「ストーリーステージでのNPC反応追加」
- 進級時のNPC台詞変化（#31）は Done 済み
- 現ブランチでの作業完了後、別ブランチ `feat/grade-select-dialog` で実装する方が安全

---

## 優先順位まとめ

| 優先 | タスク | 規模 | ブランチ |
|---|---|---|---|
| ★★★ | #52 ロング髪の口描画バグ | 小 | 現ブランチ or 別ブランチ |
| ★★★ | #52 ロング髪の重力弾性 | 小 | 同上 |
| ★★★ | #47 高校生が中学校に入れるバグ | 小 | 現ブランチ or hotfix |
| ★★☆ | #47 進級選択ダイアログ | 中〜大 | `feat/grade-select-dialog`（後で） |
