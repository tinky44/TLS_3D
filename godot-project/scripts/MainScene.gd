extends Node2D

const ROOM_STAGE = {
    "name": "家の中",
    "width": 2000.0,
    "ceilingHeight": 240.0,
    "obstacles": [
        {"id": "door_left", "x": 80.0, "x2": 160.0, "height": 200.0, "type": "overhead"},
        {"id": "side_door", "x": 1150.0, "x2": 1180.0, "height": 200.0, "type": "overhead"},
        {"id": "washstand", "x": 1250.0, "x2": 1350.0, "height": 180.0, "type": "background"},
        {"id": "door_right", "x": 1840.0, "x2": 1920.0, "height": 200.0, "type": "overhead"},
        {"id": "range_hood", "x": 490.0, "x2": 540.0, "height": 180.0, "type": "overhead"}
    ]
}

var floor_y: float = 600.0

@onready var player: Node = $Player

func _ready() -> void:
    # 古いテスト用障害物(Floor, ObstacleHigh, ObstacleLow)があれば削除
    if has_node("Floor"): get_node("Floor").queue_free()
    if has_node("ObstacleHigh"): get_node("ObstacleHigh").queue_free()
    if has_node("ObstacleLow"): get_node("ObstacleLow").queue_free()
    
    # Globalがあるはず
    var global = get_node("/root/Global")
    var p = global.CM_TO_PX if global else 2.0
    
    _build_stage(ROOM_STAGE, p)

# 動的にステージを生成する
func _build_stage(stage_def: Dictionary, p: float):
    # 床
    var floor_body = StaticBody2D.new()
    floor_body.collision_layer = 3 # 1 and 2
    var floor_shape = CollisionShape2D.new()
    var floor_rect = RectangleShape2D.new()
    floor_rect.size = Vector2(stage_def.width * p + 1000, 40)
    floor_shape.shape = floor_rect
    floor_shape.position = Vector2((stage_def.width * p)/2, floor_y + 20)
    floor_body.add_child(floor_shape)
    
    # 描画用ColorRect
    var f_vis = ColorRect.new()
    f_vis.color = Color("#ffebcd")
    f_vis.size = Vector2(stage_def.width * p, 40)
    f_vis.position = Vector2(0, floor_y)
    floor_body.add_child(f_vis)
    add_child(floor_body)
    
    # 天井
    if stage_def.ceilingHeight > 0:
        var c_body = StaticBody2D.new()
        c_body.collision_layer = 3
        var c_shape = CollisionShape2D.new()
        var c_rect = RectangleShape2D.new()
        c_rect.size = Vector2(stage_def.width * p, 40)
        c_shape.shape = c_rect
        var ceil_y = floor_y - stage_def.ceilingHeight * p
        c_shape.position = Vector2((stage_def.width * p)/2, ceil_y - 20)
        c_body.add_child(c_shape)
        
        var c_vis = ColorRect.new()
        c_vis.color = Color("#ffefd5")
        c_vis.size = Vector2(stage_def.width * p, 40)
        c_vis.position = Vector2(0, ceil_y - 40)
        c_body.add_child(c_vis)
        add_child(c_body)
        
    # 左の壁
    var l_wall = StaticBody2D.new()
    l_wall.collision_layer = 3
    var l_shape = CollisionShape2D.new()
    var l_rect = RectangleShape2D.new()
    l_rect.size = Vector2(40, 2000)
    l_shape.shape = l_rect
    l_shape.position = Vector2(-20, floor_y - 1000)
    l_wall.add_child(l_shape)
    add_child(l_wall)
    
    # 右の壁
    var r_wall = StaticBody2D.new()
    r_wall.collision_layer = 3
    var r_shape = CollisionShape2D.new()
    var r_rect = RectangleShape2D.new()
    r_rect.size = Vector2(40, 2000)
    r_shape.shape = r_rect
    r_shape.position = Vector2(stage_def.width * p + 20, floor_y - 1000)
    r_wall.add_child(r_shape)
    add_child(r_wall)

    # 障害物
    var cm_ceiling = stage_def.ceilingHeight * p
    for obs in stage_def.obstacles:
        if obs.type == "overhead":
            var o_body = StaticBody2D.new()
            o_body.collision_layer = 3
            var o_shape = CollisionShape2D.new()
            var o_rect = RectangleShape2D.new()
            
            var w = (obs.x2 - obs.x) * p
            var h = cm_ceiling - (obs.height * p) # 天井から下に伸びる長さ
            
            o_rect.size = Vector2(w, h)
            o_shape.shape = o_rect
            # 中央位置
            var cx = obs.x * p + w / 2.0
            var cy = floor_y - cm_ceiling + h / 2.0
            o_shape.position = Vector2(cx, cy)
            
            o_body.add_child(o_shape)
            
            var o_vis = ColorRect.new()
            o_vis.color = Color("#8b4513") if "door" in obs.id else Color("#555555")
            o_vis.size = Vector2(w, h)
            o_vis.position = Vector2(obs.x * p, floor_y - cm_ceiling)
            o_body.add_child(o_vis)
            
            # Label
            var lbl = Label.new()
            lbl.text = "%scmh" % [obs.height]
            lbl.position = Vector2(obs.x * p, floor_y - obs.height * p - 25)
            lbl.add_theme_color_override("font_color", Color.BLACK)
            o_body.add_child(lbl)
            
            add_child(o_body)
