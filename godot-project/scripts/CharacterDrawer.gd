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
	var d = CharacterPoseCalculator.calculate_pose_data(player, m, p)

	# === 描画実行 ===
	var flip = (dir == -1 and facing == "side")

	# 見た目データの取得
	var appearance = Global.current_appearance

	var skin_color = Color("#ffe4c4")
	var base_shirt_color = Color(appearance.get("tops_color", "#ab82a8"))
	var pants_color = Color(appearance.get("bottoms_color", "#e5d6ba"))

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

# 袖付き腕を描画するヘルパー
# 台形の袖を腕の上に重ねて描画し、袖がない部分は通常のlimbで描画する
func _draw_sleeve_arm(p_shoulder: Vector2, p_elbow: Vector2, p_hand: Vector2,
		arm_w: float, hand_hw: float, hand_hh: float, hand_angle: float,
		tops_type: String, skin: Color, shirt: Color) -> void:
	var sleeve_top_w = arm_w * 1.4 # 袖の肩側の太さ
	var sleeve_bot_w = arm_w * 1.15 # 袖口の太さ

	if tops_type == "sweater" or tops_type == "blouse":
		# 長袖: 肩→肘 台形、肘→手首 台形（やや細め）
		CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_shoulder, p_elbow, arm_w, skin)
		CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_elbow, p_hand, arm_w * 0.8, skin)
		CharacterDrawUtils.draw_trapezoid(self , p_shoulder, p_elbow, sleeve_top_w, sleeve_bot_w, shirt)
		CharacterDrawUtils.draw_trapezoid(self , p_elbow, p_hand, sleeve_bot_w, arm_w * 1.0, shirt)
	elif tops_type == "t_shirt":
		# 半袖: 肩→上腕60%地点まで台形袖、残りは肌色limb
		var sleeve_end = p_shoulder.lerp(p_elbow, 0.6)
		CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_shoulder, p_elbow, arm_w, skin)
		CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_elbow, p_hand, arm_w * 0.8, skin)
		CharacterDrawUtils.draw_trapezoid(self , p_shoulder, sleeve_end, sleeve_top_w, sleeve_bot_w, shirt)
	else:
		# ノースリーブ等: 通常の腕描画のみ
		CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_shoulder, p_elbow, arm_w, skin)
		CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_elbow, p_hand, arm_w * 0.8, skin)

	CharacterDrawUtils.draw_hand(self , p_hand, hand_hw, hand_hh, skin, hand_angle)

# 髪型描画ヘルパー
# 後髪 → 頭（肌色） → 前髪 の順で描画する
func _draw_hair(head_center: Vector2, head_r: float, head_w: float,
		hair_style: String, hair_color: Color, skin_color: Color,
		facing: String, head_angle: float = 0.0) -> void:
	var hr = head_r # 頭の半径

	if facing == "front":
		# 【調整用】髪の横幅。大きいほど頭が横に膨らむ（側面1.05、背面1.08に合わせた値）
		var hair_outer_w = hr * 1.12
		# 【調整用】ドーム（頭頂部の丸み）の高さ。大きいほど頭が縦に膨らむ
		var hair_top_h = hr * 1.08

		# 【調整用】髪の下端位置（ショート/ロング）。値を大きくすると髪が長くなる
		var hair_bottom_y = head_center.y + hr * 1.3 # 短い場合
		if hair_style == "long":
			hair_bottom_y = head_center.y + hr * 3.5 # ロングの場合

		# 1. 後ろ髪（顔の背面に描画）
		# 【調整用】ドーム中心のYオフセット。マイナスで上にずれる
		var dome_offset_y = - hr * 0.1
		CharacterDrawUtils.draw_ellipse(self , head_center + Vector2(0, dome_offset_y), hair_outer_w, hair_top_h, hair_color)
		# そこから下へ落ちるベース
		var back_pts = PackedVector2Array([
			Vector2(head_center.x - hair_outer_w, head_center.y),
			Vector2(head_center.x + hair_outer_w, head_center.y),
			Vector2(head_center.x + hair_outer_w * 1.0, hair_bottom_y),
			Vector2(head_center.x - hair_outer_w * 1.0, hair_bottom_y)
		])
		draw_polygon(back_pts, PackedColorArray([hair_color]))

		# 2. 顔（肌色の円）
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

		# 4. 前髪（額にかかるポリゴン）
		_draw_bangs_front(head_center, hr, head_w, hair_style, hair_color)

	elif facing == "back":
		# 背面: 髪全体が見える
		CharacterDrawUtils.draw_ellipse(self , head_center, hr * 1.08, hr * 1.08, hair_color)
		if hair_style == "long":
			# ロングヘア: 肩まで垂れる
			var hair_bottom = head_center + Vector2(0, hr * 2.0)
			CharacterDrawUtils.draw_trapezoid(self , head_center + Vector2(0, hr * 0.3), hair_bottom, head_w * 0.9, head_w * 0.6, hair_color)

	else: # side
		var down_dir = Vector2(0, 1).rotated(head_angle)
		var back_dir = Vector2(-1, 0).rotated(head_angle)
		var fwd_dir = Vector2(1, 0).rotated(head_angle)
		var up_dir = Vector2(0, -1).rotated(head_angle)
		
		# 後ろ髪の長さ決定
		var hair_bottom_len = hr * 1.3 # ショートヘアのデフォルト
		if hair_style == "long":
			hair_bottom_len = hr * 3.5

		# 1. 顔（肌色の円を先に描画する）
		CharacterDrawUtils.draw_ellipse(self , head_center, hr, hr, skin_color, head_angle)
		
		# 2. 横髪〜後ろ髪（顔の側面〜後頭部を覆う）
		# 【調整用】髪の後頭部のボリューム（1.2などで膨らむ、0.9などで平らに）
		var R = hr * 1.05
		var hair_pts = PackedVector2Array()
		# 【調整用】顔にかかる縦のライン（横髪が来る位置）
		# 数値を 0.0 や +hr*0.1 などに増やすと、髪が後ろに下がって顔が広く見え、目への干渉が減ります。
		# -hr*0.2 などマイナスを強めると、髪が前進して顔が隠れます。
		var cut_dist = - hr * 0.1 # マイナス＝中心より前
		
		# (A) 下部・顔側の頂点
		var p_face_bottom = head_center + back_dir * cut_dist + down_dir * hair_bottom_len
		hair_pts.append(p_face_bottom)
		
		# (B) 頭頂部〜後頭部の丸み
		var steps = 15
		# cut_dist がマイナスなので、起点の角度はマイナス（前寄り）になるように asin の中身を変える
		var min_ang = asin(cut_dist / R)
		var max_ang = PI / 2.0
		for i in range(steps + 1):
			var t = float(i) / steps
			var ang = lerp(min_ang, max_ang, t)
			var l_back = R * sin(ang)
			var l_up = R * cos(ang)
			hair_pts.append(head_center + back_dir * l_back + up_dir * l_up)
			
		# (C) 下部・後ろ側の頂点
		var p_back_bottom = head_center + back_dir * R + down_dir * hair_bottom_len
		hair_pts.append(p_back_bottom)
		
		draw_polygon(hair_pts, PackedColorArray([hair_color]))
		
		# 3. 中間髪（前髪と後ろ髪の間の扇形オブジェクト）
		# 頭の後ろから前（生え際）へと繋がる自然な丸みを作ります。
		var fan_pts = PackedVector2Array()
		# 【調整用】扇形の中心点。ここから放射状にポリゴンが作られます。
		var fan_center = head_center + back_dir * cut_dist + up_dir * hr * 0.2
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
			fan_pts.append(head_center + back_dir * l_back + up_dir * l_up)
			
		draw_polygon(fan_pts, PackedColorArray([hair_color]))

		# 4. 前髪
		# 額を覆うように、前方に突き出し、顔の前面をカバーする四角形
		# 【調整用】各頂点の座標を変えることで、前髪のシルエットを作れます。目の位置に合わせて微調整してください。
		var p1 = head_center + back_dir * (R * sin(fan_end_ang)) + up_dir * (R * cos(fan_end_ang))
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


# 正面の前髪
func _draw_bangs_front(head_center: Vector2, hr: float, head_w: float, hair_style: String, hair_color: Color) -> void:
	# 【調整用】前髪の下端。大きくすると前髪が目に近づく（マイナス値=頭中心より上）
	var bangs_bottom_y = head_center.y - hr * 0.2
	# 【調整用】前髪の横幅（半幅）。大きいほど前髪が広がる
	var half_w = head_w * 0.55
	# ドーム上端に合わせて前髪の上端を設定（隙間を防ぐ）
	var dome_top_y = head_center.y - hr * 0.1 - hr * 1.08
	# 【調整用】ドーム上端からのオフセット。小さいほど前髪がドームに密着する
	var top_y = dome_top_y + hr * 0.15

	# 向かって左側を少し長くし、右側に分け目を入れる形状
	var pts = PackedVector2Array([
		Vector2(head_center.x - half_w, top_y), # 左上
		Vector2(head_center.x + half_w, top_y), # 右上
		# 【調整用】右下端。0.8を変えると右端の角度が変わる
		Vector2(head_center.x + half_w * 0.8, bangs_bottom_y),
		# 【調整用】分け目の切れ込み。0.3=横位置、0.15=切れ込みの深さ
		Vector2(head_center.x + half_w * 0.3, bangs_bottom_y - hr * 0.15),
		# 【調整用】前髪中央付近。-0.2を変えると中央の位置が左右にずれる
		Vector2(head_center.x - half_w * 0.2, bangs_bottom_y),
		# 【調整用】左サイドバング。0.8=横位置、0.6=下への伸び（大きいほど長い）
		Vector2(head_center.x - half_w * 0.8, bangs_bottom_y + hr * 0.6),
	])
	draw_polygon(pts, PackedColorArray([hair_color]))

# 側面の前髪
func _draw_bangs_side(head_center: Vector2, hr: float, hair_style: String, hair_color: Color, head_angle: float) -> void:
	var forward = Vector2(1, 0).rotated(head_angle)
	var up = Vector2(0, -1).rotated(head_angle)

	# 前髪: 頭頂部から前方に突き出す三角形
	var p1 = head_center + up * hr * 0.9 + forward * hr * 0.1 # 頭頂やや前
	var p2 = head_center + up * hr * 0.3 + forward * hr * 0.95 # 前方に突き出す先端
	var p3 = head_center + up * hr * 0.1 + forward * hr * 0.3 # 額の下端

	var pts = PackedVector2Array([p1, p2, p3])
	draw_polygon(pts, PackedColorArray([hair_color]))

# スカート描画ヘルパー
func _draw_skirt(d: Dictionary, bottoms_type: String, bottoms_color: Color, waist_pos: Vector2, base_width: float) -> void:
	var waist_to_crotch = d["cy"] - waist_pos.y
	var skirt_length: float
	var hem_w: float

	if bottoms_type == "skirt_long":
		skirt_length = waist_to_crotch + d["thigh_l"] + d["shin_l"] * 0.3
		hem_w = base_width * 1.3
	else: # "skirt" or "skirt_short"
		skirt_length = waist_to_crotch + d["thigh_l"] * 0.4
		hem_w = base_width * 1.5

	var p_bottom = Vector2(waist_pos.x, waist_pos.y + skirt_length)
	CharacterDrawUtils.draw_trapezoid(self , waist_pos, p_bottom, base_width, hem_w, bottoms_color)

# --- 正面・背面 描画 ---
func _draw_front_back(m, p, d, appearance, skin_color, base_shirt_color, pants_color, skin_dark, shirt_dark, _pants_dark, shoulder_w, thigh_w, shin_w, arm_w, neck_w):
	var facing = player.facing
	var body_w = shoulder_w * 0.6
	var body_w_half = body_w / 2.0
	var sh_off = shoulder_w * 0.5 - arm_w * 0.5
	var hp_off = body_w_half * 0.6

	var p_hip_l = Vector2(d["cx"] - hp_off, d["cy"])
	var p_hip_r = Vector2(d["cx"] + hp_off, d["cy"])

	# === 正面用の微調整（ここを書き換えて動作確認します） ===
	var front_offset_x = 0.0 # プラスにすると腕が外側に広がる、マイナスで内側
	var front_offset_y = 10.0 # プラスにすると腕が下に下がる、マイナスで上に上がる
	# Note: 腕の太さ分だけ下に下げたかった

	var p_sh_l = Vector2(d["front_sx"] - sh_off + front_offset_x, d["front_sy"] + front_offset_y)
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

	# 服装タイプの判定
	var bottoms_type = appearance.get("bottoms_type", "pants")
	var tops_type = appearance.get("tops_type", "t_shirt")
	var is_skirt = bottoms_type.begins_with("skirt")
	var thigh_color = skin_color if is_skirt else pants_color

	# 1. 両足
	var p_thigh_l = CharacterPoseCalculator.rotated_point(p_hip_l.x, p_hip_l.y, d["thigh_l"], f_leg_l_ang)
	var p_shin_l = CharacterPoseCalculator.rotated_point(p_thigh_l.x, p_thigh_l.y, d["shin_l"], f_leg_l_ang + d["knee_l"] * 0.2)
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_hip_l, p_thigh_l, thigh_w, thigh_color)
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_thigh_l, p_shin_l, shin_w, skin_color)
	CharacterDrawUtils.draw_foot_front(self , p_shin_l, foot_w, foot_h, shoe_color)

	var p_thigh_r = CharacterPoseCalculator.rotated_point(p_hip_r.x, p_hip_r.y, d["thigh_l"], f_leg_r_ang)
	var p_shin_r = CharacterPoseCalculator.rotated_point(p_thigh_r.x, p_thigh_r.y, d["shin_l"], f_leg_r_ang + d["knee_r"] * 0.2)
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_hip_r, p_thigh_r, thigh_w, thigh_color)
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_thigh_r, p_shin_r, shin_w, skin_color)
	CharacterDrawUtils.draw_foot_front(self , p_shin_r, foot_w, foot_h, shoe_color)

	# 2. 胴体 (シャツ) — 正面ビュー用座標を使用
	CharacterDrawUtils.draw_torso_part(self , part_shapes["torso_front_lower"], Vector2(d["front_wx"], d["front_wy"]), Vector2(d["cx"], d["cy"]), body_w, body_w, base_shirt_color)
	CharacterDrawUtils.draw_torso_part(self , part_shapes["torso_front_upper"], Vector2(d["front_sx"], d["front_sy"]), Vector2(d["front_wx"], d["front_wy"]), body_w, body_w, base_shirt_color)

	# 3. スカート（該当する場合）
	if is_skirt:
		_draw_skirt(d, bottoms_type, pants_color, Vector2(d["front_wx"], d["front_wy"]), body_w)

	# 4. 頭 + 髪
	var head_w = (m["headWidth"] if m.has("headWidth") else m["head"] * 0.702) * p
	var head_r = d["head_h"] / 2.0
	var hair_style = appearance.get("hair_style", "short")
	var hair_color = Color(appearance.get("hair_color", "#4a3c31"))
	_draw_hair(Vector2(d["front_hx"], d["front_hy"]), head_r, head_w, hair_style, hair_color, skin_color, facing)

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

		var eye_off_x = head_w * 0.2
		var eye_y = hy # 真ん中（高さオフセットなし）
		draw_circle(Vector2(hx - eye_off_x, eye_y), 2.5, Color("#333333"))
		draw_circle(Vector2(hx + eye_off_x, eye_y), 2.5, Color("#333333"))

		var mouth_y = hy + (d["head_h"] * 0.25) # 目と顎の中間
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
	var back_thigh_color = skin_dark if is_skirt else pants_dark
	var front_thigh_color = skin_color if is_skirt else pants_color

	# 1. 奥の腕（台形袖の描画）
	var arm_len = m["armLength"] * p
	var u_arm = arm_len * 0.5
	var l_arm = arm_len * 0.5

	var p_elb_l = CharacterPoseCalculator.rotated_point(p_arm_shoulder.x, p_arm_shoulder.y, u_arm, d["arm_l_angle"] * PI / 180 + d["waist_angle"] + PI / 2)
	var p_hand_l = CharacterPoseCalculator.rotated_point(p_elb_l.x, p_elb_l.y, l_arm, d["arm_l_angle"] * PI / 180 + d["waist_angle"] + PI / 2 - 0.1)

	var s_arm_l_ang = d["arm_l_angle"] * PI / 180 + d["waist_angle"] + PI / 2 - 0.1
	_draw_sleeve_arm(p_arm_shoulder, p_elb_l, p_hand_l, arm_w, hand_hw, hand_hh, s_arm_l_ang - PI / 2, tops_type, skin_dark, shirt_dark)

	# 2. 奥の足
	var p_thigh_l = CharacterPoseCalculator.rotated_point(p_crotch.x, p_crotch.y, d["thigh_l"], d["leg_l_angle"] * PI / 180 + PI / 2)
	var p_shin_l = CharacterPoseCalculator.rotated_point(p_thigh_l.x, p_thigh_l.y, d["shin_l"], d["leg_l_angle"] * PI / 180 + PI / 2 + d["knee_l"])
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_crotch, p_thigh_l, thigh_w, back_thigh_color)
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_thigh_l, p_shin_l, shin_w, skin_dark)
	CharacterDrawUtils.draw_foot_side(self , p_shin_l, foot_w, foot_h, shoe_color.darkened(0.15))

	# 3. 胴体（服）: 腰で曲がるように分割
	var p_waist = Vector2(d["wx"], d["wy"])
	var nipple_ratio_upper = 0.55 # 上部(胸)の下から55%の高さ
	CharacterDrawUtils.draw_side_torso(self , p_shoulder, p_waist, p_crotch, nipple_ratio_upper, torso_thickness, base_shirt_color)

	# 4. 手前の足
	var p_thigh_r = CharacterPoseCalculator.rotated_point(p_crotch.x, p_crotch.y, d["thigh_l"], d["leg_r_angle"] * PI / 180 + PI / 2)
	var p_shin_r = CharacterPoseCalculator.rotated_point(p_thigh_r.x, p_thigh_r.y, d["shin_l"], d["leg_r_angle"] * PI / 180 + PI / 2 + d["knee_r"])
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_crotch, p_thigh_r, thigh_w, front_thigh_color)
	CharacterDrawUtils.draw_limb_part(self , part_shapes["limb"], p_thigh_r, p_shin_r, shin_w, skin_color)
	CharacterDrawUtils.draw_foot_side(self , p_shin_r, foot_w, foot_h, shoe_color)

	# 5. スカート（該当する場合 — 手前の足の上に重ねる）
	if is_skirt:
		_draw_skirt(d, bottoms_type, pants_color, Vector2(d["wx"], d["wy"]), torso_thickness)

	# 6. 頭 + 髪
	var head_angle = d["waist_angle"] * 0.6
	var head_r = d["head_h"] / 2.0
	var hair_style = appearance.get("hair_style", "short")
	var hair_color = Color(appearance.get("hair_color", "#4a3c31"))
	_draw_hair(Vector2(hx, hy), head_r, head_w, hair_style, hair_color, skin_color, "side", head_angle)

	var eye_offset = Vector2(head_r * 0.5, 0.0) # 高さオフセットなし
	var rot_eye = Vector2(eye_offset.x * cos(head_angle) - eye_offset.y * sin(head_angle), eye_offset.x * sin(head_angle) + eye_offset.y * cos(head_angle))
	draw_circle(Vector2(hx, hy) + rot_eye, 2.5, Color("#333333"))

	var mouth_offset = Vector2(head_r * 0.5, head_r * 0.5)
	var rot_mouth = Vector2(mouth_offset.x * cos(head_angle) - mouth_offset.y * sin(head_angle), mouth_offset.x * sin(head_angle) + mouth_offset.y * cos(head_angle))
	var mouth_center = Vector2(hx, hy) + rot_mouth
	draw_line(mouth_center - Vector2(3, 0), mouth_center + Vector2(3, 0), Color("#c07070"), 2.0)

	# 7. 手前の腕（台形袖の描画）
	var p_elb_r = CharacterPoseCalculator.rotated_point(p_arm_shoulder.x, p_arm_shoulder.y, u_arm, d["arm_r_angle"] * PI / 180 + d["waist_angle"] + PI / 2)
	var p_hand_r = CharacterPoseCalculator.rotated_point(p_elb_r.x, p_elb_r.y, l_arm, d["arm_r_angle"] * PI / 180 + d["waist_angle"] + PI / 2 - 0.1)

	var s_arm_r_ang = d["arm_r_angle"] * PI / 180 + d["waist_angle"] + PI / 2 - 0.1
	_draw_sleeve_arm(p_arm_shoulder, p_elb_r, p_hand_r, arm_w, hand_hw, hand_hh, s_arm_r_ang - PI / 2, tops_type, skin_color, base_shirt_color)
