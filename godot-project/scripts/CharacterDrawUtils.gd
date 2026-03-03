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
    canvas.draw_circle(p_top, top_width / 2.0, color)
    canvas.draw_circle(p_bottom, bottom_width / 2.0, color)

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

# ユーザー指定の形状（shape）に応じて描画を切り替えるヘルパー
# torsoは p_top, p_bottom, width を受け取る汎用インタフェース
static func draw_torso_part(canvas: CanvasItem, shape: String, p_top: Vector2, p_bottom: Vector2, top_w: float, bottom_w: float, color: Color):
    if shape == "rect":
        draw_rect(canvas, p_top, p_bottom, (top_w + bottom_w) / 2.0, color)
    elif shape == "trapezoid":
        draw_trapezoid(canvas, p_top, p_bottom, top_w, bottom_w, color)
    elif shape == "ellipse":
        # 中点を中心として楕円を描くなど、必要に応じて実装
        draw_limb(canvas, p_top, p_bottom, (top_w + bottom_w) / 2.0, color)
    else:
        # デフォルトフォールバック
        draw_trapezoid(canvas, p_top, p_bottom, top_w, bottom_w, color)

static func draw_limb_part(canvas: CanvasItem, shape: String, p_top: Vector2, p_bottom: Vector2, width: float, color: Color):
    if shape == "rect":
        draw_rect(canvas, p_top, p_bottom, width, color)
    elif shape == "line":
        canvas.draw_line(p_top, p_bottom, color, width)
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
