extends CharacterBody2D

const SPEED = 250.0
const JUMP_VELOCITY = -500.0
const GRAVITY = 1200.0
var CM_TO_PX: float = 2.0 # Updated in _ready from Global

# 状態
var facing: String = "side" # "side", "front", "back"
var dir: int = 1 # 1: right, -1: left
var is_walking: bool = false
var walk_phase: float = 0.0
var walk_speed: float = 12.0 # 位相の進行速度
var pose: String = "stand" # "stand", "reach", "squat", "sit", "crouch", "chair_sit"

var auto_crouch: bool = true
var target_crouch_cm: float = -1.0

# 計測データ
var m: Dictionary

# Node References
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# 物理センサー (Auto-Crouch用)
# 配列として持たせ、前方の複数の高さをチェックする
var sensors: Array = []

func _ready() -> void:
    # Globalオートロードが設定されていれば取得
    if has_node("/root/Global"):
        var global = get_node("/root/Global")
        m = global.get_body_measurements()
        CM_TO_PX = global.CM_TO_PX
    else:
        # フォールバック (とりあえず180cm女性)
        m = _mock_measurements()

    _setup_sensors()
    _update_collision()

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y += GRAVITY * delta

    if Input.is_action_just_pressed("ui_accept") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    # キー入力によるポーズと向き
    _handle_input()

    # 移動処理
    var direction := Input.get_axis("ui_left", "ui_right")
    if direction:
        velocity.x = direction * SPEED
        dir = int(sign(direction))
        if Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down"):
            pass # 上下入力中は向きを上書きしない
        else:
            facing = "side"
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)

    is_walking = (velocity.x != 0)
    if is_walking:
        walk_phase += walk_speed * delta
    else:
        # ゆっくり基本状態(0)に戻す
        walk_phase = lerp_angle(walk_phase, 0.0, 10.0 * delta)

    _handle_auto_crouch()
    _update_collision()
    move_and_slide()
    queue_redraw() # 毎フレーム再描画

func _handle_input():
    # 上下で向き変更
    if Input.is_action_pressed("ui_up"):
        facing = "back"
    elif Input.is_action_pressed("ui_down"):
        facing = "front"

    # 数字キー等で基本ポーズ手動切り替え
    if Input.is_key_pressed(KEY_1): pose = "stand"
    elif Input.is_key_pressed(KEY_2): pose = "reach"
    elif Input.is_key_pressed(KEY_3): pose = "squat"
    elif Input.is_key_pressed(KEY_4): pose = "sit"
    elif Input.is_key_pressed(KEY_5): pose = "chair_sit"

    # 手動屈み
    if Input.is_key_pressed(KEY_S) and pose == "stand":
        pose = "crouch"
        target_crouch_cm = -1.0 # default 80%
    elif not Input.is_key_pressed(KEY_S) and pose == "crouch" and not _is_ceiling_blocked():
        pose = "stand"

func _setup_sensors():
    # 進行方向の前方 40cm に RayCast を複数配置
    var look_ahead_px: float = 40.0 * CM_TO_PX
    var heights_cm = [ m["landmarks"]["top"], m["landmarks"]["eye"], m["landmarks"]["shoulder"], m["height"] * 0.75 ]
    
    for h_cm in heights_cm:
        var ray = RayCast2D.new()
        # 自分自身の足元を0とした時のY座標 (Godotは下が正なのでマイナス)
        ray.position = Vector2(0, -h_cm * CM_TO_PX)
        ray.target_position = Vector2(look_ahead_px, 0)
        # 障害物はレイヤー2に配置する想定（頭上のみレイヤー2等）
        ray.collision_mask = 2 | 1
        add_child(ray)
        sensors.append(ray)
        
    # 天井検知用レーダー (立ち上がる時用)
    var ceil_ray = RayCast2D.new()
    ceil_ray.position = Vector2(0, -m["height"] * 0.5 * CM_TO_PX)
    ceil_ray.target_position = Vector2(0, -m["height"] * 0.55 * CM_TO_PX)
    ceil_ray.collision_mask = 2 | 1
    add_child(ceil_ray)
    sensors.append(ceil_ray) # index 4

func _handle_auto_crouch():
    if not auto_crouch: return
    if pose != "stand" and pose != "crouch": return

    # センサーの向き更新
    var look_px = 40.0 * CM_TO_PX * dir
    for i in range(4):
        sensors[i].target_position.x = look_px
        sensors[i].force_raycast_update()

    var should_crouch = false
    var min_obs_h_cm = INF

    for i in range(4):
        var ray: RayCast2D = sensors[i]
        if ray.is_colliding():
            var hit_point = ray.get_collision_point()
            # 障害物の高さを大まかに計算(地面から)
            # 修正：より正確にはRayCastのヒット位置を頼りにするが、今回はシンプルに
            # ヒットしたオブジェクトのCollider設定から拾う事も可能。
            # 今回はヒットしたY座標のワールド位置から cmを算出
            # (ここでは簡略化のため、自キャラYのワールド座標との差分)
            var obj_y = global_position.y - hit_point.y
            var obs_cm = obj_y / CM_TO_PX
            should_crouch = true
            if obs_cm < min_obs_h_cm:
                min_obs_h_cm = obs_cm

    if should_crouch:
        pose = "crouch"
        # 2cm余裕を持たせる
        target_crouch_cm = min_obs_h_cm - 2.0
    else:
        # 天井が塞がっていなければ立つ
        sensors[4].force_raycast_update() # ceiling
        if not sensors[4].is_colliding() and not Input.is_key_pressed(KEY_S):
            pose = "stand"
            target_crouch_cm = -1.0

func _is_ceiling_blocked() -> bool:
    sensors[4].force_raycast_update()
    return sensors[4].is_colliding()

func _update_collision():
    # ポーズに応じてコリジョンの高さと位置を調節
    var h_cm = m["height"]
    var current_top_cm = h_cm
    
    if pose == "squat": current_top_cm *= 0.65
    elif pose == "sit": current_top_cm *= 0.55
    elif pose == "chair_sit": current_top_cm = 45.0 + h_cm * 0.55
    elif pose == "crouch":
        if target_crouch_cm > 0: current_top_cm = target_crouch_cm
        else: current_top_cm *= 0.8
        
    var h_px = current_top_cm * CM_TO_PX
    var shape = collision_shape.shape as CapsuleShape2D
    if shape:
        shape.height = max(40.0, h_px)
        collision_shape.position.y = -h_px / 2.0

# ---------------------------------------------------------
# フルプロシージャル・スケルタル描画 (_draw)
# ---------------------------------------------------------

func _draw() -> void:
    # 描画系の変数
    var p = CM_TO_PX
    var leg_l_angle = 0.0
    var leg_r_angle = 0.0
    var arm_l_angle = 0.0
    var arm_r_angle = 0.0
    var knee_l = 0.1
    var knee_r = 0.1
    var waist_angle = 0.0

    # 歩行波
    var walk_amp = 12.0 if is_walking else 0.0
    leg_l_angle = walk_amp * sin(walk_phase)
    leg_r_angle = walk_amp * sin(walk_phase + PI)
    arm_l_angle = -walk_amp * 0.6 * sin(walk_phase)
    arm_r_angle = -walk_amp * 0.6 * sin(walk_phase + PI)

    var y_crotch = -m["leg"] * p
    var head_h = m["head"] * p
    var waist_l = (m["arm"] * 0.45) * p
    var chest_l = (m["arm"] * 0.55) * p
    var thigh_l = (m["leg"] * 0.55) * p
    var shin_l = (m["leg"] * 0.45) * p
    
    # Crouch時の二分探索ロジック
    if pose == "crouch":
        var target_cm = target_crouch_cm
        if target_cm <= 0: target_cm = m["height"] * 0.8
        var target_px = target_cm * p
        
        var min_t = 0.0
        var max_t = 2.0
        var best_t = 0.0
        
        # 二分探索で t(0~2) を求める簡略版
        for i in range(15):
            var mid_t = (min_t + max_t) / 2.0
            var hp = _eval_crouch_height(mid_t, p, thigh_l, shin_l, waist_l, chest_l, head_h)
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
        
        # IKによるy_crotch計算
        var dy1 = thigh_l * cos(leg_l_angle * PI/180) + shin_l * cos(leg_l_angle * PI/180 + knee_l)
        var dy2 = thigh_l * cos(leg_r_angle * PI/180) + shin_l * cos(leg_r_angle * PI/180 + knee_r)
        y_crotch = -max(dy1, dy2)
    elif pose == "squat":
        waist_angle = 0.5
        leg_l_angle = -100
        leg_r_angle = -100
        knee_l = PI * 0.7
        knee_r = PI * 0.7
        arm_l_angle = 30
        arm_r_angle = 30
        var rad = leg_l_angle * PI/180
        var dy = thigh_l * cos(rad) + shin_l * cos(rad + knee_l)
        y_crotch = -dy
        
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
    
    var nx = sx + 2.0*(m["neck"]*p) * sin(waist_angle)
    var ny = sy - 2.0*(m["neck"]*p) * cos(waist_angle)
    
    var hx = nx + (head_h/2) * sin(waist_angle)
    var hy = ny - (head_h/2) * cos(waist_angle)

    # Transform設定
    var t_orig = get_canvas_transform()
    if flip:
        draw_set_transform(Vector2.ZERO, 0, Vector2(-1, 1))

    # 奥の足
    var p_thigh_l = _rotated_point(cx, cy, thigh_l, leg_l_angle * PI/180 + PI/2)
    var p_shin_l = _rotated_point(p_thigh_l.x, p_thigh_l.y, shin_l, leg_l_angle * PI/180 + PI/2 + knee_l)
    draw_line(Vector2(cx, cy), p_thigh_l, Color("#d0a279"), thick)
    draw_line(p_thigh_l, p_shin_l, Color("#d0a279"), thick)

    # 手前の足
    var p_thigh_r = _rotated_point(cx, cy, thigh_l, leg_r_angle * PI/180 + PI/2)
    var p_shin_r = _rotated_point(p_thigh_r.x, p_thigh_r.y, shin_l, leg_r_angle * PI/180 + PI/2 + knee_r)
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
    var p_elb = _rotated_point(sx, sy, u_arm, arm_r_angle * PI/180 + waist_angle + PI/2)
    var p_hand = _rotated_point(p_elb.x, p_elb.y, l_arm, arm_r_angle * PI/180 + waist_angle + PI/2 - 0.1)
    draw_line(Vector2(sx, sy), p_elb, color, thick)
    draw_line(p_elb, p_hand, color, thick)

    # 頭
    draw_circle(Vector2(hx, hy), head_h/2, Color("#f5deb3"))

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

func _eval_crouch_height(t: float, p: float, th: float, sh: float, wl: float, cl: float, hh: float) -> float:
    var params = _get_crouch_params(t)
    var w = params["w"]
    var l = params["l"]
    
    var knee = PI * 0.7 * l
    var base_leg = -100.0 * l * PI/180
    var dy = th * cos(base_leg) + sh * cos(base_leg + knee)
    var crotch_y = (th+sh) - dy
    
    var tor_h = wl * cos(w*0.5) + cl * cos(w)
    var neck_h = (m["neck"]*p*2.0) * cos(w)
    var hd_radius = hh * 0.5 * cos(w*0.5)
    
    return (th+sh) - crotch_y + tor_h + neck_h + hd_radius

func _rotated_point(px: float, py: float, len: float, rad: float) -> Vector2:
    return Vector2(px + cos(rad)*len, py + sin(rad)*len)

func _mock_measurements() -> Dictionary:
    var h = 180.0
    var ht = h / 7.5
    var n = ht * 0.22
    var leg = h * 0.48
    var arm = h - leg - ht - 2*n
    return {
        "height": h, "head": ht, "neck": n, "arm": arm, "armLength": ht*2.7, "leg": leg,
        "landmarks": { "top": h, "eye": h - ht*0.5, "shoulder": h-ht-2*n }
    }
