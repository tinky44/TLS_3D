# 服装・髪型関連ロジックおよび描画アーキテクチャ設計

## 1. 目的
`CharacterPoseCalculator.gd` 等から算出されるプロポーション・ポーズ座標を活用し、キャラクターに多様な「服」や「髪型」を着せ替えられるシステム。現在、手足の描画方法は旧来のポリゴンベースから、`CharacterDrawUtils` を活用した太さを持たせた線形描画（スティック・ベース）に移行している。
本ドキュメントは、実際のスクリプト実装（`CharacterDrawFront`, `CharacterDrawSide`, `CharacterBodyDrawer`, `CharacterClothingDrawer` 等）に基づく正確な描画アーキテクチャ・手順を定義する。

## 2. PoseCalculator 座標キーと微調整仕様

ポーズ計算から返却される主要座標は以下の通り。

| ビュー | 股・脚の付け根 | へそ・腰 | 肩 | 頭中心 |
|---|---|---|---|---|
| 側面 | `cx, cy` | `navel_x, navel_y`, `hip_x, hip_y` | `sx, sy` | `hx, hy` |
| 正面/背面 | `cx, cy` | `front_navel_x(y)`, `front_hip_x(y)` | `front_sx, front_sy` | `front_hx, front_hy` |

※ `CharacterDrawFront` および `CharacterDrawSide` 側で、プロポーションの違和感を和らげるため、肩関節座標には独自のオフセット（`front_offset_x`, `front_offset_y`, `side_offset_x`, `side_offset_y`）が現在ハードコードで適用・調整されている。

## 3. クラス構成と役割分担

現在の描画実装は以下のクラスに分割されている。

1. **`CharacterDrawFront` / `CharacterDrawSide`** (エントリ・Zオーダー管理)
   - キャラクター描画の起点。ここで「どのパーツから奥から手前へ描くか（Zオーダー）」を管理し、各描画ヘルパーを呼び出す。
2. **`CharacterDrawUtils`** (プリミティブ・ベース描画)
   - 最下層の描画ツール。`draw_limb_part`（肌色の手足ベース描画）、`draw_trapezoid`（台形描画）、`draw_torso_part` などを提供。
3. **`CharacterBodyDrawer`** (手足＋服ベースの統合描画)
   - `draw_sleeve_arm` : 腕を描きつつ、その上に袖（台形）を重ねて描く。
   - `draw_pants_leg` : 脚を描きつつ、必要に応じてズボン（台形）を重ねて描く。
   - `draw_skirt` : 指定した腰座標と胴体幅から、脚の広がりに応じて動的に裾が広がるスカートを描画。
4. **`CharacterClothingDrawer`** (服装の固有ディテール描画)
   - `draw_tops_detail_front` / `draw_tops_detail_side`
   - セーラー服の襟やスカーフ、ブレザー、リボンブラウスのリボン、サスペンダースカートのベルトなど、それぞれの服特有の「飾りやレイヤー」を前面に上書きする。
5. **`CharacterHairDrawer`** (髪型の描画)
   - 髪レイヤーの描画（ベースレイヤーとトップレイヤー）。

## 4. 実際の描画フローと Zオーダー (Z-Order)

描画順は物理的に背後にあるものから手前に描く処理として、ビューごとに以下のように厳密にコントロールされている。

### 4.1 正面・背面ビュー (`CharacterDrawFront.gd`)
1. **髪ベース**: `CharacterHairDrawer.draw_hair_base_layer`
   - 後頭部側の髪ベースレイヤーを体の後ろに置く。
2. **両足**: `CharacterBodyDrawer.draw_pants_leg`
   - 脚部本体＋パンツの描画、さらに靴下、靴を描く。
3. **両腕**: `CharacterBodyDrawer.draw_sleeve_arm`
   - 腕＋袖。左右同時に胴体より奥（または同レベル）として描画（肩のオフセット調整有り）。
4. **胴体**: `CharacterDrawUtils.draw_torso_part`
   - 下半身側（腰）、上半身側（胸）に分けて描画。前面に上書きする形となる。
5. **ボトムス・スカート**: `CharacterBodyDrawer.draw_skirt`
   - 腰の位置にスカートを描画。(但し `tops_type` がブレザーなど、上着で覆う特殊な服の場合は後で調整される)
6. **頭＋髪レイヤー**: `CharacterHairDrawer.draw_hair`
   - 頭部の円、前髪レイヤー。
7. **詳細な衣服装飾**: `CharacterClothingDrawer.draw_tops_detail_front`
   - 胸元のスカーフや襟などを乗せる。一番手前。
8. **顔（目・口）**
   - パラメータ計算と微調整に基づいて描画。

### 4.2 側面ビュー (`CharacterDrawSide.gd`)
1. **奥の腕**: `CharacterBodyDrawer.draw_sleeve_arm` (左腕など奥側)
2. **奥の足**: `CharacterBodyDrawer.draw_pants_leg` ＋ 靴下 ＋ 靴
3. **胴全体**: `CharacterDrawUtils.draw_side_torso`
   - 胴体の厚みを持たせて曲線的に繋いで描画。
4. **手前の足**: `CharacterBodyDrawer.draw_pants_leg` ＋ 靴下 ＋ 靴
5. **ボトムス・スカート**: `CharacterBodyDrawer.draw_skirt`
   - 歩行アニメ等で前後に脚が広がる際、両足のX座標幅 (`legs_spread`) を計算し、スカート布が脚を覆えるように動的に広がって描画される。
6. **頭＋前髪**: `CharacterHairDrawer.draw_hair`
7. **詳細な衣服装飾**: `CharacterClothingDrawer.draw_tops_detail_side`
   - 側面の角度計算に沿って、首元のディテールなどを貼る。
8. **顔（目・口）**
9. **手前の腕**: `CharacterBodyDrawer.draw_sleeve_arm` (右腕など手前側)
   - ***※最前面に描写される。胴体や手前の足よりも手前であることに注意。***

## 5. 特殊な衣服（ Tops Specific Logic ）によるオーバーライド

実装上、単に「台形を被せる」「ポリゴンを描く」以外にも `CharacterBodyDrawer` および `CharacterClothingDrawer` で以下のような衣服ごとの複雑な処理が導入されている。

- **半袖と長袖の切り分け** (`t_shirt`)
  - `draw_sleeve_arm` にて、袖が全体の60%の長さに制限され、残りの下部分は肌色の腕として塗られる。それ以外（セーラー等）は上腕・前腕すべてを覆い隠す。
- **セーラー服の袖の2本線** (`sailor`)
  - `draw_sleeve_arm` にて、手首の先端数％の位置に白線を2本引いている。
- **スカートの吊り上げとプリーツ表現** (`blouse_bow`, `jumper_skirt`, `blazer`)
  - `draw_skirt` の内部で、スカートの開始位置（ウエスト）を独自に「肘の高さ (`sy + arm_len * 0.5 + offset`)」まで強制的に引き上げ、ハイウエスト構造（ワンピース形状）を作り出している。
  - プリーツはスカートの下端カーブ計算を用いて頂点を結び、薄い暗色の縦線を6本等間隔に引いている。
- **側面ビューにおける袖の上すぼみ補正** (`is_side` == true)
  - `draw_sleeve_arm` で側面ビューの場合、単純な台形では前後に太くなりすぎるため、背中側の位置をアンカーとして前側（胸側）を切り詰める特殊な補正座標計算が適用されている。
