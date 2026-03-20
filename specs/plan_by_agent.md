# plan_by_agent.md — AIメモ


## Design Task ガイド（ユーザー主導）

ユーザーが以下のデザイン項目を主導で実装するための手順書です。

### 概要

キャラクター描画システムは以下の層で構成されています：

```
DrawContext（描画用のデータ構造）
    ↓
CharacterDrawer（エントリーポイント）
    ↓
CharacterDrawFront / CharacterDrawSide（facing別ロジック）
    ↓
CharacterBodyDrawer / CharacterHairDrawer / CharacterClothingDrawer
    ↓
CharacterDrawUtils（基本図形描画）
```

各 drawer は **static 関数群** で構成。appearance（外見パラメータ）の値に応じて描画内容を切り替えます。

---

### 【Task 1】NPC向けの髪形追加

**関連ファイル:**
- `godot-project/scripts/CharacterHairDrawer.gd` — 髪型描画ロジック
- `godot-project/scripts/SkeletalNPC.gd` — NPC の appearance 定義
- `godot-project/scripts/CharacterDrawer.gd` — 髪の呼び出し元

**現在対応している髪型:**
```gdscript
# CharacterHairDrawer.gd:15 参照
"short"      # ショートヘア（デフォルト）
"long"       # ロングヘア
"ponytail"   # ポニーテール
"side_tail"  # サイドテール
```

**新しい髪型を追加する手順:**

1. **CharacterHairDrawer.gd に新規描画関数を追加**
   - 例：`_get_back_hair_bottom_y()` 関数（452行）を参考に、新しい髪型の下端Y位置を計算
   - または `_draw_back_tail()` 関数（465行）を参考に、結び目や毛先の形状を描画

2. **既存の switch 文に新しい髪型を追加**
   - `draw_hair_base_layer()` 関数（15行）の中で `hair_style == "new_style"` に対応させる
   - `draw_hair()` 関数（76行）で正面・背面・側面それぞれの描画を追加

3. **NPC に髪型を割り当て**
   - `SkeletalNPC.gd` で NPC の appearance に `hair_style` を設定
   - 例：`appearance["hair_style"] = "new_style"`

**調整パラメータ:**
- 頭の大きさ基準：`hr`（head_r = 頭の半径）を基準に相対サイズを指定
- 例：`hair_outer_w = hr * 1.12` → 髪の幅 = 頭半径 × 1.12 倍

---

### 【Task 2】帽子などのdesign変更

**関連ファイル:**
- `godot-project/scripts/CharacterClothingDrawer.gd`  — 帽子描画ロジック（600行以降）
- `godot-project/scripts/CharacterDrawer.gd` — 帽子の色設定（80行）
- `godot-project/scripts/DrawContext.gd` — `hat_type` / `hat_color` 属性

**現在対応している帽子:**
```gdscript
# CharacterClothingDrawer.gd:607
"none"       # 帽子なし
"school_hat" # 通学帽（ハット型、全周つば）
```

**新しい帽子タイプを追加する手順:**

1. **CharacterClothingDrawer.gd の `draw_hat_front()` に match 句を追加**
   - 603行の match 文に新規帽子タイプを追加
   - 例：`"cap":` で野球帽を描画するロジックを追加

2. **側面用に `draw_hat_side()` にも対応させる**
   - 637行の match 文に同じく追加
   - 側面のシルエットを調整

3. **帽子の色を CharacterDrawer.gd で定義（オプション）**
   - 82行の `default_hat_color` を新規タイプに対応させる

**既存帽子の調整:**
- `school_hat` の場合、632行の以下パラメータで形状調整可能：
  - `crown_w` — クラウン（かぶる部分）の横幅
  - `crown_h` — クラウンの縦幅
  - `brim_w` — つばの横幅
  - `brim_h` — つばの厚さ

---

### 【Task 3】手の形を三角形+親指で演出

**関連ファイル:**
- `godot-project/scripts/CharacterDrawUtils.gd` — 手描画関数（79行）
- `godot-project/scripts/CharacterDrawFront.gd` / `CharacterDrawSide.gd` — 手の描画呼び出し
- `godot-project/scripts/DrawContext.gd` — コンテキスト定義

**現在の手の形状:**
```gdscript
# CharacterDrawUtils.gd:79
# draw_hand() — 長方形（hw=半幅, hh=半高さ）のシンプル形状
```

**改善手順:**

1. **CharacterDrawUtils.gd に新規関数を追加**
   - `draw_hand_with_thumb()` という新しい関数を追加
   - 親指を三角形で演出：手本体（長方形）+ 親指（小さな三角形）
   - 例：
     ```gdscript
     static func draw_hand_with_thumb(canvas: CanvasItem, pos: Vector2, hw: float, hh: float, color: Color, thumb_side: int = 1):
         # 手本体（長方形）を描画
         # 親指を小さな三角形で描画（thumb_side: 1=右, -1=左）
     ```

2. **CharacterDrawFront / CharacterDrawSide で呼び出し変更**
   - 現在の `CharacterDrawUtils.draw_hand()` 呼び出しを新しい関数に変更
   - または appearance に `hand_style: "with_thumb"` フラグを追加して条件分岐

3. **親指の位置・角度調整**
   - 手の回転角度 `angle` に応じて親指の向きも変わるようにする
   - 参考：`CharacterHairDrawer.gd` の回転処理（13行）

---

### 【Task 4】上履きの先っぽの色を変更

**関連ファイル:**
- `godot-project/scripts/CharacterDrawUtils.gd` — 足描画関数（92行・104行）
- `godot-project/scripts/CharacterDrawFront.gd` / `CharacterDrawSide.gd` — 足の描画呼び出し
- `godot-project/scripts/CharacterDrawer.gd` — 靴の色定義（78行）

**現在の靴の描画:**
```gdscript
# CharacterDrawUtils.gd:92
# draw_foot_front() — 正面足（台形）
# draw_foot_side()  — 側面足（靴シルエット、6頂点）

# CharacterDrawer.gd:78
ctx.shoe_color = Color(appearance.get("shoes_color", "#f0f0f0"))
```

**改善手順:**

1. **CharacterDrawUtils.gd の `draw_foot_side()` を編集**
   - 現在 104行で足全体を1色で描画している
   - つま先部分（点3・4あたり：`ankle + Vector2(foot_w, foot_h * 0.4)` ～ `ankle + Vector2(foot_w, foot_h * 0.85)`）を別色で描画

2. **方法A：2つのポリゴンに分割**
   ```gdscript
   # 足の本体（かかと～甲まで）を base_color で描画
   # つま先部分を toe_color で描画
   ```

3. **CharacterDrawer.gd で toe_color を定義（新規）**
   - `ctx.shoe_toe_color = Color(...)` を追加
   - appearance に `shoes_toe_color` フラグを追加

4. **front 側も同様に対応**
   - `draw_foot_front()` でも つま先を別色に

---

### 【Task 5】NPCの服装を変更（ジャージなど）

**関連ファイル:**
- `godot-project/scripts/CharacterClothingDrawer.gd` — 服装オーバーレイ描画
- `godot-project/scripts/CharacterBodyDrawer.gd` — 体本体の色定義（まだ読んでない）
- `godot-project/scripts/CharacterDrawer.gd` — 服装タイプ設定（73行）
- `godot-project/scripts/SkeletalNPC.gd` — NPC appearance 定義

**現在対応している服装:**
```gdscript
# CharacterDrawer.gd:73-74
tops_type:    "t_shirt", "sweater", "blouse", "sailor", "blazer", "blouse_bow", "jumper_skirt"
bottoms_type: "pants", "skirt_*"
```

**ジャージを追加する手順:**

1. **新しい bottoms_type を定義**
   - 例：`"sweatpants"` （スウェットパンツ）
   - 色も appearance に追加：`sweatpants_color`

2. **CharacterBodyDrawer.gd で下半身描画関数を追加**
   - `draw_legs()` 関数で bottoms_type を switch 分岐（詳細は CharacterBodyDrawer.gd を確認）
   - スウェットパンツ用のポリゴン形状を定義

3. **セーター（トップス）を追加**
   - 既に `"sweater"` は bottoms_type に含まれる可能性あり
   - tops_type に対応する色をオーバーレイで追加

4. **SkeletalNPC.gd で NPC に着せる**
   - 体育館の NPC：`appearance["tops_type"] = "sweater"` + `appearance["bottoms_type"] = "sweatpants"`

5. **色の調整**
   - `CharacterDrawer.gd` で新規フラグの色デフォルトを設定
   - 例：`ctx.sweatpants_color = Color(appearance.get("sweatpants_color", "#333333"))`

---

### 実装の流れ（一般的な手順）

各タスク共通の実装パターン：

1. **データ層の拡張** → appearance に新しいプロパティを追加
2. **描画層の実装** → draw_xxx() 関数を追加・修正
3. **NPC/キャラ設定** → SkeletalNPC.gd で appearance を割り当て
4. **テスト** → Godot エディタで動作確認

---

### 使える補助機能

**CharacterDrawUtils.gd 内の便利関数:**
- `draw_ellipse()` — 楕円（回転対応）
- `draw_trapezoid()` — 台形
- `draw_rect()` — 矩形
- `draw_limb()` — 太い線（カプセル形）
- `draw_pentagon_lower_torso()` — 5角形（胴体下部用）

これらを組み合わせて新しい形状を作成できます。
