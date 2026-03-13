# 衣装・髪描画システム仕様（現行実装準拠）

本書は、衣装と髪の描画を実装コードと一致させた最新版仕様です。  
対象は「どの変数を使って、どの高さ/角度に描いているか」です。

## 0. 対象ファイル

- `godot-project/scripts/CharacterBodyDrawer.gd`
- `godot-project/scripts/CharacterClothingDrawer.gd`
- `godot-project/scripts/CharacterHairDrawer.gd`
- `godot-project/scripts/CharacterDrawFront.gd`
- `godot-project/scripts/CharacterDrawSide.gd`
- `godot-project/scripts/CharacterDrawer.gd`

## 1. 描画責務の分離

### 1.1 BodyDrawer（体＋衣装ベース）

- `draw_sleeve_arm`: 腕ベース + 袖（長袖/半袖/袖なし）
- `draw_pants_leg`: 脚ベース + パンツ上書き
- `draw_skirt`: スカート本体（丈、角度、裾幅、プリーツ、ベルト）

### 1.2 ClothingDrawer（衣装ディテール）

- `draw_tops_detail_front/side` で服種ごとの装飾を追加
- 対応服:
  - `sailor`
  - `blazer`
  - `blouse_bow`
  - `jumper_skirt`
- `t_shirt/sweater/blouse` はオーバーレイなし（袖・胴体色で表現済み）
- 帽子/バッグもここに集約

### 1.3 HairDrawer（髪）

- `draw_hair_base_layer`: 後ろ髪レイヤー
- `draw_hair`: front/back/sideで本体 + 前髪

## 2. 服（腕・脚）の基本ロジック

## 2.1 袖のタイプ分岐

長袖対象:

- `sweater`, `blouse`, `sailor`, `blazer`, `blouse_bow`, `jumper_skirt`

半袖:

- `t_shirt`（肩→肘の60%まで袖）

袖なし:

- その他

共通寸法:

```gdscript
sleeve_top_w = arm_w * 1.5
sleeve_bot_w = arm_w * 1.8
```

側面補正:

```gdscript
sleeve_top_w = arm_w * 1.15
```

- 背中側固定で胸側を絞る（上すぼみ）。

## 2.2 パンツ

`bottoms_type == "pants"` のときのみ台形上書き:

```gdscript
pants_knee_w  = thigh_w * 1.1
pants_ankle_w = shin_w * 1.15
```

## 3. スカート仕様（服ロジック中核）

## 3.1 上端位置（waist_pos）

ジャンパー系（`blazer`, `blouse_bow`, `jumper_skirt`）は上端を上げる:

```gdscript
u_arm = m["armLength"] * p * 0.5 + 10.0
```

- 側面: `CharacterBodyDrawer.get_side_garment_waist_pos(ctx)` を共有利用
- 正面/背面: `waist_pos.y = front_sy + u_arm`

## 3.2 丈計算

```gdscript
waist_to_crotch = d["cy"] - waist_pos.y
```

丈の式:

- `skirt_long`: `waist_to_crotch + thigh_l + shin_l*0.3`
- `blouse_bow`: `waist_to_crotch + thigh_l*0.8`
- `jumper_skirt`: `waist_to_crotch + thigh_l*0.4`
- `skirt_sailor` or `blazer`: `waist_to_crotch + thigh_l + shin_l*0.1`
- `skirt/skirt_short`: `waist_to_crotch + thigh_l*0.4`

## 3.3 裾幅計算（側面）

```gdscript
spread_x       = abs(max_x - min_x)
reach_from_hem = max(abs(max_x - p_bottom.x), abs(min_x - p_bottom.x))
side_hem_w     = max(hem_w, spread_x*spread_margin, reach_from_hem*2.0) + 15.0
```

`spread_margin`:

- long=1.5
- pleated=1.6
- normal=1.2

## 3.4 裾幅計算（正面/背面）

```gdscript
legs_spread  = abs(ankle_r_x - ankle_l_x)
actual_hem_w = max(hem_w, legs_spread * 0.9)
curve_drop   = skirt_length * 0.05
```

## 3.5 プリーツ対象

- `skirt_sailor`, `blazer`, `blouse_bow`, `jumper_skirt`
- 縦線6本

## 3.6 `jumper_skirt` 専用

- 上端にダークベルト追加（front/side 両方）。

## 4. トップス詳細ロジック

## 4.1 セーラー（front/back）

front:

- V開口（肌色）
- 襟ポリゴン
- 内側胸当て
- 白ライン
- 赤スカーフ + 結び目

主要高さ:

- `v_y = lerp(sy, navel_y, 0.45)`
- `scarf_tip_y = lerp(v_y, navel_y, 0.72)`

back:

- 背面フラップを別ポリゴンで描画
- フラップ内側に白ラインを追加
- 背面バッグはこの上に重なってよい

## 4.2 セーラー（side）

- `fwd`, `up_v`, `torso_down` で襟・V底・スカーフ先端を配置
- `v_bottom = p_sh_front + torso_down * 0.42`

## 4.3 blazer（実装名は jumperSkirt 系）

front:

- 胴体を暗色で上書き
- `belt_y = sy + u_arm`
- 必要なら `draw_skirt()` を再呼び出しして同色で接続
- 内側白シャツ矩形 + リボン

side:

- `CharacterBodyDrawer.get_side_garment_waist_pos(ctx)` をベルト中心として共有
- 暗色胴体 + ベルト + 前面白シャツ帯 + リボン

## 4.4 blouse_bow

- front: 前立て2本線 + 黒リボン
- side: 側面リボンのみ（`draw_bow_side`）

## 4.5 jumper_skirt（サスペンダー）

front:

- 左右ストラップ（黒、幅7px）
- `strap_top_y = sy`
- `strap_bot_y = sy + u_arm`

side:

- 前後2本の細帯
- `fw = half_t * 0.12`
- 下端は `get_side_garment_waist_pos(ctx)` を基準に前後へ展開

## 5. 髪ロジック（高さ・向き）

## 5.1 共通スケール

`hr = head_r` に対して:

- `hair_outer_w = hr * 1.12`
- `hair_top_h  = hr * 1.08`
- 下端:
  - short: `head_center.y + hr * 1.3`
  - long:  `head_center.y + hr * 3.5`

## 5.2 front

順序:

1. 顔（肌色円）
2. サイド髪ポリゴン
3. 中間アーク（額埋め）
4. 前髪ポリゴン

前髪下端:

- `bangs_bottom_y = head_center.y - hr * 0.2`

## 5.3 back

- `draw_hair_base_layer` のみで後ろ髪全体を見せる。

## 5.4 side

頭角 `head_angle` を受け、方向ベクトルを回転して使用:

```gdscript
down_dir = Vector2(0,1).rotated(head_angle)
back_dir = Vector2(-1,0).rotated(head_angle)
fwd_dir  = Vector2(1,0).rotated(head_angle)
up_dir   = Vector2(0,-1).rotated(head_angle)
```

重力補正:

- long: `hair_down_dir = Vector2(0,1)`（真下）
- short: `hair_down_dir = lerp(down_dir, gravity, 0.5).normalized()`

つまり、長髪は首角より重力を優先して垂れる。

## 6. 帽子・バッグ

## 6.1 帽子（school_hat）

- front:
  - クラウン幅 `hair_outer_w * 1.05`
  - つば幅 `hair_outer_w * 1.35`
- side:
  - 頭角に追従した回転ポリゴン

## 6.2 バッグ（randoseru）

側面:

- `bag_depth = 22.0 * p`
- 高さ `34.0 * p`（肩から下）
- アーチ天板あり

背面:

- 幅 `26.0 * p`
- 高さ `torso_h * 0.90`
- 蓋、ポケット、金具、ストラップを別描画

正面:

- 胸側ストラップのみ上描き
- 下端は側面仕様に合わせて `sy + 34.0 * p`

## 7. 高さがどう決まるか（衣装・髪）

衣装・髪は身長を直接計算しない。高さはすべて `d` の座標に従う。

実際には:

1. `SkeletalPlayer` が `visual_height_cm` を更新
2. `CharacterPoseCalculator` が `cx/cy/sy/hy/...` を算出
3. 衣装・髪はその座標とベクトルでポリゴン配置

このため、正面・側面・屈みすべてで「同じ骨格値」に対して整合した見た目になる。

## 8. 旧仕様との差分（更新点）

- 旧来の単一描画クラス前提ではなく、Body/Clothing/Hair の責務分離が現行。
- スカートは「丈固定」ではなく、`waist_pos` 再配置 + 裾幅動的補正で屈みに対応。
- 髪は side で重力補正があり、特に long は首角より重力優先。
- 帽子・バッグ寸法（22cm/26cm/34cm など）がコード内定数として明確化されている。
