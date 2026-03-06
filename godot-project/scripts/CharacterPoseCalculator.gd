class_name CharacterPoseCalculator
extends RefCounted

# キャラクターの各種骨格位置や角度を計算して返す

static func calculate_pose_data(player: Node, m: Dictionary, p: float) -> Dictionary:
    var pose = player.pose
    var is_walking = player.is_walking
    var walk_phase = player.walk_phase
    var visual_height_cm = player.visual_height_cm

    var leg_l_angle = 0.0
    var leg_r_angle = 0.0
    var arm_l_angle = 0.0
    var arm_r_angle = 0.0
    var knee_l = 0.1
    var knee_r = 0.1
    var waist_angle = 0.0

    var walk_amp = 12.0 if is_walking else 0.0
    leg_l_angle = walk_amp * sin(walk_phase)
    leg_r_angle = walk_amp * sin(walk_phase + PI)
    arm_l_angle = - walk_amp * 0.6 * sin(walk_phase)
    arm_r_angle = - walk_amp * 0.6 * sin(walk_phase + PI)

    var y_crotch = -m["leg"] * p
    var head_h = m["head"] * p
    var waist_l = (m["arm"] * 0.45) * p
    var chest_l = (m["arm"] * 0.55) * p
    var thigh_l = (m["leg"] * 0.55) * p
    var shin_l = (m["leg"] * 0.45) * p

    var is_crouching = (pose == "normal" and visual_height_cm < m["height"] - 0.1)
    
    if pose == "taiiku_suwari":
        waist_angle = 0.3
        leg_l_angle = -130
        leg_r_angle = -130
        knee_l = PI * 0.72
        knee_r = PI * 0.72
        arm_l_angle = -60
        arm_r_angle = -60
        y_crotch = -15.0 * p
    elif is_crouching:
        var target_px = visual_height_cm * p
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
        arm_l_angle = base_arm - walk_amp * 0.4 * sin(walk_phase)
        arm_r_angle = base_arm - walk_amp * 0.4 * sin(walk_phase + PI)
        
        var dy1 = thigh_l * cos(leg_l_angle * PI / 180) + shin_l * cos(leg_l_angle * PI / 180 + knee_l)
        var dy2 = thigh_l * cos(leg_r_angle * PI / 180) + shin_l * cos(leg_r_angle * PI / 180 + knee_r)
        y_crotch = - max(dy1, dy2)

    var cx = 0.0
    var cy = y_crotch
    
    var hip_ang = waist_angle * 0.5
    var wx = cx + waist_l * sin(hip_ang)
    var wy = cy - waist_l * cos(hip_ang) # 腰（へそ付近）
    
    var sx = wx + chest_l * sin(waist_angle)
    var sy = wy - chest_l * cos(waist_angle) # 肩中心
    
    var nx = sx + 2.0 * (m["neck"] * p) * sin(waist_angle)
    var ny = sy - 2.0 * (m["neck"] * p) * cos(waist_angle) # 顎下
    
    var hx = nx + (head_h / 2.0) * sin(waist_angle)
    var hy = ny - (head_h / 2.0) * cos(waist_angle) # 頭中心

    # 正面・背面ビュー用: 背骨のX座標は中心(cx)に固定、Yのみ腰曲げで圧縮
    var front_wx = cx
    var front_wy = cy - waist_l * cos(hip_ang)
    var front_sx = cx
    var front_sy = front_wy - chest_l * cos(waist_angle)
    var front_nx = cx
    var front_ny = front_sy - 2.0 * (m["neck"] * p) * cos(waist_angle)
    var front_hx = cx
    var front_hy = front_ny - (head_h / 2.0) * cos(waist_angle * 0.5)

    return {
        "leg_l_angle": leg_l_angle,
        "leg_r_angle": leg_r_angle,
        "arm_l_angle": arm_l_angle,
        "arm_r_angle": arm_r_angle,
        "knee_l": knee_l,
        "knee_r": knee_r,
        "waist_angle": waist_angle,
        "y_crotch": y_crotch,
        "head_h": head_h,
        "waist_l": waist_l,
        "chest_l": chest_l,
        "thigh_l": thigh_l,
        "shin_l": shin_l,
        "cx": cx, "cy": cy,
        "wx": wx, "wy": wy,
        "sx": sx, "sy": sy,
        "nx": nx, "ny": ny,
        "hx": hx, "hy": hy,
        "front_wx": front_wx, "front_wy": front_wy,
        "front_sx": front_sx, "front_sy": front_sy,
        "front_nx": front_nx, "front_ny": front_ny,
        "front_hx": front_hx, "front_hy": front_hy
    }


static func _get_crouch_params(t: float) -> Dictionary:
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

static func _eval_crouch_height(t: float, p: float, th: float, sh: float, wl: float, cl: float, hh: float, m: Dictionary) -> float:
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

# 各関節の終点座標を計算するヘルパー
static func rotated_point(px: float, py: float, length: float, rad: float) -> Vector2:
    return Vector2(px + cos(rad) * length, py + sin(rad) * length)
