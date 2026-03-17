class_name DrawContext
extends RefCounted

# 描画先のCanvasItem（draw_polygon 等を呼ぶために必要）
var canvas: Node2D

# 基本データ
var m: Dictionary          # プロポーション辞書
var p: float               # CM_TO_PX スケール
var d: Dictionary          # ポーズデータ（CharacterPoseCalculatorの出力）
var appearance: Dictionary # 見た目設定
var part_shapes: Dictionary # パーツ形状設定

# 向き・姿勢
var facing: String         # "front" / "back" / "side"
var flip: bool             # 反転フラグ（side + dir == -1）

# 色
var skin_color: Color
var base_shirt_color: Color
var pants_color: Color
var skin_dark: Color
var shirt_dark: Color
var pants_dark: Color

# サイズ（px）
var shoulder_w: float
var hip_w: float
var thigh_w: float
var shin_w: float
var arm_w: float
var neck_w: float

# 服装タイプ（頻繁に参照するためキャッシュ）
var tops_type: String
var bottoms_type: String
var is_skirt: bool

# 髪・靴・帽子
var hair_style: String
var hair_color: Color
var shoes_type: String
var shoe_color: Color
var hat_type: String
var hat_color: Color
var bag_type: String
var bag_color: Color

# 頭
var head_r: float

# プレイヤー参照（look_pitch, look_head_angle など取得用）
var look_pitch: float
var look_head_angle: float

# 現在のポーズ名（ポーズ別描画分岐用）
var pose: String = "normal"
