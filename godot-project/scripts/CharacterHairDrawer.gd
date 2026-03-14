class_name CharacterHairDrawer

# ---------------------------------------------------------------
# 後ろ髪などのベース部分（体の奥に配置されるレイヤー）を描画するヘルパー
#
# 正面ビューで「体の後ろにある髪」として先に描画する。
# 背面ビューでは髪全体として使う。
#
# 引数:
#   head_center : 頭の中心座標
#   head_r      : 頭の半径
#   hair_style  : "short" / "long" / "ponytail" / "side_tail"
#   hair_color  : 髪の色
# ---------------------------------------------------------------
static func draw_hair_base_layer(ctx: DrawContext, head_center: Vector2, head_r: float, hair_style: String, hair_color: Color) -> void:
	var hr = head_r
	var hair_outer_w = hr * 1.12
	var hair_top_h = hr * 1.08
	# 【調整用】後ろ髪の下端位置。hair_style に応じて変わる
	var hair_bottom_y = _get_back_hair_bottom_y(head_center, hr, hair_style)

	var dome_offset_y = - hr * 0.1
	CharacterDrawUtils.draw_ellipse(ctx.canvas, head_center + Vector2(0, dome_offset_y), hair_outer_w, hair_top_h, hair_color)
	if hair_style == "ponytail" or hair_style == "side_tail":
		# ポニテ・サイドテール: 下端を横幅いっぱいの半楕円で丸めた形状
		# 半楕円の最下点 = hair_bottom_y（顎の位置）になる
		# 【調整用】下端の楕円の縦半径。大きいほど丸みが深くなる。hair_bottom_y から上に食い込む量
		var eh = hr * 0.5
		# 楕円の中心Y（ここから eh 下が hair_bottom_y になる）
		var arc_center_y = hair_bottom_y - eh
		var rnd_pts = PackedVector2Array([
			Vector2(head_center.x - hair_outer_w, head_center.y), # 上左
			Vector2(head_center.x + hair_outer_w, head_center.y), # 上右
		])
		# 【調整用】arc_steps を増やすと下端が滑らかになる
		var arc_steps = 10
		for i in range(arc_steps + 1):
			var a = lerp(0.0, PI, float(i) / arc_steps)
			# X: 横幅いっぱい(hair_outer_w)、Y: 縦の丸み(eh) の半楕円
			rnd_pts.append(Vector2(head_center.x + hair_outer_w * cos(a), arc_center_y + eh * sin(a)))
		ctx.canvas.draw_polygon(rnd_pts, PackedColorArray([hair_color]))
		if hair_style == "ponytail":
			# 生え際マーカー（後頭部の中心、髪が一点に集まる位置）
			# 【調整用】マーカーの縦位置。_draw_back_tail の tie_center(hr*0.55) - 根元上端(hr*0.02) に合わせた値
			var hairline_pos = head_center + Vector2(0, hr * 0.43) # 尾の生え際の少し上
			# 【調整用】マーカーの色（赤系）
			var hairline_color = Color(0.85, 0.15, 0.10)
			# 【調整用】マーカーの半径
			ctx.canvas.draw_circle(hairline_pos, hr * 0.15, hairline_color)
	else:
		var back_pts = PackedVector2Array([
			Vector2(head_center.x - hair_outer_w, head_center.y),
			Vector2(head_center.x + hair_outer_w, head_center.y),
			Vector2(head_center.x + hair_outer_w * 1.0, hair_bottom_y),
			Vector2(head_center.x - hair_outer_w * 1.0, hair_bottom_y)
		])
		ctx.canvas.draw_polygon(back_pts, PackedColorArray([hair_color]))
	_draw_back_tail(ctx, head_center, hr, hair_style, hair_color)

# ---------------------------------------------------------------
# 髪型描画ヘルパー（メイン）
#
# facing に応じて正面・背面・側面の髪を描き分ける。
# 描画順: 後髪 → 頭（肌色） → 前髪
#
# 引数:
#   head_center : 頭の中心座標
#   head_r      : 頭の半径
#   head_w      : 頭の横幅（px）
#   hair_style  : "short" / "long" / "ponytail" / "side_tail"
#   hair_color  : 髪の色
#   skin_color  : 肌色
#   facing      : "front" / "back" / "side"
#   head_angle  : 頭の傾き（ラジアン、側面のみ使用）
# ---------------------------------------------------------------
static func draw_hair(ctx: DrawContext, head_center: Vector2, head_r: float, head_w: float,
		hair_style: String, hair_color: Color, skin_color: Color,
		facing: String, head_angle: float = 0.0) -> void:
	var hr = head_r # 頭の半径

	if facing == "front":
		# 【調整用】髪の横幅。大きいほど頭が横に膨らむ（側面1.05、背面1.08に合わせた値）
		var hair_outer_w = hr * 1.12
		# 【調整用】ドーム（頭頂部の丸み）の高さ。大きいほど頭が縦に膨らむ

		# 【調整用】髪の下端位置（ショート/ロング）。値を大きくすると髪が長くなる
		var hair_bottom_y = _get_back_hair_bottom_y(head_center, hr, hair_style)

		# 1. 後ろ髪（顔の背面に描画）は事前描画されるため省略
		var dome_offset_y = - hr * 0.1 # 2. 顔（肌色の円）
		CharacterDrawUtils.draw_ellipse(ctx.canvas, head_center, hr, hr, skin_color)

		# 3. サイドヘア（顔の左右の手前にかぶせる髪）
		# 【調整用】顔が見える幅。小さいほど髪が顔に迫り、大きいほど顔が広く見える
		var side_inner_w = hr * 0.75
		# 【調整用】サイドヘアの上端位置。マイナスを大きくすると上から始まる
		var side_top_y = head_center.y - hr * 0.3

		var left_side_pts = PackedVector2Array([
			Vector2(head_center.x - hair_outer_w, side_top_y),
			Vector2(head_center.x - side_inner_w, side_top_y),
			Vector2(head_center.x - side_inner_w, hair_bottom_y),
			Vector2(head_center.x - hair_outer_w * 0.95, hair_bottom_y)
		])
		ctx.canvas.draw_polygon(left_side_pts, PackedColorArray([hair_color]))

		var right_side_pts = PackedVector2Array([
			Vector2(head_center.x + side_inner_w, side_top_y),
			Vector2(head_center.x + hair_outer_w, side_top_y),
			Vector2(head_center.x + hair_outer_w * 0.95, hair_bottom_y),
			Vector2(head_center.x + side_inner_w, hair_bottom_y)
		])
		ctx.canvas.draw_polygon(right_side_pts, PackedColorArray([hair_color]))

		# 4. 中間髪（ドームと前髪の間の額を埋めるドーナツ弧）
		# 【調整用】弧の中心。ドームの中心と合わせるのが基本
		var arc_center = head_center + Vector2(0, dome_offset_y)
		# 【調整用】弧の外側半径。ドームに合わせる（大きいほど外に広がる）
		var arc_outer_r = hr * 1.10
		# 【調整用】弧の太さ。大きいほど額を広くカバーする
		var arc_thickness = hr * 0.35
		var arc_inner_r = arc_outer_r - arc_thickness
		# 【調整用】弧の開始角度と終了角度（度）。180=左端、270=真上、360=右端
		# 180→360 で上半分180度をカバー。狭めたい場合は例えば 200→340 など
		var arc_start_deg = 180.0
		var arc_end_deg = 360.0
		# 【調整用】ステップ数。多いほど滑らか
		var arc_steps = 16

		var arc_pts = PackedVector2Array()
		# 外側の弧（左→上→右）
		for i in range(arc_steps + 1):
			var t = float(i) / arc_steps
			var a = deg_to_rad(lerp(arc_start_deg, arc_end_deg, t))
			arc_pts.append(arc_center + Vector2(cos(a), sin(a)) * arc_outer_r)
		# 内側の弧（右→上→左、逆順で閉じる）
		for i in range(arc_steps + 1):
			var t = float(i) / arc_steps
			var a = deg_to_rad(lerp(arc_end_deg, arc_start_deg, t))
			arc_pts.append(arc_center + Vector2(cos(a), sin(a)) * arc_inner_r)
		ctx.canvas.draw_polygon(arc_pts, PackedColorArray([hair_color]))

		# 5. 前髪（額にかかるポリゴン）
		draw_bangs_front(ctx, head_center, hr, head_w, hair_style, hair_color)

	elif facing == "back":
		# 背面: 髪全体が見える
		draw_hair_base_layer(ctx, head_center, hr, hair_style, hair_color)

	else: # side
		var down_dir = Vector2(0, 1).rotated(head_angle)
		var back_dir = Vector2(-1, 0).rotated(head_angle)
		var fwd_dir = Vector2(1, 0).rotated(head_angle)
		var up_dir = Vector2(0, -1).rotated(head_angle)

		# 追加：髪の毛先を重力に従って下に向けるベクトル
		var gravity_dir = Vector2(0, 1)
		var hair_down_dir = down_dir
		if hair_style == "long":
			hair_down_dir = gravity_dir # ロングヘアは重力で真下に垂れる
		else:
			hair_down_dir = down_dir.lerp(gravity_dir, 0.5).normalized() # ショートも少し下向きに補正

		# 後ろ髪の長さ決定
		var hair_bottom_len = hr * 1.3 # ショートヘアのデフォルト
		if hair_style == "long":
			hair_bottom_len = hr * 3.5

		# 1. 顔（肌色の円を先に描画する）
		CharacterDrawUtils.draw_ellipse(ctx.canvas, head_center, hr, hr, skin_color, head_angle)

		# 2. 横髪〜後ろ髪（顔の側面〜後頭部を覆う）
		# 【調整用】髪の後頭部のボリューム（1.2などで膨らむ、0.9などで平らに）
		var R = hr * 1.08
		# 【調整用】ドーム中心の上方向オフセット。正面と合わせた値
		var dome_up_offset = hr * 0.1
		var dome_center = head_center + up_dir * dome_up_offset
		var hair_pts = PackedVector2Array()
		# 【調整用】顔にかかる縦のライン（横髪が来る位置）
		# 数値を 0.0 や +hr*0.1 などに増やすと、髪が後ろに下がって顔が広く見え、目への干渉が減ります。
		# -hr*0.2 などマイナスを強めると、髪が前進して顔が隠れます。
		var cut_dist = - hr * 0.1 # マイナス＝中心より前

		var pivot = head_center + back_dir * cut_dist

		# (A) 下部・顔側の頂点
		var p_face_bottom = pivot + hair_down_dir * hair_bottom_len
		hair_pts.append(p_face_bottom)

		# (A') 頭の中央を通るピボット（首を曲げた時の剥げ・隙間防止）
		hair_pts.append(pivot)

		# (B) 頭頂部〜後頭部の丸み（ドーム中心を上にオフセット）
		var steps = 15
		var min_ang = asin(cut_dist / R)

		# 髪が頭の後ろから自然に垂れる「分離点（接点）」の角度を計算
		var sep_dir = hair_down_dir.rotated(PI / 2) # 左（後ろ）を向く法線
		var dot_up = sep_dir.dot(up_dir)
		var dot_back = sep_dir.dot(back_dir)
		var max_ang = atan2(dot_back, dot_up)
		if max_ang < min_ang:
			max_ang += PI * 2.0

		for i in range(steps + 1):
			var t = float(i) / steps
			var ang = lerp(min_ang, max_ang, t)
			var l_back = R * sin(ang)
			var l_up = R * cos(ang)
			hair_pts.append(dome_center + back_dir * l_back + up_dir * l_up)

		# (C) 下部・後ろ側の頂点
		# 分離点（一番後ろの輪郭）から毛先の方向へ垂らす
		var l_back_sep = R * sin(max_ang)
		var l_up_sep = R * cos(max_ang)
		var sep_point = dome_center + back_dir * l_back_sep + up_dir * l_up_sep
		var p_back_bottom = sep_point + hair_down_dir * hair_bottom_len
		hair_pts.append(p_back_bottom)

		ctx.canvas.draw_polygon(hair_pts, PackedColorArray([hair_color]))
		_draw_side_tail_profile(ctx, head_center, hr, hair_style, hair_color, back_dir, fwd_dir, up_dir, down_dir)

		# 3. 中間髪（前髪と後ろ髪の間の扇形オブジェクト）
		# 頭の後ろから前（生え際）へと繋がる自然な丸みを作ります。
		var fan_pts = PackedVector2Array()
		# 【調整用】扇形の中心点。ドーム中心と合わせる
		var fan_center = dome_center + back_dir * cut_dist + up_dir * hr * 0.1
		fan_pts.append(fan_center)

		var fan_steps = 10
		var fan_start_ang = min_ang
		# 【調整用】扇形が前方のどこまで広がるか（-PI/2で額の真ん前）
		var fan_end_ang = - PI / 4 # 45度が生え際とする

		for i in range(fan_steps + 1):
			var t = float(i) / fan_steps
			var ang = lerp(fan_start_ang, fan_end_ang, t)
			var l_back = R * sin(ang)
			var l_up = R * cos(ang)
			fan_pts.append(dome_center + back_dir * l_back + up_dir * l_up)

		ctx.canvas.draw_polygon(fan_pts, PackedColorArray([hair_color]))

		# 4. 前髪
		# 額を覆うように、前方に突き出し、顔の前面をカバーする四角形
		# 【調整用】各頂点の座標を変えることで、前髪のシルエットを作れます。目の位置に合わせて微調整してください。
		var p1 = dome_center + back_dir * (R * sin(fan_end_ang)) + up_dir * (R * cos(fan_end_ang))
		var bangs_pts = PackedVector2Array([
			# ① 扇形の終端あたり（前髪の起点）
			p1,

			# ② 前方に突き出す先端 (ここをいじって長さを調整)
			head_center + fwd_dir * hr * 1.1 + up_dir * hr * 0.1, # 顔の正面方向*1.1倍

			# ③ 前髪の毛先 / 額・目の上のライン
			#   ※ 目が隠れてしまう場合は、ここの `down_dir * hr * 0.1` を
			#      `up_dir * hr * 0.1` などに変更して上に持ち上げるか、 `0.0` に寄せてください。
			#   ※ `fwd_dir * hr * 0.7` の 0.7 を小さくすると、おでこ側へ後退します。
			head_center + fwd_dir * hr * 0.5 + up_dir * hr * 0.1,

			# ④ 横髪の顔側ラインと接触する点
			fan_center.lerp(p1, 0.2)
		])
		ctx.canvas.draw_polygon(bangs_pts, PackedColorArray([hair_color]))


# ---------------------------------------------------------------
# 正面の前髪
#
# 額にかかる前髪のポリゴンを描画する。
# 向かって左側を少し長くし、右側に分け目を入れる形状。
#
# 【調整用パラメータ】
#   bangs_bottom_y : 前髪の下端Y位置。大きくすると目に近づく
#   half_w         : 前髪の横幅（半幅）
#   top_y          : 前髪の上端Y位置（ドーム上端に追従）
# ---------------------------------------------------------------
static func draw_bangs_front(ctx: DrawContext, head_center: Vector2, hr: float, head_w: float, hair_style: String, hair_color: Color) -> void:
	# 【調整用】前髪の下端。大きくすると前髪が目に近づく（マイナス値=頭中心より上）
	var bangs_bottom_y = head_center.y - hr * 0.2
	# 【調整用】前髪の横幅（半幅）。大きいほど前髪が広がる
	var half_w = head_w * 0.55
	# ドーム上端に合わせて前髪の上端を設定（隙間を防ぐ）
	var dome_top_y = head_center.y - hr * 0.1 - hr * 1.08
	# 【調整用】ドーム上端からのオフセット。小さいほど前髪がドームに密着する
	var top_y = dome_top_y + hr * 0.25

	# 向かって左側を少し長くし、右側に分け目を入れる形状
	var pts = PackedVector2Array([
		Vector2(head_center.x - half_w, top_y), # 左上
		Vector2(head_center.x + half_w, top_y), # 右上
		# 【調整用】右下端。0.8を変えると右端の角度が変わる
		Vector2(head_center.x + half_w * 0.8, bangs_bottom_y),
		# 【調整用】分け目の切れ込み。0.3=横位置、0.15=切れ込みの深さ
		Vector2(head_center.x + half_w * 0.00, bangs_bottom_y - hr * 0.0),
		# 【調整用】前髪中央付近。magic number: 中央の位置が左右にずれる
		Vector2(head_center.x - half_w * 0.2, bangs_bottom_y),
		# 【調整用】左サイドバング。magic number: 横位置、下への伸び（大きいほど長い）
		Vector2(head_center.x - half_w * 0.8, bangs_bottom_y + hr * 0.1),
	])
	ctx.canvas.draw_polygon(pts, PackedColorArray([hair_color]))

# ---------------------------------------------------------------
# 側面の前髪（現在未使用: draw_hair の side ブロック内に直接記述済み）
#
# 頭頂部から前方に突き出す三角形の前髪。
# ---------------------------------------------------------------
static func draw_bangs_side(ctx: DrawContext, head_center: Vector2, hr: float, hair_style: String, hair_color: Color, head_angle: float) -> void:
	var forward = Vector2(1, 0).rotated(head_angle)
	var up = Vector2(0, -1).rotated(head_angle)

	# 前髪: 頭頂部から前方に突き出す三角形
	var p1 = head_center + up * hr * 0.9 + forward * hr * 0.1 # 頭頂やや前
	var p2 = head_center + up * hr * 0.3 + forward * hr * 0.95 # 前方に突き出す先端
	var p3 = head_center + up * hr * 0.1 + forward * hr * 0.3 # 額の下端

	var pts = PackedVector2Array([p1, p2, p3])
	ctx.canvas.draw_polygon(pts, PackedColorArray([hair_color]))

static func _get_back_hair_bottom_y(head_center: Vector2, hr: float, hair_style: String) -> float:
	if hair_style == "long":
		return head_center.y + hr * 3.5
	if hair_style == "ponytail":
		# 【調整用】ポニテの後ろ髪の下端。hr * 1.0 = 顎（頭の下端）、hr * 1.3 で首あたり
		# ※ draw_hair_base_layer の半楕円の最下点がここに来る
		return head_center.y + hr * 1.2
	if hair_style == "side_tail":
		return head_center.y + hr * 1.45
	return head_center.y + hr * 1.3

static func _draw_back_tail(ctx: DrawContext, head_center: Vector2, hr: float, hair_style: String, hair_color: Color) -> void:
	if hair_style == "ponytail":
		# 【調整用】結び目の位置。Y を大きくすると下（後頭部の低い位置）に移動する
		var tie_center = head_center + Vector2(0, hr * 0.55)
		# 【調整用】結び目の円の半径
		ctx.canvas.draw_circle(tie_center, hr * 0.16, hair_color.darkened(0.06))
		var tail_pts = PackedVector2Array([
			# 【調整用】尾の根元の幅。X値（±0.18）を変えると根元の太さが変わる
			tie_center + Vector2(-hr * 0.18, -hr * 0.02),
			tie_center + Vector2(hr * 0.18, -hr * 0.02),
			# 【調整用】尾の中間のふくらみ。X * 0.32 を大きくすると尾が広がる
			tie_center + Vector2(hr * 0.32, hr * 2.15),
			# 【調整用】尾の先端。Y * 2.75 で長さを調整（大きいほど長い）
			tie_center + Vector2(0, hr * 2.75),
			tie_center + Vector2(-hr * 0.32, hr * 2.15),
		])
		ctx.canvas.draw_polygon(tail_pts, PackedColorArray([hair_color]))
		# 尾のアウトライン
		# 【調整用】尾の輪郭の色。darkened(0.45) を変えると濃さが変わる
		var tail_outline_color = hair_color.darkened(0.45)
		# 【調整用】尾の輪郭の太さ
		var tail_outline_w = hr * 0.02
		var tail_outline_pts = tail_pts.duplicate()
		tail_outline_pts.append(tail_pts[0]) # 閉じる
		ctx.canvas.draw_polyline(tail_outline_pts, tail_outline_color, tail_outline_w, true)
	elif hair_style == "side_tail":
		# 右側・左側の両方を描画（左右対称）
		for side_sign in [1.0, -1.0]:
			# 【調整用】サイドテールの結び目位置。X を大きくすると外側、Y を大きくすると下
			var tie_side = head_center + Vector2(hr * 0.72 * side_sign, hr * 0.18)
			# 【調整用】結び目の円の半径
			ctx.canvas.draw_circle(tie_side, hr * 0.15, hair_color.darkened(0.06))
			var side_tail = PackedVector2Array([
				tie_side + Vector2(-hr * 0.10 * side_sign, -hr * 0.02),
				tie_side + Vector2(hr * 0.18 * side_sign, hr * 0.02),
				# 【調整用】尾の中間のふくらみと長さ
				tie_side + Vector2(hr * 0.62 * side_sign, hr * 0.85),
				# 【調整用】尾の先端。Y * 2.20 を変えると長さが変わる
				tie_side + Vector2(hr * 0.30 * side_sign, hr * 2.20),
				tie_side + Vector2(-hr * 0.06 * side_sign, hr * 1.65),
			])
			ctx.canvas.draw_polygon(side_tail, PackedColorArray([hair_color]))
			# 【調整用】輪郭線の色（darkened値を大きくすると濃く）と太さ
			var outline_color = hair_color.darkened(0.35)
			var outline_w = hr * 0.02
			var outline_pts = side_tail.duplicate()
			outline_pts.append(side_tail[0])
			ctx.canvas.draw_polyline(outline_pts, outline_color, outline_w, true)
			# 生え際マーカー（結び目位置の確認用）
			# 【調整用】マーカーの色（黄色系）
			var marker_color = Color(0.95, 0.85, 0.10)
			# 【調整用】マーカーの半径
			ctx.canvas.draw_circle(tie_side, hr * 0.08, marker_color)

# 現在未使用（正面ビューのサイドテールは draw_hair_base_layer → _draw_back_tail が担う）
static func _draw_front_side_tail(ctx: DrawContext, head_center: Vector2, hr: float, hair_color: Color) -> void:
	# 右側・左側の両方を描画（左右対称）
	for side_sign in [1.0, -1.0]:
		# 【調整用】正面から見たサイドテールの結び目位置。X で左右位置、Y で高さを調整
		var tie_side = head_center + Vector2(hr * 0.72 * side_sign, hr * 0.16)
		# 【調整用】結び目の円の半径
		ctx.canvas.draw_circle(tie_side, hr * 0.14, hair_color.darkened(0.06))
		var tail_pts = PackedVector2Array([
			tie_side + Vector2(-hr * 0.08 * side_sign, 0.0),
			tie_side + Vector2(hr * 0.12 * side_sign, hr * 0.04),
			# 【調整用】尾の中間のふくらみ
			tie_side + Vector2(hr * 0.40 * side_sign, hr * 0.65),
			# 【調整用】尾の先端。Y * 1.85 を変えると長さが変わる
			tie_side + Vector2(hr * 0.25 * side_sign, hr * 1.85),
			tie_side + Vector2(-hr * 0.02 * side_sign, hr * 1.45),
		])
		ctx.canvas.draw_polygon(tail_pts, PackedColorArray([hair_color]))
		# 【調整用】輪郭線の色（darkened値を大きくすると濃く）と太さ
		var outline_color = hair_color.darkened(0.35)
		var outline_w = hr * 0.02
		var outline_pts = tail_pts.duplicate()
		outline_pts.append(tail_pts[0])
		ctx.canvas.draw_polyline(outline_pts, outline_color, outline_w, true)

static func _draw_side_tail_profile(
	ctx: DrawContext,
	head_center: Vector2,
	hr: float,
	hair_style: String,
	hair_color: Color,
	back_dir: Vector2,
	fwd_dir: Vector2,
	up_dir: Vector2,
	down_dir: Vector2
) -> void:
	if hair_style == "ponytail":
		# 【調整用】側面から見たポニテの結び目位置。back_dir * 1.1 で後頭部表面あたり、down_dir で高さ
		var pony_tie = head_center + back_dir * hr * 1.1 + down_dir * hr * 0.18
		# 【調整用】結び目の円の半径
		ctx.canvas.draw_circle(pony_tie, hr * 0.14, hair_color.darkened(0.06))
		# ヘ音記号状のカーブ:
		#   背面(外側)エッジ → 後ろ上に出て最大後方点を経て下りてくる
		#   前面(内側)エッジ → ほぼ直線で下り、先端で少し前方に流れる
		var pony_pts = PackedVector2Array([
			# --- 背面(外側)エッジ ---
			pony_tie + up_dir * hr * 0.12,                                  # 根元（上）
			# 【調整用】後方への初期張り出し。up_dir を増やすと根元が上に出る
			pony_tie + back_dir * hr * 0.26 + up_dir * hr * 0.06,
			# 【調整用】弧の最後方点。back_dir * 0.34 が後方への最大距離
			pony_tie + back_dir * hr * 0.34 + down_dir * hr * 0.55,
			# 【調整用】後方から下りてくる中間点
			pony_tie + back_dir * hr * 0.16 + down_dir * hr * 1.40,
			# 【調整用】先端。down_dir * 2.30 で長さ調整。fwd_dir で前方への流れを調整
			pony_tie + fwd_dir * hr * 0.06 + down_dir * hr * 2.30,
			# --- 前面(内側)エッジ ---
			# 【調整用】先端の内側。fwd_dir を大きくすると先端が前方に流れる
			pony_tie + fwd_dir * hr * 0.20 + down_dir * hr * 2.05,
			pony_tie + fwd_dir * hr * 0.18 + down_dir * hr * 1.20,        # 前方中間
			pony_tie + fwd_dir * hr * 0.14 + down_dir * hr * 0.45,        # 前方ふくらみ
			pony_tie + fwd_dir * hr * 0.06,                                # 根元（下）
		])
		ctx.canvas.draw_polygon(pony_pts, PackedColorArray([hair_color]))
		# 【調整用】尾の輪郭の色。darkened(0.45) を変えると濃さが変わる
		var outline_color = hair_color.darkened(0.45)
		# 【調整用】尾の輪郭の太さ
		var outline_w = hr * 0.01
		var outline_pts = pony_pts.duplicate()
		outline_pts.append(pony_pts[0]) # 閉じる
		ctx.canvas.draw_polyline(outline_pts, outline_color, outline_w, true)
	elif hair_style == "side_tail":
		# 【調整用】側面から見たサイドテールの結び目位置。
		# back_dir を増やすと後頭部方向（後ろへ）、down_dir を増やすと下に
		var side_tie = head_center + back_dir * hr * 0.75 + down_dir * hr * 0.20
		# 【調整用】結び目の円の半径
		ctx.canvas.draw_circle(side_tie, hr * 0.14, hair_color.darkened(0.06))
		# D字型（背中側に膨らむ）の尾。ポニテと同様に外側エッジ→先端→内側エッジの構造
		var side_pts = PackedVector2Array([
			# --- 背面(外側)エッジ ---
			side_tie + up_dir * hr * 0.10,                                  # 根元（上）
			# 【調整用】後方への初期張り出し。up_dir を増やすと根元が上に出る
			side_tie + back_dir * hr * 0.22 + up_dir * hr * 0.05,
			# 【調整用】弧の最後方点。back_dir * 0.32 が後方への最大距離（ポニテの0.34相当）
			side_tie + back_dir * hr * 0.5 + down_dir * hr * 0.50,
			# 【調整用】後方から下りてくる中間点
			side_tie + back_dir * hr * 0.14 + down_dir * hr * 1.30,
			# 【調整用】先端。down_dir * 1.88 で長さ調整。fwd_dir で前方への流れを調整
			side_tie + fwd_dir * hr * 0.04 + down_dir * hr * 1.88,
			# --- 前面(内側)エッジ ---
			# 【調整用】先端の内側。fwd_dir を大きくすると先端が前方に流れる
			side_tie + fwd_dir * hr * 0.18 + down_dir * hr * 1.65,
			side_tie + fwd_dir * hr * 0.16 + down_dir * hr * 1.05,         # 前方中間
			side_tie + fwd_dir * hr * 0.12 + down_dir * hr * 0.40,         # 前方ふくらみ
			side_tie + fwd_dir * hr * 0.04,                                 # 根元（下）
		])
		ctx.canvas.draw_polygon(side_pts, PackedColorArray([hair_color]))
		# 【調整用】輪郭線の色（darkened値を大きくすると濃く）と太さ
		var outline_color = hair_color.darkened(0.35)
		var outline_w = hr * 0.02
		var outline_pts = side_pts.duplicate()
		outline_pts.append(side_pts[0])
		ctx.canvas.draw_polyline(outline_pts, outline_color, outline_w, true)
