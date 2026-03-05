extends RefCounted
class_name StageBuilder

const STAGES = {
    "room": {
        "name": "家の中",
        "width": 2000,
        "ceiling_height": 240,
        "obstacles": [
            {"id": "door_left", "x": 80, "x2": 160, "height": 200, "type": "overhead"},
            {"id": "ceiling_light", "x": 280, "x2": 380, "height": 215, "type": "overhead"},
            {"id": "kitchen_counter", "x": 450, "x2": 600, "height": 80, "type": "ground"},
            {"id": "range_hood", "x": 490, "x2": 560, "height": 180, "type": "overhead"},
            {"id": "wall_clock", "x": 650, "x2": 690, "height": 200, "type": "background"},
            {"id": "chair", "x": 700, "x2": 740, "height": 45, "type": "ground"},
            {"id": "table", "x": 760, "x2": 900, "height": 70, "type": "ground"},
            {"id": "window_1", "x": 920, "x2": 1050, "height": 160, "type": "background"},
            {"id": "poster", "x": 1080, "x2": 1130, "height": 170, "type": "background"},
            {"id": "side_door", "x": 1150, "x2": 1180, "height": 200, "type": "overhead"},
            {"id": "washstand", "x": 1250, "x2": 1350, "height": 180, "type": "background"},
            {"id": "shower", "x": 1450, "x2": 1550, "height": 190, "type": "background"},
            {"id": "door_right", "x": 1840, "x2": 1920, "height": 200, "type": "overhead"}
        ]
    },
    "train": {
        "name": "電車の中",
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
        "name": "屋外",
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
        "name": "学校",
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
    
    # 床の描画 (フローリング風の少し明るい茶色)
    var floor_rect = ColorRect.new()
    if stage_id == "room":
        floor_rect.color = Color(0.65, 0.52, 0.40) # フローリング風
    else:
        floor_rect.color = Color(0.2, 0.2, 0.2)
    floor_rect.position = Vector2(0, 0)
    floor_rect.size = Vector2(stage_data["width"] * cm_to_px, 100)
    floor_body.add_child(floor_rect)
    
    parent_node.add_child(floor_body)

    # 部屋（room）の場合、背景を壁紙風にする
    if stage_id == "room" and stage_data.get("ceiling_height") != null:
        var wall_bg = Node2D.new()
        wall_bg.set_meta("is_stage_obj", true)
        wall_bg.z_index = -5 # 一番奥に配置する
        
        var ceil_h_px = stage_data["ceiling_height"] * cm_to_px
        var stage_w_px = stage_data["width"] * cm_to_px
        
        # 壁紙 上半分（薄いクリーム色）
        var wall_top = ColorRect.new()
        wall_top.color = Color(0.96, 0.94, 0.90)
        wall_top.position = Vector2(0, -ceil_h_px)
        wall_top.size = Vector2(stage_w_px, ceil_h_px * 0.5)
        wall_bg.add_child(wall_top)
        
        # 壁紙 下半分（やや暖かみのあるベージュ、ツートンカラー）
        var wall_btm = ColorRect.new()
        wall_btm.color = Color(0.92, 0.88, 0.82)
        wall_btm.position = Vector2(0, -ceil_h_px * 0.5)
        wall_btm.size = Vector2(stage_w_px, ceil_h_px * 0.5)
        wall_bg.add_child(wall_btm)
        
        # 見切り材（上下の壁紙の境界の帯）
        var molding = ColorRect.new()
        molding.color = Color(0.85, 0.78, 0.70)
        molding.position = Vector2(0, -ceil_h_px * 0.5 - 4)
        molding.size = Vector2(stage_w_px, 8)
        wall_bg.add_child(molding)
        
        # 巾木（床と壁の境界の板）
        var baseboard = ColorRect.new()
        baseboard.color = Color(0.35, 0.24, 0.18) # 暗めの茶色
        baseboard.position = Vector2(0, -15)
        baseboard.size = Vector2(stage_w_px, 15)
        wall_bg.add_child(baseboard)
        
        parent_node.add_child(wall_bg)

    # 天井の生成
    if stage_data.get("ceiling_height") != null:
        var ceil_h_px = stage_data["ceiling_height"] * cm_to_px
        var ceil_thick_px = 20.0 * cm_to_px
        var ceiling_body = StaticBody2D.new()
        ceiling_body.set_meta("is_stage_obj", true)
        ceiling_body.collision_layer = 4 # センサー(layer2)に検知されないよう別レイヤー
        ceiling_body.z_index = -1 # ラベル・コメントより奥に描画する
        var ceil_col_shape = CollisionShape2D.new()
        var ceil_col_rect = RectangleShape2D.new()
        ceil_col_rect.size = Vector2(stage_data["width"] * cm_to_px, ceil_thick_px)
        ceil_col_shape.shape = ceil_col_rect
        ceil_col_shape.position = Vector2(stage_data["width"] * cm_to_px / 2.0, -ceil_h_px - ceil_thick_px / 2.0)
        ceiling_body.add_child(ceil_col_shape)
        var ceil_visual = ColorRect.new()
        ceil_visual.color = Color(0.85, 0.82, 0.78)
        ceil_visual.position = Vector2(0, -ceil_h_px - ceil_thick_px)
        ceil_visual.size = Vector2(stage_data["width"] * cm_to_px, ceil_thick_px)
        ceiling_body.add_child(ceil_visual)
        parent_node.add_child(ceiling_body)

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
    
    var global = parent.get_node_or_null("/root/Global")
    var enable_ground_col = global.enable_ground_collision if global else false
    
    var is_solid = false
    if type == "overhead":
        is_solid = true
    elif type == "ground" and enable_ground_col:
        is_solid = true
    
    if is_solid:
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
            # CollisionShapeはすり抜け防止のためかなり分厚くする(100cm)
            var coll_thick_cm = 100.0
            rect.size = Vector2(w_px, coll_thick_cm * cm_to_px)
            shape.position = Vector2(obs["x"] * cm_to_px + w_px / 2.0, -h_px - (coll_thick_cm * cm_to_px / 2.0))
            
        shape.shape = rect
        body.add_child(shape)
        node = body
    else: # background や 衝突無効のground
        var area = Area2D.new()
        area.position = Vector2(0, 0)
        node = area
        
    node.set_meta("is_stage_obj", true)
    
    # ソリッドではない背景オブジェクトはキャラクター(-1か0)の奥に描画する
    if not is_solid:
        node.z_index = -1
    node.set_meta("obs_id", obs["id"])
    node.set_meta("obs_height_cm", h_cm)
    node.set_meta("obs_x", obs["x"])
    node.set_meta("obs_x2", obs["x2"])
    node.set_meta("obs_type", type)
    
    # 描画の準備
    var main_color: Color
    var y_pos: float
    var h_draw_px: float

    if type == "overhead":
        main_color = Color(0.8, 0.4, 0.4, 0.8) # 赤っぽく
        var thick_cm = 20.0
        y_pos = - h_px - thick_cm * cm_to_px
        h_draw_px = thick_cm * cm_to_px
        
        # ドアの場合は別で背景側に本格的な描画を行うため、ここでは何もしない
        if "door" in obs["id"]:
            pass

        
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
    
    # ---------------------------------------------------------
    # IDに応じた装飾の追加 (ドアの取っ手、吊り革の丸、鏡の枠など)
    # ---------------------------------------------------------
    var o_id = obs["id"]
    if "door" in o_id:
        # 元の梁（上枠）の色をドアの枠色に合わせる
        cr.color = Color(0.24, 0.16, 0.12)
        
        # 本格的なドアの描画 (背景側に描画)
        # ドア全体のベース枠
        var door_frame = ColorRect.new()
        door_frame.color = Color(0.24, 0.16, 0.12) # 暗い茶色
        door_frame.position = Vector2(obs["x"] * cm_to_px, -h_px)
        door_frame.size = Vector2(w_px, h_px)
        door_frame.z_index = -1
        node.add_child(door_frame)
        
        # ドアの内側パネル
        var panel_margin = 8.0
        var door_panel = ColorRect.new()
        door_panel.color = Color(0.36, 0.25, 0.20)
        door_panel.position = door_frame.position + Vector2(panel_margin, panel_margin)
        door_panel.size = Vector2(w_px - panel_margin * 2, h_px - panel_margin * 2)
        door_panel.z_index = -1
        node.add_child(door_panel)
        
        # パネルの飾り枠（上下2段）
        var inset_margin = 12.0
        var border_color = Color(0.45, 0.32, 0.25)
        
        # 上段枠
        var top_box_h = h_px * 0.45
        var top_box = ReferenceRect.new()
        top_box.editor_only = false
        top_box.border_color = border_color
        top_box.border_width = 2.0
        top_box.position = door_panel.position + Vector2(inset_margin, inset_margin)
        top_box.size = Vector2(door_panel.size.x - inset_margin * 2, top_box_h)
        top_box.z_index = -1
        node.add_child(top_box)
        
        # 下段枠
        var btm_box_y = panel_margin + inset_margin + top_box_h + inset_margin
        var btm_box_h = h_px - btm_box_y - panel_margin - inset_margin
        var btm_box = ReferenceRect.new()
        btm_box.editor_only = false
        btm_box.border_color = border_color
        btm_box.border_width = 2.0
        btm_box.position = Vector2(door_panel.position.x + inset_margin, door_frame.position.y + btm_box_y)
        btm_box.size = Vector2(door_panel.size.x - inset_margin * 2, btm_box_h)
        btm_box.z_index = -1
        node.add_child(btm_box)
        
        # ドアノブ
        var knob_radius = 8.0
        var is_right_door = ("right" in o_id or "2" in o_id or "4" in o_id)
        var knob_cx = door_panel.position.x + (25.0 if not is_right_door else door_panel.size.x - 25.0)
        var knob_cy = - h_px * 0.5
        
        var knob_panel = Panel.new()
        var style = StyleBoxFlat.new()
        style.bg_color = Color(0.85, 0.65, 0.1) # ゴールド
        style.corner_radius_top_left = 8
        style.corner_radius_top_right = 8
        style.corner_radius_bottom_left = 8
        style.corner_radius_bottom_right = 8
        knob_panel.add_theme_stylebox_override("panel", style)
        knob_panel.position = Vector2(knob_cx - 8, knob_cy - 8)
        knob_panel.size = Vector2(16, 16)
        knob_panel.z_index = -1
        node.add_child(knob_panel)
        
    elif "strap" in o_id:
        # 吊り革の場合は、上のバーから伸びる紐と輪っかを描く
        var strap_line = Line2D.new()
        strap_line.add_point(Vector2(cr.position.x + w_px * 0.5, cr.position.y))
        strap_line.add_point(Vector2(cr.position.x + w_px * 0.5, cr.position.y + 40.0))
        strap_line.width = 4.0
        strap_line.default_color = Color(0.8, 0.8, 0.8)
        node.add_child(strap_line)
        
        # 簡易的な輪っかとして、中抜きのPolygon2DやLine2Dを使う代わりに小さい矩形を置く
        var ring = ColorRect.new()
        ring.color = Color(0.9, 0.9, 0.4)
        ring.size = Vector2(24, 24)
        ring.position = Vector2(cr.position.x + w_px * 0.5 - 12, cr.position.y + 40)
        node.add_child(ring)
        var ring_hole = ColorRect.new()
        ring_hole.color = main_color
        ring_hole.size = Vector2(14, 14)
        ring_hole.position = ring.position + Vector2(5, 5)
        node.add_child(ring_hole)

    elif "window" in o_id:
        cr.color = Color(0.85, 0.9, 0.95, 0.3) # 窓ガラスを透けるように
        
        # 窓枠（サッシ）外枠
        var frame = ReferenceRect.new()
        frame.editor_only = false
        frame.border_color = Color(0.7, 0.7, 0.75) # シルバー系
        frame.border_width = 4.0
        frame.position = cr.position
        frame.size = cr.size
        node.add_child(frame)
        
        # 窓の中央スタッド（2枚引き違い窓風）
        var center_bar = ColorRect.new()
        center_bar.color = Color(0.7, 0.7, 0.75)
        center_bar.position = Vector2(cr.position.x + w_px * 0.5 - 2, cr.position.y)
        center_bar.size = Vector2(4, h_draw_px)
        node.add_child(center_bar)
        
        # 風景（空と地面）少し透明にして窓ガラスっぽさを出す
        var sky = ColorRect.new()
        sky.color = Color(0.4, 0.7, 1.0, 0.5) # 青空
        sky.position = cr.position
        sky.size = Vector2(w_px, h_draw_px * 0.6)
        # sky.z_index = -2 # 窓枠の後ろ
        node.add_child(sky)
        
        var ground = ColorRect.new()
        ground.color = Color(0.3, 0.6, 0.3, 0.5) # 緑地
        ground.position = Vector2(cr.position.x, cr.position.y + h_draw_px * 0.6)
        ground.size = Vector2(w_px, h_draw_px * 0.4)
        node.add_child(ground)

    elif o_id == "poster":
        # ポスターの枠
        var poster_bg = ColorRect.new()
        poster_bg.color = Color(0.9, 0.9, 0.9) # 白い余白
        poster_bg.position = cr.position
        poster_bg.size = cr.size
        node.add_child(poster_bg)
        
        var poster_content = ColorRect.new()
        poster_content.color = Color(0.3, 0.6, 0.8) # 青っぽい絵
        poster_content.position = cr.position + Vector2(4, 4)
        poster_content.size = cr.size - Vector2(8, 8)
        node.add_child(poster_content)
        
        # ポスター内の適当な図形（太陽？）
        var sun = ColorRect.new()
        sun.color = Color(1.0, 0.8, 0.3)
        sun.position = poster_content.position + Vector2(10, 10)
        sun.size = Vector2(15, 15)
        node.add_child(sun)

    elif o_id == "wall_clock":
        cr.color = Color(0, 0, 0, 0) # 背景を透明に
        # 時計のベース（丸が作りにくいので角丸のパネル）
        var clock_panel = Panel.new()
        var style = StyleBoxFlat.new()
        style.bg_color = Color(0.95, 0.95, 0.95)
        style.border_color = Color(0.3, 0.3, 0.3)
        style.border_width_left = 3
        style.border_width_right = 3
        style.border_width_top = 3
        style.border_width_bottom = 3
        style.corner_radius_top_left = int(w_px / 2.0)
        style.corner_radius_top_right = int(w_px / 2.0)
        style.corner_radius_bottom_left = int(w_px / 2.0)
        style.corner_radius_bottom_right = int(w_px / 2.0)
        clock_panel.add_theme_stylebox_override("panel", style)
        # 指定高さから40cm分を下に向けて描画
        var clock_size = w_px
        clock_panel.position = cr.position
        clock_panel.size = Vector2(clock_size, clock_size)
        node.add_child(clock_panel)
        
        # 時計の針
        var cx = cr.position.x + clock_size * 0.5
        var cy = cr.position.y + clock_size * 0.5
        
        # 長針
        var min_hand = Line2D.new()
        min_hand.add_point(Vector2(cx, cy))
        min_hand.add_point(Vector2(cx, cy - clock_size * 0.35))
        min_hand.width = 3
        min_hand.default_color = Color(0.2, 0.2, 0.2)
        node.add_child(min_hand)
        
        # 短針
        var hour_hand = Line2D.new()
        hour_hand.add_point(Vector2(cx, cy))
        hour_hand.add_point(Vector2(cx + clock_size * 0.2, cy))
        hour_hand.width = 4
        hour_hand.default_color = Color(0.2, 0.2, 0.2)
        node.add_child(hour_hand)

        # 中心点
        var dot = ColorRect.new()
        dot.color = Color(0.1, 0.1, 0.1)
        dot.position = Vector2(cx - 3, cy - 3)
        dot.size = Vector2(6, 6)
        node.add_child(dot)

    elif o_id == "washstand":
        # 鏡らしく、内側を明るい水色にする
        var glass = ColorRect.new()
        glass.color = Color(0.8, 0.9, 1.0, 0.7)
        glass.size = Vector2(w_px - 20, h_draw_px - 20)
        glass.position = cr.position + Vector2(10, 10)
        node.add_child(glass)

    elif o_id == "range_hood":
        # 換気扇の吸い込み口（斜めに見えるよう下部に暗い色）
        var hole = ColorRect.new()
        hole.color = Color(0.2, 0.2, 0.2, 0.8)
        hole.size = Vector2(w_px - 10, 20)
        hole.position = Vector2(cr.position.x + 5, cr.position.y + h_draw_px - 25)
        node.add_child(hole)

    elif o_id == "ceiling_light":
        var light_cr = ColorRect.new()
        light_cr.color = Color(1.0, 1.0, 0.7, 0.9)
        light_cr.size = Vector2(w_px * 0.8, 16)
        light_cr.position = Vector2(cr.position.x + w_px * 0.1, cr.position.y + h_draw_px - 16)
        node.add_child(light_cr)

    elif o_id == "kitchen_counter":
        # 扉の線を引いてキッチンっぽくする
        var line1 = Line2D.new()
        line1.add_point(Vector2(cr.position.x + w_px * 0.33, cr.position.y + 10))
        line1.add_point(Vector2(cr.position.x + w_px * 0.33, cr.position.y + h_draw_px))
        line1.width = 2
        line1.default_color = Color(0.2, 0.4, 0.2, 0.5)
        node.add_child(line1)
        var line2 = Line2D.new()
        line2.add_point(Vector2(cr.position.x + w_px * 0.66, cr.position.y + 10))
        line2.add_point(Vector2(cr.position.x + w_px * 0.66, cr.position.y + h_draw_px))
        line2.width = 2
        line2.default_color = Color(0.2, 0.4, 0.2, 0.5)
        node.add_child(line2)

    elif o_id == "table":
        cr.color = Color(0, 0, 0, 0)
        var top = ColorRect.new()
        top.color = Color(0.6, 0.4, 0.2)
        top.size = Vector2(w_px, 16)
        top.position = cr.position
        node.add_child(top)
        var leg1 = ColorRect.new()
        leg1.color = Color(0.4, 0.2, 0.1)
        leg1.size = Vector2(10, h_draw_px - 16)
        leg1.position = cr.position + Vector2(10, 16)
        node.add_child(leg1)
        var leg2 = ColorRect.new()
        leg2.color = Color(0.4, 0.2, 0.1)
        leg2.size = Vector2(10, h_draw_px - 16)
        leg2.position = cr.position + Vector2(w_px - 20, 16)
        node.add_child(leg2)

    elif "chair" in o_id:
        cr.color = Color(0, 0, 0, 0)
        var seat = ColorRect.new()
        seat.color = Color(0.7, 0.5, 0.3)
        seat.size = Vector2(w_px, 10)
        seat.position = cr.position
        node.add_child(seat)
        var leg_c = ColorRect.new()
        leg_c.color = Color(0.5, 0.3, 0.1)
        leg_c.size = Vector2(w_px * 0.6, h_draw_px - 10)
        leg_c.position = cr.position + Vector2(w_px * 0.2, 10)
        node.add_child(leg_c)
        var back = ColorRect.new()
        back.color = Color(0.6, 0.4, 0.2)
        back.size = Vector2(8, 40)
        back.position = Vector2(cr.position.x + w_px - 8, cr.position.y - 40)
        node.add_child(back)
    # ---------------------------------------------------------

    
    # 基準となる高さのライン（黄色線）
    var line = Line2D.new()
    line.add_point(Vector2(obs["x"] * cm_to_px, -h_px))
    line.add_point(Vector2(obs["x2"] * cm_to_px, -h_px))
    line.width = 3.0
    line.default_color = Color(1.0, 1.0, 0.2, 0.9) # やや明るい黄色
    line.z_as_relative = false
    line.z_index = 10 # 全てのビジュアルより手前
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
    label.z_as_relative = false
    label.z_index = 10 # 全てのビジュアルより手前
    
    node.add_child(label)
    parent.add_child(node)

static func get_obstacle_comment(obs_id: String, h: float, oh: float) -> String:
    match obs_id:
        "door_left", "door_right", "side_door", "school_door_1", "door_1", "door_2", "door_3", "door_4":
            if h > oh:
                return "ドア（高さ%dcm）。あなた（%dcm）は%dcm頭が当たります！" % [oh, h, round(h - oh)]
            else:
                return "ドア（高さ%dcm）を余裕でくぐれます（余裕%dcm）。" % [oh, round(oh - h)]
        "range_hood":
            if h > oh:
                return "レンジフード（高さ%dcm）に頭がぶつかります！\n%dcmかがまないと通れません。" % [oh, round(h - oh)]
            else:
                return "レンジフード（高さ%dcm）はあなたの頭より%dcm上にあります。" % [oh, round(oh - h)]
        "ceiling_light":
            if h > oh:
                return "シーリングライト（高さ%dcm）。\nあなた（%dcm）は頭がぶつかってしまいます！" % [oh, h]
            else:
                return "シーリングライト。頭上まであと%dcmです。" % round(oh - h)
        "kitchen_counter":
            if h > 170:
                return "キッチン台（80cm）。少し低くて腰が痛くなりそうです。"
            else:
                return "キッチン台（80cm）。丁度良い高さですね。"
        "table":
            if h > 170:
                return "テーブル（%dcm）。少し低く感じるかもしれません。" % oh
            else:
                return "テーブル（%dcm）です。" % oh
        "chair":
            return "椅子（%dcm）。" % oh
        "window_1":
            if h > oh:
                return "窓（上端%dcm）。外を見るにはかがむ必要があります（身長%dcm）。" % [oh, h]
            else:
                return "窓です。外の景色が見えます。"
        "poster":
            if h > oh + 20:
                return "ポスター（%dcm）。かなり下の方に貼ってあります。" % oh
            else:
                return "ポスターです。"
        "wall_clock":
            return "壁掛け時計。今は...何時でしょう？"
        "washstand":
            if h > 180:
                return "洗面台の鏡。かがまないと顔が見えません（身長%dcm）。" % h
            else:
                return "洗面台の鏡。ちょうど顔が映ります。"
        "shower":
            return "シャワー（%dcm）から頭上へお湯が降り注ぎます。" % oh
        "strap_1", "strap_2", "strap_3":
            if h >= oh:
                return "吊り革バー（%dcm）が目の前！楽々手が届きます！" % oh
            else:
                return "吊り革バー（%dcm）まで%dcm届きません。" % [oh, round(oh - h)]
        "public_phone":
            return "公衆電話（高さ%dcm）。\nあなたが使うと受話器は胸のあたりの位置です。" % oh
        "pedestrian_signal":
            return "歩行者用信号機（%dm）。\nあなた（%dcm）の%.1f倍の高さです。" % [oh / 100, h, oh / h]
        "streetlight", "traffic_signal", "curve_mirror", "footbridge":
            return "障害物（%dm）。\nあなた（%dcm）の%.1f倍の高さです。" % [oh / 100, h, oh / h]
        "utility_pole":
            return "電柱（%dm）！\nあなた（%dcm）が%.1f人分積み重なった高さ。" % [oh / 100, h, oh / h]
        "house_2f", "house_3f":
            return "建物（%dm）。あなた（%dcm）が%.1f人分の高さ。" % [oh / 100, h, oh / h]
        "vending_machine":
            if h > oh:
                return "自販機（%dcm）より背が高いですね。\n取り出し口が遠く感じそうです。" % oh
            else:
                return "自販機（%dcm）。\nあなた（%dcm）より%dcm高いです。" % [oh, h, round(oh - h)]
        "blackboard":
            if h > 180:
                return "黒板の上の方まで楽々手が届きますね。"
            else:
                return "黒板の上の方は少し背伸びが必要かもしれません。"
        "desk_1", "desk_2", "teacher_desk":
            return "学校の机（%dcm）。\n昔はこんなに小さかったですね。" % oh
    
    if h > oh:
        return "オブジェクト（高さ%dcm）。\nあなた（%dcm）は%dcm頭が当たります！" % [oh, h, math_round(h - oh)]
    return "オブジェクト（高さ%dcm）。" % oh

static func math_round(val: float) -> int:
    return int(round(val))
