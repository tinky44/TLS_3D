class_name CharacterPoseCalculator
extends RefCounted
const WALK_AMP_DEG := 12.0

# キャラクターの各種骨格位置や角度を計算して返す

static func calculate_pose_data(player: Node, m: Dictionary, p: float) -> Dictionary:
    var pose = player.pose
    var is_walking = player.is_walking
    var walk_phase = player.walk_phase
    var visual_height_cm = player.visual_height_cm

    # プレイヤー系ノードだけが stress 姿勢を受ける
    var is_leg_pain: bool = false
    var stress_ratio: float = 0.0
    var _g: Node = player.get_node_or_null("/root/Global")
    var receives_global_stress: bool = false
    if player.get("receives_global_stress") != null:
        receives_global_stress = bool(player.get("receives_global_stress"))
    if _g and _g.get("is_leg_pain"):
        is_leg_pain = _g.is_leg_pain
    if receives_global_stress and _g and _g.get("stress") != null:
        stress_ratio = clampf(float(_g.stress) / 100.0, 0.0, 1.0)

    var leg_l_angle = 0.0
    var leg_r_angle = 0.0
    var arm_l_angle = 0.0
    var arm_r_angle = 0.0
    var knee_l = 0.1
    var knee_r = 0.1
    var waist_angle = 0.0

    var walk_amp = WALK_AMP_DEG if is_walking else 0.0
    leg_l_angle = walk_amp * sin(walk_phase)
    # is_leg_pain 時は右脚の振幅を 0.3 倍（ひきずり歩き）
    leg_r_angle = (walk_amp * 0.3 if is_leg_pain else walk_amp) * sin(walk_phase + PI)
    arm_l_angle = - walk_amp * 0.6 * sin(walk_phase)
    arm_r_angle = - walk_amp * 0.6 * sin(walk_phase + PI)

    var y_crotch = -m["leg"] * p
    var head_h = m["head"] * p
    var navel_l = (m["arm"] * 0.40) * p # へそ〜股下 (胴体下部 40%)
    var chest_l = (m["arm"] * 0.60) * p # 肩〜へそ (胴体上部 60%)
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
    elif pose == "chair_sit":
        # Phase 1: 座面高さを sit_context から取得（未設定時はすね長さで代用）
        var raw_seat_h_cm: float = -1.0
        var raw_desk_h_cm: float = -1.0
        var sc = player.get("sit_context")
        if sc is Dictionary:
            raw_seat_h_cm = float(sc.get("seat_h_cm", -1.0))
            raw_desk_h_cm = float(sc.get("desk_h_cm", -1.0))
        var seat_h_px: float = (raw_seat_h_cm if raw_seat_h_cm > 0.0 else m["leg"] * 0.45) * p

        waist_angle = 0.1
        leg_l_angle = -90
        leg_r_angle = -90
        arm_l_angle = -50
        arm_r_angle = -50
        y_crotch = -seat_h_px

        # Phase 2: すね IK — asin でかかとを床に合わせる
        var ratio: float = clampf(seat_h_px / shin_l, 0.0, 1.0)
        knee_l = asin(ratio)
        knee_r = knee_l

        # Phase 3: 机の制約 — 膝が机天板より上に来ないよう太ももを下げる
        if raw_desk_h_cm > 0.0:
            var desk_h_px: float = raw_desk_h_cm * p
            if seat_h_px > desk_h_px:
                var delta: float = asin(clampf((seat_h_px - desk_h_px) / thigh_l, 0.0, 0.9))
                leg_l_angle = -90 + rad_to_deg(delta)
                leg_r_angle = leg_l_angle
    elif pose == "reach_low":
        waist_angle = 0.12
        leg_l_angle = -2
        leg_r_angle = 4
        knee_l = 0.08
        knee_r = 0.08
        arm_l_angle = -18
        arm_r_angle = -55
    elif pose == "reach_up":
        waist_angle = -0.04
        leg_l_angle = -4
        leg_r_angle = 2
        knee_l = 0.05
        knee_r = 0.05
        arm_l_angle = -20
        arm_r_angle = -165
    elif pose == "sleep":
        # 寝る: 体を大きく前傾させて床近くで丸まる（床埋め防止のため waist_angle を抑制）
        waist_angle = 1.2
        leg_l_angle = -120
        leg_r_angle = -120
        knee_l = PI * 0.72
        knee_r = PI * 0.72
        arm_l_angle = 20
        arm_r_angle = 20
        y_crotch = -15.0 * p
    elif is_crouching:
        var target_px = visual_height_cm * p
        var min_t = 0.0
        var max_t = 2.0
        var best_t = 0.0
        
        # 二分探索で t(0~2) を求める簡略版
        for i in range(15):
            var mid_t = (min_t + max_t) / 2.0
            var hp = _eval_crouch_height(mid_t, p, thigh_l, shin_l, navel_l, chest_l, head_h, m)
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
        
        # y_crotch は歩行スウィング成分を除いた基準角度で計算する。
        # 歩行フェーズ込みの leg_*_angle を使うと腰が上下にブレて
        # 「滑るように見える」バグが発生するため。
        var base_leg_rad = base_leg * PI / 180.0
        var dy_base = thigh_l * cos(base_leg_rad) + shin_l * cos(base_leg_rad + knee_l)
        y_crotch = -dy_base
    else:
        var stress_pose: float = stress_ratio * (0.35 if is_walking else 1.0)
        waist_angle = 0.20 * stress_pose
        arm_l_angle += 8.0 * stress_pose
        arm_r_angle += 8.0 * stress_pose

    var cx = 0.0
    var cy = y_crotch
    
    var navel_ang = waist_angle * 0.5
    var navel_x = cx + navel_l * sin(navel_ang)
    var navel_y = cy - navel_l * cos(navel_ang) # へそ
    
    var sx = navel_x + chest_l * sin(waist_angle)
    var sy = navel_y - chest_l * cos(waist_angle) # 肩中心
    
    var nx = sx + 2.0 * (m["neck"] * p) * sin(waist_angle)
    var ny = sy - 2.0 * (m["neck"] * p) * cos(waist_angle) # 顎下
    
    var hx = nx + (head_h / 2.0) * sin(waist_angle)
    var hy = ny - (head_h / 2.0) * cos(waist_angle) # 頭中心

    # 正面・背面ビュー用: 背骨のX座標は中心(cx)に固定、Yのみ腰曲げで圧縮
    var front_navel_x = cx
    var front_navel_y = cy - navel_l * cos(navel_ang)
    var front_sx = cx
    var front_sy = front_navel_y - chest_l * cos(waist_angle)
    var front_nx = cx
    var front_ny = front_sy - 2.0 * (m["neck"] * p) * cos(waist_angle)
    var front_hx = cx
    var front_hy = front_ny - (head_h / 2.0) * cos(waist_angle * 0.5)

    # 腰/骨盤（パンツやスカートのライン。下から20%付近）
    var hip_l = (m["arm"] * 0.20) * p
    var hip_ang = waist_angle * 0.25
    var hip_x = cx + hip_l * sin(hip_ang)
    var hip_y = cy - hip_l * cos(hip_ang)
    var front_hip_x = cx
    var front_hip_y = cy - hip_l * cos(hip_ang)

    return {
        "leg_l_angle": leg_l_angle,
        "leg_r_angle": leg_r_angle,
        "arm_l_angle": arm_l_angle,
        "arm_r_angle": arm_r_angle,
        "knee_l": knee_l,
        "knee_r": knee_r,
        "waist_angle": waist_angle, # 胴体の曲がり角度
        "y_crotch": y_crotch,
        "head_h": head_h,
        "navel_l": navel_l,
        "chest_l": chest_l,
        "thigh_l": thigh_l,
        "shin_l": shin_l,
        "cx": cx, "cy": cy,
        "navel_x": navel_x, "navel_y": navel_y,
        "hip_x": hip_x, "hip_y": hip_y,
        "sx": sx, "sy": sy,
        "nx": nx, "ny": ny,
        "hx": hx, "hy": hy,
        "front_navel_x": front_navel_x, "front_navel_y": front_navel_y,
        "front_hip_x": front_hip_x, "front_hip_y": front_hip_y,
        "front_sx": front_sx, "front_sy": front_sy,
        "front_nx": front_nx, "front_ny": front_ny,
        "front_hx": front_hx, "front_hy": front_hy,
        "stress_ratio": stress_ratio
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

# 現在の visual_height_cm から屈み深さ l_fac を逆算する
# l_fac = 0.0: 直立 / l_fac > 0: 屈み深さ
# walk_phase の速度補正に使う用途向け
static func get_l_fac(visual_height_cm: float, m: Dictionary, p: float) -> float:
    if m.is_empty() or visual_height_cm >= float(m.get("height", 0.0)) - 0.1:
        return 0.0
    var thigh_l = (m["leg"] * 0.55) * p
    var shin_l  = (m["leg"] * 0.45) * p
    var navel_l = (m["arm"] * 0.40) * p
    var chest_l = (m["arm"] * 0.60) * p
    var head_h  = m["head"] * p
    var target_px = visual_height_cm * p
    var min_t = 0.0
    var max_t = 2.0
    for _i in range(15):
        var mid_t = (min_t + max_t) / 2.0
        var hp = _eval_crouch_height(mid_t, p, thigh_l, shin_l, navel_l, chest_l, head_h, m)
        if hp > target_px: min_t = mid_t
        else: max_t = mid_t
    return _get_crouch_params((min_t + max_t) / 2.0)["l"]

static func get_crouch_stride_ratio(visual_height_cm: float, m: Dictionary, p: float) -> float:
    if m.is_empty():
        return 1.0
    var body_height = float(m.get("height", 0.0))
    if visual_height_cm >= body_height - 0.1:
        return 1.0

    var thigh_l = float(m["leg"]) * 0.55 * p
    var shin_l = float(m["leg"]) * 0.45 * p
    var foot_h = body_height * p / 20.0
    var shin_draw = maxf(shin_l - foot_h, 0.0)
    var normal_stride = thigh_l + shin_draw * cos(0.1)
    if normal_stride <= 0.0:
        return 1.0

    var l_fac = get_l_fac(visual_height_cm, m, p)
    var base_leg_rad = deg_to_rad(-100.0 * l_fac)
    var knee_rad = PI * 0.7 * l_fac
    var crouch_stride = thigh_l * cos(base_leg_rad) + shin_draw * cos(base_leg_rad + knee_rad)
    return clampf(crouch_stride / normal_stride, 0.0, 1.0)

# 各関節の終点座標を計算するヘルパー
static func rotated_point(px: float, py: float, length: float, rad: float) -> Vector2:
    return Vector2(px + cos(rad) * length, py + sin(rad) * length)
