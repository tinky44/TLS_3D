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
			draw_blazer_front(ctx, sx, sy, neck_y, navel_y, half_sh, half_body, tops_color, true)
		"blouse_bow":
			draw_bow_front(ctx, sx, sy, navel_y, half_body, tops_color)
		"jumper_skirt":
			draw_jumper_front(ctx, sx, sy, neck_y, navel_y, half_sh, half_body, tops_color)

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
			draw_blazer_side(ctx, sx, sy, navel_y, navel_x, half_t, fwd, up_v, waist_angle, tops_color, true)
		"blouse_bow":
			draw_bow_side(ctx, sx, sy, navel_y, half_t, fwd, up_v, waist_angle, tops_color)
		"jumper_skirt":
			draw_jumper_side(ctx, sx, sy, navel_y, half_t, fwd, up_v, waist_angle, tops_color)

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
# TODO 本当はジャンパースカート
#
# 描画パーツ:
#   1. (is_dark のみ) ジャケット胴体の塗りつぶし（暗色用途）
#   2. 内側の白シャツ（逆V字形）
#   3. 左ラペル（折り返し襟）
#   4. 右ラペル
#   5. ラペルの縁取りライン
#   6. ボタンライン（中央縦線）
#   7. ボタン（3個）
#   8. リボン/ネクタイ（draw_bow_front を呼び出し）
#
# 引数:
#   is_dark : 常にtrue (暗色仕様に統一)
#
# 【調整用】
#   lapel_inner_y : ラペル内側下端（sy〜navel_y の lerp）
# ---------------------------------------------------------------
static func draw_blazer_front(ctx: DrawContext, sx: float, sy: float, _neck_y: float, navel_y: float,
		half_sh: float, half_body: float, jacket_color: Color, is_dark: bool) -> void:
	# 暗色仕様の場合: 胴体部分を塗りつぶし
	if is_dark:
		var jacket_body_pts = PackedVector2Array([
			Vector2(sx - half_body, sy),
			Vector2(sx + half_body, sy),
			Vector2(sx + half_body, navel_y + 10.0),
			Vector2(sx - half_body, navel_y + 10.0),
		])
		ctx.canvas.draw_polygon(jacket_body_pts, PackedColorArray([jacket_color]))

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
	var bow_w = half_body * 0.55 # リボンの横方向の広がり
	var bow_h = half_body * 0.28 # リボンの縦の高さ

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
		waist_angle: float, sailor_color: Color, skin_color: Color) -> void:
	# 胴体上部の前方点（首元〜肩のライン）
	var p_sh_front = Vector2(sx, sy) + fwd * half_t * 0.95
	var p_nk = Vector2(sx, sy) + up_v * 12.0 # 首付近
	var p_nk_front = p_nk + fwd * half_t * 0.8

	# 胸元のV字の開きを肌色で塗って青線を隠す
	var v_bottom = p_sh_front + Vector2(0, (navel_y - sy) * 0.42)
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
	var scarf_end = v_bottom + Vector2(0, (navel_y - sy) * 0.40)
	var sc = Color(0.8, 0.15, 0.15)
	var scarf_pts = PackedVector2Array([
		v_bottom + fwd * 3.0,
		v_bottom - fwd * 3.0,
		scarf_end - fwd * 1.0,
	])
	ctx.canvas.draw_polygon(scarf_pts, PackedColorArray([sc]))

# ---------------------------------------------------------------
# ジャンパースカートオーバーレイ（側面）
# TODO 関数名変更 draw_blazer_side
#
# 描画パーツ:
#   1. (is_dark のみ) ジャケット胴体の塗りつぶし
#   2. 白シャツ（前面の細い帯）
#   3. 前面のラペル（折り返し部分の三角形）
#   4. ラペルのエッジライン
#   5. リボン（draw_bow_side を呼び出し）
#
# 引数:
#   is_dark : 常にtrue (暗色仕様に統一)
# ---------------------------------------------------------------
static func draw_blazer_side(ctx: DrawContext, sx: float, sy: float, navel_y: float, navel_x: float,
		half_t: float, fwd: Vector2, up_v: Vector2,
		waist_angle: float, jacket_color: Color, is_dark: bool) -> void:
	var p_sh = Vector2(sx, sy)
	var p_sh_front = p_sh + fwd * half_t
	var p_sh_back = p_sh - fwd * half_t

	# 暗色仕様: 胴体前面を上書き
	if is_dark:
		var white_fw = half_t * 0.66 # 胴体の厚みに対しておよそ1/3（前面側）
		
		# 後ろ側2/3をジャンパースカート（暗色）として描画
		var jacket_cover = PackedVector2Array([
			p_sh_back,
			p_sh_front - fwd * white_fw,
			p_sh_front - fwd * white_fw + Vector2(0, (navel_y - sy) + 10.0),
			p_sh_back + Vector2(0, (navel_y - sy) + 10.0),
		])
		ctx.canvas.draw_polygon(jacket_cover, PackedColorArray([jacket_color]))

		# 前面側1/3を白シャツとして描画
		var shirt_inner = Color(0.96, 0.96, 0.96)
		var shirt_cover = PackedVector2Array([
			p_sh_front - fwd * white_fw,
			p_sh_front,
			p_sh_front + Vector2(0, (navel_y - sy) + 10.0),
			p_sh_front - fwd * white_fw + Vector2(0, (navel_y - sy) + 10.0),
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
		waist_angle: float, bow_color: Color) -> void:
	# 側面では蝶ネクタイが胴体の前面に小さく見える。肩と乳首の間にハイライト
	var p_sh = Vector2(sx, sy)
	var chest_y_offset = (navel_y - sy) * 0.22
	var center = p_sh + Vector2(0, chest_y_offset) + fwd * half_t * 0.88
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
static func draw_jumper_front(ctx: DrawContext, sx: float, sy: float, neck_y: float, navel_y: float,
		half_sh: float, half_body: float, jumper_color: Color) -> void:
	var strap_outer = half_sh * 0.98 # ストラップ外端（肩幅満杖）
	var strap_inner = half_body * 0.30 # ストラップ内端（白い部分の境界）
	var strap_top_y = sy - 4.0 # ストラップ上端
	var strap_bot_y = navel_y + 10.0 # ストラップ下端

	# 左ストラップ
	var left_pts = PackedVector2Array([
		Vector2(sx - strap_outer, strap_top_y),
		Vector2(sx - strap_inner, strap_top_y),
		Vector2(sx - strap_inner, strap_bot_y),
		Vector2(sx - strap_outer, strap_bot_y),
	])
	ctx.canvas.draw_polygon(left_pts, PackedColorArray([jumper_color]))

	# 右ストラップ
	var right_pts = PackedVector2Array([
		Vector2(sx + strap_inner, strap_top_y),
		Vector2(sx + strap_outer, strap_top_y),
		Vector2(sx + strap_outer, strap_bot_y),
		Vector2(sx + strap_inner, strap_bot_y),
	])
	ctx.canvas.draw_polygon(right_pts, PackedColorArray([jumper_color]))

	# ストラップ内側繁（陰影感）
	var edge_dark = jumper_color.darkened(0.28)
	ctx.canvas.draw_line(Vector2(sx - strap_inner, strap_top_y), Vector2(sx - strap_inner, strap_bot_y), edge_dark, 1.6)
	ctx.canvas.draw_line(Vector2(sx + strap_inner, strap_top_y), Vector2(sx + strap_inner, strap_bot_y), edge_dark, 1.6)

	# 小さな折り返し襟（ブラウスの襟）
	var collar_white = Color(1.0, 1.0, 1.0)
	var collar_shadow = Color(0.2, 0.2, 0.2, 0.35)
	# 左襟フラップ
	var lc = PackedVector2Array([
		Vector2(sx - half_body * 0.22, neck_y + 2.0),
		Vector2(sx - half_body * 0.04, sy + 4.0),
		Vector2(sx + half_body * 0.06, neck_y + 4.0),
		Vector2(sx - half_body * 0.08, neck_y + 2.0),
	])
	ctx.canvas.draw_polygon(lc, PackedColorArray([collar_white]))
	# 右襟フラップ
	var rc = PackedVector2Array([
		Vector2(sx + half_body * 0.22, neck_y + 2.0),
		Vector2(sx + half_body * 0.04, sy + 4.0),
		Vector2(sx - half_body * 0.06, neck_y + 4.0),
		Vector2(sx + half_body * 0.08, neck_y + 2.0),
	])
	ctx.canvas.draw_polygon(rc, PackedColorArray([collar_white]))
	# 襟の縁取りライン
	ctx.canvas.draw_line(Vector2(sx - half_body * 0.22, neck_y + 2.0), Vector2(sx, sy + 4.0), collar_shadow, 1.2)
	ctx.canvas.draw_line(Vector2(sx + half_body * 0.22, neck_y + 2.0), Vector2(sx, sy + 4.0), collar_shadow, 1.2)

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
static func draw_jumper_side(ctx: DrawContext, sx: float, sy: float, navel_y: float,
		half_t: float, fwd: Vector2, up_v: Vector2,
		waist_angle: float, jumper_color: Color) -> void:
	var p_sh = Vector2(sx, sy)
	var p_sh_front = p_sh + fwd * half_t * 0.95
	var p_sh_back = p_sh - fwd * half_t * 0.95
	var strap_len = Vector2(0, (navel_y - sy) + 10.0)
	var fw = half_t * 0.40 # ストラップの幅

	# 前面ストラップ（胴体前面側の帯）
	var front_band = PackedVector2Array([
		p_sh_front,
		p_sh_front - fwd * fw,
		p_sh_front - fwd * fw + strap_len,
		p_sh_front + strap_len,
	])
	ctx.canvas.draw_polygon(front_band, PackedColorArray([jumper_color]))

	# 背面ストラップ（胴体背面側の帯）
	var back_band = PackedVector2Array([
		p_sh_back,
		p_sh_back + fwd * fw,
		p_sh_back + fwd * fw + strap_len,
		p_sh_back + strap_len,
	])
	ctx.canvas.draw_polygon(back_band, PackedColorArray([jumper_color]))

	# 側面から見える小さな襟（白いブラウス）
	var collar_white = Color(1.0, 1.0, 1.0)
	var p_nk = p_sh + up_v * 9.0
	var p_nk_f = p_nk + fwd * half_t * 0.5
	var collar_pts = PackedVector2Array([
		p_nk_f,
		p_nk_f + fwd * 5.0,
		p_nk_f + fwd * 4.0 + Vector2(0, 11.0),
		p_nk_f + Vector2(0, 9.0),
	])
	ctx.canvas.draw_polygon(collar_pts, PackedColorArray([collar_white]))
