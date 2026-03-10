class_name CharacterBodyDrawer

# ---------------------------------------------------------------
# 袖付き腕を描画するヘルパー
#
# 肌色の腕（stick/limb）を先に描き、その上に服の袖（台形）を重ねる。
# tops_type によって袖の長さや形が変わる。
#
# 引数:
#   p_shoulder       : 腕の実際の付け根
#   p_elbow          : 肘の位置
#   p_hand           : 手首の位置
#   arm_w            : 腕の太さ（px）
#   hand_hw          : 手の横半径
#   hand_hh          : 手の縦半径
#   hand_angle       : 手の向き（ラジアン）
#   tops_type        : 服のタイプ（下記参照）
#   skin             : 肌色
#   shirt            : 袖の色
#   is_side          : true=側面描画（袖の形を上すぼみに補正）
#
# tops_type ごとの動作:
#   sweater / blouse / sailor / blazer / blazer_dark / blouse_bow / jumper_skirt
#     → 長袖: 肩→肘 台形 + 肘→手首 台形（末広がり）
#   t_shirt
#     → 半袖: 肩→肘の60%まで台形袖、残りは肌色
#   その他（ノースリーブ等）
#     → 袖なし: 肌色の腕のみ
# ---------------------------------------------------------------
static func draw_sleeve_arm(ctx: DrawContext, p_shoulder: Vector2, p_elbow: Vector2, p_hand: Vector2,
		arm_w: float, hand_hw: float, hand_hh: float, hand_angle: float,
		tops_type: String, skin: Color, shirt: Color, is_side: bool = false) -> void:
	# 【調整用】袖の太さ。肩側(top)と袖口側(bot)を別々に調整できる
	var sleeve_top_w = arm_w * 1.5 # 袖の肩側の太さ（肩をカバー）
	var sleeve_bot_w = arm_w * 1.8 # 袖口の太さ（末広がり）

	var p_top_center = p_shoulder
	if is_side:
		# 横向きの場合、背中側の位置を固定にして、前側を絞る（上すぼみ）
		var original_top_w = sleeve_top_w
		sleeve_top_w = arm_w * 1.15
		var shaved = original_top_w - sleeve_top_w
		var d = p_elbow - p_shoulder
		if d.length() > 0.01:
			var n = Vector2(-d.y, d.x).normalized()
			# nは向かって左(背中側)を向くので、中心を+n方向に半分(すぼめた分)だけ移動させる
			p_top_center = p_shoulder + n * (shaved / 2.0)

	var outline_color = Color(0.8, 0.8, 0.8, 0.5) # 薄いグレー(半透明)
	if tops_type == "sweater" or tops_type == "blouse" \
			or tops_type == "sailor" or tops_type == "blazer" \
			or tops_type == "blazer_dark" or tops_type == "blouse_bow" \
			or tops_type == "jumper_skirt":
		# 長袖（セーラー/ブレザー/リボン含む）: 肩→肘 台形、肘→手首 台形
		CharacterDrawUtils.draw_limb_part(ctx.canvas, ctx.part_shapes["limb"], p_shoulder, p_elbow, arm_w, skin)
		CharacterDrawUtils.draw_limb_part(ctx.canvas, ctx.part_shapes["limb"], p_elbow, p_hand, arm_w * 0.8, skin)
		CharacterDrawUtils.draw_trapezoid(ctx.canvas, p_top_center, p_elbow, sleeve_top_w, sleeve_bot_w, shirt, outline_color)
		CharacterDrawUtils.draw_trapezoid(ctx.canvas, p_elbow, p_hand, sleeve_bot_w, arm_w * 1.3, shirt, outline_color)

		# セーラー服の袖（手首付近）に白い2本線を追加
		if tops_type == "sailor":
			var d_arm = p_hand - p_elbow
			if d_arm.length() > 0.01:
				var dir = d_arm.normalized()
				var norm = Vector2(-dir.y, dir.x)
				var line_col = Color(0.97, 0.97, 0.97)

				# 1本目 (手首より少し上)
				var t1 = 0.83
				var p1_center = p_elbow.lerp(p_hand, t1)
				var w1 = lerp(sleeve_bot_w, float(arm_w * 1.3), t1)
				ctx.canvas.draw_line(p1_center - norm * w1 / 2.0, p1_center + norm * w1 / 2.0, line_col, 1.5)

				# 2本目 (手首付近)
				var t2 = 0.92
				var p2_center = p_elbow.lerp(p_hand, t2)
				var w2 = lerp(sleeve_bot_w, float(arm_w * 1.3), t2)
				ctx.canvas.draw_line(p2_center - norm * w2 / 2.0, p2_center + norm * w2 / 2.0, line_col, 1.5)
	elif tops_type == "t_shirt":
		# 半袖: 肩→上腕60%地点まで台形袖（末広がり）、残りは肌色limb
		var sleeve_end = p_top_center.lerp(p_elbow, 0.6)
		CharacterDrawUtils.draw_limb_part(ctx.canvas, ctx.part_shapes["limb"], p_shoulder, p_elbow, arm_w, skin)
		CharacterDrawUtils.draw_limb_part(ctx.canvas, ctx.part_shapes["limb"], p_elbow, p_hand, arm_w * 0.8, skin)
		CharacterDrawUtils.draw_trapezoid(ctx.canvas, p_top_center, sleeve_end, sleeve_top_w, sleeve_bot_w, shirt, outline_color)
	else:
		# ノースリーブ等: 通常の腕描画のみ
		CharacterDrawUtils.draw_limb_part(ctx.canvas, ctx.part_shapes["limb"], p_shoulder, p_elbow, arm_w, skin)
		CharacterDrawUtils.draw_limb_part(ctx.canvas, ctx.part_shapes["limb"], p_elbow, p_hand, arm_w * 0.8, skin)

	CharacterDrawUtils.draw_hand(ctx.canvas, p_hand, hand_hw, hand_hh, skin, hand_angle)

# ---------------------------------------------------------------
# パンツ付き脚を描画するヘルパー
#
# 肌色の脚（stick/limb）を先に描き、bottoms_type == "pants" の場合は
# その上に台形のパンツを重ねる。スカート時は肌色脚のみ描く（スカートは別で描画）。
#
# 引数:
#   p_hip         : 股関節（脚の付け根）
#   p_knee        : 膝の位置
#   p_ankle       : 足首の位置
#   thigh_w       : 太もも幅（px）
#   shin_w        : すね幅（px）
#   skin          : 肌色
#   pants         : パンツの色
#   bottoms_type  : ボトムスのタイプ
#   pants_top_w   : パンツ台形の上辺幅（骨盤の半幅に合わせる）
# ---------------------------------------------------------------
static func draw_pants_leg(ctx: DrawContext, p_hip: Vector2, p_knee: Vector2, p_ankle: Vector2,
		thigh_w: float, shin_w: float, skin: Color, pants: Color,
		bottoms_type: String, pants_top_w: float) -> void:
	# 肌色の脚を描画
	CharacterDrawUtils.draw_limb_part(ctx.canvas, ctx.part_shapes["limb"], p_hip, p_knee, thigh_w, skin)
	CharacterDrawUtils.draw_limb_part(ctx.canvas, ctx.part_shapes["limb"], p_knee, p_ankle, shin_w, skin)
	# パンツの場合は台形で上書き（股から開始してジョイントをカバー）
	if bottoms_type == "pants":
		# 【調整用】パンツの太さ倍率。1.1で太もも幅より10%広い
		var pants_knee_w = thigh_w * 1.1
		var pants_ankle_w = shin_w * 1.15
		CharacterDrawUtils.draw_trapezoid(ctx.canvas, p_hip, p_knee, pants_top_w, pants_knee_w, pants)
		CharacterDrawUtils.draw_trapezoid(ctx.canvas, p_knee, p_ankle, pants_knee_w, pants_ankle_w, pants)

# ---------------------------------------------------------------
# スカート描画ヘルパー
#
# bottoms_type に応じたスカートを描画する。
# 側面では脚の動きに合わせてスカートを傾け、裾を広げる。
# 正面・背面では足の広がりに合わせて裾幅を調整し、下端にカーブを付ける。
#
# 引数:
#   bottoms_type : "skirt" / "skirt_short" / "skirt_long"
#   bottoms_color: スカートの色
#   waist_pos    : 腰（ウエスト上端）の位置
#   base_width   : 腰幅の基準（胴体の幅）
#   facing       : "front" / "back" / "side"
#
# bottoms_type ごとのスカート丈:
#   skirt_long   : 腰〜股 + 太もも全長 + すねの30%（足首丈）
#   skirt / skirt_short : 腰〜股 + 太もも40%（膝上丈）
# ---------------------------------------------------------------
static func draw_skirt(ctx: DrawContext, bottoms_type: String, bottoms_color: Color, waist_pos: Vector2, base_width: float, facing: String = "front") -> void:
	var d = ctx.d
	var waist_to_crotch = d["cy"] - waist_pos.y
	var skirt_length: float
	var hem_w: float

	if bottoms_type == "skirt_long":
		skirt_length = waist_to_crotch + d["thigh_l"] + d["shin_l"] * 0.3
		hem_w = base_width * 1.3
	elif bottoms_type == "skirt_sailor":
		# 膝（thigh_l）より少し下（shin_lの10%）まで
		skirt_length = waist_to_crotch + d["thigh_l"] + d["shin_l"] * 0.1
		hem_w = base_width * 1.4
	else: # "skirt" or "skirt_short"
		skirt_length = waist_to_crotch + d["thigh_l"] * 0.4
		hem_w = base_width * 1.5

	# 側面では脚の動きに合わせて前後に傾け、裾を広げる
	if facing == "side":
		var avg_leg_ang = (d["leg_l_angle"] + d["leg_r_angle"]) / 2.0
		# スカートは布のため重力で多少下に向くので、脚の角度を完全に追うのではなく軽減(0.7倍)
		var skirt_ang = (avg_leg_ang * 0.7) * PI / 180.0 + PI / 2.0
		var p_bottom = Vector2(waist_pos.x + skirt_length * cos(skirt_ang), waist_pos.y + skirt_length * sin(skirt_ang))

		# 脚の実際のX座標の広がりを計算して、裾が脚を覆い隠せるようにする
		var ang_l = d["leg_l_angle"] * PI / 180.0 + PI / 2.0
		var ang_r = d["leg_r_angle"] * PI / 180.0 + PI / 2.0
		var knee_l_x = d["cx"] + d["thigh_l"] * cos(ang_l)
		var knee_r_x = d["cx"] + d["thigh_l"] * cos(ang_r)

		var min_x = min(knee_l_x, knee_r_x)
		var max_x = max(knee_l_x, knee_r_x)

		if bottoms_type == "skirt_long":
			# ロングスカートの場合は足首のX座標まで考慮する
			var ankle_l_x = knee_l_x + d["shin_l"] * cos(ang_l + d["knee_l"])
			var ankle_r_x = knee_r_x + d["shin_l"] * cos(ang_r + d["knee_r"])
			min_x = min(min_x, min(ankle_l_x, ankle_r_x))
			max_x = max(max_x, max(ankle_l_x, ankle_r_x))

		var spread_x = abs(max_x - min_x)
		# 【調整用】裾の広がりマージン。大きいほど裾が脚より広がる
		var spread_margin = 1.4 if bottoms_type == "skirt_long" else 1.2
		var actual_hem_w = max(hem_w, spread_x * spread_margin)

		CharacterDrawUtils.draw_trapezoid(ctx.canvas, waist_pos, p_bottom, base_width, actual_hem_w, bottoms_color)

		# プリーツ（セーラー服スカート用）
		if bottoms_type == "skirt_sailor":
			var pleat_col = bottoms_color.darkened(0.2)
			var d_vec = p_bottom - waist_pos
			if d_vec.length() > 0.01:
				var n = Vector2(-d_vec.y, d_vec.x).normalized()
				var h_top = base_width / 2.0
				var h_hem = actual_hem_w / 2.0
				for i in range(1, 7): # 6本の線を入れる
					var t = float(i) / 7.0
					var top_p = waist_pos + n * lerp(-h_top, h_top, t)
					var bot_p = p_bottom + n * lerp(-h_hem, h_hem, t)
					ctx.canvas.draw_line(top_p, bot_p, pleat_col, 1.5)
		return

	# 正面・背面の場合、足の広がりに合わせて裾を広げ、下端に緩やかなカーブを付ける
	var p_bottom_y = waist_pos.y + skirt_length

	# 両足首のおおよその位置を計算して、脚が大きく開いているなら裾を広げる
	var f_leg_l_ang = (d["leg_l_angle"] * 0.2) * PI / 180 + PI / 2
	var f_leg_r_ang = (d["leg_r_angle"] * 0.2) * PI / 180 + PI / 2

	# 正面の腰の左右のオフセット（_draw_front_back内で計算しているものと同じ）
	var hip_off = base_width * 0.25
	var p_hip_l_x = waist_pos.x - hip_off
	var p_hip_r_x = waist_pos.x + hip_off

	var ankle_l_x = p_hip_l_x + (d["thigh_l"] + d["shin_l"]) * cos(f_leg_l_ang)
	var ankle_r_x = p_hip_r_x + (d["thigh_l"] + d["shin_l"]) * cos(f_leg_r_ang)
	var legs_spread = abs(ankle_r_x - ankle_l_x)

	var actual_hem_w = max(hem_w, legs_spread * 0.9) # 足幅の90%まではスカートが追従して広がる
	var half_top = base_width / 2.0
	var half_hem = actual_hem_w / 2.0

	# 【調整用】下端を下向きに少し膨らませる（カーブの近似）。0.05で5%の垂れ
	var curve_drop = skirt_length * 0.05

	var pts = PackedVector2Array([
		Vector2(waist_pos.x - half_top, waist_pos.y),
		Vector2(waist_pos.x + half_top, waist_pos.y),
		Vector2(waist_pos.x + half_hem, p_bottom_y),
		Vector2(waist_pos.x, p_bottom_y + curve_drop), # 裾の中央が少し下がる
		Vector2(waist_pos.x - half_hem, p_bottom_y)
	])
	ctx.canvas.draw_polygon(pts, PackedColorArray([bottoms_color]))

	# プリーツ（セーラー服スカート用）
	if bottoms_type == "skirt_sailor":
		var pleat_col = bottoms_color.darkened(0.2)
		for i in range(1, 7): # 6本の線を入れる
			var t = float(i) / 7.0
			var top_p = Vector2(lerp(waist_pos.x - half_top, waist_pos.x + half_top, t), waist_pos.y)
			var bx = lerp(waist_pos.x - half_hem, waist_pos.x + half_hem, t)
			# カーブに合わせて下端を計算
			var drop = curve_drop * (1.0 - pow((t - 0.5) * 2.0, 2.0))
			var bot_p = Vector2(bx, p_bottom_y + drop)
			ctx.canvas.draw_line(top_p, bot_p, pleat_col, 1.5)
