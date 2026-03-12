class_name CharacterClothingDrawer

# ============================================================
# === 服装オーバーレイ（カラー・ラペル・リボン）描画関数群 ===
# ============================================================

# ---------------------------------------------------------------
# 正面・背面ビューの服装オーバーレイ振り分け
#
# tops_type に応じて専用の描画関数を呼び出す。
# t_shirt / sweater / blouse はオーバーレイなし（袖で表現済み）。
# ---------------------------------------------------------------
static func draw_tops_detail_front(ctx: DrawContext, tops_type: String, tops_color: Color, body_w: float, shoulder_w: float, skin_color: Color = Color.WHITE) -> void:
	var d = ctx.d
	var sx = d["front_sx"]
	var sy = d["front_sy"]
	var navel_y = d["front_navel_y"]
	var neck_y = d["front_ny"]
	var half_sh = shoulder_w * 0.5
	var half_body = body_w * 0.5

	match tops_type:
		"sailor":
			draw_sailor_front(ctx, sx, sy, neck_y, navel_y, half_sh, half_body, tops_color, skin_color)
		"blazer":
			draw_jumperSkirt_front(ctx, sx, sy, neck_y, navel_y, half_sh, half_body, tops_color, true)
		"blouse_bow":
			draw_blouse_bow_front(ctx, sx, sy, neck_y, navel_y, half_sh, half_body)
		"jumper_skirt":
			draw_suspenderSkirt_front(ctx, sx, sy, neck_y, navel_y, half_sh, half_body, tops_color)

# ---------------------------------------------------------------
# 側面ビューの服装オーバーレイ振り分け
#
# tops_type に応じて専用の描画関数を呼び出す。
# waist_angle を考慮して体の向きに合わせたベクトルを渡す。
# ---------------------------------------------------------------
static func draw_tops_detail_side(ctx: DrawContext, tops_type: String, tops_color: Color, torso_thickness: float, head_angle: float, skin_color: Color = Color.WHITE) -> void:
	var d = ctx.d
	var sx = d["sx"]
	var sy = d["sy"]
	var navel_y = d["navel_y"]
	var navel_x = d["navel_x"]
	var waist_angle = d["waist_angle"]

	# 体の前方方向ベクトル（胴体の前面）
	var fwd = Vector2(cos(waist_angle), sin(waist_angle)) # 前方
	var up_v = Vector2(-sin(waist_angle), cos(waist_angle)) # 上方
	var half_t = torso_thickness * 0.5

	match tops_type:
		"sailor":
			draw_sailor_side(ctx, sx, sy, navel_y, navel_x, half_t, fwd, up_v, waist_angle, tops_color, skin_color)
		"blazer":
			draw_jumperSkirt_side(ctx, sx, sy, navel_y, navel_x, half_t, fwd, up_v, waist_angle, tops_color, true)
		"blouse_bow":
			draw_blouse_bow_side(ctx, sx, sy, navel_y, half_t, fwd, up_v, waist_angle)
		"jumper_skirt":
			draw_suspenderSkirt_side(ctx, sx, sy, navel_y, half_t, fwd, up_v, waist_angle, tops_color)

# ---------------------------------------------------------------
# セーラー服オーバーレイ（正面）
#
# 描画パーツ:
#   1. セーラーカラー本体（肩→首→胸V字のポリゴン）
#   2. 内側の白い三角形（衿の内側）
#   3. セーラーカラーの白いライン（縁取り）
#   4. スカーフ（Vの底から垂れ下がる五角形先細り）
#   5. 結び目（スカーフ上部の小さな四角形）
#
# 【調整用】
#   v_y          : Vの底点Y（sy〜navel_y の lerp 値で決まる）
#   scarf_tip_y  : スカーフの先端Y（v_y〜navel_y の lerp 値で決まる）
# ---------------------------------------------------------------
static func draw_sailor_front(ctx: DrawContext, sx: float, sy: float, neck_y: float, navel_y: float,
		half_sh: float, half_body: float, sailor_color: Color, skin_color: Color) -> void:
	var v_y = lerp(sy, navel_y, 0.45) # Vの底点Y

	# V字の開口部を肌色で塗りつぶして青線を隠す（肩の高さ sy で止まる単純な三角形）
	var skin_open_pts = PackedVector2Array([
		Vector2(sx - half_body * 0.28, sy), # 左上
		Vector2(sx + half_body * 0.28, sy), # 右上
		Vector2(sx, v_y), # V字の底（下）
	])
	ctx.canvas.draw_polygon(skin_open_pts, PackedColorArray([skin_color]))

	# セーラーカラー本体（両肩から首に広がり、胸でVに収束する台形ポリゴン）
	var collar_pts = PackedVector2Array([
		Vector2(sx - half_sh * 1.05, sy), # 左肩外端
		Vector2(sx - half_sh * 0.85, neck_y + 4.0), # 左上（首付近）
		Vector2(sx - half_body * 0.18, sy + 6.0), # V左縁
		Vector2(sx, v_y), # V底
		Vector2(sx + half_body * 0.18, sy + 6.0), # V右縁
		Vector2(sx + half_sh * 0.85, neck_y + 4.0), # 右上
		Vector2(sx + half_sh * 1.05, sy), # 右肩外端
	])
	ctx.canvas.draw_polygon(collar_pts, PackedColorArray([sailor_color]))

	# 内側の胸当て（セーラーカラーと同じ紺色にし、縁を白くする）
	var chest_y = lerp(sy, v_y, 0.3)
	var chest_w = half_body * 0.12
	var inner_pts = PackedVector2Array([
		Vector2(sx - chest_w, chest_y),
		Vector2(sx + chest_w, chest_y),
		Vector2(sx, v_y - 3.0),
	])
	ctx.canvas.draw_polygon(inner_pts, PackedColorArray([sailor_color]))

	# 胸当ての上の縁（V字の横線のようになっている箇所の白輪郭）
	var inner_line_col = Color(0.97, 0.97, 0.97)
	ctx.canvas.draw_polyline(PackedVector2Array([
		Vector2(sx - chest_w, chest_y),
		Vector2(sx, v_y),
		Vector2(sx + chest_w, chest_y)
	]), inner_line_col, 0.6) # <--- さらに細く
	ctx.canvas.draw_line(Vector2(sx - chest_w, chest_y), Vector2(sx + chest_w, chest_y), inner_line_col, 0.6) # <--- こちらも

	# セーラーカラーの白いライン（縁取り）※胴体の側面で止める
	var line_col = Color(1, 1, 1, 0.75)
	var lw = 2.2
	var line_y = lerp(sy, v_y, 0.2)
	ctx.canvas.draw_line(Vector2(sx - half_body * 1.0, line_y), Vector2(sx, v_y), line_col, lw)
	ctx.canvas.draw_line(Vector2(sx + half_body * 1.0, line_y), Vector2(sx, v_y), line_col, lw)

	# スカーフ（Vの底から垂れ下がる五角形 → 先細り）※赤色に変更
	var scarf_tip_y = lerp(v_y, navel_y, 0.72)
	var sc = Color(0.8, 0.15, 0.15)
	var scarf_pts = PackedVector2Array([
		Vector2(sx - half_body * 0.09, v_y),
		Vector2(sx + half_body * 0.09, v_y),
		Vector2(sx + half_body * 0.04, scarf_tip_y - 10.0),
		Vector2(sx, scarf_tip_y),
		Vector2(sx - half_body * 0.04, scarf_tip_y - 10.0),
	])
	ctx.canvas.draw_polygon(scarf_pts, PackedColorArray([sc]))

	# 結び目（スカーフの上部の小さな輪）
	var knot_y = v_y + 4.0
	var knot_pts = PackedVector2Array([
		Vector2(sx - half_body * 0.075, knot_y),
		Vector2(sx + half_body * 0.075, knot_y),
		Vector2(sx + half_body * 0.06, knot_y + 9.0),
		Vector2(sx - half_body * 0.06, knot_y + 9.0),
	])
	ctx.canvas.draw_polygon(knot_pts, PackedColorArray([sc.lightened(0.12)]))

# ---------------------------------------------------------------
# ジャンパースカートオーバーレイ（正面）
#
# 描画パーツ:
#   1. (is_dark のみ) ジャケット胴体の塗りつぶし（暗色用途）
#   2. 内側の白シャツ（コの字形）
#   8. リボン/ネクタイ（draw_bow_front を呼び出し）
#
# 引数:
#   is_dark : 常にtrue (暗色仕様に統一)
#
# 【調整用】
#   lapel_inner_y : ラペル内側下端（sy〜navel_y の lerp）
# ---------------------------------------------------------------
static func draw_jumperSkirt_front(ctx: DrawContext, sx: float, sy: float, _neck_y: float, navel_y: float,
		_half_sh: float, half_body: float, jacket_color: Color, is_dark: bool) -> void:
	# 暗色仕様の場合: 胴体部分をひじの高さまで塗りつぶし
	if is_dark:
		var u_arm = ctx.m["armLength"] * ctx.p * 0.5 + 10.0 # offset分下げている
		var belt_y = sy + u_arm

		var jacket_body_pts = PackedVector2Array([
			Vector2(sx - half_body, sy),
			Vector2(sx + half_body, sy),
			Vector2(sx + half_body, belt_y),
			Vector2(sx - half_body, belt_y),
		])
		ctx.canvas.draw_polygon(jacket_body_pts, PackedColorArray([jacket_color]))

		# ベルト（帯）の描画
		var belt_pts = PackedVector2Array([
			Vector2(sx - half_body * 1.0, belt_y - 4.5),
			Vector2(sx + half_body * 1.0, belt_y - 4.5),
			Vector2(sx + half_body * 1.0, belt_y),
			Vector2(sx - half_body * 1.0, belt_y),
		])
		ctx.canvas.draw_polygon(belt_pts, PackedColorArray([jacket_color.darkened(0.25)]))

		if ctx.is_skirt:
			# ベルトの横幅(half_body * 2.0)に合わせてスカートの上端幅を設定
			CharacterBodyDrawer.draw_skirt(ctx, ctx.bottoms_type, jacket_color, Vector2(sx, belt_y), half_body * 2.0, ctx.tops_type, ctx.facing)

	# 内側の白シャツ（四角く開いたスクエアネック）
	var shirt_inner = Color(0.97, 0.97, 0.97)
	var chest_w = half_body * 0.45 # 開きの幅
	var chest_depth_y = lerp(sy, navel_y, 0.35) # 開きの深さ
	var inner_pts = PackedVector2Array([
		Vector2(sx - chest_w, sy),
		Vector2(sx + chest_w, sy),
		Vector2(sx + chest_w, chest_depth_y),
		Vector2(sx - chest_w, chest_depth_y),
	])
	ctx.canvas.draw_polygon(inner_pts, PackedColorArray([shirt_inner]))

	# リボン/ネクタイ（スクエアネックの内側下部に小さなリボン）
	# 【調整用】赤リボン
	var bow_col = Color(0.75, 0.18, 0.25) if is_dark else Color(0.25, 0.35, 0.75)
	draw_bow_front(ctx, sx, sy, navel_y, half_body * 0.55, bow_col)

# ---------------------------------------------------------------
# リボン（蝶結び）オーバーレイ（正面）
#
# 描画パーツ:
#   1. 左ウィング（五角形: 中央から外側に膨らんで先が細い）
#   2. 右ウィング（左の鏡像）
#   3. 中央の結び目（円）
#   4. リボンの垂れ（左右2本の帯が斜め下に伸びる）
#
# 引数:
#   sx        : 胴体中心X
#   sy        : 肩Y
#   navel_y   : おへそY
#   half_body : 胴体半幅（リボンのスケール基準）
#   bow_color : リボンの色
#
# 【調整用】
#   bow_y   : リボンの中心Y（sy〜navel_y の lerp 0.22）
#   bow_w   : リボンの横幅（half_body * 0.55）
#   bow_h   : リボンの縦幅（half_body * 0.28）
#   tail_len: 垂れの長さ（bow_h * 2.8）
# ---------------------------------------------------------------
static func draw_bow_front(ctx: DrawContext, sx: float, sy: float, navel_y: float, half_body: float, bow_color: Color) -> void:
	var bow_y = lerp(sy, navel_y, 0.22) # 肩と乳首の間くらいの高さにリボン
	var bow_w = half_body * 0.8 # リボンの横方向の広がり
	var bow_h = half_body * 0.5 # リボンの縦の高さ

	# 左ウィング（五角形: 中央から外側に膨らんで先が細い形）
	var left_wing = PackedVector2Array([
		Vector2(sx - 3.5, bow_y - bow_h * 0.28),
		Vector2(sx - bow_w * 0.85, bow_y - bow_h),
		Vector2(sx - bow_w, bow_y),
		Vector2(sx - bow_w * 0.85, bow_y + bow_h),
		Vector2(sx - 3.5, bow_y + bow_h * 0.28),
	])
	ctx.canvas.draw_polygon(left_wing, PackedColorArray([bow_color]))

	# 右ウィング
	var right_wing = PackedVector2Array([
		Vector2(sx + 3.5, bow_y - bow_h * 0.28),
		Vector2(sx + bow_w * 0.85, bow_y - bow_h),
		Vector2(sx + bow_w, bow_y),
		Vector2(sx + bow_w * 0.85, bow_y + bow_h),
		Vector2(sx + 3.5, bow_y + bow_h * 0.28),
	])
	ctx.canvas.draw_polygon(right_wing, PackedColorArray([bow_color]))

	# 中央の結び目（円）
	ctx.canvas.draw_circle(Vector2(sx, bow_y), 4.5, bow_color.darkened(0.22))

	# リボンの垂れ（2本の帯が斜め下に伸びる）
	var tail_len = bow_h * 2.8
	var tail_w = 3.5
	var tail_l_pts = PackedVector2Array([
		Vector2(sx - tail_w, bow_y + 4.0),
		Vector2(sx - 2.5, bow_y + 4.0),
		Vector2(sx - 4.5, bow_y + tail_len),
		Vector2(sx - tail_w - 4.0, bow_y + tail_len),
	])
	var tail_r_pts = PackedVector2Array([
		Vector2(sx + 2.5, bow_y + 4.0),
		Vector2(sx + tail_w, bow_y + 4.0),
		Vector2(sx + tail_w + 4.0, bow_y + tail_len),
		Vector2(sx + 4.5, bow_y + tail_len),
	])
	ctx.canvas.draw_polygon(tail_l_pts, PackedColorArray([bow_color]))
	ctx.canvas.draw_polygon(tail_r_pts, PackedColorArray([bow_color]))

# ---------------------------------------------------------------
# リボンブラウスオーバーレイ（正面）
# ---------------------------------------------------------------
static func draw_blouse_bow_front(ctx: DrawContext, sx: float, sy: float, _neck_y: float, navel_y: float, _half_sh: float, half_body: float) -> void:
	# ブラウスの下端（スカートの開始位置）
	var u_arm = ctx.m["armLength"] * ctx.p * 0.5 + 10.0
	var belt_y = sy + u_arm

	# 前立て（ボタンの重なり部分）
	var placket_color = Color(0.8, 0.8, 0.8)
	var placket_w = 4.0
	# 上端は sy (肩のライン)、下端は belt_y (スカート境界) に合わせる
	ctx.canvas.draw_line(Vector2(sx - placket_w, sy), Vector2(sx - placket_w, belt_y), placket_color, 1.2)
	ctx.canvas.draw_line(Vector2(sx + placket_w, sy), Vector2(sx + placket_w, belt_y), placket_color, 1.2)
	
	# リボン（黒色で小さめ、最前面に描画）
	var ribbon_color = Color(0.15, 0.15, 0.15)
	draw_bow_front(ctx, sx, sy, navel_y, half_body * 0.55, ribbon_color)

# ---------------------------------------------------------------
# リボンブラウスオーバーレイ（側面）
# ---------------------------------------------------------------
static func draw_blouse_bow_side(ctx: DrawContext, sx: float, sy: float, navel_y: float, half_t: float, fwd: Vector2, up_v: Vector2, waist_angle: float) -> void:
	# リボン（黒色で小さめ、最前面に描画）
	var ribbon_color = Color(0.15, 0.15, 0.15)
	draw_bow_side(ctx, sx, sy, navel_y, half_t * 0.55, fwd, up_v, waist_angle, ribbon_color)

# ---------------------------------------------------------------
# セーラー服オーバーレイ（側面）
#
# 描画パーツ:
#   1. セーラーカラーの大きな三角形フラップ（背中→首→胸V底）
#   2. 白い内側ライン（縁取り）
#   3. スカーフ（Vの底から垂れ下がる三角形）
#
# 【調整用】
#   v_bottom : カラーの先端（肩前端から垂直に降りた位置、sy〜navel_y の 42%）
# ---------------------------------------------------------------
static func draw_sailor_side(ctx: DrawContext, sx: float, sy: float, navel_y: float, navel_x: float,
		half_t: float, fwd: Vector2, up_v: Vector2,
		_waist_angle: float, sailor_color: Color, skin_color: Color) -> void:
	# 胴体に沿った下方ベクトル（肩→へそ方向、腰曲げを考慮）
	var torso_down_s = Vector2(navel_x - sx, navel_y - sy)

	# 胴体上部の前方点（首元〜肩のライン）
	var p_sh_front = Vector2(sx, sy) + fwd * half_t * 0.95
	var p_nk = Vector2(sx, sy) + up_v * 12.0 # 首付近
	var p_nk_front = p_nk + fwd * half_t * 0.8

	# 胸元のV字の開きを肌色で塗って青線を隠す
	var v_bottom = p_sh_front + torso_down_s * 0.42
	var skin_pts = PackedVector2Array([
		p_nk_front + up_v * 5.0,
		p_nk_front,
		v_bottom,
		v_bottom - fwd * 4.0,
	])
	ctx.canvas.draw_polygon(skin_pts, PackedColorArray([skin_color]))

	# セーラーカラーの大きな三角形フラップ（背中から肩に）
	var p_sh_back = Vector2(sx, sy) - fwd * half_t * 0.95

	var collar_pts = PackedVector2Array([
		p_sh_back,
		p_nk_front,
		v_bottom,
		Vector2(sx, sy) - fwd * half_t * 0.2,
	])
	ctx.canvas.draw_polygon(collar_pts, PackedColorArray([sailor_color]))

	# 白い内側ライン ※背中まで伸びないよう短くする
	var line_col = Color(1, 1, 1, 0.72)
	var line_start = p_nk_front - fwd * half_t * 0.8
	ctx.canvas.draw_line(line_start, v_bottom, line_col, 2.0)

	# スカーフ（Vの底から垂れ下がる）※赤色に変更
	var scarf_end = v_bottom + torso_down_s * 0.40
	var sc = Color(0.8, 0.15, 0.15)
	var scarf_pts = PackedVector2Array([
		v_bottom + fwd * 3.0,
		v_bottom - fwd * 3.0,
		scarf_end - fwd * 1.0,
	])
	ctx.canvas.draw_polygon(scarf_pts, PackedColorArray([sc]))

# ---------------------------------------------------------------
# ジャンパースカートオーバーレイ（側面）
#
# 描画パーツ:
#   1. (is_dark のみ) ジャケット胴体の塗りつぶし
#   2. 白シャツ（前面の細い帯）
#   3. リボン（draw_bow_side を呼び出し）
#
# 引数:
#   is_dark : 常にtrue (暗色仕様に統一)
# ---------------------------------------------------------------
static func draw_jumperSkirt_side(ctx: DrawContext, sx: float, sy: float, navel_y: float, navel_x: float,
		half_t: float, fwd: Vector2, up_v: Vector2,
		waist_angle: float, jacket_color: Color, is_dark: bool) -> void:
	var p_sh = Vector2(sx, sy)
	var p_sh_front = p_sh + fwd * half_t
	var p_sh_back = p_sh - fwd * half_t

	# 胴体に沿った下方ベクトル（肩→へそ方向、腰曲げを考慮）
	var torso_down_b = Vector2(navel_x - sx, navel_y - sy)
	var torso_dir_b = torso_down_b.normalized() if torso_down_b.length() > 0.01 else up_v

	# 暗色仕様: 胴体全体を上書きしてから、前面のみ白シャツを描画
	if is_dark:
		# ひじの高さをベルト位置（胴体の下端）とする
		var u_arm = ctx.m["armLength"] * ctx.p * 0.5 + 10.0 # offset分下げている
		var belt_vec = torso_dir_b * u_arm # 胴体方向にu_armだけ下げたベクトル

		# まず胴体のベルト位置までを暗色のジャンパースカートで塗る
		var jacket_cover = PackedVector2Array([
			p_sh_back,
			p_sh_front,
			p_sh_front + belt_vec,
			p_sh_back + belt_vec,
		])
		ctx.canvas.draw_polygon(jacket_cover, PackedColorArray([jacket_color]))

		# ベルトを描画
		var belt_pts = PackedVector2Array([
			p_sh_back + fwd * half_t * 0.05 + belt_vec - torso_dir_b * 4.5,
			p_sh_front + fwd * half_t * 0.05 + belt_vec - torso_dir_b * 4.5,
			p_sh_front + fwd * half_t * 0.05 + belt_vec,
			p_sh_back + fwd * half_t * 0.05 + belt_vec,
		])
		ctx.canvas.draw_polygon(belt_pts, PackedColorArray([jacket_color.darkened(0.25)]))

		if ctx.is_skirt:
			var center_x = lerp(p_sh_back.x, p_sh_front.x, 0.5)
			CharacterBodyDrawer.draw_skirt(ctx, ctx.bottoms_type, jacket_color, Vector2(center_x, sy + u_arm), half_t * 2.0, ctx.tops_type, ctx.facing)

		# 前面側1/3の上部（正面の35%の深さまで）を白シャツとして上書き描画
		var white_fw = half_t * 0.35 # 胴体の厚みに対しておよそ1/3（前面側）
		var shirt_inner = Color(0.96, 0.96, 0.96)
		var shirt_cover = PackedVector2Array([
			p_sh_front - fwd * white_fw,
			p_sh_front,
			p_sh_front + torso_down_b * 0.35,
			p_sh_front - fwd * white_fw + torso_down_b * 0.35,
		])
		ctx.canvas.draw_polygon(shirt_cover, PackedColorArray([shirt_inner]))

	# リボン
	# 【調整用】赤リボン
	var bow_col = Color(0.75, 0.18, 0.25) if is_dark else Color(0.25, 0.35, 0.75)
	draw_bow_side(ctx, sx, sy, navel_y, half_t, fwd, up_v, waist_angle, bow_col)

# ---------------------------------------------------------------
# リボン（蝶結び）オーバーレイ（側面）
#
# 側面から見た蝶ネクタイを描画する。
# 胴体前面に小さく、前方に突出するウィング片方と、垂れを描く。
#
# 描画パーツ:
#   1. 片方のウィング（前方に突出する四角形）
#   2. リボンの垂れ（下方向の線）
#
# 【調整用】
#   center  : リボンの中心（胴体前面）
#   bow_w   : ウィングの前方への突き出し量（half_t * 0.6）
#   bow_h   : ウィングの縦幅（half_t * 0.35）
# ---------------------------------------------------------------
static func draw_bow_side(ctx: DrawContext, sx: float, sy: float, navel_y: float,
		half_t: float, fwd: Vector2, up_v: Vector2,
		_waist_angle: float, bow_color: Color) -> void:
	# 側面では蝶ネクタイが胴体の前面に小さく見える。肩と乳首の間にハイライト
	var p_sh = Vector2(sx, sy)
	var navel_x_bow = ctx.d["navel_x"]
	var torso_down_bow = Vector2(navel_x_bow - sx, navel_y - sy)
	var center = p_sh + torso_down_bow * 0.22 + fwd * half_t * 0.88
	var bow_w = half_t * 0.6
	var bow_h = half_t * 0.35

	# 側面から見た片方のウィングのみ（前方に突出）
	var wing_pts = PackedVector2Array([
		center - up_v * bow_h,
		center + fwd * bow_w,
		center + up_v * bow_h,
		center,
	])
	ctx.canvas.draw_polygon(wing_pts, PackedColorArray([bow_color]))

	# リボンの垂れ
	var tail_end = center + Vector2(0, bow_h * 3.0)
	ctx.canvas.draw_line(center, tail_end, bow_color, 3.0)

# ============================================================
# サスペンダースカート（小学校制服）描画関数
# ============================================================

# ---------------------------------------------------------------
# サスペンダースカート 正面オーバーレイ
#
# 白いブラウス（base_shirt_color=白で胴体描画済み）の上から
# 濃色のサロペットストラップを描画する。
#
# 描画パーツ:
#   1. 左ストラップ（肩から腰まで縦長の矩形）
#   2. 右ストラップ
#   3. ストラップ内縁の影線（陰影感）
#   4. 左襟フラップ（ブラウスの白い折り返し襟）
#   5. 右襟フラップ
#   6. 襟の縁取りライン
#
# 【調整用】
#   strap_outer  : ストラップ外端位置（half_sh * 0.98 で肩幅に合わせる）
#   strap_inner  : ストラップ内端位置（half_body * 0.30 で胸中央を開ける）
#   strap_top_y  : ストラップ上端Y（sy - 4.0 で肩より少し上）
#   strap_bot_y  : ストラップ下端Y（navel_y + 10.0 でウエストより少し下）
# ---------------------------------------------------------------
static func draw_suspenderSkirt_front(ctx: DrawContext, sx: float, sy: float, _neck_y: float, _navel_y: float,
		_half_sh: float, half_body: float, _jumper_color: Color) -> void:
	var strap_top_y = sy # ストラップ上端（肩）
	var u_arm = ctx.m["armLength"] * ctx.p * 0.5 + 10.0
	var strap_bot_y = sy + u_arm # ストラップ下端（ひじ＝スカート上端）

	# サスペンダーストラップ（細い黒縦線、左右に余白あり）
	var strap_color = Color(0.08, 0.08, 0.08) # 黒
	var strap_w = 7.0 # ストラップ幅
	var strap_cx = half_body * 0.6 # 中心からストラップ中心位置（横10分割の2・8の位置）

	# 左ストラップ
	var left_pts = PackedVector2Array([
		Vector2(sx - strap_cx - strap_w * 0.5, strap_top_y),
		Vector2(sx - strap_cx + strap_w * 0.5, strap_top_y),
		Vector2(sx - strap_cx + strap_w * 0.5, strap_bot_y),
		Vector2(sx - strap_cx - strap_w * 0.5, strap_bot_y),
	])
	ctx.canvas.draw_polygon(left_pts, PackedColorArray([strap_color]))

	# 右ストラップ
	var right_pts = PackedVector2Array([
		Vector2(sx + strap_cx - strap_w * 0.5, strap_top_y),
		Vector2(sx + strap_cx + strap_w * 0.5, strap_top_y),
		Vector2(sx + strap_cx + strap_w * 0.5, strap_bot_y),
		Vector2(sx + strap_cx - strap_w * 0.5, strap_bot_y),
	])
	ctx.canvas.draw_polygon(right_pts, PackedColorArray([strap_color]))

# ---------------------------------------------------------------
# サスペンダースカート 側面オーバーレイ
#
# 胴体の前面・背面にサロペットストラップ帯を描画する。
# 側面から見ると前後2本の縦帯として見える。
#
# 描画パーツ:
#   1. 前面ストラップ（胴体前端から内側に fw 幅の帯）
#   2. 背面ストラップ（胴体背端から内側に fw 幅の帯）
#   3. 小さな白い折り返し襟（ブラウス）
#
# 【調整用】
#   fw          : ストラップ帯の幅（half_t * 0.40）
#   strap_len   : ストラップの縦方向の長さ（navel_y - sy + 10px）
# ---------------------------------------------------------------
static func draw_suspenderSkirt_side(ctx: DrawContext, sx: float, sy: float, navel_y: float,
		half_t: float, fwd: Vector2, _up_v: Vector2,
		_waist_angle: float, _jumper_color: Color) -> void:
	var p_sh = Vector2(sx, sy)
	var p_sh_front = p_sh + fwd * half_t * 0.95
	var p_sh_back = p_sh - fwd * half_t * 0.95
	var fw = half_t * 0.12 # ストラップの幅（細い黒帯）
	var strap_color = Color(0.08, 0.08, 0.08) # 黒

	# 胴体に沿った下向きベクトル（肩→へそ方向、腰曲げを考慮）
	var navel_x = ctx.d["navel_x"]
	var torso_down = Vector2(navel_x - sx, navel_y - sy)
	var torso_dir = torso_down.normalized() if torso_down.length() > 0.01 else Vector2(0, 1)

	# 前面ストラップ（胴体前端に細い黒帯、上端は胸のでっぱり位置から）
	var p_front_top = p_sh_front + torso_down * 0.45 # 乳首高さ(肩から45%下)
	var p_front_bot = p_sh_front + torso_down + torso_dir * 10.0
	var front_band = PackedVector2Array([
		p_front_top,
		p_front_top - fwd * fw,
		p_front_bot - fwd * fw,
		p_front_bot,
	])
	ctx.canvas.draw_polygon(front_band, PackedColorArray([strap_color]))

	# 背面ストラップ（胴体背端に細い黒帯）
	var p_back_bot = p_sh_back + torso_down + torso_dir * 10.0
	var back_band = PackedVector2Array([
		p_sh_back,
		p_sh_back + fwd * fw,
		p_back_bot + fwd * fw,
		p_back_bot,
	])
	ctx.canvas.draw_polygon(back_band, PackedColorArray([strap_color]))

	# # 側面から見える小さな襟（白いブラウス）
	# var collar_white = Color(1.0, 1.0, 1.0)
	# var p_nk = p_sh + up_v * 9.0
	# var p_nk_f = p_nk + fwd * half_t * 0.5
	# var collar_pts = PackedVector2Array([
	# 	p_nk_f,
	# 	p_nk_f + fwd * 5.0,
	# 	p_nk_f + Vector2(0, 9.0),
	# ])
	# ctx.canvas.draw_polygon(collar_pts, PackedColorArray([collar_white]))

# ============================================================
# 帽子描画関数
# ============================================================

static func draw_hat_front(ctx: DrawContext, hx: float, hy: float, head_r: float, _head_w: float, hat_type: String, hat_color: Color) -> void:
	if hat_type == "none" or hat_type == "":
		return
	
	match hat_type:
		"school_hat":
			# 通学帽 (正面) - ハット型 (全周つば)
			# 髪を含めた頭の実幅: hair_outer_w = head_r * 1.12
			var hair_outer_w = head_r * 1.12
			# クラウン半幅: 髪の幅より少し大きく覆う
			var crown_w = hair_outer_w * 1.05
			var crown_h = head_r * 0.9
			var crown_base_y = hy - head_r * 0.4 # 被る深さ
			var crown_pts = PackedVector2Array()
			var segments = 16
			for i in range(segments + 1):
				var angle = PI + PI * (float(i) / segments)
				crown_pts.append(Vector2(hx + cos(angle) * crown_w, crown_base_y + sin(angle) * crown_h))
			ctx.canvas.draw_polygon(crown_pts, PackedColorArray([hat_color]))
			
			# つば: 髪を含めた頭の幅に合わせて広がる (hair_outer_w + つば追加分)
			var brim_w = hair_outer_w * 1.35
			var brim_h = head_r * 0.15
			var brim_pts = PackedVector2Array()
			# 下半分のカーブ
			for i in range(segments + 1):
				var angle = 0.0 + PI * (float(i) / segments)
				brim_pts.append(Vector2(hx + cos(angle) * brim_w, crown_base_y + sin(angle) * brim_h))
			# 上半分のカーブ (外側だけ見えて、内側はクラウンに隠れる形)
			for i in range(segments + 1):
				var angle = PI + PI * (float(i) / segments)
				brim_pts.append(Vector2(hx - cos(angle) * brim_w, crown_base_y - sin(angle) * brim_h * 0.5))
			ctx.canvas.draw_polygon(brim_pts, PackedColorArray([hat_color.darkened(0.15)]))

static func draw_hat_side(ctx: DrawContext, hx: float, hy: float, head_r: float, _head_w: float, head_angle: float, hat_type: String, hat_color: Color) -> void:
	if hat_type == "none" or hat_type == "":
		return
	
	match hat_type:
		"school_hat":
			# 通学帽 (側面) - ハット型 (全周つば)
			var dir_fwd = Vector2(cos(head_angle), sin(head_angle))
			var dir_up = Vector2(-sin(head_angle), cos(head_angle))
			
			# 髪を含めた頭の実幅 (正面と同じ計算)
			var hair_outer_w_s = head_r * 1.12
			var crown_r_x = hair_outer_w_s * 1.05
			var crown_r_y = head_r * 0.9
			
			# ── クラウン ──────────────────────────────────────
			# 髪の上端を計算（CharacterHairDrawer と同じ値）:
			#   dome_up_offset = head_r * 0.1
			#   hair_dome_R    = head_r * 1.08
			#   → 髪上端 = dir_up * (0.1 + 1.08) * head_r = dir_up * head_r * 1.18
			var hair_top = Vector2(hx, hy) + dir_up * (head_r * 1.18) - dir_up * (head_r) * 0.7
			# クラウン中心 = 髪上端から crown_r_y 分だけ下（内側）
			var crown_center = hair_top - dir_up * crown_r_y
			
			var crown_pts = PackedVector2Array()
			var segments = 16
			for i in range(segments + 1):
				var angle = PI + PI * (float(i) / segments) # 上半分
				var local_x = cos(angle) * crown_r_x
				var local_y = sin(angle) * crown_r_y
				var rot_x = local_x * cos(head_angle) - local_y * sin(head_angle)
				var rot_y = local_x * sin(head_angle) + local_y * cos(head_angle)
				crown_pts.append(crown_center + Vector2(rot_x, rot_y))
			ctx.canvas.draw_polygon(crown_pts, PackedColorArray([hat_color]))
			
			# ── つば ──────────────────────────────────────────
			# つばの基準位置: 正面の crown_base_y = hy - head_r * 0.25 に対応
			# （クラウン中心とは独立して計算）
			var crown_brim_base = crown_center # Vector2(hx, hy) + dir_up * (head_r * 0.25)
			var brim_len = hair_outer_w_s * 1.35 # 正面の brim_w と統一
			var brim_curve = head_r * 0.15 # つばの端が少し下がる設定
			var brim_pts = PackedVector2Array()
			
			# 前側のつばの端（底辺基準から前方・下方へ）
			var p_front = crown_brim_base + dir_fwd * brim_len - dir_up * brim_curve
			# 後ろ側のつばの端
			var p_back = crown_brim_base - dir_fwd * brim_len - dir_up * brim_curve
			
			# 前から後ろへ（太さを持たせたポリゴン）
			brim_pts.append(p_front - dir_up * 2.0)
			brim_pts.append(crown_brim_base + dir_up * 1.0) # 中央は少し上げる
			brim_pts.append(p_back - dir_up * 2.0)
			brim_pts.append(p_back + dir_up * 2.0)
			brim_pts.append(crown_brim_base + dir_up * 5.0)
			brim_pts.append(p_front + dir_up * 2.0)

			ctx.canvas.draw_polygon(brim_pts, PackedColorArray([hat_color.darkened(0.15)]))

# ============================================================
# バッグ（ランドセルなど）描画関数
# ============================================================

# 側面ビュー用バッグ描画
static func draw_bag_side(ctx: DrawContext) -> void:
	if ctx.bag_type == "none" or ctx.bag_type == "":
		return
	match ctx.bag_type:
		"randoseru":
			_draw_randoseru_side(ctx, ctx.bag_color)

static func _draw_randoseru_side(ctx: DrawContext, bag_color: Color) -> void:
	var d = ctx.d
	var m = ctx.m
	var p = ctx.p
	var waist_angle = d["waist_angle"]

	var head_w_m = (m.get("headWidth", m["head"] * 0.702)) * p * 0.85
	var half_t = head_w_m * 0.5

	var fwd = Vector2(cos(waist_angle), sin(waist_angle))
	var up_v = Vector2(-sin(waist_angle), cos(waist_angle))  # +方向=画面下

	var p_sh = Vector2(d["sx"], d["sy"])
	var torso_vec = Vector2(d["navel_x"] - d["sx"], d["navel_y"] - d["sy"])

	var bag_depth = head_w_m * 0.62

	# 胴体背面上端・下端
	var back_top = p_sh - fwd * half_t
	var back_bot = p_sh - fwd * half_t + torso_vec * 0.90
	# バッグ外側上端・下端
	var outer_top = back_top - fwd * bag_depth
	var outer_bot = back_bot - fwd * bag_depth

	# メイン本体
	ctx.canvas.draw_polygon(
		PackedVector2Array([back_top, back_bot, outer_bot, outer_top]),
		PackedColorArray([bag_color])
	)
	# 蓋（上部38%を明るく）
	var lid_r = 0.38
	var lid_ib = back_top + (back_bot - back_top) * lid_r
	var lid_ob = outer_top + (outer_bot - outer_top) * lid_r
	ctx.canvas.draw_polygon(
		PackedVector2Array([back_top, lid_ib, lid_ob, outer_top]),
		PackedColorArray([bag_color.lightened(0.15)])
	)
	# 枠線と蓋の境界線
	var edge = bag_color.darkened(0.25)
	ctx.canvas.draw_polyline(PackedVector2Array([outer_top, outer_bot, back_bot, back_top, outer_top]), edge, 1.2)
	ctx.canvas.draw_line(lid_ib, lid_ob, edge, 1.5)

	# 前ポケット
	var pk0 = lid_r + 0.06
	var pk1 = pk0 + 0.28
	var pk_it = back_top + (back_bot - back_top) * pk0
	var pk_ib2 = back_top + (back_bot - back_top) * pk1
	var pk_ot = outer_top + (outer_bot - outer_top) * pk0
	var pk_ob2 = outer_top + (outer_bot - outer_top) * pk1
	ctx.canvas.draw_polyline(PackedVector2Array([pk_it, pk_ot, pk_ob2, pk_ib2, pk_it]), edge, 0.9)

	# 持ち手（上部にアーチ）
	# -up_v 方向 = 画面上（Yを小さくする）
	var mid = (back_top + outer_top) * 0.5
	var h_l = mid - fwd * bag_depth * 0.12 - up_v * 8.0
	var h_r = mid + fwd * bag_depth * 0.12 - up_v * 8.0
	ctx.canvas.draw_polyline(
		PackedVector2Array([mid - fwd * bag_depth * 0.12, h_l, h_r, mid + fwd * bag_depth * 0.12]),
		edge, 3.0
	)

	# 金具
	ctx.canvas.draw_circle((lid_ib + lid_ob) * 0.5, 2.5, Color(0.85, 0.75, 0.2))

# 背面ビュー用バッグ描画（胴体の後で呼ぶ）
static func draw_bag_back(ctx: DrawContext) -> void:
	if ctx.bag_type == "none" or ctx.bag_type == "":
		return
	match ctx.bag_type:
		"randoseru":
			_draw_randoseru_back(ctx, ctx.bag_color)

static func _draw_randoseru_back(ctx: DrawContext, bag_color: Color) -> void:
	var d = ctx.d
	var sx = d["front_sx"]
	var sy = d["front_sy"]
	var navel_y = d["front_navel_y"]
	var torso_h = navel_y - sy

	var bag_w = ctx.shoulder_w * 0.55
	var bag_h = torso_h * 0.90
	var bag_l = sx - bag_w * 0.5
	var bag_r = sx + bag_w * 0.5
	var bag_top = sy
	var bag_bot = sy + bag_h

	# メイン本体
	ctx.canvas.draw_polygon(
		PackedVector2Array([Vector2(bag_l, bag_top), Vector2(bag_r, bag_top), Vector2(bag_r, bag_bot), Vector2(bag_l, bag_bot)]),
		PackedColorArray([bag_color])
	)
	# 蓋
	var lid_bot = sy + bag_h * 0.38
	ctx.canvas.draw_polygon(
		PackedVector2Array([Vector2(bag_l, bag_top), Vector2(bag_r, bag_top), Vector2(bag_r, lid_bot), Vector2(bag_l, lid_bot)]),
		PackedColorArray([bag_color.lightened(0.15)])
	)
	# 枠線
	var edge = bag_color.darkened(0.25)
	ctx.canvas.draw_rect(Rect2(Vector2(bag_l, bag_top), Vector2(bag_w, bag_h)), edge, false, 1.5)
	ctx.canvas.draw_line(Vector2(bag_l, lid_bot), Vector2(bag_r, lid_bot), edge, 1.5)

	# 前ポケット
	var pk_top = lid_bot + bag_h * 0.06
	var pk_bot = pk_top + bag_h * 0.28
	var pk_l = bag_l + bag_w * 0.15
	var pk_r = bag_r - bag_w * 0.15
	ctx.canvas.draw_rect(Rect2(Vector2(pk_l, pk_top), Vector2(pk_r - pk_l, pk_bot - pk_top)), edge, false, 0.9)

	# 持ち手
	var hb = bag_top - 7.0
	var hl = sx - bag_w * 0.12
	var hr = sx + bag_w * 0.12
	ctx.canvas.draw_line(Vector2(hl, bag_top), Vector2(hl, hb), edge, 3.0)
	ctx.canvas.draw_line(Vector2(hl, hb), Vector2(hr, hb), edge, 3.0)
	ctx.canvas.draw_line(Vector2(hr, hb), Vector2(hr, bag_top), edge, 3.0)

	# ショルダーストラップ
	var strap = bag_color.darkened(0.35)
	ctx.canvas.draw_line(Vector2(bag_l + bag_w * 0.2, bag_top), Vector2(sx - ctx.shoulder_w * 0.28, sy - 5.0), strap, 4.0)
	ctx.canvas.draw_line(Vector2(bag_r - bag_w * 0.2, bag_top), Vector2(sx + ctx.shoulder_w * 0.28, sy - 5.0), strap, 4.0)

	# 金具
	ctx.canvas.draw_circle(Vector2(sx, lid_bot), 3.0, Color(0.85, 0.75, 0.2))

# 正面ビュー用ストラップ描画（胴体の前で呼ぶ）
static func draw_bag_straps_front(ctx: DrawContext) -> void:
	if ctx.bag_type == "none" or ctx.bag_type == "":
		return
	var d = ctx.d
	var sx = d["front_sx"]
	var sy = d["front_sy"]
	var navel_y = d["front_navel_y"]
	var strap = ctx.bag_color.darkened(0.20)
	var sw = ctx.shoulder_w
	var strap_w = maxf(sw * 0.07, 3.0)
	ctx.canvas.draw_line(Vector2(sx - sw * 0.28, sy - 3.0), Vector2(sx - sw * 0.12, navel_y), strap, strap_w)
	ctx.canvas.draw_line(Vector2(sx + sw * 0.28, sy - 3.0), Vector2(sx + sw * 0.12, navel_y), strap, strap_w)
