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
var visual_height_cm: float = 180.0 # 補間用の現在の高さ

# 計測データ
var m: Dictionary

# Node References
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var character_drawer: Node2D = $CharacterDrawer

# 物理センサー (Auto-Crouch用)
# 配列として持たせ、前方の複数の高さをチェックする
var sensors: Array = []

func _ready() -> void:
    update_measurements()

func update_measurements() -> void:
    # Globalオートロードが設定されていれば取得
    if has_node("/root/Global"):
        var global = get_node("/root/Global")
        m = global.get_body_measurements()
        CM_TO_PX = global.CM_TO_PX
        visual_height_cm = m["height"]
    else:
        # フォールバック (とりあえず180cm女性)
        m = _mock_measurements()
        visual_height_cm = m["height"] # Initialize for fallback too

    # 古いセンサーを破棄
    for s in sensors:
        s.queue_free()
    sensors.clear()

    _setup_sensors()
    _update_collision()
    
    # 描画更新
    if character_drawer:
        character_drawer.queue_redraw()

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
    _update_visual_height(delta)
    _update_collision()
    move_and_slide()
    character_drawer.queue_redraw() # 毎フレーム再描画

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
    var heights_cm = [m["landmarks"]["top"], m["landmarks"]["eye"], m["landmarks"]["shoulder"], m["height"] * 0.75]
    
    for h_cm in heights_cm:
        var ray = RayCast2D.new()
        # 自分自身の足元を0とした時のY座標 (Godotは下が正なのでマイナス)
        ray.position = Vector2(0, -h_cm * CM_TO_PX)
        ray.target_position = Vector2(look_ahead_px, 0)
        # 障害物はレイヤー2に配置する想定（頭上のみレイヤー2等）
        ray.collision_mask = 2 | 1
        ray.hit_from_inside = true # 薄いColliderの内部からでも拾えるように
        add_child(ray)
        sensors.append(ray)
        
    # 天井検知用レーダー (立ち上がる時用) - 上方向へ飛ばす
    var ceil_ray = RayCast2D.new()
    ceil_ray.position = Vector2(0, -m["height"] * 0.5 * CM_TO_PX)
    # 真上に向かって、身長の1.2倍くらいまでチェック
    ceil_ray.target_position = Vector2(0, -m["height"] * 0.7 * CM_TO_PX)
    ceil_ray.collision_mask = 2 | 1
    ceil_ray.hit_from_inside = true
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
            var collider = ray.get_collider()
            var obs_cm = 0.0
            
            if collider and collider.has_meta("obs_height_cm"):
                obs_cm = float(collider.get_meta("obs_height_cm"))
            else:
                var obj_y = global_position.y - hit_point.y
                obs_cm = obj_y / CM_TO_PX
                
            should_crouch = true
            if obs_cm < min_obs_h_cm:
                min_obs_h_cm = obs_cm

    if should_crouch:
        pose = "crouch"
        # めり込み防止のため8cm余裕を持たせる
        target_crouch_cm = min_obs_h_cm - 8.0
    else:
        # 天井が塞がっていなければ立つ
        sensors[4].force_raycast_update() # ceiling
        if not sensors[4].is_colliding() and not Input.is_key_pressed(KEY_S):
            pose = "stand"
            target_crouch_cm = -1.0

func _is_ceiling_blocked() -> bool:
    sensors[4].force_raycast_update()
    return sensors[4].is_colliding()

func _update_visual_height(delta: float):
    var target_h_cm = m["height"]
    
    if pose == "squat": target_h_cm *= 0.65
    elif pose == "sit": target_h_cm *= 0.55
    elif pose == "chair_sit": target_h_cm = 45.0 + m["height"] * 0.55
    elif pose == "crouch":
        if target_crouch_cm > 0:
            target_h_cm = target_crouch_cm
        else:
            target_h_cm *= 0.8
            
    # 補間の速さ (15.0 くらいだとヌルっとしつつキビキビ動く)
    visual_height_cm = lerp(visual_height_cm, target_h_cm, 15.0 * delta)

func _update_collision():
    # 補間された高さに基づいてコリジョンの高さを調節
    var h_px = visual_height_cm * CM_TO_PX
    var shape = collision_shape.shape as CapsuleShape2D
    if shape:
        shape.height = max(40.0, h_px)
        collision_shape.position.y = - h_px / 2.0


func _mock_measurements() -> Dictionary:
    var h = 180.0
    var ht = h / 7.5
    var n = ht * 0.22
    var leg = h * 0.48
    var arm = h - leg - ht - 2 * n
    return {
        "height": h, "head": ht, "headWidth": ht * 0.702, "neck": n,
        "shoulder": ht * 1.872, "arm": arm, "armLength": ht * 3.2, "leg": leg,
        "landmarks": {"top": h, "eye": h - ht * 0.5, "shoulder": h - ht - 2 * n}
    }
