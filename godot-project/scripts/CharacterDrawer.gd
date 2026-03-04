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
	# IK / Crouch / 関節角度 などの計算を別クラス(CharacterPoseCalculator)で処理
	var d = CharacterPoseCalculator.calculate_pose_data(player, m, p)

	# === 描画実行 ===
	var flip = (dir == -1 and facing == "side")
	
	var skin_color = Color("#ffe4c4")
	var base_shirt_color = Color("#ab82a8")
	var pants_color = Color("#e5d6ba")

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
		_draw_front_back(m, p, d, skin_color, base_shirt_color, pants_color, skin_dark, shirt_dark, pants_dark, shoulder_w, thigh_w, shin_w, arm_w, neck_w)
	else:
		_draw_side(m, p, d, skin_color, base_shirt_color, pants_color, skin_dark, shirt_dark, pants_dark, shoulder_w, hip_w, thigh_w, shin_w, arm_w, neck_w)

	if flip:
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

# --- 正面・背面 描画 ---
func _draw_front_back(m, p, d, skin_color, base_shirt_color, pants_color, skin_dark, _shirt_dark, _pants_dark, shoulder_w, thigh_w, shin_w, arm_w, neck_w):
	var facing = player.facing
	var body_w = shoulder_w * 0.6
	var body_w_half = body_w / 2.0
	var sh_off = shoulder_w * 0.5 - arm_w * 0.5
	var hp_off = body_w_half * 0.6

	var p_hip_l = Vector2(d["cx"] - hp_off, d["cy"])
	var p_hip_r = Vector2(d["cx"] + hp_off, d["cy"])
	var p_sh_l = Vector2(d["sx"] - sh_off, d["front_sy"])
	var p_sh_r = Vector2(d["sx"] + sh_off, d["front_sy"])

	var f_leg_l_ang = (d["leg_l_angle"] * 0.2) * PI / 180 + PI / 2
	var f_leg_r_ang = (d["leg_r_angle"] * 0.2) * PI / 180 + PI / 2

	var foot_w = 7.0 * p
	var foot_h = 3.5 * p
	var hand_size = 3.5 * p
	var shoe_color = pants_color

	# 1. 両足
	var p_thigh_l = CharacterPoseCalculator.rotated_point(p_hip_l.x, p_hip_l.y, d["thigh_l"], f_leg_l_ang)
	var p_shin_l = CharacterPoseCalculator.rotated_point(p_thigh_l.x, p_thigh_l.y, d["shin_l"], f_leg_l_ang + d["knee_l"] * 0.2)
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_hip_l, p_thigh_l, thigh_w, pants_color)
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_thigh_l, p_shin_l, shin_w, skin_color)
	CharacterDrawUtils.draw_foot_front(self , p_shin_l, foot_w, foot_h, shoe_color)

	var p_thigh_r = CharacterPoseCalculator.rotated_point(p_hip_r.x, p_hip_r.y, d["thigh_l"], f_leg_r_ang)
	var p_shin_r = CharacterPoseCalculator.rotated_point(p_thigh_r.x, p_thigh_r.y, d["shin_l"], f_leg_r_ang + d["knee_r"] * 0.2)
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_hip_r, p_thigh_r, thigh_w, pants_color)
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_thigh_r, p_shin_r, shin_w, skin_color)
	CharacterDrawUtils.draw_foot_front(self , p_shin_r, foot_w, foot_h, shoe_color)

	# 2. 胴体 (シャツ)
	CharacterDrawUtils.draw_torso_part(self , part_shapes["torso_front_lower"], Vector2(d["wx"], d["wy"]), Vector2(d["cx"], d["cy"]), body_w, body_w, base_shirt_color)
	CharacterDrawUtils.draw_torso_part(self , part_shapes["torso_front_upper"], Vector2(d["sx"], d["front_sy"]), Vector2(d["wx"], d["wy"]), body_w, body_w, base_shirt_color)

	# 3. 首
	CharacterDrawUtils.draw_limb_part(self , part_shapes["neck"], Vector2(d["sx"], d["front_sy"]), Vector2(d["nx"], d["ny"]), neck_w, skin_color)

	# 4. 頭
	var head_w = (m["headWidth"] if m.has("headWidth") else m["head"] * 0.702) * p
	CharacterDrawUtils.draw_head_part(self , part_shapes["head"], Vector2(d["hx"], d["hy"]), head_w, d["head_h"], skin_color)

	# 5. 両腕（線 + 円関節 + 小さな手）
	var arm_len = m["armLength"] * p
	var u_arm = arm_len * 0.45
	var l_arm = arm_len * 0.55

	var f_arm_l_ang = 0.12 + (d["arm_l_angle"] * 0.3) * PI / 180 + PI / 2
	var p_elb_l = CharacterPoseCalculator.rotated_point(p_sh_l.x, p_sh_l.y, u_arm, f_arm_l_ang)
	var p_hand_l = CharacterPoseCalculator.rotated_point(p_elb_l.x, p_elb_l.y, l_arm, f_arm_l_ang)

	var f_arm_r_ang = -0.12 + (d["arm_r_angle"] * 0.3) * PI / 180 + PI / 2
	var p_elb_r = CharacterPoseCalculator.rotated_point(p_sh_r.x, p_sh_r.y, u_arm, f_arm_r_ang)
	var p_hand_r = CharacterPoseCalculator.rotated_point(p_elb_r.x, p_elb_r.y, l_arm, f_arm_r_ang)

	var arm_color = skin_color if facing == "front" else skin_dark

	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_sh_l, p_elb_l, arm_w, arm_color)
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_elb_l, p_hand_l, arm_w * 0.8, arm_color)
	CharacterDrawUtils.draw_hand(self , p_hand_l, hand_size, arm_color)

	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_sh_r, p_elb_r, arm_w, arm_color)
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_elb_r, p_hand_r, arm_w * 0.8, arm_color)
	CharacterDrawUtils.draw_hand(self , p_hand_r, hand_size, arm_color)

	# 6. 顔とディテール
	if facing == "front":
		var hx = d["hx"]
		var hy = d["hy"]

		var eye_off_x = head_w * 0.2
		var eye_y = hy - (d["head_h"] * 0.1)
		draw_circle(Vector2(hx - eye_off_x, eye_y), 2.5, Color("#333333"))
		draw_circle(Vector2(hx + eye_off_x, eye_y), 2.5, Color("#333333"))

		var mouth_y = hy + (d["head_h"] * 0.15)
		var m_pts = PackedVector2Array()
		for i in range(11):
			var t = float(i) / 10.0
			var xx = lerp(-head_w * 0.15, head_w * 0.15, t)
			var yy = mouth_y + sin(t * PI) * 3.0
			m_pts.append(Vector2(hx + xx, yy))
		for i in range(m_pts.size() - 1):
			draw_line(m_pts[i], m_pts[i + 1], Color("#c07070"), 2.0)

# --- 横向き 描画 ---
func _draw_side(m, p, d, skin_color, base_shirt_color, pants_color, skin_dark, _shirt_dark, pants_dark, _shoulder_w, _hip_w, thigh_w, shin_w, arm_w, _neck_w):
	var hx = d["hx"]
	var hy = d["hy"]

	# 側面: 胴体の厚み = 頭の幅（仕様書）
	var head_w = (m["headWidth"] if m.has("headWidth") else m["head"] * 0.702) * p * 0.85
	var torso_thickness = head_w

	var foot_w = 9.0 * p
	var foot_h = 3.5 * p
	var hand_size = 3.5 * p
	var shoe_color = pants_color

	var p_shoulder = Vector2(d["sx"], d["sy"])
	var p_crotch = Vector2(d["cx"], d["cy"])

	# 1. 奥の腕（線 + 円関節 + 小さな手）
	var arm_len = m["armLength"] * p
	var u_arm = arm_len * 0.45
	var l_arm = arm_len * 0.55

	var p_elb_l = CharacterPoseCalculator.rotated_point(p_shoulder.x, p_shoulder.y, u_arm, d["arm_l_angle"] * PI / 180 + d["waist_angle"] + PI / 2)
	var p_hand_l = CharacterPoseCalculator.rotated_point(p_elb_l.x, p_elb_l.y, l_arm, d["arm_l_angle"] * PI / 180 + d["waist_angle"] + PI / 2 - 0.1)

	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_shoulder, p_elb_l, arm_w, skin_dark)
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_elb_l, p_hand_l, arm_w * 0.8, skin_dark)
	CharacterDrawUtils.draw_hand(self , p_hand_l, hand_size, skin_dark)

	# 2. 奥の足
	var p_thigh_l = CharacterPoseCalculator.rotated_point(p_crotch.x, p_crotch.y, d["thigh_l"], d["leg_l_angle"] * PI / 180 + PI / 2)
	var p_shin_l = CharacterPoseCalculator.rotated_point(p_thigh_l.x, p_thigh_l.y, d["shin_l"], d["leg_l_angle"] * PI / 180 + PI / 2 + d["knee_l"])
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_crotch, p_thigh_l, thigh_w, pants_dark)
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_thigh_l, p_shin_l, shin_w, skin_dark)
	CharacterDrawUtils.draw_foot_side(self , p_shin_l, foot_w, foot_h, shoe_color.darkened(0.15))

	# 3. 胴体（服）: 腰で曲がるように分割
	var p_waist = Vector2(d["wx"], d["wy"])
	var nipple_ratio_upper = 0.55 # 上部(胸)の下から55%の高さ
	CharacterDrawUtils.draw_side_torso(self , p_shoulder, p_waist, p_crotch, nipple_ratio_upper, torso_thickness, base_shirt_color)

	# 4. 手前の足
	var p_thigh_r = CharacterPoseCalculator.rotated_point(p_crotch.x, p_crotch.y, d["thigh_l"], d["leg_r_angle"] * PI / 180 + PI / 2)
	var p_shin_r = CharacterPoseCalculator.rotated_point(p_thigh_r.x, p_thigh_r.y, d["shin_l"], d["leg_r_angle"] * PI / 180 + PI / 2 + d["knee_r"])
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_crotch, p_thigh_r, thigh_w, pants_color)
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_thigh_r, p_shin_r, shin_w, skin_color)
	CharacterDrawUtils.draw_foot_side(self , p_shin_r, foot_w, foot_h, shoe_color)

	# 6. 頭
	var head_angle = d["waist_angle"] * 0.6
	CharacterDrawUtils.draw_head_part(self , part_shapes["head"], Vector2(hx, hy), head_w, d["head_h"], skin_color, head_angle)

	var eye_offset = Vector2(head_w * 0.25, -d["head_h"] * 0.1)
	var rot_eye = Vector2(eye_offset.x * cos(head_angle) - eye_offset.y * sin(head_angle), eye_offset.x * sin(head_angle) + eye_offset.y * cos(head_angle))
	draw_circle(Vector2(hx, hy) + rot_eye, 2.5, Color("#333333"))

	var mouth_offset = Vector2(head_w * 0.25, d["head_h"] * 0.15)
	var rot_mouth = Vector2(mouth_offset.x * cos(head_angle) - mouth_offset.y * sin(head_angle), mouth_offset.x * sin(head_angle) + mouth_offset.y * cos(head_angle))
	draw_line(Vector2(hx, hy) + rot_mouth - Vector2(1, 0), Vector2(hx, hy) + rot_mouth + Vector2(3, -2), Color("#c07070"), 2.0)

	# 7. 手前の腕
	var p_elb_r = CharacterPoseCalculator.rotated_point(p_shoulder.x, p_shoulder.y, u_arm, d["arm_r_angle"] * PI / 180 + d["waist_angle"] + PI / 2)
	var p_hand_r = CharacterPoseCalculator.rotated_point(p_elb_r.x, p_elb_r.y, l_arm, d["arm_r_angle"] * PI / 180 + d["waist_angle"] + PI / 2 - 0.1)

	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_shoulder, p_elb_r, arm_w, skin_color)
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_elb_r, p_hand_r, arm_w * 0.8, skin_color)
	CharacterDrawUtils.draw_hand(self , p_hand_r, hand_size, skin_color)
