# キャラクター描画システム (Character Drawing System)

## 概要

以前は `CharacterDrawer.gd` に集約されていた「高さや座標の計算」「描画ロジック」「基本図形（楕円・矩形など）の描画」を、柔軟性とメンテナンス性を高めるために3つの要素に分割しました。
これにより、ユーザー（開発者）側で、キャラクターのベースとなる形（頭を円にするか、トルソーを矩形にするかなど）を定義・カスタマイズしやすくなります。

## アーキテクチャ

システムは以下の3つのファイル（クラス）で構成されています。

### 1. `CharacterPoseCalculator` (`scripts/CharacterPoseCalculator.gd`)
キャラクターのステータス（現在のポーズ、歩行フェーズ、向いている方向など）と測定データ（身長・股下などの比率 `m` データ）を基に、各関節の角度や位置（IK計算結果など）を算出します。
- **入力:** キャラクターの状態、体のプロポーション(`m`)、1cmあたりのピクセル数(`p`)
- **出力:** 全ての関節座標、角度などをまとめた辞書 (`pose_data`)

### 2. `CharacterDrawUtils` (`scripts/CharacterDrawUtils.gd`)
実際のキャンバスに図形を描画するための、純粋なユーティリティ関数群です。
基本図形ごとに静的(static)関数が用意されています。
- `draw_ellipse` (楕円)
- `draw_rect` (矩形)
- `draw_limb` (カプセル状のパーツ)
- `draw_trapezoid` (台形)

### 3. `CharacterDrawer` (`scripts/CharacterDrawer.gd`)
キャラクターの `Node2D` コンポーネント本体です。
`CharacterPoseCalculator` によって計算された骨格データを受け取り、自身のプロパティ（`part_shapes`）に従って、どの部分をどのような図形で描画するかを選択し、`CharacterDrawUtils` を使って描画を実行します。

## カスタマイズ方法

`CharacterDrawer.gd` には、パーツごとの形状指定を管理する連想配列が用意されています。
スクリプトの先頭部分にある `part_shapes` を変更することで、描画のベースとなる形状を変えることができます。

```gdscript
# 例：CharacterDrawer.gd 内での設定
var part_shapes = {
    "head": "ellipse",       # "ellipse" または "rect"
    "torso": "trapezoid",    # "trapezoid" または "rect"
    "limb": "capsule"        # "capsule" (デフォルトの丸みのある線) または "rect"
}
```

例えば、ロボット風のキャラクターを作るためにトルソーを `rect` (矩形) にしたり、手足を切り離されたような長方形として描画するなどの変更が、計算ロジックをいじることなく行えます。

## 今後の拡張性

新しくサポートする基本形状を増やしたい場合は、`CharacterDrawUtils.gd` に関数を追加し、`CharacterDrawer.gd` 側でその設定値に対応させるロジックを追加するだけで済みます。
