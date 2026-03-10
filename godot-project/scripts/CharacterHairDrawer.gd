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
#   hair_style  : "short" or "long"
#   hair_color  : 髪の色
# ---------------------------------------------------------------
static func draw_hair_base_layer(ctx: DrawContext, head_center: Vector2, head_r: float, hair_style: String, hair_color: Color) -> void:
	var hr = head_r
	var hair_outer_w = hr * 1.12
	var hair_top_h = hr * 1.08
	# 【調整用】後ろ髪の下端位置。hair_style に応じて変わる
	var hair_bottom_y = head_center.y + hr * 1.3
	if hair_style == "long":
		hair_bottom_y = head_center.y + hr * 3.5

	var dome_offset_y = - hr * 0.1
	CharacterDrawUtils.draw_ellipse(ctx.canvas, head_center + Vector2(0, dome_offset_y), hair_outer_w, hair_top_h, hair_color)
	var back_pts = PackedVector2Array([
		Vector2(head_center.x - hair_outer_w, head_center.y),
		Vector2(head_center.x + hair_outer_w, head_center.y),
		Vector2(head_center.x + hair_outer_w * 1.0, hair_bottom_y),
		Vector2(head_center.x - hair_outer_w * 1.0, hair_bottom_y)
	])
	ctx.canvas.draw_polygon(back_pts, PackedColorArray([hair_color]))

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
#   hair_style  : "short" or "long"
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
		var hair_bottom_y = head_center.y + hr * 1.3 # 短い場合
		if hair_style == "long":
			hair_bottom_y = head_center.y + hr * 3.5 # ロングの場合

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
