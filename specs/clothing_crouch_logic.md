# 屈み時の衣装描画ロジック仕様（現行実装準拠）

本書は、屈み・前傾時に衣装がどう追従するかを、実装式ベースで整理した仕様です。

## 0. 対象ファイル

- `godot-project/scripts/CharacterBodyDrawer.gd`
- `godot-project/scripts/CharacterClothingDrawer.gd`
- `godot-project/scripts/CharacterDrawFront.gd`
- `godot-project/scripts/CharacterDrawSide.gd`
- `godot-project/scripts/CharacterPoseCalculator.gd`

## 1. 屈み情報の入力元

衣装側が直接参照する屈み関連値（`ctx.d`）:

- `waist_angle`
- `leg_l_angle`, `leg_r_angle`
- `knee_l`, `knee_r`
- `cx`, `cy`（股）
- `sx`, `sy`（肩）
- `navel_x`, `navel_y`（へそ）
- `hip_x`, `hip_y` / `front_hip_x`, `front_hip_y`
- `thigh_l`, `shin_l`

これらは `CharacterPoseCalculator` が `visual_height_cm` から更新した結果。

## 2. トップスの屈み追従（側面）

`CharacterClothingDrawer.draw_tops_detail_side()` の基準ベクトル:

```gdscript
fwd  = Vector2(cos(waist_angle), sin(waist_angle))      # 胴体前方
up_v = Vector2(-sin(waist_angle), cos(waist_angle))     # 胴体上方
```

`sailor` / `blazer` / `blouse_bow` / `jumper_skirt` のディテールはこの `fwd` と `up_v` で回転追従する。

### 2.1 胴体方向ベクトルの使い方

多くの関数で肩→へそベクトルを使う:

```gdscript
torso_down = Vector2(navel_x - sx, navel_y - sy)
torso_dir  = torso_down.normalized()
```

用途:

- V字襟の先端位置
- スカーフ垂れ
- ジャンパースカートのベルト位置
- サスペンダー帯の終端
- ジャンパー系スカート上端の共有アンカー

つまり、腰を曲げると装飾ポリゴンの基準軸そのものが回る。

## 3. 袖（腕）の屈み対応

`draw_sleeve_arm()` 自体は屈み角を計算しないが、呼び出し側が屈み反映済みの肩/肘/手座標を渡すため結果的に追従する。

側面時の追加補正:

```gdscript
sleeve_top_w = arm_w * 1.15          # 元は1.5、側面時は上すぼみ
p_top_center = p_shoulder + n * (shaved / 2.0)
```

- 背中側を基準に、胸側だけ細くする補正。
- 前傾時に袖が前へ膨らみすぎるのを抑える。

## 4. スカートの基準点（waist_pos）と丈

`draw_skirt()` ではまずスカート上端 `waist_pos` を決める。

## 4.1 ジャンパー系の上端引き上げ

対象: `tops_type in {"blazer", "blouse_bow", "jumper_skirt"}`

```gdscript
u_arm = m["armLength"] * p * 0.5 + 10.0
```

- 側面: `CharacterBodyDrawer.get_side_garment_waist_pos(ctx)` を共有利用
- 正面/背面: `waist_pos.y = front_sy + u_arm`

### 4.1.1 セーラースカート（側面）の上端補正

`bottoms_type == "skirt_sailor"` かつ `facing == "side"` のときは、
`hip_x/hip_y` をそのまま使わず、へそ〜股の中心線上の中点を上端に使う。

```gdscript
waist_pos = lerp((navel_x, navel_y), (cx, cy), 0.5)
```

- 下胴の見た目上の中心線に合わせることで、屈み時のトップスとの段差を減らす。

## 4.2 スカート丈

`waist_to_crotch = d["cy"] - waist_pos.y`

条件別:

- `skirt_long`:
  - `skirt_length = waist_to_crotch + thigh_l + shin_l * 0.3`
  - `hem_w = base_width * 1.3`
- `blouse_bow`:
  - `skirt_length = waist_to_crotch + thigh_l * 0.8`
  - `hem_w = base_width * 1.45`
- `jumper_skirt`:
  - `skirt_length = waist_to_crotch + thigh_l * 0.4`
  - `hem_w = base_width * 1.5`
- `skirt_sailor` または `blazer`:
  - `skirt_length = waist_to_crotch + thigh_l + shin_l * 0.1`
  - `hem_w = base_width * (1.6 if blazer else 1.4)`
- それ以外（`skirt`, `skirt_short`）:
  - `skirt_length = waist_to_crotch + thigh_l * 0.4`
  - `hem_w = base_width * 1.5`

## 5. 側面スカートの屈み追従

## 5.1 角度

```gdscript
avg_leg_ang = (leg_l_angle + leg_r_angle) / 2.0
skirt_ang = (avg_leg_ang * 0.7) * PI / 180.0 + PI / 2.0

waist_lean = 0.5 if (is_jumper or is_blouse_bow or is_jumper_skirt) else 0.3
skirt_ang += waist_angle * waist_lean
```

ポイント:

- 脚角は 0.7 倍で追従（布の遅れを表現）。
- ジャンパー系は腰前傾を 50% 反映、通常系は30%。

## 5.2 側面裾幅（屈み破綻回避）

脚の実X広がりを算出:

```gdscript
knee_x, ankle_x(条件付き), hem_x(条件付き) から min_x/max_x
spread_x = abs(max_x - min_x)
```

補正係数:

- `spread_margin = 1.5`（long）
- `spread_margin = 1.6`（プリーツ系）
- `spread_margin = 1.2`（通常）

さらに、深屈みで `spread_x ≈ 0` になるケース対策:

```gdscript
reach_from_hem = max(abs(max_x - p_bottom.x), abs(min_x - p_bottom.x))
side_hem_w = max(hem_w, spread_x * spread_margin, reach_from_hem * 2.0) + 15.0
```

- `+15.0` は膝隠し用マージン。
- これで「膝が同方向に揃ったとき裾が極端に細くなる」問題を防ぐ。

## 5.3 側面プリーツとベルト

- プリーツ対象: `skirt_sailor`, `blazer`, `blouse_bow`, `jumper_skirt`
- 縦線本数: 6本（`for i in 1..6`）
- `jumper_skirt` は上端にダークベルトを追加描画
- `blazer` / `jumper_skirt` の側面ベルト終端は、共有アンカー基準でそろえる

## 5.4 観察ポイント（現行補正で見たいケース）

- 深い屈みで両膝が同方向に揃うケース
- `jumper_skirt` / `skirt_sailor` などのプリーツ系
- 膝近くまで届く中間丈
- 歩行と屈みが重なった中間姿勢

## 6. 正面・背面スカートの屈み追従

正面は脚角を弱投影した足首位置から裾幅を広げる。

```gdscript
f_leg_ang = (leg_angle * 0.2) * PI/180 + PI/2
ankle_x = hip_x + (thigh_l + shin_l) * cos(f_leg_ang)
legs_spread = abs(ankle_r_x - ankle_l_x)

actual_hem_w = max(hem_w, legs_spread * 0.9)
curve_drop = skirt_length * 0.05
```

- 裾中央を `curve_drop` だけ下げた5頂点ポリゴンで描画。
- プリーツ線もこのカーブに合わせて下端を補正している。

## 7. 屈み時の実際の高さ感との対応

衣装ロジックは `d` の骨格高さに完全追従する。特に重要なのは:

- `waist_pos` が `cy` と `sy/navel` から再計算される
- 裾先 `p_bottom` が `skirt_length` と `skirt_ang` で決まる

例（180cm, `p=2` の実装値目安）:

- 直立: `cy=-172.8`
- 深め屈み（`t≈1.0`）: `cy≈-149.3`, `waist_angle=1.3rad`
- さらに深屈み（`t≈2.0`）: `cy≈-53.4`

`cy` が上がるほどスカート上端も上がり、同時に `waist_angle` によって前方へ倒れる。

## 8. 服種別ごとの屈み時見え方まとめ

- `pants`: 脚台形のみ。屈み時は脚角と膝角で自然追従。
- `skirt/skirt_short`: 短め丈、腰追従は弱め（waist 30%）。
- `skirt_long`: 足首寄りまで長い。側面裾幅は広め補正。
- `skirt_sailor`: プリーツ + やや長め丈（膝下少し）。
- `blazer`: ジャンパー系。高い腰位置、プリーツ、腰追従強め（50%）。
- `blouse_bow`: ジャンパー系寄りの追従。膝上寄り丈。
- `jumper_skirt`: 高い腰位置 + ベルト + プリーツ + 強追従。

## 9. 旧仕様との差分（更新点）

- スカート追従は単純角度追従ではなく、`脚角0.7倍 + 腰角追従` の合成。
- 側面裾幅は `spread_x` だけでなく `reach_from_hem` を使って屈み破綻を防止。
- ジャンパー系の上端位置は「肩から胴体方向へ `u_arm`」で統一され、トップス装飾と同じ基準になっている。
