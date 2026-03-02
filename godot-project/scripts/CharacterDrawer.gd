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
    
    # 色設定
    var skin_color = Color("#ffe4c4")
    var base_shirt_color = Color("#ab82a8") # grep_simulatorの参考画像風(くすんだ紫/ピンク)
    var pants_color = Color("#e5d6ba") # 下は肌色に近いベージュ

    # 奥のパーツ用暗めカラー
    var skin_dark = skin_color.darkened(0.15)
    var pants_dark = pants_color.darkened(0.15)
    var shirt_dark = base_shirt_color.darkened(0.15)

    # 太さの算出 (cm -> px)
    # 横向きの場合は「肩幅」ではなく「体の厚み」として狭くする
    var width_scale = 0.35 if facing == "side" else 1.0
    
    var shoulder_w = (m["shoulder"] if m.has("shoulder") else 35.0) * p * width_scale
    var hip_w = shoulder_w * 0.95 # やや寸胴気味
    
    # 腕・脚の太さ (少しスリムに)
    var thigh_w = 9.0 * p
    var shin_w = 6.5 * p
    var arm_w = 5.5 * p
    var neck_w = 4.5 * p

    # 座標計算（骨構造の各点）
    var cx = 0.0
    var cy = y_crotch
    
    var hip_ang = waist_angle * 0.5
    var wx = cx + waist_l * sin(hip_ang)
    var wy = cy - waist_l * cos(hip_ang) # 腰（へそ付近）
    
    var sx = wx + chest_l * sin(waist_angle)
    var sy = wy - chest_l * cos(waist_angle) # 肩中心
    
    var nx = sx + 2.0 * (m["neck"] * p) * sin(waist_angle)
    var ny = sy - 2.0 * (m["neck"] * p) * cos(waist_angle) # 顎下
    
    var hx = nx + (head_h / 2) * sin(waist_angle)
    var hy = ny - (head_h / 2) * cos(waist_angle) # 頭中心

    # Transform設定
    var _t_orig = get_canvas_transform()
    if flip:
        draw_set_transform(Vector2.ZERO, 0, Vector2(-1, 1))
        
    # --- 描画順：奥の腕 -> 奥の足 -> 胴体下 -> 胴体上 -> 手前の足 -> 首・頭 -> 手前の腕 ---

    if facing == "front" or facing == "back":
        # ======== 正面・背面 (Front / Back) ========
        # grep_simulatorのロジックに倣い、胴体自体の幅(body_w)は肩幅(shoulder_w)の 3/5 程度にする
        var body_w = shoulder_w * 0.6
        var body_w_half = body_w / 2.0
        
        # 腕のオフセット：胴体の幅のすぐ外側（肩幅の 1/2 より少し内側）
        var sh_off = shoulder_w * 0.5 - arm_w * 0.5
        
        # 肩の高さ（sy は元々背骨の曲がり等を考慮した位置だが、正面描画では少し高く見えすぎるため調整）
        # grep_simulator では yShoulderScaled = crotchY - currentTorsoL としている
        var front_sy = cy - m["arm"] * p
        
        # 脚のオフセット：胴体幅の半分より少し内側
        var hp_off = body_w_half * 0.6
        
        # 腕と脚の基点
        var p_hip_l = Vector2(cx - hp_off, cy)
        var p_hip_r = Vector2(cx + hp_off, cy)
        var p_sh_l = Vector2(sx - sh_off, front_sy)
        var p_sh_r = Vector2(sx + sh_off, front_sy)
        
        # 歩行時の左右のブレを抑えるため角度変化を小さくする
        var f_leg_l_ang = (leg_l_angle * 0.2) * PI / 180 + PI / 2
        var f_leg_r_ang = (leg_r_angle * 0.2) * PI / 180 + PI / 2

        # 1. 両足 (背面に配置するため最初に描画)
        var p_thigh_l = _rotated_point(p_hip_l.x, p_hip_l.y, thigh_l, f_leg_l_ang)
        var p_shin_l = _rotated_point(p_thigh_l.x, p_thigh_l.y, shin_l, f_leg_l_ang + knee_l * 0.2)
        _draw_limb(p_hip_l, p_thigh_l, thigh_w, pants_color)
        _draw_limb(p_thigh_l, p_shin_l, shin_w, skin_color)
        
        var p_thigh_r = _rotated_point(p_hip_r.x, p_hip_r.y, thigh_l, f_leg_r_ang)
        var p_shin_r = _rotated_point(p_thigh_r.x, p_thigh_r.y, shin_l, f_leg_r_ang + knee_r * 0.2)
        _draw_limb(p_hip_r, p_thigh_r, thigh_w, pants_color)
        _draw_limb(p_thigh_r, p_shin_r, shin_w, skin_color)

        # 2. 胴体 (シャツ)
        # 胴体の丸みを消し、角ばった形にして「服」らしいシルエットを強調
        var body_pts_lower = PackedVector2Array([
            Vector2(wx - body_w_half, wy), Vector2(wx + body_w_half, wy),
            Vector2(cx + body_w_half, cy), Vector2(cx - body_w_half, cy)
        ])
        draw_polygon(body_pts_lower, PackedColorArray([base_shirt_color]))
        
        var body_pts_upper = PackedVector2Array([
            Vector2(sx - body_w_half, front_sy), Vector2(sx + body_w_half, front_sy),
            Vector2(wx + body_w_half, wy), Vector2(wx - body_w_half, wy)
        ])
        draw_polygon(body_pts_upper, PackedColorArray([base_shirt_color]))

        # 3. 首
        _draw_limb(Vector2(sx, front_sy), Vector2(nx, ny), neck_w, skin_color)

        # 4. 頭
        var head_w = (m["headWidth"] if m.has("headWidth") else m["head"] * 0.702) * p
        _draw_ellipse(Vector2(hx, hy), head_w / 2.0, head_h / 2.0, skin_color)

        # 5. 両腕 (胴体の上に描画)
        var arm_len = m["armLength"] * p
        var u_arm = arm_len * 0.45
        var l_arm = arm_len * 0.55
        
        # 左腕（画面左側）: やや左へ広げる (+0.12ラジアン)
        var f_arm_l_ang = 0.12 + (_arm_l_angle * 0.3) * PI / 180 + PI / 2
        var p_elb_l = _rotated_point(p_sh_l.x, p_sh_l.y, u_arm, f_arm_l_ang)
        var p_hand_l = _rotated_point(p_elb_l.x, p_elb_l.y, l_arm, f_arm_l_ang)
        var p_sleeve_l = _rotated_point(p_sh_l.x, p_sh_l.y, u_arm * 0.4, f_arm_l_ang)
        
        # 右腕（画面右側）: やや右へ広げる (-0.12ラジアン)
        var f_arm_r_ang = -0.12 + (arm_r_angle * 0.3) * PI / 180 + PI / 2
        var p_elb_r = _rotated_point(p_sh_r.x, p_sh_r.y, u_arm, f_arm_r_ang)
        var p_hand_r = _rotated_point(p_elb_r.x, p_elb_r.y, l_arm, f_arm_r_ang)
        var p_sleeve_r = _rotated_point(p_sh_r.x, p_sh_r.y, u_arm * 0.4, f_arm_r_ang)

        # 腕の描画
        var arm_color = skin_color if facing == "front" else skin_dark
        var sleeve_color = base_shirt_color if facing == "front" else shirt_dark
        _draw_limb(p_sh_l, p_elb_l, arm_w, arm_color)
        _draw_limb(p_sh_l, p_sleeve_l, arm_w * 1.05, sleeve_color)
        _draw_limb(p_elb_l, p_hand_l, arm_w * 0.8, arm_color)
        
        _draw_limb(p_sh_r, p_elb_r, arm_w, arm_color)
        _draw_limb(p_sh_r, p_sleeve_r, arm_w * 1.05, sleeve_color)
        _draw_limb(p_elb_r, p_hand_r, arm_w * 0.8, arm_color)

        # 6. 顔とディテール (一番上に描画)
        if facing == "front":
            var eye_off_x = head_w * 0.2
            var eye_y = hy - (head_h * 0.1)
            draw_circle(Vector2(hx - eye_off_x, eye_y), 2.5, Color("#333333"))
            draw_circle(Vector2(hx + eye_off_x, eye_y), 2.5, Color("#333333"))
            
            # ニッコリ口
            var mouth_y = hy + (head_h * 0.15)
            var m_pts = PackedVector2Array()
            for i in range(11):
                var t = float(i) / 10.0
                var xx = lerp(-head_w * 0.15, head_w * 0.15, t)
                var yy = mouth_y + sin(t * PI) * 3.0
                m_pts.append(Vector2(hx + xx, yy))
            for i in range(m_pts.size() - 1):
                draw_line(m_pts[i], m_pts[i + 1], Color("#c07070"), 2.0)
            
            # 胸のポッチ
            # currentTorsoL = arm_p (胴体の長さ全体)
            var current_torso_l = m["arm"] * p
            var nipple_y = front_sy + (current_torso_l * 0.25)
            # nipple_x は肩幅の 3/25 程度 (grep_simulator準拠)
            var nip_x = shoulder_w * (3.0 / 25.0)
            draw_circle(Vector2(sx - nip_x, nipple_y), 3.0, Color("#d0a0a0"))
            draw_circle(Vector2(sx + nip_x, nipple_y), 3.0, Color("#d0a0a0"))
            
            # おへそ
            var navel_y = front_sy + (current_torso_l * 0.60)
            draw_circle(Vector2(wx, navel_y), 2.0, Color("#d0a0a0"))

    else:
        # ======== 横向き (Side) ========
        # 1. 奥の腕
        var arm_len = m["armLength"] * p
        var u_arm = arm_len * 0.45
        var l_arm = arm_len * 0.55
        var shoulder_offset = Vector2.ZERO # 真横ならオフセットなし
        
        var s_pos_l = Vector2(sx, sy) - shoulder_offset
        var p_elb_l = _rotated_point(s_pos_l.x, s_pos_l.y, u_arm, _arm_l_angle * PI / 180 + waist_angle + PI / 2)
        var p_hand_l = _rotated_point(p_elb_l.x, p_elb_l.y, l_arm, _arm_l_angle * PI / 180 + waist_angle + PI / 2 - 0.1)
        var p_sleeve_l = _rotated_point(s_pos_l.x, s_pos_l.y, u_arm * 0.4, _arm_l_angle * PI / 180 + waist_angle + PI / 2)
        
        _draw_limb(s_pos_l, p_elb_l, arm_w, skin_dark)
        _draw_limb(s_pos_l, p_sleeve_l, arm_w * 1.05, shirt_dark) # 奥の袖
        _draw_limb(p_elb_l, p_hand_l, arm_w * 0.8, skin_dark)

        # 2. 奥の足
        var p_thigh_l = _rotated_point(cx, cy, thigh_l, leg_l_angle * PI / 180 + PI / 2)
        var p_shin_l = _rotated_point(p_thigh_l.x, p_thigh_l.y, shin_l, leg_l_angle * PI / 180 + PI / 2 + knee_l)
        _draw_limb(Vector2(cx, cy), p_thigh_l, thigh_w, pants_dark) # 太もも
        _draw_limb(p_thigh_l, p_shin_l, shin_w, skin_dark) # すね

        # 3. 胴体（服）
        _draw_trapezoid(Vector2(wx, wy), Vector2(cx, cy), hip_w, hip_w, base_shirt_color, waist_angle * 0.5)
        _draw_trapezoid(Vector2(sx, sy), Vector2(wx, wy), shoulder_w, hip_w, base_shirt_color, waist_angle)

        # 4. 手前の足
        var p_thigh_r = _rotated_point(cx, cy, thigh_l, leg_r_angle * PI / 180 + PI / 2)
        var p_shin_r = _rotated_point(p_thigh_r.x, p_thigh_r.y, shin_l, leg_r_angle * PI / 180 + PI / 2 + knee_r)
        _draw_limb(Vector2(cx, cy), p_thigh_r, thigh_w, pants_color) # 太もも
        _draw_limb(p_thigh_r, p_shin_r, shin_w, skin_color) # すね
        
        # 5. 首
        _draw_limb(Vector2(sx, sy), Vector2(nx, ny), neck_w, skin_color)

        # 6. 頭
        var head_w = (m["headWidth"] if m.has("headWidth") else m["head"] * 0.702) * p * 0.85 # 横顔は少し幅を狭める
        _draw_ellipse(Vector2(hx, hy), head_w / 2.0, head_h / 2.0, skin_color)
        
        # 目と口（サイドビュー時）
        var eye_x = hx + (head_w * 0.25)
        var eye_y = hy - (head_h * 0.1)
        draw_circle(Vector2(eye_x, eye_y), 2.5, Color("#333333"))
        
        var mouth_x = hx + (head_w * 0.25)
        var mouth_y = hy + (head_h * 0.15)
        draw_line(Vector2(mouth_x - 1, mouth_y), Vector2(mouth_x + 3, mouth_y - 2), Color("#c07070"), 2.0)

        # 7. 手前の腕
        var s_pos_r = Vector2(sx, sy) + shoulder_offset
        var p_elb_r = _rotated_point(s_pos_r.x, s_pos_r.y, u_arm, arm_r_angle * PI / 180 + waist_angle + PI / 2)
        var p_hand_r = _rotated_point(p_elb_r.x, p_elb_r.y, l_arm, arm_r_angle * PI / 180 + waist_angle + PI / 2 - 0.1)
        var p_sleeve_r = _rotated_point(s_pos_r.x, s_pos_r.y, u_arm * 0.4, arm_r_angle * PI / 180 + waist_angle + PI / 2)
        
        _draw_limb(s_pos_r, p_elb_r, arm_w, skin_color)
        _draw_limb(s_pos_r, p_sleeve_r, arm_w * 1.05, base_shirt_color) # 手前の袖
        _draw_limb(p_elb_r, p_hand_r, arm_w * 0.8, skin_color)

    if flip:
        draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


# ヘルパー (図形描画用)
func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color):
    var points = PackedVector2Array()
    var segs = 32
    for i in range(segs):
        var ang = PI * 2.0 * i / float(segs)
        points.append(center + Vector2(cos(ang) * rx, sin(ang) * ry))
    draw_polygon(points, PackedColorArray([color]))

func _draw_limb(p1: Vector2, p2: Vector2, width: float, color: Color):
    var d = p2 - p1
    var length = d.length()
    if length <= 0.01:
        return
    var n = Vector2(-d.y, d.x).normalized() * (width / 2.0)
    var pts = PackedVector2Array([
        p1 - n, p1 + n, p2 + n, p2 - n
    ])
    draw_polygon(pts, PackedColorArray([color]))
    draw_circle(p1, width / 2.0, color)
    draw_circle(p2, width / 2.0, color)

func _draw_trapezoid(p_top: Vector2, p_bottom: Vector2, top_width: float, bottom_width: float, color: Color, angle: float):
    var d = p_bottom - p_top
    var length = d.length()
    if length <= 0.01:
        return
    # 接続の法線（左右の拡がり）を計算
    var n = Vector2(-d.y, d.x).normalized()
    var nt = n * (top_width / 2.0)
    var nb = n * (bottom_width / 2.0)
    
    var pts = PackedVector2Array([
        p_top - nt, p_top + nt, p_bottom + nb, p_bottom - nb
    ])
    draw_polygon(pts, PackedColorArray([color]))
    
    # 継ぎ目を丸める（簡略化版。角度によって楕円にするなど工夫の余地あり）
    draw_circle(p_top, top_width / 2.0, color)
    draw_circle(p_bottom, bottom_width / 2.0, color)


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
