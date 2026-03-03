class_name CharacterDrawUtils
extends RefCounted

# CanvasItem への図形描画をまとめるユーティリティクラス

static func draw_ellipse(canvas: CanvasItem, center: Vector2, rx: float, ry: float, color: Color):
    var points = PackedVector2Array()
    var segs = 32
    for i in range(segs):
        var ang = PI * 2.0 * i / float(segs)
        points.append(center + Vector2(cos(ang) * rx, sin(ang) * ry))
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

static func draw_trapezoid(canvas: CanvasItem, p_top: Vector2, p_bottom: Vector2, top_width: float, bottom_width: float, color: Color):
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

static func draw_hand(canvas: CanvasItem, pos: Vector2, size: float, color: Color):
    # 小さな手（楕円形）
    draw_ellipse(canvas, pos, size * 1.4, size * 0.9, color)

static func draw_foot_front(canvas: CanvasItem, ankle: Vector2, foot_w: float, foot_h: float, color: Color):
    # 正面: 小さな四角形
    var pts = PackedVector2Array([
        ankle + Vector2(-foot_w * 0.5, 0.0),
        ankle + Vector2(foot_w * 0.5, 0.0),
        ankle + Vector2(foot_w * 0.5, foot_h),
        ankle + Vector2(-foot_w * 0.5, foot_h),
    ])
    canvas.draw_polygon(pts, PackedColorArray([color]))

static func draw_foot_side(canvas: CanvasItem, ankle: Vector2, foot_w: float, foot_h: float, color: Color):
    # 側面: くさび形（三角形）、右向き（つま先が右）
    var pts = PackedVector2Array([
        ankle,
        ankle + Vector2(0.0, foot_h),
        ankle + Vector2(foot_w, foot_h),
    ])
    canvas.draw_polygon(pts, PackedColorArray([color]))

static func draw_side_torso(canvas: CanvasItem, top_cx: float, top_y: float, nipple_y: float, mid_cx: float, mid_y: float, bot_cx: float, bottom_y: float, thickness: float, color: Color):
    # 側面胴体: 腰の中間頂点を追加してくの字に曲がるようにする
    # top(肩) → mid(腰) → bot(股) の3中心点それぞれに前後の端点を持つ6頂点ポリゴン
    # thickness は固定値のため、どの姿勢でも体の前後幅は一定に保たれる
    var half = thickness / 2.0

    # 乳首の高さ: 肩〜腰の上半分あたりで前面が折れる
    var nipple_t = clamp((nipple_y - top_y) / (mid_y - top_y + 0.001), 0.0, 1.0)
    var nipple_front_x = lerp(top_cx + half, mid_cx + half, nipple_t)

    var pts = PackedVector2Array([
        # 背面 (後ろ側): 肩→腰→股
        Vector2(top_cx - half, top_y),
        Vector2(mid_cx - half, mid_y),
        Vector2(bot_cx - half, bottom_y),
        # 前面 (前側): 股→腰→乳首折れ→肩（逆順）
        Vector2(bot_cx + half, bottom_y),
        Vector2(mid_cx + half, mid_y),
        Vector2(nipple_front_x, nipple_y),
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
        # 線 + 両端に円関節
        var joint_r = width * 0.35
        canvas.draw_line(p_top, p_bottom, color, max(1.5, width * 0.15))
        canvas.draw_circle(p_top, joint_r, color)
        canvas.draw_circle(p_bottom, joint_r, color)
    else:
        # デフォルトは丸みを帯びた limb
        draw_limb(canvas, p_top, p_bottom, width, color)

static func draw_head_part(canvas: CanvasItem, shape: String, center: Vector2, head_w: float, head_h: float, color: Color):
    if shape == "rect":
        var p_top = center - Vector2(0, head_h / 2)
        var p_bottom = center + Vector2(0, head_h / 2)
        draw_rect(canvas, p_top, p_bottom, head_w, color)
    else:
        # デフォルトは ellipse
        draw_ellipse(canvas, center, head_w / 2.0, head_h / 2.0, color)
