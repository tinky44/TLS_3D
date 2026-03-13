# キャラクター描画システム仕様（現行実装準拠）

本書は、現在の描画実装（`CharacterDrawer` + Front/Side分離 + Body/Clothing/Hair分離）を正として整理した仕様です。

## 0. 対象ファイル

- `godot-project/scripts/CharacterDrawer.gd`
- `godot-project/scripts/DrawContext.gd`
- `godot-project/scripts/CharacterDrawFront.gd`
- `godot-project/scripts/CharacterDrawSide.gd`
- `godot-project/scripts/CharacterDrawUtils.gd`
- `godot-project/scripts/CharacterBodyDrawer.gd`
- `godot-project/scripts/CharacterClothingDrawer.gd`
- `godot-project/scripts/CharacterHairDrawer.gd`

## 1. 全体アーキテクチャ

描画は以下の3層で分離されている。

1. オーケストレーション層（`CharacterDrawer`）
2. ビュー別合成層（`CharacterDrawFront` / `CharacterDrawSide`）
3. パーツ描画層（`CharacterDrawUtils`, `CharacterBodyDrawer`, `CharacterClothingDrawer`, `CharacterHairDrawer`）

`CharacterDrawer._draw()` の流れ:

1. `m`, `p`, 向き、見た目辞書を取得
2. `d`（ポーズデータ）を `smooth_d` 優先で取得
3. `DrawContext` に色・幅・服装タイプ・頭向き値を詰める
4. `facing` が `front/back` なら `CharacterDrawFront.draw(ctx)`、それ以外は `CharacterDrawSide.draw(ctx)`

## 2. DrawContext に入る値

### 2.1 色

- `skin_color = #ffe4c4`
- `base_shirt_color = appearance["tops_color"]`
- `pants_color = appearance["bottoms_color"]`
- `jumper_skirt` のときのみ `base_shirt_color=(0.97, 0.97, 0.97)` に上書き
- 影色:
  - `skin_dark = skin_color.darkened(0.15)`
  - `pants_dark = pants_color.darkened(0.15)`
  - `shirt_dark = base_shirt_color.darkened(0.15)`

### 2.2 幅（px）

```gdscript
width_scale = 0.35 if facing == "side" else 1.0
shoulder_w = m["shoulder"] * p * width_scale
hip_w      = shoulder_w * 0.70
thigh_w    = 9.0 * p
shin_w     = 6.5 * p
arm_w      = 5.5 * p
neck_w     = 4.5 * p
```

### 2.3 服装・付属品キャッシュ

- `tops_type`, `bottoms_type`, `is_skirt`
- `hair_style`, `hair_color`
- `shoe_color`
- `hat_type`, `hat_color`
- `bag_type`, `bag_color`

### 2.4 頭部と視線

- `head_r = d["head_h"] / 2.0`
- `look_pitch`, `look_head_angle`（プレイヤー由来）

## 3. パーツ形状テーブル（現行）

`CharacterDrawer.part_shapes`:

```gdscript
{
  "head": "ellipse",
  "torso_lower": "trapezoid",
  "torso_upper": "trapezoid",
  "torso_front_lower": "pentagon",
  "torso_front_upper": "rect",
  "limb": "stick",
  "neck": "limb"
}
```

補足:

- `draw_head_part()` は `shape!="rect"` の場合、`head_w` を使わず半径 `head_h/2` の真円で描く。

## 4. 正面・背面描画（CharacterDrawFront）

## 4.1 主要補正値

```gdscript
front_offset_x = -5.0
front_offset_y = 10.0 + stress_ratio * 8.0
```

- stress が高いほど肩位置を下げる。

## 4.2 脚角度の投影（正面用）

```gdscript
f_leg_l_ang = (d["leg_l_angle"] * 0.2) * PI/180 + PI/2
f_leg_r_ang = (d["leg_r_angle"] * 0.2) * PI/180 + PI/2
```

- 側面角度の 20% だけ反映し、正面での過剰な開脚/前蹴りを抑える。
- 膝角も `+ d["knee_*"] * 0.2` で減衰して使う。

## 4.3 足底合わせ

```gdscript
foot_h = m["height"] * p / 20.0
shin_draw = d["shin_l"] - foot_h
```

- すね長を足高分だけ短くして、足底が地面に合うようにしている。

## 4.4 描画順（front/back）

1. `draw_hair_base_layer`（front時のみ）
2. 両脚（`draw_pants_leg` + 靴下 + 靴）
3. 両腕（`draw_sleeve_arm`）
4. 胴体（front用 torso）
5. ボトムス（スカートまたは骨盤台形）
6. 頭 + 髪
7. 帽子
8. トップス詳細オーバーレイ
9. バッグ（back本体 / frontストラップ）
10. 顔

## 4.5 stress の顔反映

```gdscript
look_pitch = ctx.look_pitch + stress_ratio * 5.0
```

- stress で目線・口位置が下方向へ寄り、しんどさを見せる。

## 4.6 スカート色上書き

- `is_skirt and tops_type != "blazer"` のとき描画。
- `tops_type in {"blouse_bow", "jumper_skirt"}` は `Color(0.15,0.2,0.35)`（紺）で固定。

## 5. 側面描画（CharacterDrawSide）

## 5.1 主要補正値

```gdscript
side_offset_x = -4.0
side_offset_y = 10.0 + stress_ratio * 6.0
```

- stress が高いほど肩（腕基点）を下げる。

## 5.2 側面厚み

```gdscript
head_w = (...) * p * 0.85
torso_thickness = head_w
```

- 側面胴体厚みは「頭幅基準」で統一。

## 5.3 頭角（猫背 + 視線）

```gdscript
head_angle = d["waist_angle"] * 0.6 + stress_ratio * 0.18 + ctx.look_head_angle
```

- 腰前傾・stress・NPC注視を合成。

## 5.4 描画順（side）

1. バッグ（最背面）
2. 奥腕
3. 奥脚 + 靴下 + 靴
4. 側面胴体
5. 手前脚 + 靴下 + 靴
6. ボトムス
7. 頭 + 髪
8. 帽子
9. トップス詳細オーバーレイ
10. 顔
11. 手前腕（最前面）

## 5.5 スカート色上書き

- front/back と同条件。

## 6. 基本図形ユーティリティ（CharacterDrawUtils）

主要関数:

- `draw_ellipse`
- `draw_limb`
- `draw_trapezoid`
- `draw_rect`
- `draw_pentagon_lower_torso`
- `draw_hand`
- `draw_foot_front`
- `draw_foot_side`
- `draw_side_torso`

`draw_side_torso()` は 7頂点ポリゴンで、肩-腰-股の曲がりを前後法線で接続する。

## 7. 実際の高さ・位置がどう決まるか（描画視点）

高さや姿勢の根は `d`（`CharacterPoseCalculator` 出力）で決まり、描画層は次を行う:

- 正面: 側面角度を減衰投影（脚/膝 0.2倍）
- 側面: `waist_angle` をそのまま胴体/頭角に反映
- 両ビュー: 足底合わせのため `shin_draw = shin_l - foot_h`
- stress: 肩Yオフセットと顔ピッチへ加算

つまり「どの高さに見えるか」は、

1. `visual_height_cm -> PoseCalculator` で骨格高さを作る
2. 各ビューの投影補正で見た目へ変換

の2段構えで決定される。

## 8. 旧仕様との差分（更新ポイント）

- `CharacterDrawer + CharacterDrawFront/Side + Body/Clothing/Hair` の分割構造が現行。
- stress による肩落ち・顔ピッチ変化が既に実装済み。
- 正面脚角の 0.2 投影、側面頭角合成、足底合わせ（`shin_draw`）が現行の見た目決定点。
- `part_shapes` は残っているが、服・髪は専用ドロワー側で強くオーバーライドされる。
