extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980.0

# Player height definitions (in pixels)
const STAND_HEIGHT = 160.0
const CROUCH_HEIGHT = 80.0
const CROUCH_SPEED = 0.2 # Tween duration

# Node references
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var head_forward_cast: RayCast2D = $HeadForwardCast
@onready var head_mid_cast: RayCast2D = $HeadMidCast
@onready var ceiling_cast: RayCast2D = $CeilingCast

# State
var is_crouching: bool = false
var auto_crouch_enabled: bool = true
var height_tween: Tween

func _ready() -> void:
    # Set up initial shapes
    pass

func _physics_process(delta: float) -> void:
    # Add the gravity.
    if not is_on_floor():
        velocity.y += GRAVITY * delta

    # Handle Jump.
    if Input.is_action_just_pressed("ui_accept") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    # Handle Movement.
    var direction := Input.get_axis("ui_left", "ui_right")
    if direction:
        velocity.x = direction * SPEED
        # Update Cast direction based on facing
        head_forward_cast.target_position.x = 50 * sign(direction)
        head_mid_cast.target_position.x = 50 * sign(direction)
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)

    _handle_crouch_logic(delta)

    move_and_slide()

func _handle_crouch_logic(_delta: float) -> void:
    # Manual crouch request
    var wants_to_crouch = Input.is_action_pressed("ui_down")
    
    # Auto crouch detection
    if auto_crouch_enabled and not wants_to_crouch:
        if head_forward_cast.is_colliding() or head_mid_cast.is_colliding():
            wants_to_crouch = true
    
    # Check if we are physically blocked from standing up
    var blocked_above = ceiling_cast.is_colliding()
    
    # Determine target height
    var target_height = STAND_HEIGHT
    if wants_to_crouch or (is_crouching and blocked_above):
        target_height = CROUCH_HEIGHT
    
    if target_height == CROUCH_HEIGHT and not is_crouching:
        _set_crouch_state(true, target_height)
    elif target_height == STAND_HEIGHT and is_crouching:
        _set_crouch_state(false, target_height)

func _set_crouch_state(crouch: bool, target_height: float) -> void:
    is_crouching = crouch
    
    if height_tween and height_tween.is_valid():
        height_tween.kill()
        
    height_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
    
    # Adjust CollisionShape height (CapsuleShape2D)
    var shape = collision_shape.shape as CapsuleShape2D
    height_tween.tween_property(shape, "height", target_height, CROUCH_SPEED)
    
    # Adjust CollisionShape position (keep anchored to ground)
    # y=0 is feet, so position is -height/2
    var target_y = -target_height / 2.0
    height_tween.tween_property(collision_shape, "position:y", target_y, CROUCH_SPEED)
    
    # Adjust visuals (Sprite scale and position)
    var scale_y = target_height / STAND_HEIGHT
    height_tween.tween_property(sprite, "scale:y", scale_y, CROUCH_SPEED)
    height_tween.tween_property(sprite, "position:y", target_y, CROUCH_SPEED)
    
    # Adjust RayCast positions
    # CeilingCast should originate from the top of the character
    height_tween.tween_property(ceiling_cast, "position:y", -target_height + 10, CROUCH_SPEED)
    # HeadForwardCast needs to stay near the top
    height_tween.tween_property(head_forward_cast, "position:y", -target_height + 10, CROUCH_SPEED)
    # HeadMidCast stays 40 pixels below HeadForwardCast
    height_tween.tween_property(head_mid_cast, "position:y", -target_height + 50, CROUCH_SPEED)
