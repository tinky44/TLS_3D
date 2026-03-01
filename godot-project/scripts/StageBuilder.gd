extends RefCounted
class_name StageBuilder

const STAGES = {
    "room": {
        "name": "🏠 家の中",
        "width": 2000,
        "ceiling_height": 240,
        "obstacles": [
            {"id": "door_left", "x": 80, "x2": 160, "height": 200, "type": "overhead"},
            {"id": "side_door", "x": 1150, "x2": 1180, "height": 200, "type": "overhead"},
            {"id": "washstand", "x": 1250, "x2": 1350, "height": 180, "type": "background"},
            {"id": "shower", "x": 1450, "x2": 1550, "height": 190, "type": "background"},
            {"id": "door_right", "x": 1840, "x2": 1920, "height": 200, "type": "overhead"},
            {"id": "range_hood", "x": 490, "x2": 540, "height": 180, "type": "overhead"},
        ]
    },
    "train": {
        "name": "🚃 電車の中",
        "width": 2000,
        "ceiling_height": 230,
        "obstacles": [
            {"id": "door_1", "x": 50, "x2": 230, "height": 185, "type": "overhead"},
            {"id": "door_2", "x": 580, "x2": 760, "height": 185, "type": "overhead"},
            {"id": "door_3", "x": 1220, "x2": 1400, "height": 185, "type": "overhead"},
            {"id": "door_4", "x": 1770, "x2": 1950, "height": 185, "type": "overhead"},
            {"id": "strap_1", "x": 350, "x2": 400, "height": 163, "type": "background"},
            {"id": "strap_2", "x": 950, "x2": 1000, "height": 163, "type": "background"},
            {"id": "strap_3", "x": 1550, "x2": 1600, "height": 163, "type": "background"}
        ]
    },
    "outdoor": {
        "name": "🏙️ 屋外",
        "width": 5000,
        "ceiling_height": null,
        "obstacles": [
            {"id": "public_phone", "x": 300, "x2": 345, "height": 200, "type": "background"},
            {"id": "pedestrian_signal", "x": 700, "x2": 725, "height": 300, "type": "background"},
            {"id": "streetlight", "x": 1200, "x2": 1225, "height": 500, "type": "background"},
            {"id": "traffic_signal", "x": 1800, "x2": 1825, "height": 500, "type": "background"},
            {"id": "utility_pole", "x": 2500, "x2": 2525, "height": 1000, "type": "background"},
            {"id": "footbridge", "x": 3100, "x2": 3500, "height": 500, "type": "overhead"},
            {"id": "house_2f", "x": 3800, "x2": 4050, "height": 700, "type": "background"},
            {"id": "house_3f", "x": 4200, "x2": 4500, "height": 900, "type": "background"},
            {"id": "vending_machine", "x": 4700, "x2": 4780, "height": 183, "type": "ground"},
            {"id": "curve_mirror", "x": 4850, "x2": 4900, "height": 300, "type": "background"}
        ]
    },
    "school": {
        "name": "🏫 学校",
        "width": 2500,
        "ceiling_height": 300,
        "obstacles": [
            {"id": "school_door_1", "x": 100, "x2": 240, "height": 200, "type": "overhead"},
            {"id": "blackboard", "x": 400, "x2": 800, "height": 210, "type": "background"},
            {"id": "desk_1", "x": 1000, "x2": 1060, "height": 70, "type": "ground"},
            {"id": "desk_2", "x": 1150, "x2": 1210, "height": 70, "type": "ground"},
            {"id": "teacher_desk", "x": 2000, "x2": 2150, "height": 100, "type": "ground"}
        ]
    }
}

static func build_stage(stage_id: String, parent_node: Node2D, cm_to_px: float) -> void:
    if not STAGES.has(stage_id):
        push_error("Stage not found: " + stage_id)
        return
        
    var stage_data = STAGES[stage_id]
    
    # 既存の障害物を消去
    for child in parent_node.get_children():
        if child.has_meta("is_stage_obj"):
            child.queue_free()
            
    # 床の生成
    var floor_body = StaticBody2D.new()
    floor_body.set_meta("is_stage_obj", true)
    
    var floor_shape = CollisionShape2D.new()
    var rect = RectangleShape2D.new()
    rect.size = Vector2(stage_data["width"] * cm_to_px, 100)
    floor_shape.shape = rect
    floor_shape.position = Vector2(stage_data["width"] * cm_to_px / 2.0, 50)
    floor_body.add_child(floor_shape)
    
    var floor_rect = ColorRect.new()
    floor_rect.color = Color(0.2, 0.2, 0.2)
    floor_rect.position = Vector2(0, 0)
    floor_rect.size = Vector2(stage_data["width"] * cm_to_px, 100)
    floor_body.add_child(floor_rect)
    
    parent_node.add_child(floor_body)
    
    # 障害物の生成
    for obs in stage_data["obstacles"]:
        _build_obstacle(obs, parent_node, cm_to_px)

static func _build_obstacle(obs: Dictionary, parent: Node2D, cm_to_px: float) -> void:
    var w_cm = obs["x2"] - obs["x"]
    var w_px = w_cm * cm_to_px
    var h_cm = obs["height"]
    var h_px = h_cm * cm_to_px
    
    var type = obs["type"]
    var node: Node2D
    
    if type == "overhead" or type == "ground":
        var body = StaticBody2D.new()
        
        # collision layer 設定 (ground=1, overhead=2)
        if type == "ground":
            body.collision_layer = 1
        else:
            body.collision_layer = 2
            
        var shape = CollisionShape2D.new()
        var rect = RectangleShape2D.new()
        
        if type == "ground":
            # 地面からh_cmまでのブロック
            rect.size = Vector2(w_px, h_px)
            shape.position = Vector2(obs["x"] * cm_to_px + w_px / 2.0, -h_px / 2.0)
        else: # overhead
            # 高いところにあるブロック（厚みは20cmと仮定）
            var thick_cm = 20.0
            rect.size = Vector2(w_px, thick_cm * cm_to_px)
            shape.position = Vector2(obs["x"] * cm_to_px + w_px / 2.0, -h_px - (thick_cm * cm_to_px / 2.0))
            
        shape.shape = rect
        body.add_child(shape)
        node = body
    else: # background
        var area = Area2D.new()
        area.position = Vector2(0, 0)
        node = area
        
    node.set_meta("is_stage_obj", true)
    node.set_meta("obs_height_cm", h_cm)
    
    # 描画の準備
    var main_color: Color
    var y_pos: float
    var h_draw_px: float

    if type == "overhead":
        main_color = Color(0.8, 0.4, 0.4, 0.8) # 赤っぽく
        var thick_cm = 20.0
        y_pos = - h_px - thick_cm * cm_to_px
        h_draw_px = thick_cm * cm_to_px
        
        # ドアフレーム（柱）を描画して、空中に浮かないようにする
        var pillar_w = 12.0
        var p_left = ColorRect.new()
        p_left.color = Color(0.6, 0.3, 0.3, 0.8)
        p_left.position = Vector2(obs["x"] * cm_to_px, -h_px)
        p_left.size = Vector2(pillar_w, h_px)
        node.add_child(p_left)

        var p_right = ColorRect.new()
        p_right.color = Color(0.6, 0.3, 0.3, 0.8)
        p_right.position = Vector2(obs["x2"] * cm_to_px - pillar_w, -h_px)
        p_right.size = Vector2(pillar_w, h_px)
        node.add_child(p_right)
        
    elif type == "ground":
        main_color = Color(0.4, 0.8, 0.4, 0.8) # 緑っぽく
        y_pos = - h_px
        h_draw_px = h_px
    else: # background
        main_color = Color(0.5, 0.6, 0.9, 0.4) # 薄い青
        y_pos = - h_px
        h_draw_px = h_px

    # メインの四角形（梁や本体）
    var cr = ColorRect.new()
    cr.color = main_color
    cr.position = Vector2(obs["x"] * cm_to_px, y_pos)
    cr.size = Vector2(w_px, h_draw_px)
    node.add_child(cr)
    
    # 基準となる高さのライン（黄色線）
    var line = Line2D.new()
    line.add_point(Vector2(obs["x"] * cm_to_px, -h_px))
    line.add_point(Vector2(obs["x2"] * cm_to_px, -h_px))
    line.width = 3.0
    line.default_color = Color(1.0, 1.0, 0.2, 0.9) # やや明るい黄色
    node.add_child(line)

    # ラベル（名前と高さ）
    var label = Label.new()
    var display_name = str(obs["id"]).capitalize()
    label.text = "%s\n%.0f cm" % [display_name, h_cm]
    label.add_theme_color_override("font_color", Color.WHITE)
    label.add_theme_color_override("font_outline_color", Color.BLACK)
    label.add_theme_constant_override("outline_size", 4)
    label.add_theme_font_size_override("font_size", 14)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    
    # 表示位置の調整
    label.size = Vector2(w_px, 40)
    label.position = Vector2(obs["x"] * cm_to_px, -h_px - 45)
    
    node.add_child(label)
    parent.add_child(node)
