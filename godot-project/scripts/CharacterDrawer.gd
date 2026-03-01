extends Node2D

@onready var player = get_parent()

func _draw() -> void:
    var p = player.CM_TO_PX
    var m = player.m
    var pose = player.pose
    var dir = player.dir
    var facing = player.facing
    var is_walking = player.is_walking
    var walk_phase = player.walk_phase

    if m == null or m.is_empty():
        return

    # 描画系の変数
    var leg_l_angle = 0.0
    var leg_r_angle = 0.0
    var _arm_l_angle = 0.0
    var arm_r_angle = 0.0
    var knee_l = 0.1
    var knee_r = 0.1
    var waist_angle = 0.0

    # 歩行波
    var walk_amp = 12.0 if is_walking else 0.0
    leg_l_angle = walk_amp * sin(walk_phase)
    leg_r_angle = walk_amp * sin(walk_phase + PI)
    _arm_l_angle = - walk_amp * 0.6 * sin(walk_phase)
    arm_r_angle = - walk_amp * 0.6 * sin(walk_phase + PI)

    var y_crotch = -m["leg"] * p
    var head_h = m["head"] * p
    var waist_l = (m["arm"] * 0.45) * p
    var chest_l = (m["arm"] * 0.55) * p
    var thigh_l = (m["leg"] * 0.55) * p
    var shin_l = (m["leg"] * 0.45) * p
    
    # Crouch時の二分探索ロジック
    # pose が crouch の時、または高さが補間中(フル身長でない)の時にアニメーションを適用
    var is_crouching = (pose == "crouch") or (player.visual_height_cm < m["height"] - 0.1)
    
    if is_crouching:
        var target_px = player.visual_height_cm * p
        
        var min_t = 0.0
        var max_t = 2.0
        var best_t = 0.0
        
        # 二分探索で t(0~2) を求める簡略版
        for i in range(15):
            var mid_t = (min_t + max_t) / 2.0
            var hp = _eval_crouch_height(mid_t, p, thigh_l, shin_l, waist_l, chest_l, head_h, m)
            if hp > target_px: min_t = mid_t
            else: max_t = mid_t
        best_t = (min_t + max_t) / 2.0
        
        var c_params = _get_crouch_params(best_t)
        waist_angle = c_params["w"]
        var l_fac = c_params["l"]
        
        knee_l = PI * 0.7 * l_fac
        knee_r = knee_l
        var base_leg = -100.0 * l_fac
        leg_l_angle = base_leg + walk_amp * sin(walk_phase)
        leg_r_angle = base_leg + walk_amp * sin(walk_phase + PI)
        
        var arm_drop = waist_angle / 1.3
        var base_arm = -45.0 * arm_drop
        _arm_l_angle = base_arm - walk_amp * 0.4 * sin(walk_phase)
        arm_r_angle = base_arm - walk_amp * 0.4 * sin(walk_phase + PI)
        
        # IKによるy_crotch計算
        var dy1 = thigh_l * cos(leg_l_angle * PI / 180) + shin_l * cos(leg_l_angle * PI / 180 + knee_l)
        var dy2 = thigh_l * cos(leg_r_angle * PI / 180) + shin_l * cos(leg_r_angle * PI / 180 + knee_r)
        y_crotch = - max(dy1, dy2)
    elif pose == "squat":
        waist_angle = 0.5
        leg_l_angle = -100
        leg_r_angle = -100
        knee_l = PI * 0.7
        knee_r = PI * 0.7
        _arm_l_angle = 30
        arm_r_angle = 30
        var rad = leg_l_angle * PI / 180
        var dy = thigh_l * cos(rad) + shin_l * cos(rad + knee_l)
        y_crotch = - dy
        
    # === 描画実行 ===
    # 向きに応じたスケーリング対応のためTransformを使う
    var flip = (dir == -1 and facing == "side")
    
    var color = Color("#e8c5a0")
    var thick = 4.0

    # 座標計算
    var cx = 0.0
    var cy = y_crotch
    
    var hip_ang = waist_angle * 0.5
    var wx = cx + waist_l * sin(hip_ang)
    var wy = cy - waist_l * cos(hip_ang)
    
    var sx = wx + chest_l * sin(waist_angle)
    var sy = wy - chest_l * cos(waist_angle)
    
    var nx = sx + 2.0 * (m["neck"] * p) * sin(waist_angle)
    var ny = sy - 2.0 * (m["neck"] * p) * cos(waist_angle)
    
    var hx = nx + (head_h / 2) * sin(waist_angle)
    var hy = ny - (head_h / 2) * cos(waist_angle)

    # Transform設定
    var _t_orig = get_canvas_transform()
    if flip:
        draw_set_transform(Vector2.ZERO, 0, Vector2(-1, 1))

    # 奥の足
    var p_thigh_l = _rotated_point(cx, cy, thigh_l, leg_l_angle * PI / 180 + PI / 2)
    var p_shin_l = _rotated_point(p_thigh_l.x, p_thigh_l.y, shin_l, leg_l_angle * PI / 180 + PI / 2 + knee_l)
    draw_line(Vector2(cx, cy), p_thigh_l, Color("#d0a279"), thick)
    draw_line(p_thigh_l, p_shin_l, Color("#d0a279"), thick)

    # 手前の足
    var p_thigh_r = _rotated_point(cx, cy, thigh_l, leg_r_angle * PI / 180 + PI / 2)
    var p_shin_r = _rotated_point(p_thigh_r.x, p_thigh_r.y, shin_l, leg_r_angle * PI / 180 + PI / 2 + knee_r)
    draw_line(Vector2(cx, cy), p_thigh_r, color, thick)
    draw_line(p_thigh_r, p_shin_r, color, thick)
    
    # 胴体・首
    draw_line(Vector2(cx, cy), Vector2(wx, wy), color, thick)
    draw_line(Vector2(wx, wy), Vector2(sx, sy), color, thick)
    draw_line(Vector2(sx, sy), Vector2(nx, ny), color, thick)

    # 腕（今回は簡単のため手前のみ描写）
    var arm_len = m["armLength"] * p
    var u_arm = arm_len * 0.5
    var l_arm = arm_len * 0.5
    var p_elb = _rotated_point(sx, sy, u_arm, arm_r_angle * PI / 180 + waist_angle + PI / 2)
    var p_hand = _rotated_point(p_elb.x, p_elb.y, l_arm, arm_r_angle * PI / 180 + waist_angle + PI / 2 - 0.1)
    draw_line(Vector2(sx, sy), p_elb, color, thick)
    draw_line(p_elb, p_hand, color, thick)

    # 頭
    draw_circle(Vector2(hx, hy), head_h / 2, Color("#f5deb3"))

    if flip:
        draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

# ヘルパー (Crouch用)
func _get_crouch_params(t: float) -> Dictionary:
    var MAX_W = 1.3
    var KNEE_START = 0.7 / 1.3
    var w = 0.0
    var l = 0.0
    if t <= KNEE_START:
        w = t * MAX_W
    elif t <= 1.0:
        w = t * MAX_W
        l = ((t - KNEE_START) / (1.0 - KNEE_START)) * 0.4
    else:
        w = MAX_W
        l = 0.4 + (t - 1.0) * 0.6
    return {"w": w, "l": l}

func _eval_crouch_height(t: float, p: float, th: float, sh: float, wl: float, cl: float, hh: float, m: Dictionary) -> float:
    var params = _get_crouch_params(t)
    var w = params["w"]
    var l = params["l"]
    
    var knee = PI * 0.7 * l
    var base_leg = -100.0 * l * PI / 180
    var dy = th * cos(base_leg) + sh * cos(base_leg + knee)
    var crotch_y = (th + sh) - dy
    
    var tor_h = wl * cos(w * 0.5) + cl * cos(w)
    var neck_h = (m["neck"] * p * 2.0) * cos(w)
    var hd_radius = hh * 0.5 * cos(w * 0.5)
    
    return (th + sh) - crotch_y + tor_h + neck_h + hd_radius

func _rotated_point(px: float, py: float, length: float, rad: float) -> Vector2:
    return Vector2(px + cos(rad) * length, py + sin(rad) * length)
