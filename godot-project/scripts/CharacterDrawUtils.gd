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

static func draw_hand(canvas: CanvasItem, pos: Vector2, hw: float, hh: float, color: Color, angle: float = 0.0):
    # 手（長方形）: hw=半幅, hh=半高さ
    var pts = PackedVector2Array()
    var corners = [
        Vector2(-hw, 0), Vector2(hw, 0),
        Vector2(hw, hh * 2.0), Vector2(-hw, hh * 2.0)
    ]
    var r_offset_x = 0
    var r_offset_y = hh
    for c in corners:
        var rx = (c.x + r_offset_x) * cos(angle) - (c.y + r_offset_y) * sin(angle)
        var ry = (c.x + r_offset_x) * sin(angle) + (c.y + r_offset_y) * cos(angle)
        pts.append(pos + Vector2(rx, ry))
    canvas.draw_polygon(pts, PackedColorArray([color]))

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
        # 線 + 両端に円関節
        var joint_r = width * 0.35
        canvas.draw_line(p_top, p_bottom, color, max(1.5, width * 0.15))
        canvas.draw_circle(p_top, joint_r, color)
        canvas.draw_circle(p_bottom, joint_r, color)
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
