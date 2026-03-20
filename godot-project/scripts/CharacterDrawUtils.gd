class_name CharacterDrawUtils
extends RefCounted

# CanvasItem への図形描画をまとめるユーティリティクラス

static func draw_ellipse(canvas: CanvasItem, center: Vector2, rx: float, ry: float, color: Color, angle: float = 0.0):
	var points = PackedVector2Array()
	var segs = 32
	for i in range(segs):
		var ang = PI * 2.0 * i / float(segs)
		var px = cos(ang) * rx
		var py = sin(ang) * ry
		var rotated_px = center.x + px * cos(angle) - py * sin(angle)
		var rotated_py = center.y + px * sin(angle) + py * cos(angle)
		points.append(Vector2(rotated_px, rotated_py))
	canvas.draw_polygon(points, PackedColorArray([color]))

static func draw_limb(canvas: CanvasItem, p1: Vector2, p2: Vector2, width: float, color: Color):
	var d = p2 - p1
	var length = d.length()
	if length <= 0.01:
		return
	var n = Vector2(-d.y, d.x).normalized() * (width / 2.0)
	var pts = PackedVector2Array([
		p1 - n, p1 + n, p2 + n, p2 - n
	])
	canvas.draw_polygon(pts, PackedColorArray([color]))
	canvas.draw_circle(p1, width / 2.0, color)
	canvas.draw_circle(p2, width / 2.0, color)

static func draw_trapezoid(canvas: CanvasItem, p_top: Vector2, p_bottom: Vector2, top_width: float, bottom_width: float, color: Color, outline_color: Color = Color.TRANSPARENT):
	var d = p_bottom - p_top
	var length = d.length()
	if length <= 0.01:
		return
	var n = Vector2(-d.y, d.x).normalized()
	var nt = n * (top_width / 2.0)
	var nb = n * (bottom_width / 2.0)
	
	var pts = PackedVector2Array([
		p_top - nt, p_top + nt, p_bottom + nb, p_bottom - nb
	])
	canvas.draw_polygon(pts, PackedColorArray([color]))
	
	if outline_color != Color.TRANSPARENT:
		var outline_pts = PackedVector2Array([
			p_top - nt, p_top + nt, p_bottom + nb, p_bottom - nb, p_top - nt
		])
		canvas.draw_polyline(outline_pts, outline_color, 1.5)

static func draw_rect(canvas: CanvasItem, p_top: Vector2, p_bottom: Vector2, width: float, color: Color):
	var d = p_bottom - p_top
	var length = d.length()
	if length <= 0.01:
		return
	var n = Vector2(-d.y, d.x).normalized() * (width / 2.0)
	var pts = PackedVector2Array([
		p_top - n, p_top + n, p_bottom + n, p_bottom - n
	])
	canvas.draw_polygon(pts, PackedColorArray([color]))

static func draw_pentagon_lower_torso(canvas: CanvasItem, p_top: Vector2, p_bottom: Vector2, width: float, color: Color):
	# 五角形（下部に三角形が突き出た形）: 正面・背面の下部胴体用
	var d = p_bottom - p_top
	if d.length() <= 0.01:
		return
	var n = Vector2(-d.y, d.x).normalized() * (width / 2.0)
	# 上端から50%の位置にサイドコーナーを置き、残り50%が三角形
	var side_pt = p_top + d * 0.5
	var pts = PackedVector2Array([
		p_top - n,
		p_top + n,
		side_pt + n,
		p_bottom,
		side_pt - n,
	])
	canvas.draw_polygon(pts, PackedColorArray([color]))

static func draw_hand(canvas: CanvasItem, pos: Vector2, hw: float, hh: float, color: Color, angle: float = 0.0):
	# 手（長方形）: hw=半幅, hh=半高さ
	# 【design task 3】親指を追加する場合：
	# draw_hand_with_thumb() という新規関数を作成
	# または既存の draw_hand() 内に親指描画ロジックを追加
	# 親指は小さな三角形として描画（angle 考慮）
	var pts = PackedVector2Array()
	var corners = [
		Vector2(-hw, 0), Vector2(hw, 0),
		Vector2(hw, hh * 2.0), Vector2(-hw, hh * 2.0)
	]
	for c in corners:
		var rx = c.x * cos(angle) - c.y * sin(angle)
		var ry = c.x * sin(angle) + c.y * cos(angle)
		pts.append(pos + Vector2(rx, ry))
	canvas.draw_polygon(pts, PackedColorArray([color]))

static func draw_hand_with_thumb(canvas: CanvasItem, pos: Vector2, hw: float, hh: float, color: Color, angle: float = 0.0, thumb_side: int = 1):
	# 手を親指付きで描画（手本体と親指を独立したポリゴンで描画）
	# hw=半幅, hh=半高さ, thumb_side: 1=右親指, -1=左親指

	# 親指の頂点（ローカル座標）
	var thumb_tip_offset = Vector2(thumb_side * hw * 1.9, hh * 1.0)
	var thumb_corner_offset = Vector2(thumb_side * hw * 0.8, hh * 0.8)

	# ===== 手本体（四角形）=====
	var hand_corners = [
		Vector2(-hw, 0),              # 左上
		Vector2(hw, 0),               # 右上
		Vector2(hw, hh * 2.0),        # 右下
		Vector2(-hw, hh * 2.0)        # 左下
	]

	var hand_pts = PackedVector2Array()
	for c in hand_corners:
		var rx = c.x * cos(angle) - c.y * sin(angle)
		var ry = c.x * sin(angle) + c.y * cos(angle)
		hand_pts.append(pos + Vector2(rx, ry))

	# 手本体の頂点順序をチェック
	if hand_pts.size() >= 3:
		var v1 = hand_pts[1] - hand_pts[0]
		var v2 = hand_pts[2] - hand_pts[1]
		var cross = v1.x * v2.y - v1.y * v2.x
		if cross < 0:
			hand_pts.reverse()

	canvas.draw_polygon(hand_pts, PackedColorArray([color]))

	# ===== 親指（三角形、反転させない）=====
	# 親指は常に同じ側に表示される必要があるため、頂点順序は反転させない
	var thumb_corners: Array
	if thumb_side > 0:  # 右親指
		thumb_corners = [
			Vector2(hw, 0),               # 手の上辺（右側接点）
			thumb_tip_offset,             # 親指の先端
			thumb_corner_offset           # 親指の角
		]
	else:  # 左親指
		thumb_corners = [
			Vector2(-hw, 0),              # 手の上辺（左側接点）
			thumb_corner_offset,          # 親指の角
			thumb_tip_offset              # 親指の先端
		]

	var thumb_pts = PackedVector2Array()
	for c in thumb_corners:
		var rx = c.x * cos(angle) - c.y * sin(angle)
		var ry = c.x * sin(angle) + c.y * cos(angle)
		thumb_pts.append(pos + Vector2(rx, ry))

	# 親指は頂点順序を反転させない（常に同じ側に表示）
	canvas.draw_polygon(thumb_pts, PackedColorArray([color]))

static func draw_foot_front(canvas: CanvasItem, ankle: Vector2, foot_w: float, foot_h: float, color: Color):
	# 正面: 台形（上端=脚の太さ、底辺が少し広い）
	# 【design task 4】つま先の色を変える場合：
	# この関数を2つのポリゴンに分割
	# - 足本体（かかと～甲）: color で描画
	# - つま先: toe_color で描画
	var top_w = foot_w
	var bot_w = foot_w * 1.15
	var pts = PackedVector2Array([
		ankle + Vector2(-top_w * 0.5, 0.0),
		ankle + Vector2(top_w * 0.5, 0.0),
		ankle + Vector2(bot_w * 0.5, foot_h),
		ankle + Vector2(-bot_w * 0.5, foot_h),
	])
	canvas.draw_polygon(pts, PackedColorArray([color]))

static func draw_foot_side(canvas: CanvasItem, ankle: Vector2, foot_w: float, foot_h: float, color: Color):
	# 側面: 靴シルエット（6頂点、つま先に短い縦面を持たせて丸みを表現）
	# 【design task 4】つま先の色を変える場合：
	# 点3・4（ankle + Vector2(foot_w, foot_h * 0.4) ～ 0.85）のつま先部分
	# を別色で描き分ける
	var pts = PackedVector2Array([
		ankle,                                  # 1. 踵上
		ankle + Vector2(foot_w * 0.3, 0.0),    # 2. 甲上端（短い上辺）
		ankle + Vector2(foot_w, foot_h * 0.4), # 3. つま先上端
		ankle + Vector2(foot_w, foot_h * 0.85),# 4. つま先下端（前面を短い縦辺に）
		ankle + Vector2(foot_w * 0.8, foot_h), # 5. 靴底前端（少し手前）
		ankle + Vector2(0.0, foot_h),           # 6. 踵下端
	])
	canvas.draw_polygon(pts, PackedColorArray([color]))

static func draw_side_torso(canvas: CanvasItem, p_top: Vector2, p_mid: Vector2, p_bottom: Vector2, nipple_ratio_upper: float, thickness: float, color: Color):
	# 側面胴体: 背骨(p_bottom -> p_mid -> p_top)の角度に追従する7角形
	var d_upper = p_top - p_mid
	var d_lower = p_mid - p_bottom
	if d_upper.length() <= 0.01 or d_lower.length() <= 0.01:
		return
		
	var u_up = d_upper.normalized()
	var u_low = d_lower.normalized()
	
	var n_back_up = Vector2(u_up.y, -u_up.x)
	var n_front_up = Vector2(-u_up.y, u_up.x)
	
	var n_back_low = Vector2(u_low.y, -u_low.x)
	var n_front_low = Vector2(-u_low.y, u_low.x)
	
	var n_back_mid = (n_back_up + n_back_low).normalized()
	var n_front_mid = (n_front_up + n_front_low).normalized()
	
	var half = thickness / 2.0
	var p_nipple = p_mid + d_upper * nipple_ratio_upper
	
	var pts = PackedVector2Array([
		p_top + n_back_up * half, # 1. 肩後端
		p_mid + n_back_mid * half, # 2. 腰後端
		p_bottom + n_back_low * half, # 3. 股後端
		p_bottom + n_front_low * half, # 4. 股前端
		p_mid + n_front_mid * half, # 5. 腰前端
		p_nipple + n_front_up * half, # 6. 乳首前端（折れ点）
		p_top + n_front_up * (half * 0.2), # 7. 肩前端（斜めにカット）
	])
	canvas.draw_polygon(pts, PackedColorArray([color]))

# ユーザー指定の形状（shape）に応じて描画を切り替えるヘルパー
# torsoは p_top, p_bottom, width を受け取る汎用インタフェース
static func draw_torso_part(canvas: CanvasItem, shape: String, p_top: Vector2, p_bottom: Vector2, top_w: float, bottom_w: float, color: Color):
	if shape == "rect":
		draw_rect(canvas, p_top, p_bottom, (top_w + bottom_w) / 2.0, color)
	elif shape == "trapezoid":
		draw_trapezoid(canvas, p_top, p_bottom, top_w, bottom_w, color)
	elif shape == "pentagon":
		draw_pentagon_lower_torso(canvas, p_top, p_bottom, (top_w + bottom_w) / 2.0, color)
	elif shape == "ellipse":
		draw_limb(canvas, p_top, p_bottom, (top_w + bottom_w) / 2.0, color)
	else:
		draw_trapezoid(canvas, p_top, p_bottom, top_w, bottom_w, color)

static func draw_limb_part(canvas: CanvasItem, shape: String, p_top: Vector2, p_bottom: Vector2, width: float, color: Color):
	if shape == "rect":
		draw_rect(canvas, p_top, p_bottom, width, color)
	elif shape == "line":
		canvas.draw_line(p_top, p_bottom, color, width)
	elif shape == "stick":
		# 太い線（ジョイントボールなし）
		draw_rect(canvas, p_top, p_bottom, width, color)
	else:
		# デフォルトは丸みを帯びた limb
		draw_limb(canvas, p_top, p_bottom, width, color)

static func draw_head_part(canvas: CanvasItem, shape: String, center: Vector2, head_w: float, head_h: float, color: Color, angle: float = 0.0):
	if shape == "rect":
		# 矩形の回転対応は省略（必要に応じて実装）
		var p_top = center - Vector2(0, head_h / 2)
		var p_bottom = center + Vector2(0, head_h / 2)
		draw_rect(canvas, p_top, p_bottom, head_w, color)
	else:
		# 真円: 半径 = head_h / 2（縦幅を基準）。head_wは内部計算用のみに使い描画には使わない
		var r = head_h / 2.0
		draw_ellipse(canvas, center, r, r, color, angle)
