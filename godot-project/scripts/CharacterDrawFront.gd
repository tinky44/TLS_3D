class_name CharacterDrawFront

# --- 正面・背面 描画 ---
static func draw(ctx: DrawContext) -> void:
	var m = ctx.m
	var p = ctx.p
	var d = ctx.d
	var facing = ctx.facing
	var skin_color = ctx.skin_color
	var base_shirt_color = ctx.base_shirt_color
	var pants_color = ctx.pants_color
	var skin_dark = ctx.skin_dark
	var shirt_dark = ctx.shirt_dark
	var shoulder_w = ctx.shoulder_w
	var thigh_w = ctx.thigh_w
	var shin_w = ctx.shin_w
	var arm_w = ctx.arm_w

	var body_w = shoulder_w * 0.6
	var body_w_half = body_w / 2.0
	var sh_off = shoulder_w * 0.5 - arm_w * 0.5
	var hp_off = body_w_half * 0.6

	var p_hip_l = Vector2(d["cx"] - hp_off, d["cy"])
	var p_hip_r = Vector2(d["cx"] + hp_off, d["cy"])

	# === 正面用の微調整（ここを書き換えて動作確認します） ===
	var front_offset_x = -5.0 # プラスにすると腕が外側に広がる、マイナスで内側
	var front_offset_y = 10.0 # プラスにすると腕が下に下がる、マイナスで上に上がる
	# Note: 腕の太さ分だけ下に下げたかった

	var p_sh_l = Vector2(d["front_sx"] - sh_off - front_offset_x, d["front_sy"] + front_offset_y)
	var p_sh_r = Vector2(d["front_sx"] + sh_off + front_offset_x, d["front_sy"] + front_offset_y)

	var f_leg_l_ang = (d["leg_l_angle"] * 0.2) * PI / 180 + PI / 2
	var f_leg_r_ang = (d["leg_r_angle"] * 0.2) * PI / 180 + PI / 2

	var foot_h = m["height"] * p / 20.0
	# 正面の手: 縦=頭の縦×0.83、横=肩幅/5（側面の1/4相当）
	var shoulder_full = (m["shoulder"] if m.has("shoulder") else 35.0) * p
	var hand_hw = shoulder_full / 5.0 / 4.0 / 2.0
	var hand_hh = d["head_h"] * 0.83 / 2.0
	var shoe_color = ctx.shoe_color

	var bottoms_type = ctx.bottoms_type
	var tops_type = ctx.tops_type
	var is_skirt = ctx.is_skirt

	# 0. 髪のベースレイヤー（正面向きの場合、体の後ろに描画する）
	var hair_style = ctx.hair_style
	var hair_color = ctx.hair_color
	var head_r = ctx.head_r
	if facing == "front":
		CharacterHairDrawer.draw_hair_base_layer(ctx, Vector2(d["front_hx"], d["front_hy"]), head_r, hair_style, hair_color)

	# 1. 両足
	var pants_thigh_w = thigh_w * 1.3
	var pelvis_w = (p_hip_r.x - p_hip_l.x) + pants_thigh_w
	var leg_pants_top_w = pelvis_w / 2.0 # 各脚は骨盤の底辺の半分ずつを担当

	# すねを foot_h 分短くして足底が地面に合うようにする
	var shin_draw = d["shin_l"] - foot_h

	var p_thigh_l = CharacterPoseCalculator.rotated_point(p_hip_l.x, p_hip_l.y, d["thigh_l"], f_leg_l_ang)
	var p_shin_l = CharacterPoseCalculator.rotated_point(p_thigh_l.x, p_thigh_l.y, shin_draw, f_leg_l_ang + d["knee_l"] * 0.2)
	CharacterBodyDrawer.draw_pants_leg(ctx, p_hip_l, p_thigh_l, p_shin_l, thigh_w, shin_w, skin_color, pants_color, bottoms_type, leg_pants_top_w)
	var sock_h = foot_h * 0.55
	var sock_color = Color(0.97, 0.97, 0.97)
	var shin_up_l = (p_thigh_l - p_shin_l).normalized() # 足首→膝方向（上向き）
	CharacterDrawUtils.draw_rect(ctx.canvas, p_shin_l, p_shin_l + shin_up_l * sock_h, shin_w, sock_color)
	CharacterDrawUtils.draw_foot_front(ctx.canvas, p_shin_l, shin_w, foot_h, shoe_color)

	var p_thigh_r = CharacterPoseCalculator.rotated_point(p_hip_r.x, p_hip_r.y, d["thigh_l"], f_leg_r_ang)
	var p_shin_r = CharacterPoseCalculator.rotated_point(p_thigh_r.x, p_thigh_r.y, shin_draw, f_leg_r_ang + d["knee_r"] * 0.2)
	CharacterBodyDrawer.draw_pants_leg(ctx, p_hip_r, p_thigh_r, p_shin_r, thigh_w, shin_w, skin_color, pants_color, bottoms_type, leg_pants_top_w)
	var shin_up_r = (p_thigh_r - p_shin_r).normalized() # 足首→膝方向（上向き）
	CharacterDrawUtils.draw_rect(ctx.canvas, p_shin_r, p_shin_r + shin_up_r * sock_h, shin_w, sock_color)
	CharacterDrawUtils.draw_foot_front(ctx.canvas, p_shin_r, shin_w, foot_h, shoe_color)

	# 1.5 両腕（台形袖の描画）
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

	CharacterBodyDrawer.draw_sleeve_arm(ctx, p_sh_l, p_elb_l, p_hand_l, arm_w, hand_hw, hand_hh, f_arm_l_ang - PI / 2, tops_type, arm_skin, arm_shirt)
	CharacterBodyDrawer.draw_sleeve_arm(ctx, p_sh_r, p_elb_r, p_hand_r, arm_w, hand_hw, hand_hh, f_arm_r_ang - PI / 2, tops_type, arm_skin, arm_shirt)

	# 2. 胴体 (シャツ) — 正面ビュー用座標を使用
	CharacterDrawUtils.draw_torso_part(ctx.canvas, ctx.part_shapes["torso_front_lower"], Vector2(d["front_navel_x"], d["front_navel_y"]), Vector2(d["cx"], d["cy"]), body_w, body_w, base_shirt_color)
	CharacterDrawUtils.draw_torso_part(ctx.canvas, ctx.part_shapes["torso_front_upper"], Vector2(d["front_sx"], d["front_sy"]), Vector2(d["front_navel_x"], d["front_navel_y"]), body_w, body_w, base_shirt_color)

	# 3. ボトムス（骨盤部分またはスカート）
	# ジャンパースカート(blazer)のスカート部分は服の上に描画するためここでは描かない
	if is_skirt and tops_type != "blazer":
		var skirt_c = base_shirt_color if bottoms_type == "skirt_sailor" else pants_color
		if tops_type == "blouse_bow" or tops_type == "jumper_skirt":
			skirt_c = Color(0.15, 0.2, 0.35) # 紺色
		CharacterBodyDrawer.draw_skirt(ctx, bottoms_type, skirt_c, Vector2(d["front_hip_x"], d["front_hip_y"]), body_w, facing)
	elif bottoms_type == "pants":
		var p_pelvis_top = Vector2(d["front_hip_x"], d["front_hip_y"])
		var p_crotch = Vector2(d["cx"], d["cy"])
		var pelvis_top_w = body_w * 1.05
		CharacterDrawUtils.draw_trapezoid(ctx.canvas, p_pelvis_top, p_crotch, pelvis_top_w, pelvis_w, pants_color)

	# 4. 頭 + 髪
	var head_w = (m["headWidth"] if m.has("headWidth") else m["head"] * 0.702) * p
	CharacterHairDrawer.draw_hair(ctx, Vector2(d["front_hx"], d["front_hy"]), head_r, head_w, hair_style, hair_color, skin_color, facing)

	# 4.2 帽子
	CharacterClothingDrawer.draw_hat_front(ctx, d["front_hx"], d["front_hy"], head_r, head_w, ctx.hat_type, ctx.hat_color)

	# 4.5 服装オーバーレイ（カラー・ラペル・リボンなど）
	CharacterClothingDrawer.draw_tops_detail_front(ctx, tops_type, base_shirt_color, body_w, shoulder_w, skin_color)

	# 6. 顔とディテール
	if facing == "front":
		var hx = d["front_hx"]
		var hy = d["front_hy"]

		var look_pitch = ctx.look_pitch

		var eye_off_x = head_w * 0.2
		var eye_y = hy + look_pitch
		ctx.canvas.draw_circle(Vector2(hx - eye_off_x, eye_y), 2.5, Color("#333333"))
		ctx.canvas.draw_circle(Vector2(hx + eye_off_x, eye_y), 2.5, Color("#333333"))

		var mouth_y = hy + (d["head_h"] * 0.25) + look_pitch # 目と顎の中間
		var m_pts = PackedVector2Array()
		for i in range(11):
			var t = float(i) / 10.0
			var xx = lerp(-head_w * 0.15, head_w * 0.15, t)
			var yy = mouth_y + sin(t * PI) * 3.0
			m_pts.append(Vector2(hx + xx, yy))
		for i in range(m_pts.size() - 1):
			ctx.canvas.draw_line(m_pts[i], m_pts[i + 1], Color("#c07070"), 2.0)
