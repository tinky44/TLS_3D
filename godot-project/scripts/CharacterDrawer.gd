extends Node2D

@onready var player = get_parent()

# 描画の基本となる図形の設定
# これらの値を変更することで、矩形ベース等に切り替えることが可能
@export var part_shapes = {
	"head": "ellipse", # "ellipse", "rect"
	"torso_lower": "trapezoid", # 横向き用。"trapezoid", "rect", "ellipse" // TODO: ５角形であるべき
	"torso_upper": "trapezoid", # 横向き用。"trapezoid", "rect", "ellipse"
	"torso_front_lower": "pentagon", # 正面・背面用。"pentagon", "rect", "trapezoid"
	"torso_front_upper": "rect", # 正面・背面用。"rect", "trapezoid"
	"limb": "stick", # 腕や脚の形状。"stick"(線+関節), "limb"(カプセル型), "rect", "line"
	"neck": "limb", # 首の形状。"limb"(カプセル型), "stick"
}

func _draw() -> void:
	var p = player.CM_TO_PX
	var m = player.m
	var dir = player.dir
	var facing = player.facing

	if m == null or m.is_empty():
		return

	# === 計算ロジック ===
	var d = CharacterPoseCalculator.calculate_pose_data(player, m, p)

	# === 描画実行 ===
	var flip = (dir == -1 and facing == "side")

	# 見た目データの取得
	var appearance = Global.current_appearance

	var skin_color = Color("#ffe4c4")
	var base_shirt_color = Color(appearance.get("tops_color", "#ab82a8"))
	var pants_color = Color(appearance.get("bottoms_color", "#e5d6ba"))

	var skin_dark = skin_color.darkened(0.15)
	var pants_dark = pants_color.darkened(0.15)
	var shirt_dark = base_shirt_color.darkened(0.15)

	var width_scale = 0.35 if facing == "side" else 1.0
	var shoulder_w = (m["shoulder"] if m.has("shoulder") else 35.0) * p * width_scale
	var hip_w = shoulder_w * 0.70 # 側面台形: 上が広く下がやや狭い

	var thigh_w = 9.0 * p
	var shin_w = 6.5 * p
	var arm_w = 5.5 * p
	var neck_w = 4.5 * p

	if flip:
		draw_set_transform(Vector2.ZERO, 0, Vector2(-1, 1))

	# --- 描画ユーティリティ呼び出し ---
	if facing == "front" or facing == "back":
		_draw_front_back(m, p, d, appearance, skin_color, base_shirt_color, pants_color, skin_dark, shirt_dark, pants_dark, shoulder_w, thigh_w, shin_w, arm_w, neck_w)
	else:
		_draw_side(m, p, d, appearance, skin_color, base_shirt_color, pants_color, skin_dark, shirt_dark, pants_dark, shoulder_w, hip_w, thigh_w, shin_w, arm_w, neck_w)

	if flip:
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

# === 服装ヘルパー関数 ===

# 袖付き腕を描画するヘルパー
# 台形の袖を腕の上に重ねて描画し、袖がない部分は通常のlimbで描画する
func _draw_sleeve_arm(p_shoulder: Vector2, p_elbow: Vector2, p_hand: Vector2,
		arm_w: float, hand_hw: float, hand_hh: float, hand_angle: float,
		tops_type: String, skin: Color, shirt: Color) -> void:
	var sleeve_top_w = arm_w * 1.4 # 袖の肩側の太さ
	var sleeve_bot_w = arm_w * 1.15 # 袖口の太さ

	if tops_type == "sweater" or tops_type == "blouse":
		# 長袖: 肩→肘 台形、肘→手首 台形（やや細め）
		CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_shoulder, p_elbow, arm_w, skin)
		CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_elbow, p_hand, arm_w * 0.8, skin)
		CharacterDrawUtils.draw_trapezoid(self , p_shoulder, p_elbow, sleeve_top_w, sleeve_bot_w, shirt)
		CharacterDrawUtils.draw_trapezoid(self , p_elbow, p_hand, sleeve_bot_w, arm_w * 1.0, shirt)
	elif tops_type == "t_shirt":
		# 半袖: 肩→上腕60%地点まで台形袖、残りは肌色limb
		var sleeve_end = p_shoulder.lerp(p_elbow, 0.6)
		CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_shoulder, p_elbow, arm_w, skin)
		CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_elbow, p_hand, arm_w * 0.8, skin)
		CharacterDrawUtils.draw_trapezoid(self , p_shoulder, sleeve_end, sleeve_top_w, sleeve_bot_w, shirt)
	else:
		# ノースリーブ等: 通常の腕描画のみ
		CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_shoulder, p_elbow, arm_w, skin)
		CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_elbow, p_hand, arm_w * 0.8, skin)

	CharacterDrawUtils.draw_hand(self , p_hand, hand_hw, hand_hh, skin, hand_angle)

# 髪型描画ヘルパー
# 後髪 → 頭（肌色） → 前髪 の順で描画する
func _draw_hair(head_center: Vector2, head_r: float, head_w: float,
		hair_style: String, hair_color: Color, skin_color: Color,
		facing: String, head_angle: float = 0.0) -> void:
	var hr = head_r # 頭の半径

	if facing == "front":
		var hair_outer_w = hr * 1.35
		var hair_top_h = hr * 1.25
		
		var hair_bottom_y = head_center.y + hr * 1.8 # 短い場合
		if hair_style == "long":
			hair_bottom_y = head_center.y + hr * 3.5 # ロングの場合
		
		# 1. 後ろ髪（顔の背面に描画）
		# 頭頂部を丸く覆うドーム
		CharacterDrawUtils.draw_ellipse(self , head_center + Vector2(0, -hr * 0.1), hair_outer_w, hair_top_h, hair_color)
		# そこから下へ落ちるベース
		var back_pts = PackedVector2Array([
			Vector2(head_center.x - hair_outer_w, head_center.y),
			Vector2(head_center.x + hair_outer_w, head_center.y),
			Vector2(head_center.x + hair_outer_w * 0.95, hair_bottom_y),
			Vector2(head_center.x - hair_outer_w * 0.95, hair_bottom_y)
		])
		draw_polygon(back_pts, PackedColorArray([hair_color]))

		# 2. 顔（肌色の円）
		CharacterDrawUtils.draw_ellipse(self , head_center, hr, hr, skin_color)

		# 3. サイドヘア（顔の左右の手前にかぶせる髪）
		# これにより、顔の左右に垂直な髪のラインができ、イラストのようなシルエットになります。
		var side_inner_w = hr * 0.85 # 顔が出る幅（小さいほど髪が顔に迫る）
		var side_top_y = head_center.y - hr * 0.5
		
		var left_side_pts = PackedVector2Array([
			Vector2(head_center.x - hair_outer_w, side_top_y),
			Vector2(head_center.x - side_inner_w, side_top_y),
			Vector2(head_center.x - side_inner_w, hair_bottom_y),
			Vector2(head_center.x - hair_outer_w * 0.95, hair_bottom_y)
		])
		draw_polygon(left_side_pts, PackedColorArray([hair_color]))
		
		var right_side_pts = PackedVector2Array([
			Vector2(head_center.x + side_inner_w, side_top_y),
			Vector2(head_center.x + hair_outer_w, side_top_y),
			Vector2(head_center.x + hair_outer_w * 0.95, hair_bottom_y),
			Vector2(head_center.x + side_inner_w, hair_bottom_y)
		])
		draw_polygon(right_side_pts, PackedColorArray([hair_color]))

		# 4. 前髪（額にかかるポリゴン）
		_draw_bangs_front(head_center, hr, head_w, hair_style, hair_color)

	elif facing == "back":
		# 背面: 髪全体が見える
		CharacterDrawUtils.draw_ellipse(self , head_center, hr * 1.08, hr * 1.08, hair_color)
		if hair_style == "long":
			# ロングヘア: 肩まで垂れる
			var hair_bottom = head_center + Vector2(0, hr * 2.0)
			CharacterDrawUtils.draw_trapezoid(self , head_center + Vector2(0, hr * 0.3), hair_bottom, head_w * 0.9, head_w * 0.6, hair_color)

	else: # side
		# 後髪（後頭部側に膨らむ楕円）
		var back_offset = Vector2(-hr * 0.1, 0).rotated(head_angle)
		CharacterDrawUtils.draw_ellipse(self , head_center + back_offset, hr * 1.1, hr * 1.08, hair_color, head_angle)
		# 顔（肌色の円）
		CharacterDrawUtils.draw_ellipse(self , head_center, hr, hr, skin_color, head_angle)
		# 前髪（前方に突き出す）
		_draw_bangs_side(head_center, hr, hair_style, hair_color, head_angle)
		# ロングヘア: 後ろに垂れる
		if hair_style == "long":
			var down_dir = Vector2(0, 1).rotated(head_angle)
			var back_dir = Vector2(-1, 0).rotated(head_angle)
			var hair_start = head_center + back_dir * hr * 0.3 + down_dir * hr * 0.5
			var hair_end = hair_start + down_dir * hr * 1.8
			CharacterDrawUtils.draw_trapezoid(self , hair_start, hair_end, hr * 0.7, hr * 0.4, hair_color)

# 正面の前髪
func _draw_bangs_front(head_center: Vector2, hr: float, head_w: float, hair_style: String, hair_color: Color) -> void:
	var top_y = head_center.y - hr * 0.9
	var bangs_bottom_y = head_center.y - hr * 0.2 # 額の下あたり
	var half_w = head_w * 0.55

	# 添付画像を参考に、向かって左側を少し長くし、右側に分け目を入れる形状
	var pts = PackedVector2Array([
		Vector2(head_center.x - half_w, top_y), # 左上
		Vector2(head_center.x + half_w, top_y), # 右上
		Vector2(head_center.x + half_w * 0.8, bangs_bottom_y), # 右下端
		Vector2(head_center.x + half_w * 0.3, bangs_bottom_y - hr * 0.15), # 分け目の切れ込み
		Vector2(head_center.x - half_w * 0.2, bangs_bottom_y), # 前髪中央付近
		Vector2(head_center.x - half_w * 0.8, bangs_bottom_y + hr * 0.6), # 左側の少し長いサイドバング
	])
	draw_polygon(pts, PackedColorArray([hair_color]))

# 側面の前髪
func _draw_bangs_side(head_center: Vector2, hr: float, hair_style: String, hair_color: Color, head_angle: float) -> void:
	var forward = Vector2(1, 0).rotated(head_angle)
	var up = Vector2(0, -1).rotated(head_angle)

	# 前髪: 頭頂部から前方に突き出す三角形
	var p1 = head_center + up * hr * 0.9 + forward * hr * 0.1 # 頭頂やや前
	var p2 = head_center + up * hr * 0.3 + forward * hr * 0.95 # 前方に突き出す先端
	var p3 = head_center + up * hr * 0.1 + forward * hr * 0.3 # 額の下端

	var pts = PackedVector2Array([p1, p2, p3])
	draw_polygon(pts, PackedColorArray([hair_color]))

# スカート描画ヘルパー
func _draw_skirt(d: Dictionary, bottoms_type: String, bottoms_color: Color, waist_pos: Vector2, base_width: float) -> void:
	var waist_to_crotch = d["cy"] - waist_pos.y
	var skirt_length: float
	var hem_w: float

	if bottoms_type == "skirt_long":
		skirt_length = waist_to_crotch + d["thigh_l"] + d["shin_l"] * 0.3
		hem_w = base_width * 1.3
	else: # "skirt" or "skirt_short"
		skirt_length = waist_to_crotch + d["thigh_l"] * 0.4
		hem_w = base_width * 1.5

	var p_bottom = Vector2(waist_pos.x, waist_pos.y + skirt_length)
	CharacterDrawUtils.draw_trapezoid(self , waist_pos, p_bottom, base_width, hem_w, bottoms_color)

# --- 正面・背面 描画 ---
func _draw_front_back(m, p, d, appearance, skin_color, base_shirt_color, pants_color, skin_dark, shirt_dark, _pants_dark, shoulder_w, thigh_w, shin_w, arm_w, neck_w):
	var facing = player.facing
	var body_w = shoulder_w * 0.6
	var body_w_half = body_w / 2.0
	var sh_off = shoulder_w * 0.5 - arm_w * 0.5
	var hp_off = body_w_half * 0.6

	var p_hip_l = Vector2(d["cx"] - hp_off, d["cy"])
	var p_hip_r = Vector2(d["cx"] + hp_off, d["cy"])

	# === 正面用の微調整（ここを書き換えて動作確認します） ===
	var front_offset_x = 0.0 # プラスにすると腕が外側に広がる、マイナスで内側
	var front_offset_y = 10.0 # プラスにすると腕が下に下がる、マイナスで上に上がる
	# Note: 腕の太さ分だけ下に下げたかった

	var p_sh_l = Vector2(d["front_sx"] - sh_off + front_offset_x, d["front_sy"] + front_offset_y)
	var p_sh_r = Vector2(d["front_sx"] + sh_off + front_offset_x, d["front_sy"] + front_offset_y)

	var f_leg_l_ang = (d["leg_l_angle"] * 0.2) * PI / 180 + PI / 2
	var f_leg_r_ang = (d["leg_r_angle"] * 0.2) * PI / 180 + PI / 2

	var foot_w = 7.0 * p
	var foot_h = 3.5 * p
	# 正面の手: 縦=頭の縦×0.83、横=肩幅/5（側面の1/4相当）
	var shoulder_full = (m["shoulder"] if m.has("shoulder") else 35.0) * p
	var hand_hw = shoulder_full / 5.0 / 4.0 / 2.0
	var hand_hh = d["head_h"] * 0.83 / 2.0
	var shoe_color = Color(appearance.get("shoes_color", "#e5d6ba"))

	# 服装タイプの判定
	var bottoms_type = appearance.get("bottoms_type", "pants")
	var tops_type = appearance.get("tops_type", "t_shirt")
	var is_skirt = bottoms_type.begins_with("skirt")
	var thigh_color = skin_color if is_skirt else pants_color

	# 1. 両足
	var p_thigh_l = CharacterPoseCalculator.rotated_point(p_hip_l.x, p_hip_l.y, d["thigh_l"], f_leg_l_ang)
	var p_shin_l = CharacterPoseCalculator.rotated_point(p_thigh_l.x, p_thigh_l.y, d["shin_l"], f_leg_l_ang + d["knee_l"] * 0.2)
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_hip_l, p_thigh_l, thigh_w, thigh_color)
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_thigh_l, p_shin_l, shin_w, skin_color)
	CharacterDrawUtils.draw_foot_front(self , p_shin_l, foot_w, foot_h, shoe_color)

	var p_thigh_r = CharacterPoseCalculator.rotated_point(p_hip_r.x, p_hip_r.y, d["thigh_l"], f_leg_r_ang)
	var p_shin_r = CharacterPoseCalculator.rotated_point(p_thigh_r.x, p_thigh_r.y, d["shin_l"], f_leg_r_ang + d["knee_r"] * 0.2)
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_hip_r, p_thigh_r, thigh_w, thigh_color)
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_thigh_r, p_shin_r, shin_w, skin_color)
	CharacterDrawUtils.draw_foot_front(self , p_shin_r, foot_w, foot_h, shoe_color)

	# 2. 胴体 (シャツ) — 正面ビュー用座標を使用
	CharacterDrawUtils.draw_torso_part(self , part_shapes["torso_front_lower"], Vector2(d["front_wx"], d["front_wy"]), Vector2(d["cx"], d["cy"]), body_w, body_w, base_shirt_color)
	CharacterDrawUtils.draw_torso_part(self , part_shapes["torso_front_upper"], Vector2(d["front_sx"], d["front_sy"]), Vector2(d["front_wx"], d["front_wy"]), body_w, body_w, base_shirt_color)

	# 3. スカート（該当する場合）
	if is_skirt:
		_draw_skirt(d, bottoms_type, pants_color, Vector2(d["front_wx"], d["front_wy"]), body_w)

	# 4. 頭 + 髪
	var head_w = (m["headWidth"] if m.has("headWidth") else m["head"] * 0.702) * p
	var head_r = d["head_h"] / 2.0
	var hair_style = appearance.get("hair_style", "short")
	var hair_color = Color(appearance.get("hair_color", "#4a3c31"))
	_draw_hair(Vector2(d["front_hx"], d["front_hy"]), head_r, head_w, hair_style, hair_color, skin_color, facing)

	# 5. 両腕（台形袖の描画）
	var arm_len = m["armLength"] * p
	var u_arm = arm_len * 0.5
	var l_arm = arm_len * 0.5

	var arm_skin = skin_color if facing == "front" else skin_dark
	var arm_shirt = base_shirt_color if facing == "front" else shirt_dark

	var f_arm_l_ang = 0.12 + (d["arm_l_angle"] * 0.3) * PI / 180 + PI / 2
	var p_elb_l = CharacterPoseCalculator.rotated_point(p_sh_l.x, p_sh_l.y, u_arm, f_arm_l_ang)
	var p_hand_l = CharacterPoseCalculator.rotated_point(p_elb_l.x, p_elb_l.y, l_arm, f_arm_l_ang)

	var f_arm_r_ang = -0.12 + (d["arm_r_angle"] * 0.3) * PI / 180 + PI / 2
	var p_elb_r = CharacterPoseCalculator.rotated_point(p_sh_r.x, p_sh_r.y, u_arm, f_arm_r_ang)
	var p_hand_r = CharacterPoseCalculator.rotated_point(p_elb_r.x, p_elb_r.y, l_arm, f_arm_r_ang)

	_draw_sleeve_arm(p_sh_l, p_elb_l, p_hand_l, arm_w, hand_hw, hand_hh, f_arm_l_ang - PI / 2, tops_type, arm_skin, arm_shirt)
	_draw_sleeve_arm(p_sh_r, p_elb_r, p_hand_r, arm_w, hand_hw, hand_hh, f_arm_r_ang - PI / 2, tops_type, arm_skin, arm_shirt)

	# 6. 顔とディテール
	if facing == "front":
		var hx = d["front_hx"]
		var hy = d["front_hy"]

		var eye_off_x = head_w * 0.2
		var eye_y = hy # 真ん中（高さオフセットなし）
		draw_circle(Vector2(hx - eye_off_x, eye_y), 2.5, Color("#333333"))
		draw_circle(Vector2(hx + eye_off_x, eye_y), 2.5, Color("#333333"))

		var mouth_y = hy + (d["head_h"] * 0.25) # 目と顎の中間
		var m_pts = PackedVector2Array()
		for i in range(11):
			var t = float(i) / 10.0
			var xx = lerp(-head_w * 0.15, head_w * 0.15, t)
			var yy = mouth_y + sin(t * PI) * 3.0
			m_pts.append(Vector2(hx + xx, yy))
		for i in range(m_pts.size() - 1):
			draw_line(m_pts[i], m_pts[i + 1], Color("#c07070"), 2.0)

# --- 横向き 描画 ---
func _draw_side(m, p, d, appearance, skin_color, base_shirt_color, pants_color, skin_dark, shirt_dark, pants_dark, _shoulder_w, _hip_w, thigh_w, shin_w, arm_w, _neck_w):
	var hx = d["hx"]
	var hy = d["hy"]

	# 側面: 胴体の厚み = 頭の幅（仕様書）
	var head_w = (m["headWidth"] if m.has("headWidth") else m["head"] * 0.702) * p * 0.85
	var torso_thickness = head_w

	var foot_w = 9.0 * p
	var foot_h = 3.5 * p
	# 側面の手: 縦=頭の縦×0.83、横=肩幅/5（正面の4倍）
	var shoulder_full = (m["shoulder"] if m.has("shoulder") else 35.0) * p
	var hand_hw = shoulder_full / 5.0 / 2.0
	var hand_hh = d["head_h"] * 0.83 / 2.0
	var shoe_color = Color(appearance.get("shoes_color", "#e5d6ba"))

	# === 側面用の微調整（ここを書き換えて動作確認します） ===
	var side_offset_x = -4.0 # プラスで右(前)に移動、マイナスで左(後)に移動
	var side_offset_y = 10.0 # プラスで下に移動、マイナスで上に移動
	# Note: 腕の太さ分だけ下に下げたかった。x軸は、頭の中心あたりを目指した。今後は計算でやりたい

	var p_shoulder = Vector2(d["sx"], d["sy"])
	var p_arm_shoulder = Vector2(d["sx"] + side_offset_x, d["sy"] + side_offset_y)
	var p_crotch = Vector2(d["cx"], d["cy"])

	# 服装タイプの判定
	var bottoms_type = appearance.get("bottoms_type", "pants")
	var tops_type = appearance.get("tops_type", "t_shirt")
	var is_skirt = bottoms_type.begins_with("skirt")
	var back_thigh_color = skin_dark if is_skirt else pants_dark
	var front_thigh_color = skin_color if is_skirt else pants_color

	# 1. 奥の腕（台形袖の描画）
	var arm_len = m["armLength"] * p
	var u_arm = arm_len * 0.5
	var l_arm = arm_len * 0.5

	var p_elb_l = CharacterPoseCalculator.rotated_point(p_arm_shoulder.x, p_arm_shoulder.y, u_arm, d["arm_l_angle"] * PI / 180 + d["waist_angle"] + PI / 2)
	var p_hand_l = CharacterPoseCalculator.rotated_point(p_elb_l.x, p_elb_l.y, l_arm, d["arm_l_angle"] * PI / 180 + d["waist_angle"] + PI / 2 - 0.1)

	var s_arm_l_ang = d["arm_l_angle"] * PI / 180 + d["waist_angle"] + PI / 2 - 0.1
	_draw_sleeve_arm(p_arm_shoulder, p_elb_l, p_hand_l, arm_w, hand_hw, hand_hh, s_arm_l_ang - PI / 2, tops_type, skin_dark, shirt_dark)

	# 2. 奥の足
	var p_thigh_l = CharacterPoseCalculator.rotated_point(p_crotch.x, p_crotch.y, d["thigh_l"], d["leg_l_angle"] * PI / 180 + PI / 2)
	var p_shin_l = CharacterPoseCalculator.rotated_point(p_thigh_l.x, p_thigh_l.y, d["shin_l"], d["leg_l_angle"] * PI / 180 + PI / 2 + d["knee_l"])
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_crotch, p_thigh_l, thigh_w, back_thigh_color)
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_thigh_l, p_shin_l, shin_w, skin_dark)
	CharacterDrawUtils.draw_foot_side(self , p_shin_l, foot_w, foot_h, shoe_color.darkened(0.15))

	# 3. 胴体（服）: 腰で曲がるように分割
	var p_waist = Vector2(d["wx"], d["wy"])
	var nipple_ratio_upper = 0.55 # 上部(胸)の下から55%の高さ
	CharacterDrawUtils.draw_side_torso(self , p_shoulder, p_waist, p_crotch, nipple_ratio_upper, torso_thickness, base_shirt_color)

	# 4. 手前の足
	var p_thigh_r = CharacterPoseCalculator.rotated_point(p_crotch.x, p_crotch.y, d["thigh_l"], d["leg_r_angle"] * PI / 180 + PI / 2)
	var p_shin_r = CharacterPoseCalculator.rotated_point(p_thigh_r.x, p_thigh_r.y, d["shin_l"], d["leg_r_angle"] * PI / 180 + PI / 2 + d["knee_r"])
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_crotch, p_thigh_r, thigh_w, front_thigh_color)
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_thigh_r, p_shin_r, shin_w, skin_color)
	CharacterDrawUtils.draw_foot_side(self , p_shin_r, foot_w, foot_h, shoe_color)

	# 5. スカート（該当する場合 — 手前の足の上に重ねる）
	if is_skirt:
		_draw_skirt(d, bottoms_type, pants_color, Vector2(d["wx"], d["wy"]), torso_thickness)

	# 6. 頭 + 髪
	var head_angle = d["waist_angle"] * 0.6
	var head_r = d["head_h"] / 2.0
	var hair_style = appearance.get("hair_style", "short")
	var hair_color = Color(appearance.get("hair_color", "#4a3c31"))
	_draw_hair(Vector2(hx, hy), head_r, head_w, hair_style, hair_color, skin_color, "side", head_angle)

	var eye_offset = Vector2(head_r * 0.5, 0.0) # 高さオフセットなし
	var rot_eye = Vector2(eye_offset.x * cos(head_angle) - eye_offset.y * sin(head_angle), eye_offset.x * sin(head_angle) + eye_offset.y * cos(head_angle))
	draw_circle(Vector2(hx, hy) + rot_eye, 2.5, Color("#333333"))

	var mouth_offset = Vector2(head_r * 0.5, head_r * 0.5)
	var rot_mouth = Vector2(mouth_offset.x * cos(head_angle) - mouth_offset.y * sin(head_angle), mouth_offset.x * sin(head_angle) + mouth_offset.y * cos(head_angle))
	var mouth_center = Vector2(hx, hy) + rot_mouth
	draw_line(mouth_center - Vector2(3, 0), mouth_center + Vector2(3, 0), Color("#c07070"), 2.0)

	# 7. 手前の腕（台形袖の描画）
	var p_elb_r = CharacterPoseCalculator.rotated_point(p_arm_shoulder.x, p_arm_shoulder.y, u_arm, d["arm_r_angle"] * PI / 180 + d["waist_angle"] + PI / 2)
	var p_hand_r = CharacterPoseCalculator.rotated_point(p_elb_r.x, p_elb_r.y, l_arm, d["arm_r_angle"] * PI / 180 + d["waist_angle"] + PI / 2 - 0.1)

	var s_arm_r_ang = d["arm_r_angle"] * PI / 180 + d["waist_angle"] + PI / 2 - 0.1
	_draw_sleeve_arm(p_arm_shoulder, p_elb_r, p_hand_r, arm_w, hand_hw, hand_hh, s_arm_r_ang - PI / 2, tops_type, skin_color, base_shirt_color)
