extends Node2D

# =============================================================
# CharacterDrawer.gd
#
# キャラクターの描画を担当するノード。
# CharacterPoseCalculator が算出した骨格座標を受け取り、
# part_shapes 設定に従って各パーツをポリゴン/円で描画する。
#
# 【描画レイヤー順（正面・背面）】
#   1. 髪ベースレイヤー（後ろ髪）
#   2. 両足（左右）
#   3. 胴体（シャツ）
#   4. ボトムス（スカートまたはパンツ骨盤）
#   5. 頭 + 髪（前髪含む）
#   6. 服装オーバーレイ（カラー・ラペル・リボン等）
#   7. 両腕（袖付き）
#   8. 顔（目・口）
#
# 【描画レイヤー順（側面）】
#   1. 奥の腕（袖付き）
#   2. 奥の足
#   3. 胴体（服）
#   4. 手前の足
#   5. ボトムス（スカートまたはパンツ骨盤）
#   6. 頭 + 髪
#   7. 服装オーバーレイ（カラー・ラペル・リボン等）
#   8. 顔（目・口）
#   9. 手前の腕（袖付き）
#
# 【対応 tops_type】
#   t_shirt      : 半袖Tシャツ（半袖台形 + 下は肌色）
#   sweater      : 長袖セーター（肘まで台形 + 肘〜手首台形）
#   blouse       : 長袖ブラウス（sweaterと同形状）
#
#   以下は制服
#   sailor       : セーラー服（長袖 + セーラーカラー + スカーフ）
#   blazer       : 明色ブレザー（長袖 + ラペル + 青リボン）
#   blazer_dark  : 暗色ブレザー（長袖 + 胴体上書き + ラペル + 赤リボン）# TODO ブレザーは不要。高校の制服
#   blouse_bow   : リボン付きブラウス（長袖 + リボンのみ） # TODO これは小学校高学年
#   jumper_skirt : ジャンパースカート（白ブラウス + 濃色サロペットストラップ） # TODO 低学年用吊りスカート
#
# 【対応 bottoms_type】
#   pants        : ズボン（台形パンツ。各脚に台形を重ねる）
#   skirt        : ミディスカート（膝上丈）
#   skirt_short  : ショートスカート（スカートより短め）
#   skirt_long   : ロングスカート（足首丈）
# =============================================================

@onready var player = get_parent()

# 描画の基本となる図形の設定
# これらの値を変更することで、矩形ベース等に切り替えることが可能
@export var part_shapes = {
	"head": "ellipse", # \"ellipse\", \"rect\"
	"torso_lower": "trapezoid", # 横向き用。\"trapezoid\", \"rect\", \"ellipse\" // TODO: ５角形であるべき
	"torso_upper": "trapezoid", # 横向き用。\"trapezoid\", \"rect\", \"ellipse\"
	"torso_front_lower": "pentagon", # 正面・背面用。\"pentagon\", \"rect\", \"trapezoid\"
	"torso_front_upper": "rect", # 正面・背面用。\"rect\", \"trapezoid\"
	"limb": "stick", # 腕や脚の形状。\"stick\"(線+関節), \"limb\"(カプセル型), \"rect\", \"line\"
	"neck": "limb", # 首の形状。\"limb\"(カプセル型), \"stick\"
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
	var appearance = player.get("appearance")
	if appearance == null or appearance.is_empty():
		appearance = Global.current_appearance

	var skin_color = Color("#ffe4c4")
	var base_shirt_color = Color(appearance.get("tops_color", "#ab82a8"))
	var pants_color = Color(appearance.get("bottoms_color", "#e5d6ba"))
	# ジャンパースカートは下に白いブラウスを着るのでベースシャツ色を白に上書き
	if appearance.get("tops_type", "t_shirt") == "jumper_skirt":
		base_shirt_color = Color(0.97, 0.97, 0.97)

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

# ---------------------------------------------------------------
# 袖付き腕を描画するヘルパー
#
# 肌色の腕（stick/limb）を先に描き、その上に服の袖（台形）を重ねる。
# tops_type によって袖の長さや形が変わる。
#
# 引数:
#   p_torso_shoulder : 胴体側の肩位置（袖台形の開始点。肩の隙間をカバーするため腕より少し内側）
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
func _draw_sleeve_arm(p_shoulder: Vector2, p_elbow: Vector2, p_hand: Vector2,
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
		CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_shoulder, p_elbow, arm_w, skin)
		CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_elbow, p_hand, arm_w * 0.8, skin)
		CharacterDrawUtils.draw_trapezoid(self , p_top_center, p_elbow, sleeve_top_w, sleeve_bot_w, shirt, outline_color)
		CharacterDrawUtils.draw_trapezoid(self , p_elbow, p_hand, sleeve_bot_w, arm_w * 1.3, shirt, outline_color)

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
				draw_line(p1_center - norm * w1 / 2.0, p1_center + norm * w1 / 2.0, line_col, 1.5)
				
				# 2本目 (手首付近)
				var t2 = 0.92
				var p2_center = p_elbow.lerp(p_hand, t2)
				var w2 = lerp(sleeve_bot_w, float(arm_w * 1.3), t2)
				draw_line(p2_center - norm * w2 / 2.0, p2_center + norm * w2 / 2.0, line_col, 1.5)
	elif tops_type == "t_shirt":
		# 半袖: 肩→上腕60%地点まで台形袖（末広がり）、残りは肌色limb
		var sleeve_end = p_top_center.lerp(p_elbow, 0.6)
		CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_shoulder, p_elbow, arm_w, skin)
		CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_elbow, p_hand, arm_w * 0.8, skin)
		CharacterDrawUtils.draw_trapezoid(self , p_top_center, sleeve_end, sleeve_top_w, sleeve_bot_w, shirt, outline_color)
	else:
		# ノースリーブ等: 通常の腕描画のみ
		CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_shoulder, p_elbow, arm_w, skin)
		CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_elbow, p_hand, arm_w * 0.8, skin)

	CharacterDrawUtils.draw_hand(self , p_hand, hand_hw, hand_hh, skin, hand_angle)

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
func _draw_pants_leg(p_hip: Vector2, p_knee: Vector2, p_ankle: Vector2,
		thigh_w: float, shin_w: float, skin: Color, pants: Color,
		bottoms_type: String, pants_top_w: float) -> void:
	# 肌色の脚を描画
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_hip, p_knee, thigh_w, skin)
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_knee, p_ankle, shin_w, skin)
	# パンツの場合は台形で上書き（股から開始してジョイントをカバー）
	if bottoms_type == "pants":
		# 【調整用】パンツの太さ倍率。1.1で太もも幅より10%広い
		var pants_knee_w = thigh_w * 1.1
		var pants_ankle_w = shin_w * 1.15
		CharacterDrawUtils.draw_trapezoid(self , p_hip, p_knee, pants_top_w, pants_knee_w, pants)
		CharacterDrawUtils.draw_trapezoid(self , p_knee, p_ankle, pants_knee_w, pants_ankle_w, pants)

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
func _draw_hair_base_layer(head_center: Vector2, head_r: float, hair_style: String, hair_color: Color) -> void:
	var hr = head_r
	var hair_outer_w = hr * 1.12
	var hair_top_h = hr * 1.08
	# 【調整用】後ろ髪の下端位置。hair_style に応じて変わる
	var hair_bottom_y = head_center.y + hr * 1.3
	if hair_style == "long":
		hair_bottom_y = head_center.y + hr * 3.5

	var dome_offset_y = - hr * 0.1
	CharacterDrawUtils.draw_ellipse(self , head_center + Vector2(0, dome_offset_y), hair_outer_w, hair_top_h, hair_color)
	var back_pts = PackedVector2Array([
		Vector2(head_center.x - hair_outer_w, head_center.y),
		Vector2(head_center.x + hair_outer_w, head_center.y),
		Vector2(head_center.x + hair_outer_w * 1.0, hair_bottom_y),
		Vector2(head_center.x - hair_outer_w * 1.0, hair_bottom_y)
	])
	draw_polygon(back_pts, PackedColorArray([hair_color]))

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
func _draw_hair(head_center: Vector2, head_r: float, head_w: float,
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
		CharacterDrawUtils.draw_ellipse(self , head_center, hr, hr, skin_color)

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
		draw_polygon(left_side_pts, PackedColorArray([hair_color]))

		var right_side_pts = PackedVector2Array([
			Vector2(head_center.x + side_inner_w, side_top_y),
			Vector2(head_center.x + hair_outer_w, side_top_y),
			Vector2(head_center.x + hair_outer_w * 0.95, hair_bottom_y),
			Vector2(head_center.x + side_inner_w, hair_bottom_y)
		])
		draw_polygon(right_side_pts, PackedColorArray([hair_color]))

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
		draw_polygon(arc_pts, PackedColorArray([hair_color]))

		# 5. 前髪（額にかかるポリゴン）
		_draw_bangs_front(head_center, hr, head_w, hair_style, hair_color)

	elif facing == "back":
		# 背面: 髪全体が見える
		_draw_hair_base_layer(head_center, hr, hair_style, hair_color)

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
		CharacterDrawUtils.draw_ellipse(self , head_center, hr, hr, skin_color, head_angle)

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

		draw_polygon(hair_pts, PackedColorArray([hair_color]))

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

		draw_polygon(fan_pts, PackedColorArray([hair_color]))

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
		draw_polygon(bangs_pts, PackedColorArray([hair_color]))


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
func _draw_bangs_front(head_center: Vector2, hr: float, head_w: float, hair_style: String, hair_color: Color) -> void:
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
	draw_polygon(pts, PackedColorArray([hair_color]))

# ---------------------------------------------------------------
# 側面の前髪（現在未使用: _draw_hair の side ブロック内に直接記述済み）
#
# 頭頂部から前方に突き出す三角形の前髪。
# ---------------------------------------------------------------
func _draw_bangs_side(head_center: Vector2, hr: float, hair_style: String, hair_color: Color, head_angle: float) -> void:
	var forward = Vector2(1, 0).rotated(head_angle)
	var up = Vector2(0, -1).rotated(head_angle)

	# 前髪: 頭頂部から前方に突き出す三角形
	var p1 = head_center + up * hr * 0.9 + forward * hr * 0.1 # 頭頂やや前
	var p2 = head_center + up * hr * 0.3 + forward * hr * 0.95 # 前方に突き出す先端
	var p3 = head_center + up * hr * 0.1 + forward * hr * 0.3 # 額の下端

	var pts = PackedVector2Array([p1, p2, p3])
	draw_polygon(pts, PackedColorArray([hair_color]))

# ---------------------------------------------------------------
# スカート描画ヘルパー
#
# bottoms_type に応じたスカートを描画する。
# 側面では脚の動きに合わせてスカートを傾け、裾を広げる。
# 正面・背面では足の広がりに合わせて裾幅を調整し、下端にカーブを付ける。
#
# 引数:
#   d            : ポーズデータ辞書（CharacterPoseCalculator の出力）
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
func _draw_skirt(d: Dictionary, bottoms_type: String, bottoms_color: Color, waist_pos: Vector2, base_width: float, facing: String = "front") -> void:
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

		CharacterDrawUtils.draw_trapezoid(self , waist_pos, p_bottom, base_width, actual_hem_w, bottoms_color)
		
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
					draw_line(top_p, bot_p, pleat_col, 1.5)
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
	draw_polygon(pts, PackedColorArray([bottoms_color]))

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
			draw_line(top_p, bot_p, pleat_col, 1.5)

# --- 正面・背面 描画 ---
func _draw_front_back(m, p, d, appearance, skin_color, base_shirt_color, pants_color, skin_dark, shirt_dark, _pants_dark, shoulder_w, thigh_w, shin_w, arm_w, _neck_w):
	var facing = player.facing
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

	var foot_w = 7.0 * p
	var foot_h = 3.5 * p
	# 正面の手: 縦=頭の縦×0.83、横=肩幅/5（側面の1/4相当）
	var shoulder_full = (m["shoulder"] if m.has("shoulder") else 35.0) * p
	var hand_hw = shoulder_full / 5.0 / 4.0 / 2.0
	var hand_hh = d["head_h"] * 0.83 / 2.0
	var shoe_color = Color(appearance.get("shoes_color", "#e5d6ba"))

	var bottoms_type = appearance.get("bottoms_type", "pants")
	var tops_type = appearance.get("tops_type", "t_shirt")
	var is_skirt = bottoms_type.begins_with("skirt")

	# 0. 髪のベースレイヤー（正面向きの場合、体の後ろに描画する）
	var hair_style = appearance.get("hair_style", "short")
	var hair_color = Color(appearance.get("hair_color", "#4a3c31"))
	var head_r = d["head_h"] / 2.0
	if facing == "front":
		_draw_hair_base_layer(Vector2(d["front_hx"], d["front_hy"]), head_r, hair_style, hair_color)

	# 1. 両足
	var pants_thigh_w = thigh_w * 1.3
	var pelvis_w = (p_hip_r.x - p_hip_l.x) + pants_thigh_w
	var leg_pants_top_w = pelvis_w / 2.0 # 各脚は骨盤の底辺の半分ずつを担当

	var p_thigh_l = CharacterPoseCalculator.rotated_point(p_hip_l.x, p_hip_l.y, d["thigh_l"], f_leg_l_ang)
	var p_shin_l = CharacterPoseCalculator.rotated_point(p_thigh_l.x, p_thigh_l.y, d["shin_l"], f_leg_l_ang + d["knee_l"] * 0.2)
	_draw_pants_leg(p_hip_l, p_thigh_l, p_shin_l, thigh_w, shin_w, skin_color, pants_color, bottoms_type, leg_pants_top_w)
	CharacterDrawUtils.draw_foot_front(self , p_shin_l, foot_w, foot_h, shoe_color)

	var p_thigh_r = CharacterPoseCalculator.rotated_point(p_hip_r.x, p_hip_r.y, d["thigh_l"], f_leg_r_ang)
	var p_shin_r = CharacterPoseCalculator.rotated_point(p_thigh_r.x, p_thigh_r.y, d["shin_l"], f_leg_r_ang + d["knee_r"] * 0.2)
	_draw_pants_leg(p_hip_r, p_thigh_r, p_shin_r, thigh_w, shin_w, skin_color, pants_color, bottoms_type, leg_pants_top_w)
	CharacterDrawUtils.draw_foot_front(self , p_shin_r, foot_w, foot_h, shoe_color)

	# 2. 胴体 (シャツ) — 正面ビュー用座標を使用
	CharacterDrawUtils.draw_torso_part(self , part_shapes["torso_front_lower"], Vector2(d["front_navel_x"], d["front_navel_y"]), Vector2(d["cx"], d["cy"]), body_w, body_w, base_shirt_color)
	CharacterDrawUtils.draw_torso_part(self , part_shapes["torso_front_upper"], Vector2(d["front_sx"], d["front_sy"]), Vector2(d["front_navel_x"], d["front_navel_y"]), body_w, body_w, base_shirt_color)

	# 3. ボトムス（骨盤部分またはスカート）
	if is_skirt:
		var skirt_c = base_shirt_color if bottoms_type == "skirt_sailor" else pants_color
		_draw_skirt(d, bottoms_type, skirt_c, Vector2(d["front_hip_x"], d["front_hip_y"]), body_w, facing)
	elif bottoms_type == "pants":
		var p_pelvis_top = Vector2(d["front_hip_x"], d["front_hip_y"])
		var p_crotch = Vector2(d["cx"], d["cy"])
		var pelvis_top_w = body_w * 1.05
		CharacterDrawUtils.draw_trapezoid(self , p_pelvis_top, p_crotch, pelvis_top_w, pelvis_w, pants_color)

	# 4. 頭 + 髪
	var head_w = (m["headWidth"] if m.has("headWidth") else m["head"] * 0.702) * p
	_draw_hair(Vector2(d["front_hx"], d["front_hy"]), head_r, head_w, hair_style, hair_color, skin_color, facing)

	# 4.5 服装オーバーレイ（カラー・ラペル・リボンなど）
	_draw_tops_detail_front(d, p, m, tops_type, base_shirt_color, body_w, shoulder_w, skin_color)

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

		var look_pitch = player.get("look_pitch")
		if look_pitch == null:
			look_pitch = 0.0

		var eye_off_x = head_w * 0.2
		var eye_y = hy + look_pitch
		draw_circle(Vector2(hx - eye_off_x, eye_y), 2.5, Color("#333333"))
		draw_circle(Vector2(hx + eye_off_x, eye_y), 2.5, Color("#333333"))

		var mouth_y = hy + (d["head_h"] * 0.25) + look_pitch # 目と顎の中間
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

	# 1. 奥の腕（台形袖の描画）
	var arm_len = m["armLength"] * p
	var u_arm = arm_len * 0.5
	var l_arm = arm_len * 0.5

	var p_elb_l = CharacterPoseCalculator.rotated_point(p_arm_shoulder.x, p_arm_shoulder.y, u_arm, d["arm_l_angle"] * PI / 180 + d["waist_angle"] + PI / 2)
	var p_hand_l = CharacterPoseCalculator.rotated_point(p_elb_l.x, p_elb_l.y, l_arm, d["arm_l_angle"] * PI / 180 + d["waist_angle"] + PI / 2 - 0.1)

	var s_arm_l_ang = d["arm_l_angle"] * PI / 180 + d["waist_angle"] + PI / 2 - 0.1
	_draw_sleeve_arm(p_arm_shoulder, p_elb_l, p_hand_l, arm_w, hand_hw, hand_hh, s_arm_l_ang - PI / 2, tops_type, skin_dark, shirt_dark, true)

	# 2. 奥の足
	var pants_thigh_w = thigh_w * 1.3
	var pelvis_bottom_w = max(torso_thickness * 1.08, pants_thigh_w)

	var p_thigh_l = CharacterPoseCalculator.rotated_point(p_crotch.x, p_crotch.y, d["thigh_l"], d["leg_l_angle"] * PI / 180 + PI / 2)
	var p_shin_l = CharacterPoseCalculator.rotated_point(p_thigh_l.x, p_thigh_l.y, d["shin_l"], d["leg_l_angle"] * PI / 180 + PI / 2 + d["knee_l"])
	_draw_pants_leg(p_crotch, p_thigh_l, p_shin_l, thigh_w, shin_w, skin_dark, pants_dark, bottoms_type, pelvis_bottom_w)
	CharacterDrawUtils.draw_foot_side(self , p_shin_l, foot_w, foot_h, shoe_color.darkened(0.15))

	# 3. 胴体（服）: 腰で曲がるように分割
	var p_waist = Vector2(d["navel_x"], d["navel_y"])
	var nipple_ratio_upper = 0.55 # 上部(胸)の下から55%の高さ
	CharacterDrawUtils.draw_side_torso(self , p_shoulder, p_waist, p_crotch, nipple_ratio_upper, torso_thickness, base_shirt_color)

	# 4. 手前の足
	var p_thigh_r = CharacterPoseCalculator.rotated_point(p_crotch.x, p_crotch.y, d["thigh_l"], d["leg_r_angle"] * PI / 180 + PI / 2)
	var p_shin_r = CharacterPoseCalculator.rotated_point(p_thigh_r.x, p_thigh_r.y, d["shin_l"], d["leg_r_angle"] * PI / 180 + PI / 2 + d["knee_r"])
	_draw_pants_leg(p_crotch, p_thigh_r, p_shin_r, thigh_w, shin_w, skin_color, pants_color, bottoms_type, pelvis_bottom_w)
	CharacterDrawUtils.draw_foot_side(self , p_shin_r, foot_w, foot_h, shoe_color)

	# 5. ボトムス（骨盤部分またはスカート — 足の上に重ねる）
	if is_skirt:
		var skirt_c = base_shirt_color if bottoms_type == "skirt_sailor" else pants_color
		_draw_skirt(d, bottoms_type, skirt_c, Vector2(d["hip_x"], d["hip_y"]), torso_thickness, "side")
	elif bottoms_type == "pants":
		var p_pelvis_top = Vector2(d["hip_x"], d["hip_y"])
		var p_crotch_center = Vector2(d["cx"], d["cy"])
		var pelvis_top_w = torso_thickness * 1.05
		CharacterDrawUtils.draw_trapezoid(self , p_pelvis_top, p_crotch_center, pelvis_top_w, pelvis_bottom_w, pants_color)

	# 6. 頭 + 髪
	var head_angle = d["waist_angle"] * 0.6

	var look_angle = player.get("look_head_angle")
	if look_angle != null:
		head_angle += look_angle

	var head_r = d["head_h"] / 2.0
	var hair_style = appearance.get("hair_style", "short")
	var hair_color = Color(appearance.get("hair_color", "#4a3c31"))
	_draw_hair(Vector2(hx, hy), head_r, head_w, hair_style, hair_color, skin_color, "side", head_angle)

	# 6.5 服装オーバーレイ（側面：カラー・ラペル・リボンなど）
	_draw_tops_detail_side(d, p, m, tops_type, base_shirt_color, torso_thickness, head_angle, skin_color)

	var eye_offset = Vector2(head_r * 0.7, 0.0) # 高さオフセットなし（回転に任せる）
	var rot_eye = Vector2(eye_offset.x * cos(head_angle) - eye_offset.y * sin(head_angle), eye_offset.x * sin(head_angle) + eye_offset.y * cos(head_angle))
	draw_circle(Vector2(hx, hy) + rot_eye, 2.5, Color("#333333"))

	var mouth_offset = Vector2(head_r * 0.5, head_r * 0.5)
	var rot_mouth = Vector2(mouth_offset.x * cos(head_angle) - mouth_offset.y * sin(head_angle), mouth_offset.x * sin(head_angle) + mouth_offset.y * cos(head_angle))
	var mouth_center = Vector2(hx, hy) + rot_mouth
	draw_line(mouth_center - Vector2(2, 0), mouth_center + Vector2(5, 2), Color("#c07070"), 2.0)

	# 7. 手前の腕（台形袖の描画）
	var p_elb_r = CharacterPoseCalculator.rotated_point(p_arm_shoulder.x, p_arm_shoulder.y, u_arm, d["arm_r_angle"] * PI / 180 + d["waist_angle"] + PI / 2)
	var p_hand_r = CharacterPoseCalculator.rotated_point(p_elb_r.x, p_elb_r.y, l_arm, d["arm_r_angle"] * PI / 180 + d["waist_angle"] + PI / 2 - 0.1)

	var s_arm_r_ang = d["arm_r_angle"] * PI / 180 + d["waist_angle"] + PI / 2 - 0.1
	_draw_sleeve_arm(p_arm_shoulder, p_elb_r, p_hand_r, arm_w, hand_hw, hand_hh, s_arm_r_ang - PI / 2, tops_type, skin_color, base_shirt_color, true)

# ============================================================
# === 服装オーバーレイ（カラー・ラペル・リボン）描画関数群 ===
# ============================================================

# ---------------------------------------------------------------
# 正面・背面ビューの服装オーバーレイ振り分け
#
# tops_type に応じて専用の描画関数を呼び出す。
# t_shirt / sweater / blouse はオーバーレイなし（袖で表現済み）。
# ---------------------------------------------------------------
func _draw_tops_detail_front(d: Dictionary, p: float, m: Dictionary,
		tops_type: String, tops_color: Color, body_w: float, shoulder_w: float, skin_color: Color = Color.WHITE) -> void:
	var sx = d["front_sx"]
	var sy = d["front_sy"]
	var navel_y = d["front_navel_y"]
	var neck_y = d["front_ny"]
	var half_sh = shoulder_w * 0.5
	var half_body = body_w * 0.5

	match tops_type:
		"sailor":
			_draw_sailor_front(sx, sy, neck_y, navel_y, half_sh, half_body, tops_color, skin_color)
		"blazer":
			_draw_blazer_front(sx, sy, neck_y, navel_y, half_sh, half_body, tops_color, false)
		"blazer_dark":
			_draw_blazer_front(sx, sy, neck_y, navel_y, half_sh, half_body, tops_color, true)
		"blouse_bow":
			_draw_bow_front(sx, sy, neck_y, half_body, tops_color)
		"jumper_skirt":
			_draw_jumper_front(sx, sy, neck_y, navel_y, half_sh, half_body, tops_color)

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
func _draw_sailor_front(sx: float, sy: float, neck_y: float, navel_y: float,
		half_sh: float, half_body: float, sailor_color: Color, skin_color: Color) -> void:
	var v_y = lerp(sy, navel_y, 0.45) # Vの底点Y

	# V字の開口部を肌色で塗りつぶして青線を隠す（肩の高さ sy で止まる単純な三角形）
	var skin_open_pts = PackedVector2Array([
		Vector2(sx - half_body * 0.28, sy), # 左上
		Vector2(sx + half_body * 0.28, sy), # 右上
		Vector2(sx, v_y), # V字の底（下）
	])
	draw_polygon(skin_open_pts, PackedColorArray([skin_color]))

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
	draw_polygon(collar_pts, PackedColorArray([sailor_color]))

	# 内側の胸当て（セーラーカラーと同じ紺色にし、縁を白くする）
	var chest_y = lerp(sy, v_y, 0.3)
	var chest_w = half_body * 0.12
	var inner_pts = PackedVector2Array([
		Vector2(sx - chest_w, chest_y),
		Vector2(sx + chest_w, chest_y),
		Vector2(sx, v_y - 3.0),
	])
	draw_polygon(inner_pts, PackedColorArray([sailor_color]))
	
	# 胸当ての上の縁（V字の横線のようになっている箇所の白輪郭）
	var inner_line_col = Color(0.97, 0.97, 0.97)
	draw_polyline(PackedVector2Array([
		Vector2(sx - chest_w, chest_y),
		Vector2(sx, v_y),
		Vector2(sx + chest_w, chest_y)
	]), inner_line_col, 0.6) # <--- さらに細く
	draw_line(Vector2(sx - chest_w, chest_y), Vector2(sx + chest_w, chest_y), inner_line_col, 0.6) # <--- こちらも

	# セーラーカラーの白いライン（縁取り）※胴体の側面で止める
	var line_col = Color(1, 1, 1, 0.75)
	var lw = 2.2
	var line_y = lerp(sy, v_y, 0.2)
	draw_line(Vector2(sx - half_body * 0.8, line_y), Vector2(sx, v_y), line_col, lw)
	draw_line(Vector2(sx + half_body * 0.8, line_y), Vector2(sx, v_y), line_col, lw)

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
	draw_polygon(scarf_pts, PackedColorArray([sc]))

	# 結び目（スカーフの上部の小さな輪）
	var knot_y = v_y + 4.0
	var knot_pts = PackedVector2Array([
		Vector2(sx - half_body * 0.075, knot_y),
		Vector2(sx + half_body * 0.075, knot_y),
		Vector2(sx + half_body * 0.06, knot_y + 9.0),
		Vector2(sx - half_body * 0.06, knot_y + 9.0),
	])
	draw_polygon(knot_pts, PackedColorArray([sc.lightened(0.12)]))

# ---------------------------------------------------------------
# ブレザーオーバーレイ（正面）
#
# 描画パーツ:
#   1. (is_dark のみ) ジャケット胴体の塗りつぶし（暗色ブレザー用）
#   2. 内側の白シャツ（逆V字形）
#   3. 左ラペル（折り返し襟）
#   4. 右ラペル
#   5. ラペルの縁取りライン
#   6. ボタンライン（中央縦線）
#   7. ボタン（3個）
#   8. リボン/ネクタイ（_draw_bow_front を呼び出し）
#
# 引数:
#   is_dark : true = blazer_dark（暗色ブレザー、赤リボン）
#             false = blazer（明色ブレザー、青リボン）
#
# 【調整用】
#   lapel_inner_y : ラペル内側下端（sy〜navel_y の lerp）
# ---------------------------------------------------------------
func _draw_blazer_front(sx: float, sy: float, neck_y: float, navel_y: float,
		half_sh: float, half_body: float, jacket_color: Color, is_dark: bool) -> void:
	var lapel_inner_y = lerp(sy, navel_y, 0.28) # ラペルの内側下端Y

	# ダークブレザーの場合: ジャケット胴体部分を塗りつぶし
	if is_dark:
		var jacket_body_pts = PackedVector2Array([
			Vector2(sx - half_sh * 1.0, sy),
			Vector2(sx + half_sh * 1.0, sy),
			Vector2(sx + half_sh * 0.85, navel_y + 10.0),
			Vector2(sx - half_sh * 0.85, navel_y + 10.0),
		])
		draw_polygon(jacket_body_pts, PackedColorArray([jacket_color]))

	# 内側の白シャツ（逆V字に見える部分）
	var shirt_inner = Color(0.97, 0.97, 0.97)
	var inner_pts = PackedVector2Array([
		Vector2(sx - half_body * 0.22, sy),
		Vector2(sx + half_body * 0.22, sy),
		Vector2(sx + half_body * 0.07, lapel_inner_y),
		Vector2(sx, lapel_inner_y + 6.0),
		Vector2(sx - half_body * 0.07, lapel_inner_y),
	])
	draw_polygon(inner_pts, PackedColorArray([shirt_inner]))

	# 左ラペル（折り返し襟）
	var left_lapel_pts = PackedVector2Array([
		Vector2(sx - half_sh * 0.75, neck_y + 6.0), # 首付近の端
		Vector2(sx - half_body * 0.22, sy), # 内側上端
		Vector2(sx - half_body * 0.07, lapel_inner_y), # 内側下端
		Vector2(sx - half_sh * 0.58, sy + 22.0), # 外側下端
	])
	draw_polygon(left_lapel_pts, PackedColorArray([jacket_color]))

	# 右ラペル
	var right_lapel_pts = PackedVector2Array([
		Vector2(sx + half_body * 0.22, sy),
		Vector2(sx + half_sh * 0.75, neck_y + 6.0),
		Vector2(sx + half_sh * 0.58, sy + 22.0),
		Vector2(sx + half_body * 0.07, lapel_inner_y),
	])
	draw_polygon(right_lapel_pts, PackedColorArray([jacket_color]))

	# ラペルの縁取りライン（エッジ）
	var edge_col = jacket_color.darkened(0.28)
	draw_line(Vector2(sx - half_sh * 0.75, neck_y + 6.0), Vector2(sx, lapel_inner_y + 6.0), edge_col, 1.5)
	draw_line(Vector2(sx + half_sh * 0.75, neck_y + 6.0), Vector2(sx, lapel_inner_y + 6.0), edge_col, 1.5)

	# ボタンライン（中央縦線）
	draw_line(Vector2(sx, lapel_inner_y + 6.0), Vector2(sx, navel_y + 8.0), edge_col, 1.8)

	# ボタン
	var btn_spacing = (navel_y - lapel_inner_y) / 3.0
	for i in range(3):
		draw_circle(Vector2(sx, lapel_inner_y + 6.0 + btn_spacing * float(i + 1) * 0.7), 2.5, edge_col)

	# リボン/ネクタイ（ラペル底に小さなリボン）
	# 【調整用】blazer_dark=赤リボン、blazer=青リボン
	var bow_col = Color(0.75, 0.18, 0.25) if is_dark else Color(0.25, 0.35, 0.75)
	_draw_bow_front(sx, sy, neck_y, half_body * 0.55, bow_col)

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
#   neck_y    : 首Y
#   half_body : 胴体半幅（リボンのスケール基準）
#   bow_color : リボンの色
#
# 【調整用】
#   bow_y   : リボンの中心Y（neck_y〜sy の lerp 0.65）
#   bow_w   : リボンの横幅（half_body * 0.55）
#   bow_h   : リボンの縦幅（half_body * 0.28）
#   tail_len: 垂れの長さ（bow_h * 2.8）
# ---------------------------------------------------------------
func _draw_bow_front(sx: float, sy: float, neck_y: float, half_body: float, bow_color: Color) -> void:
	var bow_y = lerp(neck_y, sy, 0.65) # 首元〜肩の65%の高さにリボン
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
	draw_polygon(left_wing, PackedColorArray([bow_color]))

	# 右ウィング
	var right_wing = PackedVector2Array([
		Vector2(sx + 3.5, bow_y - bow_h * 0.28),
		Vector2(sx + bow_w * 0.85, bow_y - bow_h),
		Vector2(sx + bow_w, bow_y),
		Vector2(sx + bow_w * 0.85, bow_y + bow_h),
		Vector2(sx + 3.5, bow_y + bow_h * 0.28),
	])
	draw_polygon(right_wing, PackedColorArray([bow_color]))

	# 中央の結び目（円）
	draw_circle(Vector2(sx, bow_y), 4.5, bow_color.darkened(0.22))

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
	draw_polygon(tail_l_pts, PackedColorArray([bow_color]))
	draw_polygon(tail_r_pts, PackedColorArray([bow_color]))

# ---------------------------------------------------------------
# 側面ビューの服装オーバーレイ振り分け
#
# tops_type に応じて専用の描画関数を呼び出す。
# waist_angle を考慮して体の向きに合わせたベクトルを渡す。
# ---------------------------------------------------------------
func _draw_tops_detail_side(d: Dictionary, p: float, m: Dictionary,
		tops_type: String, tops_color: Color, torso_thickness: float, head_angle: float, skin_color: Color = Color.WHITE) -> void:
	var sx = d["sx"]
	var sy = d["sy"]
	var navel_y = d["navel_y"]
	var navel_x = d["navel_x"]
	var nx = d["nx"]
	var ny = d["ny"]
	var hx = d["hx"]
	var hy = d["hy"]
	var waist_angle = d["waist_angle"]

	# 体の前方方向ベクトル（胴体の前面）
	var fwd = Vector2(cos(waist_angle), sin(waist_angle)) # 前方
	var up_v = Vector2(-sin(waist_angle), cos(waist_angle)) # 上方
	var half_t = torso_thickness * 0.5

	match tops_type:
		"sailor":
			_draw_sailor_side(sx, sy, navel_y, navel_x, half_t, fwd, up_v, waist_angle, tops_color, skin_color)
		"blazer":
			_draw_blazer_side(sx, sy, navel_y, navel_x, half_t, fwd, up_v, waist_angle, tops_color, false)
		"blazer_dark":
			_draw_blazer_side(sx, sy, navel_y, navel_x, half_t, fwd, up_v, waist_angle, tops_color, true)
		"blouse_bow":
			_draw_bow_side(nx, ny, hx, hy, half_t, fwd, up_v, waist_angle, tops_color)
		"jumper_skirt":
			_draw_jumper_side(sx, sy, navel_y, half_t, fwd, up_v, waist_angle, tops_color)

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
func _draw_sailor_side(sx: float, sy: float, navel_y: float, navel_x: float,
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
	draw_polygon(skin_pts, PackedColorArray([skin_color]))

	# セーラーカラーの大きな三角形フラップ（背中から肩に）
	var p_sh_back = Vector2(sx, sy) - fwd * half_t * 0.95

	var collar_pts = PackedVector2Array([
		p_sh_back,
		p_nk_front,
		v_bottom,
		Vector2(sx, sy) - fwd * half_t * 0.2,
	])
	draw_polygon(collar_pts, PackedColorArray([sailor_color]))

	# 白い内側ライン ※背中まで伸びないよう短くする
	var line_col = Color(1, 1, 1, 0.72)
	var line_start = p_nk_front - fwd * half_t * 0.8
	draw_line(line_start, v_bottom, line_col, 2.0)

	# スカーフ（Vの底から垂れ下がる）※赤色に変更
	var scarf_end = v_bottom + Vector2(0, (navel_y - sy) * 0.40)
	var sc = Color(0.8, 0.15, 0.15)
	var scarf_pts = PackedVector2Array([
		v_bottom + fwd * 3.0,
		v_bottom - fwd * 3.0,
		scarf_end - fwd * 1.0,
	])
	draw_polygon(scarf_pts, PackedColorArray([sc]))

# ---------------------------------------------------------------
# ブレザーオーバーレイ（側面）
#
# 描画パーツ:
#   1. (is_dark のみ) ジャケット胴体の塗りつぶし
#   2. 白シャツ（前面の細い帯）
#   3. 前面のラペル（折り返し部分の三角形）
#   4. ラペルのエッジライン
#   5. リボン（_draw_bow_side を呼び出し）
#
# 引数:
#   is_dark : true = blazer_dark（暗色ブレザー、赤リボン）
# ---------------------------------------------------------------
func _draw_blazer_side(sx: float, sy: float, navel_y: float, navel_x: float,
		half_t: float, fwd: Vector2, up_v: Vector2,
		waist_angle: float, jacket_color: Color, is_dark: bool) -> void:
	var p_sh = Vector2(sx, sy)
	var p_sh_front = p_sh + fwd * half_t * 0.9
	var p_sh_back = p_sh - fwd * half_t * 0.9
	var p_nk = p_sh + up_v * 10.0
	var p_nk_front = p_nk + fwd * half_t * 0.7
	var lapel_tip = p_sh_front + Vector2(0, (navel_y - sy) * 0.25)

	# ダークブレザー: 胴体前面を上書き
	if is_dark:
		var jacket_cover = PackedVector2Array([
			p_sh_back,
			p_sh_front,
			lapel_tip + fwd * 2.0 + Vector2(0, (navel_y - sy) * 0.65),
			p_sh_back + Vector2(0, (navel_y - sy) * 0.85),
		])
		draw_polygon(jacket_cover, PackedColorArray([jacket_color]))

	# 白シャツ（前面の細い帯）
	var shirt_inner = Color(0.96, 0.96, 0.96)
	var shirt_pts = PackedVector2Array([
		p_nk_front,
		p_nk_front + fwd * 2.0,
		lapel_tip + fwd * 2.0,
		lapel_tip,
	])
	draw_polygon(shirt_pts, PackedColorArray([shirt_inner]))

	# 前面のラペル（折り返し）
	var lapel_pts = PackedVector2Array([
		p_nk_front,
		p_nk_front + up_v * 4.0,
		lapel_tip,
	])
	draw_polygon(lapel_pts, PackedColorArray([jacket_color]))

	# ラペルのエッジライン
	draw_line(p_nk_front + up_v * 4.0, lapel_tip, jacket_color.darkened(0.3), 1.6)

	# リボン
	# 【調整用】blazer_dark=赤リボン、blazer=青リボン
	var bow_col = Color(0.75, 0.18, 0.25) if is_dark else Color(0.25, 0.35, 0.75)
	_draw_bow_side(p_nk.x, p_nk.y, p_sh.x, p_sh.y, half_t, fwd, up_v, waist_angle, bow_col)

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
#   center  : リボンの中心（胴体前面 + 上方向オフセット）
#   bow_w   : ウィングの前方への突き出し量（half_t * 0.6）
#   bow_h   : ウィングの縦幅（half_t * 0.35）
# ---------------------------------------------------------------
func _draw_bow_side(nx: float, ny: float, sx: float, sy: float,
		half_t: float, fwd: Vector2, up_v: Vector2,
		waist_angle: float, bow_color: Color) -> void:
	# 側面では蝶ネクタイが胴体の前面に小さく見える
	var center = Vector2(sx, sy) + fwd * half_t * 0.85 + up_v * 8.0
	var bow_w = half_t * 0.6
	var bow_h = half_t * 0.35

	# 側面から見た片方のウィングのみ（前方に突出）
	var wing_pts = PackedVector2Array([
		center - up_v * bow_h,
		center + fwd * bow_w,
		center + up_v * bow_h,
		center,
	])
	draw_polygon(wing_pts, PackedColorArray([bow_color]))

	# リボンの垂れ
	var tail_end = center + Vector2(0, bow_h * 3.0)
	draw_line(center, tail_end, bow_color, 3.0)

# ============================================================
# ジャンパースカート（小学校制服）描画関数
# ============================================================

# ---------------------------------------------------------------
# ジャンパースカート 正面オーバーレイ
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
func _draw_jumper_front(sx: float, sy: float, neck_y: float, navel_y: float,
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
	draw_polygon(left_pts, PackedColorArray([jumper_color]))

	# 右ストラップ
	var right_pts = PackedVector2Array([
		Vector2(sx + strap_inner, strap_top_y),
		Vector2(sx + strap_outer, strap_top_y),
		Vector2(sx + strap_outer, strap_bot_y),
		Vector2(sx + strap_inner, strap_bot_y),
	])
	draw_polygon(right_pts, PackedColorArray([jumper_color]))

	# ストラップ内側繁（陷影感）
	var edge_dark = jumper_color.darkened(0.28)
	draw_line(Vector2(sx - strap_inner, strap_top_y), Vector2(sx - strap_inner, strap_bot_y), edge_dark, 1.6)
	draw_line(Vector2(sx + strap_inner, strap_top_y), Vector2(sx + strap_inner, strap_bot_y), edge_dark, 1.6)

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
	draw_polygon(lc, PackedColorArray([collar_white]))
	# 右襟フラップ
	var rc = PackedVector2Array([
		Vector2(sx + half_body * 0.22, neck_y + 2.0),
		Vector2(sx + half_body * 0.04, sy + 4.0),
		Vector2(sx - half_body * 0.06, neck_y + 4.0),
		Vector2(sx + half_body * 0.08, neck_y + 2.0),
	])
	draw_polygon(rc, PackedColorArray([collar_white]))
	# 襟の縁取りライン
	draw_line(Vector2(sx - half_body * 0.22, neck_y + 2.0), Vector2(sx, sy + 4.0), collar_shadow, 1.2)
	draw_line(Vector2(sx + half_body * 0.22, neck_y + 2.0), Vector2(sx, sy + 4.0), collar_shadow, 1.2)

# ---------------------------------------------------------------
# ジャンパースカート 側面オーバーレイ
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
func _draw_jumper_side(sx: float, sy: float, navel_y: float,
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
	draw_polygon(front_band, PackedColorArray([jumper_color]))

	# 背面ストラップ（胴体背面側の帯）
	var back_band = PackedVector2Array([
		p_sh_back,
		p_sh_back + fwd * fw,
		p_sh_back + fwd * fw + strap_len,
		p_sh_back + strap_len,
	])
	draw_polygon(back_band, PackedColorArray([jumper_color]))

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
	draw_polygon(collar_pts, PackedColorArray([collar_white]))
