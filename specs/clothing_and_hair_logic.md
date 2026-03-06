# 服装・髪型拡張ロジック設計 (Clothing & Hair Logic)

## 1. 目的
これまで実装してきた「高身長」や「等身変更」に関するプロポーション算定ロジック（`CharacterPoseCalculator.gd` 等）を活用し、キャラクターに自由な「服」や「髪型」を着せ替えられるシステムを構築する。

## 2. PoseCalculator 座標キー参照表

服・髪の描画では、ビューによって使用する座標キーが異なる。

| ビュー | 腰（へそ） | 肩 | 頭中心 |
|---|---|---|---|
| 側面 | `wx, wy` | `sx, sy` | `hx, hy` |
| 正面/背面 | `front_wx, front_wy` | `front_sx, front_sy` | `front_hx, front_hy` |

共通キー（全ビュー共通）:
- `cx, cy` — 股の座標
- `thigh_l`, `shin_l` — 太もも・すねの**長さ**（座標ではない）
- `waist_angle` — 腰の曲がり角度
- `leg_l_angle`, `leg_r_angle` — 左右脚の角度（度数法）
- `arm_l_angle`, `arm_r_angle` — 左右腕の角度（度数法）
- `knee_l`, `knee_r` — 左右膝の曲げ角度（ラジアン）

> **注意**: 膝・足首の座標は PoseCalculator から直接返されない。Section 4.1 の計算式を参照。

## 3. 実装アプローチの基本方針
現在の描画プロセスに「少し大きめのアウトライン」を持たせた服オブジェクトを被せる方式を採用する。

1. **既存の骨格・アンカーポイントの利用**
   `CharacterPoseCalculator` から返却される座標をそのまま利用する（Section 2 の参照表を参照）。
2. **厚みと長さの動的計算**
   `Global.get_body_measurements()` から取得した部位の幅（例: `["arm"]`）に対して、服の厚み係数（1.1倍〜1.3倍など）を掛けてアウトラインを決定する。
3. **Zオーダー（描画順）の整理**
   奥から手前へと順に描画するルール（奥の足 → 奥の腕 → 体幹／スカート → 手前の足 → 手前の腕 → 頭／髪）を徹底する。

## 4. 各パーツの描画ロジック

### 4.1 膝・足首座標の計算（共通）
PoseCalculator は長さ（`thigh_l`, `shin_l`）と角度（`leg_l_angle` 等）のみを返すため、座標は以下の式で都度算出する。

```gdscript
# 側面ビュー（左脚を例に）
var leg_rad = deg_to_rad(pose["leg_l_angle"])
var knee_bend = pose["knee_l"]  # ラジアン
var knee = Vector2(
    cx + thigh_l * sin(leg_rad),
    cy - thigh_l * cos(leg_rad)
)
var ankle = Vector2(
    knee.x + shin_l * sin(leg_rad + knee_bend),
    knee.y - shin_l * cos(leg_rad + knee_bend)
)
```

正面/背面ビューでは脚はほぼ垂直になるため、Y方向への `thigh_l`・`shin_l` の加算で近似する。

### 4.2 下半身服（Bottoms）
腰（側面: `wx, wy` / 正面: `front_wx, front_wy`）から股（`cx, cy`）、そして足へと繋がる処理。
- **スカート（Skirt）**
  - **アンカー**: トップは腰座標を基準とする。ここに「ベルト」の描画を配置できる。
  - **形状**: 腰座標から、下方向に向かって末広がりになるポリゴン（台形や扇形）を動的に計算する。
  - **丈の計算**: Section 4.1 で算出した膝座標・足首座標を基準にし、「ミニスカート」「ロングスカート」を描き分ける。
- **ズボン（Pants）**
  - 現在の足の描画（カプセルや矩形）と同様に、Section 4.1 で算出した膝・足首座標に沿って、少し太めの線／ポリゴンを描画する。

### 4.3 上半身服（Tops）
肩（側面: `sx, sy` / 正面: `front_sx, front_sy`）から腰（側面: `wx, wy` / 正面: `front_wx, front_wy`）までをカバーする処理。
- **胴体部分**: ベースとなる肩幅（`shoulder_w`）の1.1〜1.2倍程度にアウトラインを広げ、 `torso_upper` / `torso_lower` を上書きするように描画。
- **袖部分**: `arm_l_angle` などの角度に沿って描画。
  - 「半袖」なら上腕（`u_arm`）の途中までを服の色と太さで描画し、残りの前腕（`l_arm`）は細めの肌色として描く。
  - 「長袖」なら手首まで服の太さで描画する。

### 4.4 髪型（Hair）
頭の中心（側面: `hx, hy` / 正面: `front_hx, front_hy`）を原点とし、ベースとなる真円（現在の頭部）の背面および前面に追加の描画を行う。
- **後頭部・ベース**: 頭の円より少し大きめの円やパスを、顔の奥側に描画。
- **前髪（Bangs）**: 顔の手前側に、額にかかるような形状のポリゴンを描画。
- **ロングヘア等の拡張**: 肩や背中へ垂れるパス（Bezier曲線等）を用いて、体の傾き（`waist_angle`）に合わせて揺れるような描画も可能。

## 5. 必要なデータ構造（見た目データ）
キャラクターのパラメータ `m`（身長等の身体データ）とは完全に分離し、`appearance`（見た目パラメータ）として管理する。

```gdscript
var appearance = {
	"hair_style": "short",       // "short", "long", "twintail" など
	"hair_color": "#4a3c31",
	"tops_type": "t_shirt",      // "t_shirt", "sweater", "blouse"
	"tops_color": "#ffffff",
	"bottoms_type": "skirt",     // "skirt_short", "skirt_long", "pants"
	"bottoms_color": "#2c3e50",
	"shoes_type": "sneakers",
	"shoes_color": "#e74c3c"
}
```

## 6. 今後の実装ステップ
1. **服・髪の描画関数モジュール化**
   現在の `_draw_front_back` と `_draw_side` が非常に巨大きくなっているため、`draw_hair()`、`draw_tops()`、`draw_bottoms()` 等に処理を分割・リファクタリング。
2. **基本の「着せ替え」基盤導入**
   上記 `appearance` のデータ構造を `Player.gd` または `Global.gd` に追加。
3. **スカートの試験実装**
   一番特徴的となる「腰（へそ）基準で広がるスカート形状」を描画する関数をテスト的に追加。
4. **袖（半袖／長袖）の試験実装**
   腕の長さに応じて、どこまでを服として描くかの分割描画処理を追加。
