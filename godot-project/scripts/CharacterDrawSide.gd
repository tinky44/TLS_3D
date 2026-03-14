class_name CharacterDrawSide

# --- 横向き 描画 ---
static func draw(ctx: DrawContext) -> void:
	var m = ctx.m
	var p = ctx.p
	var d = ctx.d
	var skin_color = ctx.skin_color
	var base_shirt_color = ctx.base_shirt_color
	var pants_color = ctx.pants_color
	var skin_dark = ctx.skin_dark
	var shirt_dark = ctx.shirt_dark
	var pants_dark = ctx.pants_dark
	var thigh_w = ctx.thigh_w
	var shin_w = ctx.shin_w
	var arm_w = ctx.arm_w

	var hx = d["hx"]
	var hy = d["hy"]

	# 側面: 胴体の厚み = 頭の幅（仕様書）
	var head_w = (m["headWidth"] if m.has("headWidth") else m["head"] * 0.702) * p * 0.85
	var torso_thickness = head_w

	var foot_w = m["height"] * p * 0.15
	var foot_h = m["height"] * p / 20.0
	# 側面の手: 縦=頭の縦×0.83、横=肩幅/5（正面の4倍）
	var shoulder_full = (m["shoulder"] if m.has("shoulder") else 35.0) * p
	var hand_hw = shoulder_full / 5.0 / 2.0
	var hand_hh = d["head_h"] * 0.83 / 2.0
	var shoe_color = ctx.shoe_color
	var stress_ratio: float = float(d.get("stress_ratio", 0.0))

	# 0. バッグ（ランドセルなど） — 最背面に描画
	CharacterClothingDrawer.draw_bag_side(ctx)

	# === 側面用の微調整（ここを書き換えて動作確認します） ===
	var side_offset_x = -4.0 # プラスで右(前)に移動、マイナスで左(後)に移動
	var side_offset_y = 10.0 + stress_ratio * 6.0 # stressが高いほど肩を少し落とす
	# Note: 腕の太さ分だけ下に下げたかった。x軸は、頭の中心あたりを目指した。今後は計算でやりたい

	var p_shoulder = Vector2(d["sx"], d["sy"])
	var p_arm_shoulder = Vector2(d["sx"] + side_offset_x, d["sy"] + side_offset_y)
	var p_crotch = Vector2(d["cx"], d["cy"])

	# 服装タイプの判定
	var bottoms_type = ctx.bottoms_type
	var tops_type = ctx.tops_type
	var is_skirt = ctx.is_skirt

	# 1. 奥の腕（台形袖の描画）
	var arm_len = m["armLength"] * p
	var u_arm = arm_len * 0.5
	var l_arm = arm_len * 0.5

	var p_elb_l = CharacterPoseCalculator.rotated_point(p_arm_shoulder.x, p_arm_shoulder.y, u_arm, d["arm_l_angle"] * PI / 180 + d["waist_angle"] + PI / 2)
	var p_hand_l = CharacterPoseCalculator.rotated_point(p_elb_l.x, p_elb_l.y, l_arm, d["arm_l_angle"] * PI / 180 + d["waist_angle"] + PI / 2 - 0.1)

	var s_arm_l_ang = d["arm_l_angle"] * PI / 180 + d["waist_angle"] + PI / 2 - 0.1
	CharacterBodyDrawer.draw_sleeve_arm(ctx, p_arm_shoulder, p_elb_l, p_hand_l, arm_w, hand_hw, hand_hh, s_arm_l_ang - PI / 2, tops_type, skin_dark, shirt_dark, true)

	# 2. 奥の足
	var pants_thigh_w = thigh_w * 1.3
	var pelvis_bottom_w = max(torso_thickness * 1.08, pants_thigh_w)
	# すねを foot_h 分短くして足底が地面に合うようにする
	var shin_draw = d["shin_l"] - foot_h

	var p_thigh_l = CharacterPoseCalculator.rotated_point(p_crotch.x, p_crotch.y, d["thigh_l"], d["leg_l_angle"] * PI / 180 + PI / 2)
	var p_shin_l = CharacterPoseCalculator.rotated_point(p_thigh_l.x, p_thigh_l.y, shin_draw, d["leg_l_angle"] * PI / 180 + PI / 2 + d["knee_l"])
	CharacterBodyDrawer.draw_pants_leg(ctx, p_crotch, p_thigh_l, p_shin_l, thigh_w, shin_w, skin_dark, pants_dark, bottoms_type, pelvis_bottom_w)
	_draw_legwear_side(ctx, p_shin_l, p_thigh_l, shin_w, foot_w, foot_h, 0.15)

	# 3. 胴体（服）: 腰で曲がるように分割
	var p_waist = Vector2(d["navel_x"], d["navel_y"])
	var nipple_ratio_upper = 0.55 # 上部(胸)の下から55%の高さ
	CharacterDrawUtils.draw_side_torso(ctx.canvas, p_shoulder, p_waist, p_crotch, nipple_ratio_upper, torso_thickness, base_shirt_color)

	# 4. 手前の足
	var p_thigh_r = CharacterPoseCalculator.rotated_point(p_crotch.x, p_crotch.y, d["thigh_l"], d["leg_r_angle"] * PI / 180 + PI / 2)
	var p_shin_r = CharacterPoseCalculator.rotated_point(p_thigh_r.x, p_thigh_r.y, shin_draw, d["leg_r_angle"] * PI / 180 + PI / 2 + d["knee_r"])
	CharacterBodyDrawer.draw_pants_leg(ctx, p_crotch, p_thigh_r, p_shin_r, thigh_w, shin_w, skin_color, pants_color, bottoms_type, pelvis_bottom_w)
	_draw_legwear_side(ctx, p_shin_r, p_thigh_r, shin_w, foot_w, foot_h)

	# 5. ボトムス（骨盤部分またはスカート — 足の上に重ねる）
	# ジャンパースカート(blazer)のスカート部分は服の上に描画するためここでは描かない
	if is_skirt and tops_type != "blazer":
		var skirt_c = base_shirt_color if bottoms_type == "skirt_sailor" else pants_color
		if tops_type == "blouse_bow" or tops_type == "jumper_skirt":
			skirt_c = Color(0.15, 0.2, 0.35) # 紺色
		CharacterBodyDrawer.draw_skirt(ctx, bottoms_type, skirt_c, Vector2(d["hip_x"], d["hip_y"]), torso_thickness, tops_type, "side")
	elif bottoms_type == "pants":
		var p_pelvis_top = Vector2(d["hip_x"], d["hip_y"])
		var p_crotch_center = Vector2(d["cx"], d["cy"])
		var pelvis_top_w = torso_thickness * 1.05
		CharacterDrawUtils.draw_trapezoid(ctx.canvas, p_pelvis_top, p_crotch_center, pelvis_top_w, pelvis_bottom_w, pants_color)

	# 6. 頭 + 髪
	var head_angle = d["waist_angle"] * 0.6 + stress_ratio * 0.18

	var look_angle = ctx.look_head_angle
	head_angle += look_angle

	var head_r = ctx.head_r
	var hair_style = ctx.hair_style
	var hair_color = ctx.hair_color
	if hair_style == "long":
		_draw_mouth_side(ctx, hx, hy, head_r, head_angle)
	CharacterHairDrawer.draw_hair(ctx, Vector2(hx, hy), head_r, head_w, hair_style, hair_color, skin_color, "side", head_angle)

	# 6.2 帽子
	CharacterClothingDrawer.draw_hat_side(ctx, hx, hy, head_r, head_w, head_angle, ctx.hat_type, ctx.hat_color)

	# 6.5 服装オーバーレイ（側面：カラー・ラペル・リボンなど）
	CharacterClothingDrawer.draw_tops_detail_side(ctx, tops_type, base_shirt_color, torso_thickness, head_angle, skin_color)

	var eye_offset = Vector2(head_r * 0.7, 0.0) # 高さオフセットなし（回転に任せる）
	var rot_eye = Vector2(eye_offset.x * cos(head_angle) - eye_offset.y * sin(head_angle), eye_offset.x * sin(head_angle) + eye_offset.y * cos(head_angle))
	ctx.canvas.draw_circle(Vector2(hx, hy) + rot_eye, 2.5, Color("#333333"))

	if hair_style != "long":
		_draw_mouth_side(ctx, hx, hy, head_r, head_angle)

	# 7. 手前の腕（台形袖の描画）
	var p_elb_r = CharacterPoseCalculator.rotated_point(p_arm_shoulder.x, p_arm_shoulder.y, u_arm, d["arm_r_angle"] * PI / 180 + d["waist_angle"] + PI / 2)
	var p_hand_r = CharacterPoseCalculator.rotated_point(p_elb_r.x, p_elb_r.y, l_arm, d["arm_r_angle"] * PI / 180 + d["waist_angle"] + PI / 2 - 0.1)

	var s_arm_r_ang = d["arm_r_angle"] * PI / 180 + d["waist_angle"] + PI / 2 - 0.1
	CharacterBodyDrawer.draw_sleeve_arm(ctx, p_arm_shoulder, p_elb_r, p_hand_r, arm_w, hand_hw, hand_hh, s_arm_r_ang - PI / 2, tops_type, skin_color, base_shirt_color, true)

static func _draw_mouth_side(ctx: DrawContext, hx: float, hy: float, head_r: float, head_angle: float) -> void:
	var mouth_offset = Vector2(head_r * 0.5, head_r * 0.5)
	var rot_mouth = Vector2(mouth_offset.x * cos(head_angle) - mouth_offset.y * sin(head_angle), mouth_offset.x * sin(head_angle) + mouth_offset.y * cos(head_angle))
	var mouth_center = Vector2(hx, hy) + rot_mouth
	ctx.canvas.draw_line(mouth_center - Vector2(2, 0), mouth_center + Vector2(5, 2), Color("#c07070"), 2.0)

static func _draw_legwear_side(ctx: DrawContext, ankle: Vector2, knee: Vector2, shin_w: float, foot_w: float, foot_h: float, shoe_tint: float = 0.0) -> void:
	var sock_h = foot_h * 0.55
	var shin_up = (knee - ankle).normalized()
	CharacterDrawUtils.draw_rect(ctx.canvas, ankle, ankle + shin_up * sock_h, shin_w, _get_sock_color_side(ctx))

	var heel = ankle - Vector2(shin_w * 0.5, 0.0)
	var foot_color = _get_shoe_color_side(ctx).darkened(shoe_tint)
	CharacterDrawUtils.draw_foot_side(ctx.canvas, heel, foot_w, foot_h, foot_color)

	match ctx.shoes_type:
		"uwabaki":
			ctx.canvas.draw_line(
				heel + Vector2(foot_w * 0.14, foot_h * 0.30),
				heel + Vector2(foot_w * 0.82, foot_h * 0.30),
				Color("#d84a4a"),
				2.0
			)
		"loafer":
			ctx.canvas.draw_line(
				heel + Vector2(foot_w * 0.18, foot_h * 0.22),
				heel + Vector2(foot_w * 0.62, foot_h * 0.18),
				foot_color.darkened(0.30),
				2.0
			)
		_:
			pass

static func _get_sock_color_side(ctx: DrawContext) -> Color:
	match ctx.shoes_type:
		"loafer":
			return Color(0.94, 0.94, 0.96)
		"socks":
			return Color(0.98, 0.98, 1.0)
		_:
			return Color(0.97, 0.97, 0.97)

static func _get_shoe_color_side(ctx: DrawContext) -> Color:
	match ctx.shoes_type:
		"uwabaki":
			return Color("#f7f7f2")
		"loafer":
			return Color("#4b4b52")
		"socks":
			return Color("#f5f4fb")
		_:
			return ctx.shoe_color
