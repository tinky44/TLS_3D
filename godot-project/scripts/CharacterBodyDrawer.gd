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
#   sweater / blouse / sailor / blazer / blouse_bow / jumper_skirt
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
			or tops_type == "blouse_bow" \
			or tops_type == "jumper_skirt":
		# 長袖（セーラー/ジャンパースカート/リボン含む）: 肩→肘 台形、肘→手首 台形
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

# ジャンパー系トップスが側面で共有するウエスト上端位置。
# draw_skirt と衣装ディテール側で同じアンカーを使い、屈み時の分離を防ぐ。
static func get_side_garment_waist_pos(ctx: DrawContext) -> Vector2:
	var d = ctx.d
	var u_arm = ctx.m["armLength"] * ctx.p * 0.5 + 10.0
	var shoulder = Vector2(d["sx"], d["sy"])
	var torso_vec = Vector2(d["navel_x"] - shoulder.x, d["navel_y"] - shoulder.y)
	var torso_dir = torso_vec.normalized() if torso_vec.length() > 0.01 else Vector2(0, 1)
	return shoulder + torso_dir * u_arm

# ジャンパー系トップスが正面・背面で共有するウエスト上端位置。
# 側面と同じ「肩から胴体上部を一定距離 내려る」基準を、
# 正面投影された胴体長へ比率変換して合わせる。
static func get_front_garment_waist_pos(ctx: DrawContext) -> Vector2:
	var d = ctx.d
	var shoulder = Vector2(d["front_sx"], d["front_sy"])
	var navel = Vector2(d["front_navel_x"], d["front_navel_y"])
	var chest_l = max(float(d.get("chest_l", 0.0)), 0.01)
	var u_arm = ctx.m["armLength"] * ctx.p * 0.5 + 10.0
	var t = clamp(u_arm / chest_l, 0.0, 1.0)
	return shoulder.lerp(navel, t)

# セーラースカートの側面上端位置。
# 下胴の中心線（へそ→股）上で合わせ、屈み時にトップス下端とのずれを抑える。
static func get_side_sailor_waist_pos(ctx: DrawContext) -> Vector2:
	var d = ctx.d
	var p_waist = Vector2(d["navel_x"], d["navel_y"])
	var p_crotch = Vector2(d["cx"], d["cy"])
	return p_waist.lerp(p_crotch, 0.5)

static func _normalized_or(v: Vector2, fallback: Vector2) -> Vector2:
	if v.length() > 0.01:
		return v.normalized()
	if fallback.length() > 0.01:
		return fallback.normalized()
	return Vector2(0, 1)

static func _side_proj(point: Vector2, origin: Vector2, side_dir: Vector2) -> float:
	return (point - origin).dot(side_dir)

static func _append_segment_edge_candidates(candidates: Array, p_start: Vector2, p_end: Vector2, width: float, samples: Array) -> void:
	var seg = p_end - p_start
	if seg.length() <= 0.01:
		return
	var side_n = Vector2(-seg.y, seg.x).normalized() * (width / 2.0)
	for sample in samples:
		var t := float(sample)
		var center = p_start.lerp(p_end, t)
		candidates.append(center + side_n)
		candidates.append(center - side_n)

static func _pick_side_outer_candidate(candidates: Array, waist_pos: Vector2, belt_pos: Vector2,
		side_dir: Vector2, axis_dir: Vector2, skirt_length: float, min_axis: float = -12.0) -> Dictionary:
	var best_score := -1000000000.0
	var best_axis := 0.0
	var best_pos := belt_pos
	var found := false
	for candidate in candidates:
		var point: Vector2 = candidate
		var axis_pos = (point - waist_pos).dot(axis_dir)
		if axis_pos < min_axis or axis_pos > skirt_length + 12.0:
			continue
		var first_seg = belt_pos.distance_to(point)
		if first_seg >= skirt_length - 0.5:
			continue
		var score = _side_proj(point, waist_pos, side_dir)
		if (not found) or score > best_score + 0.01 or (abs(score - best_score) <= 0.01 and axis_pos > best_axis):
			best_score = score
			best_axis = axis_pos
			best_pos = point
			found = true
	return {
		"found": found,
		"pos": best_pos,
		"score": best_score,
		"axis_pos": best_axis,
	}

static func _pick_side_peak_candidate(candidates: Array, waist_pos: Vector2, belt_pos: Vector2,
		side_dir: Vector2, axis_dir: Vector2, skirt_length: float, min_axis: float = -24.0) -> Dictionary:
	var best_score := -1000000000.0
	var best_axis := 0.0
	var best_pos := belt_pos
	var found := false
	for candidate in candidates:
		var point: Vector2 = candidate
		var axis_pos = (point - waist_pos).dot(axis_dir)
		if axis_pos < min_axis or axis_pos > skirt_length * 0.7:
			continue
		var first_seg = belt_pos.distance_to(point)
		if first_seg >= skirt_length - 0.5:
			continue
		var frontness = _side_proj(point, waist_pos, side_dir)
		var height_bonus = max(belt_pos.y - point.y, 0.0) * 2.0
		var score = frontness + height_bonus
		if (not found) or score > best_score + 0.01 or (abs(score - best_score) <= 0.01 and point.y < best_pos.y):
			best_score = score
			best_axis = axis_pos
			best_pos = point
			found = true
	return {
		"found": found,
		"pos": best_pos,
		"score": best_score,
		"axis_pos": best_axis,
	}

static func _cross2(a: Vector2, b: Vector2) -> float:
	return a.x * b.y - a.y * b.x

static func _point_on_segment(a: Vector2, point: Vector2, b: Vector2, eps: float = 0.01) -> bool:
	if abs(_cross2(point - a, b - a)) > eps:
		return false
	return (
		point.x >= min(a.x, b.x) - eps
		and point.x <= max(a.x, b.x) + eps
		and point.y >= min(a.y, b.y) - eps
		and point.y <= max(a.y, b.y) + eps
	)

static func _segments_intersect(a: Vector2, b: Vector2, c: Vector2, d: Vector2, eps: float = 0.01) -> bool:
	var ab_c = _cross2(b - a, c - a)
	var ab_d = _cross2(b - a, d - a)
	var cd_a = _cross2(d - c, a - c)
	var cd_b = _cross2(d - c, b - c)

	if (
		((ab_c > eps and ab_d < -eps) or (ab_c < -eps and ab_d > eps))
		and ((cd_a > eps and cd_b < -eps) or (cd_a < -eps and cd_b > eps))
	):
		return true
	if abs(ab_c) <= eps and _point_on_segment(a, c, b, eps):
		return true
	if abs(ab_d) <= eps and _point_on_segment(a, d, b, eps):
		return true
	if abs(cd_a) <= eps and _point_on_segment(c, a, d, eps):
		return true
	if abs(cd_b) <= eps and _point_on_segment(c, b, d, eps):
		return true
	return false

static func _side_skirt_polygon_is_valid(points: PackedVector2Array, back_outer: Vector2, back_lower: Vector2,
		back_hem: Vector2, front_hem: Vector2, front_lower: Vector2, front_outer: Vector2,
		front_peak: Vector2, belt_front: Vector2) -> bool:
	if back_outer.x > front_outer.x + 0.01:
		return false
	if back_lower.x > front_lower.x + 0.01:
		return false
	if back_hem.x > front_hem.x + 0.01:
		return false
	if back_lower.y < back_outer.y - 0.01:
		return false
	if back_hem.y < back_lower.y - 0.01:
		return false
	if front_lower.y < front_outer.y - 0.01:
		return false
	if front_hem.y < front_lower.y - 0.01:
		return false
	if front_peak.y > front_outer.y + 0.01:
		return false
	if front_peak.x < belt_front.x - 0.01:
		return false

	var edge_count := points.size()
	for i in range(edge_count):
		var a1: Vector2 = points[i]
		var a2: Vector2 = points[(i + 1) % edge_count]
		for j in range(i + 1, edge_count):
			if j == i or j == i + 1 or (i == 0 and j == edge_count - 1):
				continue
			var b1: Vector2 = points[j]
			var b2: Vector2 = points[(j + 1) % edge_count]
			if _segments_intersect(a1, a2, b1, b2):
				return false
	return true

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
static func draw_skirt(ctx: DrawContext, bottoms_type: String, bottoms_color: Color, waist_pos: Vector2, base_width: float, tops_type: String = "", facing: String = "front") -> void:
	var d = ctx.d

	# ジャンパースカート(blazer)やリボンブラウス(blouse_bow)の場合は、スカート開始位置をひじ付近に引き上げる
	var is_jumper = (tops_type == "blazer")
	var is_blouse_bow = (tops_type == "blouse_bow")
	var is_jumper_skirt = (tops_type == "jumper_skirt")
	if is_jumper or is_blouse_bow or is_jumper_skirt:
		if facing == "side":
			waist_pos = get_side_garment_waist_pos(ctx)
		else:
			waist_pos = get_front_garment_waist_pos(ctx)
	elif facing == "side" and bottoms_type == "skirt_sailor":
		waist_pos = get_side_sailor_waist_pos(ctx)

	var waist_to_crotch = d["cy"] - waist_pos.y
	var skirt_length: float
	var hem_w: float

	if bottoms_type == "skirt_long":
		skirt_length = waist_to_crotch + d["thigh_l"] + d["shin_l"] * 0.3
		hem_w = base_width * 1.3
	elif is_blouse_bow:
		# リボンブラウスのスカートは膝上（thigh_lの80%）
		skirt_length = waist_to_crotch + d["thigh_l"] * 0.8
		hem_w = base_width * 1.45
	elif is_jumper_skirt:
		# サスペンダースカートは膝上丈（thigh_lの40%）
		skirt_length = waist_to_crotch + d["thigh_l"] * 0.4
		hem_w = base_width * 1.5
	elif bottoms_type == "skirt_sailor" or is_jumper:
		# 膝（thigh_l）より少し下（shin_lの10%）まで
		skirt_length = waist_to_crotch + d["thigh_l"] + d["shin_l"] * 0.1
		# ジャンパースカートはセーラーより少し広めに
		hem_w = base_width * (1.6 if is_jumper else 1.4)
	else: # "skirt" or "skirt_short"
		skirt_length = waist_to_crotch + d["thigh_l"] * 0.4
		hem_w = base_width * 1.5

	var is_pleated = (bottoms_type == "skirt_sailor" or is_jumper or is_blouse_bow or is_jumper_skirt)

	# 側面では脚の動きに合わせて前後に傾け、裾を広げる
	if facing == "side":
		var avg_leg_ang = (d["leg_l_angle"] + d["leg_r_angle"]) / 2.0
		# スカートは布のため重力で多少下に向くので、脚の角度を完全に追うのではなく軽減(0.7倍)
		var skirt_ang = (avg_leg_ang * 0.7) * PI / 180.0 + PI / 2.0
		# 【調整用】背中の傾きをスカート角度に反映する。waist_angleが増えるほど前方へ傾く。
		# ジャンパー系(blazer/blouse_bow/jumper_skirt)は構造が固いため50%追従。
		# 通常スカートは布が重力に引かれるため30%追従。
		# → 屈んだとき、ベルト位置とスカート上端のズレを解消する
		var waist_lean = 0.5 if (is_jumper or is_blouse_bow or is_jumper_skirt) else 0.3
		skirt_ang += d["waist_angle"] * waist_lean
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
		elif is_pleated:
			# セーラースカートやジャンパースカートも、歩いた際にすねの動きに合わせてすそが大きく広がるようにする
			var hem_l_x = knee_l_x + d["shin_l"] * 0.4 * cos(ang_l + d["knee_l"])
			var hem_r_x = knee_r_x + d["shin_l"] * 0.4 * cos(ang_r + d["knee_r"])
			min_x = min(min_x, min(hem_l_x, hem_r_x))
			max_x = max(max_x, max(hem_l_x, hem_r_x))

		var spread_x = abs(max_x - min_x)
		# 【調整用】裾の広がりマージン。大きいほど裾が脚より広がる
		var spread_margin = 1.5 if bottoms_type == "skirt_long" else (1.6 if is_pleated else 1.2)
		# 屈んだとき両膝が同方向(前方)に揃うと spread_x ≈ 0 になるため、
		# 裾中心(p_bottom.x)から各脚位置までの最大距離も考慮する
		var reach_from_hem = max(abs(max_x - p_bottom.x), abs(min_x - p_bottom.x))
		var side_hem_w = max(hem_w, spread_x * spread_margin, reach_from_hem * 2.0) + 15.0 # +15.0は調整用。膝を隠すため

		var axis = p_bottom - waist_pos
		var skirt_u = _normalized_or(axis, Vector2(0, 1))
		var skirt_n = Vector2(-skirt_u.y, skirt_u.x).normalized()
		var crotch_pos = Vector2(d["cx"], d["cy"])
		var torso_u = _normalized_or(crotch_pos - waist_pos, skirt_u)
		var top_n = Vector2(-torso_u.y, torso_u.x).normalized()
		var extend_u = Vector2(0, 1)
		var half_top = base_width / 2.0
		var half_hem = side_hem_w / 2.0
		var belt_back = waist_pos + top_n * half_top
		var belt_front = waist_pos - top_n * half_top
		var hem_back_base = p_bottom + skirt_n * half_hem
		var hem_front_base = p_bottom - skirt_n * half_hem
		var front_side = Vector2(1, 0)
		var back_side = Vector2(-1, 0)
		var knee_l = Vector2(knee_l_x, d["cy"] + d["thigh_l"] * sin(ang_l))
		var knee_r = Vector2(knee_r_x, d["cy"] + d["thigh_l"] * sin(ang_r))
		var foot_h = ctx.m["height"] * ctx.p / 20.0
		var shin_draw = max(d["shin_l"] - foot_h, d["shin_l"] * 0.45)
		var ankle_l = knee_l + Vector2(cos(ang_l + d["knee_l"]), sin(ang_l + d["knee_l"])) * shin_draw
		var ankle_r = knee_r + Vector2(cos(ang_r + d["knee_r"]), sin(ang_r + d["knee_r"])) * shin_draw

		var outer_candidates: Array = []
		var lower_candidates: Array = []
		var peak_candidates: Array = []
		var pelvis_half = max(half_top, ctx.thigh_w * 0.5)
		outer_candidates.append(crotch_pos + top_n * pelvis_half)
		outer_candidates.append(crotch_pos - top_n * pelvis_half)
		_append_segment_edge_candidates(outer_candidates, crotch_pos, knee_l, ctx.thigh_w, [0.35, 0.7, 1.0])
		_append_segment_edge_candidates(outer_candidates, crotch_pos, knee_r, ctx.thigh_w, [0.35, 0.7, 1.0])
		_append_segment_edge_candidates(outer_candidates, knee_l, ankle_l, ctx.shin_w, [0.2])
		_append_segment_edge_candidates(outer_candidates, knee_r, ankle_r, ctx.shin_w, [0.2])
		_append_segment_edge_candidates(lower_candidates, knee_l, ankle_l, ctx.shin_w, [0.45, 0.75])
		_append_segment_edge_candidates(lower_candidates, knee_r, ankle_r, ctx.shin_w, [0.45, 0.75])
		_append_segment_edge_candidates(peak_candidates, crotch_pos, knee_l, ctx.thigh_w, [0.7, 0.85, 1.0])
		_append_segment_edge_candidates(peak_candidates, crotch_pos, knee_r, ctx.thigh_w, [0.7, 0.85, 1.0])
		_append_segment_edge_candidates(peak_candidates, knee_l, ankle_l, ctx.shin_w, [0.0, 0.1])
		_append_segment_edge_candidates(peak_candidates, knee_r, ankle_r, ctx.shin_w, [0.0, 0.1])
		peak_candidates.append(knee_l)
		peak_candidates.append(knee_r)

		var front_pick = _pick_side_outer_candidate(outer_candidates, waist_pos, belt_front, front_side, torso_u, skirt_length)
		var back_pick = _pick_side_outer_candidate(outer_candidates, waist_pos, belt_back, back_side, torso_u, skirt_length)

		var use_legacy_side = (not bool(front_pick["found"])) or (not bool(back_pick["found"]))
		var front_outer = belt_front.lerp(hem_front_base, 0.5)
		var back_outer = belt_back.lerp(hem_back_base, 0.5)
		var front_lower = front_outer.lerp(hem_front_base, 0.45)
		var back_lower = back_outer.lerp(hem_back_base, 0.45)
		var front_peak = belt_front.lerp(front_outer, 0.35)
		var front_hem = hem_front_base
		var back_hem = hem_back_base

		if not use_legacy_side:
			var front_axis_ratio = clamp(float(front_pick["axis_pos"]) / skirt_length, 0.0, 1.0)
			var back_axis_ratio = clamp(float(back_pick["axis_pos"]) / skirt_length, 0.0, 1.0)
			var front_base_at_pick = belt_front.lerp(hem_front_base, front_axis_ratio)
			var back_base_at_pick = belt_back.lerp(hem_back_base, back_axis_ratio)
			var peak_min_axis = -max(18.0, skirt_length * 0.18)
			var front_peak_pick = _pick_side_peak_candidate(peak_candidates, waist_pos, belt_front, front_side, torso_u, skirt_length, peak_min_axis)
			var front_candidate: Vector2 = front_pick["pos"]
			var back_candidate: Vector2 = back_pick["pos"]

			front_outer = front_candidate if _side_proj(front_candidate, waist_pos, front_side) > _side_proj(front_base_at_pick, waist_pos, front_side) else front_base_at_pick
			back_outer = back_candidate if _side_proj(back_candidate, waist_pos, back_side) > _side_proj(back_base_at_pick, waist_pos, back_side) else back_base_at_pick
			front_peak = belt_front.lerp(front_outer, 0.35)
			if bool(front_peak_pick["found"]):
				var front_peak_candidate: Vector2 = front_peak_pick["pos"]
				front_peak.x = clamp(front_peak_candidate.x, belt_front.x + 2.0, front_outer.x + ctx.shin_w * 0.35)
				front_peak.y = min(front_peak_candidate.y, front_outer.y - 2.0)

			var front_seg1 = belt_front.distance_to(front_outer)
			var back_seg1 = belt_back.distance_to(back_outer)
			if front_seg1 >= skirt_length - 0.5 or back_seg1 >= skirt_length - 0.5:
				use_legacy_side = true
			else:
				var front_hem_ext = front_outer + extend_u * (skirt_length - front_seg1)
				var back_hem_ext = back_outer + extend_u * (skirt_length - back_seg1)
				# 体育座りでは hem_base が前方へ跳ね上がるため、
				# 候補点を通過した後は純粋に重力方向へ残り丈を延長する。
				front_hem = front_hem_ext
				back_hem = back_hem_ext
				front_lower = front_outer.lerp(front_hem, 0.45)
				back_lower = back_outer.lerp(back_hem, 0.45)

				var front_lower_pick = _pick_side_outer_candidate(lower_candidates, waist_pos, front_outer, front_side, torso_u, skirt_length)
				var back_lower_pick = _pick_side_outer_candidate(lower_candidates, waist_pos, back_outer, back_side, torso_u, skirt_length)
				if bool(front_lower_pick["found"]):
					var front_lower_candidate: Vector2 = front_lower_pick["pos"]
					front_lower.x = max(front_lower.x, front_lower_candidate.x)
					front_lower.y = clamp(front_lower_candidate.y, front_outer.y + 4.0, front_hem.y - 4.0)
				if bool(back_lower_pick["found"]):
					var back_lower_candidate: Vector2 = back_lower_pick["pos"]
					back_lower.x = min(back_lower.x, back_lower_candidate.x)
					back_lower.y = clamp(back_lower_candidate.y, back_outer.y + 4.0, back_hem.y - 4.0)

				var pts = PackedVector2Array([
					belt_back,
					back_outer,
					back_lower,
					back_hem,
					front_hem,
					front_lower,
					front_outer,
					front_peak,
					belt_front,
				])
				if not _side_skirt_polygon_is_valid(pts, back_outer, back_lower, back_hem, front_hem, front_lower, front_outer, front_peak, belt_front):
					use_legacy_side = true

		if use_legacy_side:
			CharacterDrawUtils.draw_trapezoid(ctx.canvas, waist_pos, p_bottom, base_width, side_hem_w, bottoms_color)
		else:
			var pts = PackedVector2Array([
				belt_back,
				back_outer,
				back_lower,
				back_hem,
				front_hem,
				front_lower,
				front_outer,
				front_peak,
				belt_front,
			])
			ctx.canvas.draw_polygon(pts, PackedColorArray([bottoms_color]))

		# プリーツ（セーラー服・ジャンパースカート用）
		if is_pleated:
			var pleat_col = bottoms_color.darkened(0.2)
			if use_legacy_side:
				var d_vec = p_bottom - waist_pos
				if d_vec.length() > 0.01:
					var legacy_n = Vector2(-d_vec.y, d_vec.x).normalized()
					var h_top = base_width / 2.0
					var h_hem = side_hem_w / 2.0
					for i in range(1, 7): # 6本の線を入れる
						var t = float(i) / 7.0
						var top_p = waist_pos + legacy_n * lerp(-h_top, h_top, t)
						var bot_p = p_bottom + legacy_n * lerp(-h_hem, h_hem, t)
						ctx.canvas.draw_line(top_p, bot_p, pleat_col, 1.5)
			else:
				for i in range(1, 7): # 6本の線を入れる
					var t = float(i) / 7.0
					var top_p = belt_back.lerp(belt_front, t)
					var peak_p = back_outer.lerp(front_peak, pow(t, 1.8))
					var upper_p = back_outer.lerp(front_outer, t)
					var lower_p = back_lower.lerp(front_lower, t)
					var bot_p = back_hem.lerp(front_hem, t)
					ctx.canvas.draw_polyline(PackedVector2Array([top_p, peak_p, upper_p, lower_p, bot_p]), pleat_col, 1.5)

		# サスペンダースカート用：スカート上端にダークネイビーの帯
		if is_jumper_skirt:
			var belt_color = bottoms_color.darkened(0.35)
			var belt_h = 7.0
			if use_legacy_side:
				var legacy_n = Vector2(-p_bottom.y + waist_pos.y, p_bottom.x - waist_pos.x).normalized() if (p_bottom - waist_pos).length() > 0.01 else Vector2(1, 0)
				var h_top = base_width / 2.0
				var belt_pts = PackedVector2Array([
					waist_pos - legacy_n * h_top,
					waist_pos + legacy_n * h_top,
					waist_pos + legacy_n * h_top + (p_bottom - waist_pos).normalized() * belt_h,
					waist_pos - legacy_n * h_top + (p_bottom - waist_pos).normalized() * belt_h,
				])
				ctx.canvas.draw_polygon(belt_pts, PackedColorArray([belt_color]))
			else:
				var belt_pts = PackedVector2Array([
					belt_back,
					belt_front,
					belt_front + torso_u * belt_h,
					belt_back + torso_u * belt_h,
				])
				ctx.canvas.draw_polygon(belt_pts, PackedColorArray([belt_color]))
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

	# プリーツ（セーラー服・ジャンパースカート用）
	if is_pleated:
		var pleat_col = bottoms_color.darkened(0.2)
		for i in range(1, 7): # 6本の線を入れる
			var t = float(i) / 7.0
			var top_p = Vector2(lerp(waist_pos.x - half_top, waist_pos.x + half_top, t), waist_pos.y)
			var bx = lerp(waist_pos.x - half_hem, waist_pos.x + half_hem, t)
			# カーブに合わせて下端を計算
			var drop = curve_drop * (1.0 - pow((t - 0.5) * 2.0, 2.0))
			var bot_p = Vector2(bx, p_bottom_y + drop)
			ctx.canvas.draw_line(top_p, bot_p, pleat_col, 1.5)

	# サスペンダースカート用：スカート上端にダークネイビーのベルト
	if is_jumper_skirt:
		var belt_color = bottoms_color.darkened(0.35)
		var belt_h = 7.0
		var belt_pts = PackedVector2Array([
			Vector2(waist_pos.x - half_top, waist_pos.y),
			Vector2(waist_pos.x + half_top, waist_pos.y),
			Vector2(waist_pos.x + half_top, waist_pos.y + belt_h),
			Vector2(waist_pos.x - half_top, waist_pos.y + belt_h),
		])
		ctx.canvas.draw_polygon(belt_pts, PackedColorArray([belt_color]))
