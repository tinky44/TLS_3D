extends RefCounted
class_name StageBuilder

const STAGES = {
    "room": {
        "name": "家の中",
        "width": 2000,
        "ceiling_height": 240,
        "obstacles": [
            {"id": "door_exit", "x": 100, "x2": 180, "height": 200, "type": "overhead"},
            {"id": "ceiling_light", "x": 280, "x2": 380, "height": 200, "type": "overhead"},
            {"id": "refrigerator", "x": 380, "x2": 440, "height": 180, "type": "background"},
            {"id": "kitchen_cabinet", "x": 440, "x2": 550, "height": 180, "type": "background"},
            {"id": "kitchen_counter", "x": 440, "x2": 640, "height": 80, "type": "ground"},
            {"id": "range_hood", "x": 550, "x2": 640, "height": 180, "type": "overhead"},
            {"id": "wall_clock", "x": 650, "x2": 690, "height": 200, "type": "background"},
            {"id": "chair", "x": 700, "x2": 740, "height": 45, "type": "ground"},
            {"id": "table", "x": 760, "x2": 900, "height": 70, "type": "ground"},
            {"id": "window_1", "x": 920, "x2": 1050, "height": 160, "type": "background"},
            {"id": "poster", "x": 1080, "x2": 1130, "height": 170, "type": "background"},
            {"id": "side_door", "x": 1150, "x2": 1180, "height": 200, "type": "overhead"},
            {"id": "washstand", "x": 1250, "x2": 1350, "height": 180, "type": "background"},
            {"id": "bathroom_wall", "x": 1610, "x2": 1630, "height": 240, "type": "background"},
            {"id": "bathroom_bg", "x": 1640, "x2": 1950, "height": 240, "type": "background"},
            {"id": "bathroom_ceiling", "x": 1640, "x2": 1950, "height": 200, "type": "overhead"},
            {"id": "bathtub", "x": 1640, "x2": 1820, "height": 60, "type": "ground"},
            {"id": "bath_stool", "x": 1850, "x2": 1890, "height": 30, "type": "ground"},
            {"id": "shower_nozzle", "x": 1900, "x2": 1940, "height": 180, "type": "overhead"}
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
    },
    "myroom": {
        "name": "自分の部屋",
        "width": 700,
        "ceiling_height": 240,
        "obstacles": [
            {"id": "bed", "x": 30, "x2": 230, "height": 50, "type": "ground"},
            {"id": "window_myroom", "x": 50, "x2": 190, "height": 155, "type": "background"},
            {"id": "ceiling_light", "x": 250, "x2": 345, "height": 200, "type": "overhead"},
            {"id": "bookshelf", "x": 295, "x2": 355, "height": 195, "type": "background"},
            {"id": "chair", "x": 360, "x2": 400, "height": 45, "type": "ground"},
            {"id": "desk_myroom", "x": 415, "x2": 550, "height": 72, "type": "ground"},
            {"id": "randoseru", "x": 560, "x2": 597, "height": 35, "type": "ground"},
            {"id": "door_to_room", "x": 600, "x2": 675, "height": 200, "type": "overhead"}
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
    
    # 床の描画 (フローリング風の少し落ち着いた茶色)
    var floor_rect = ColorRect.new()
    if stage_id == "room" or stage_id == "myroom":
        floor_rect.color = Color(0.45, 0.35, 0.25) # フローリング風（濃いめ）
    else:
        floor_rect.color = Color(0.2, 0.2, 0.2)
    floor_rect.position = Vector2(0, 0)
    floor_rect.size = Vector2(stage_data["width"] * cm_to_px, 100)
    floor_body.add_child(floor_rect)
    
    parent_node.add_child(floor_body)

    # 部屋系ステージの場合、背景を壁紙風にする
    if (stage_id == "room" or stage_id == "myroom") and stage_data.get("ceiling_height") != null:
        var wall_bg = Node2D.new()
        wall_bg.set_meta("is_stage_obj", true)
        wall_bg.z_index = -5 # 一番奥に配置する

        var ceil_h_px = stage_data["ceiling_height"] * cm_to_px
        var stage_w_px = stage_data["width"] * cm_to_px

        # ステージ別の壁紙カラー
        var wall_top_color: Color
        var wall_btm_color: Color
        var molding_color: Color
        var baseboard_color: Color
        if stage_id == "myroom":
            wall_top_color = Color(0.90, 0.85, 0.78)  # 温かみのあるクリーム
            wall_btm_color = Color(0.80, 0.75, 0.68)
            molding_color  = Color(0.65, 0.55, 0.40)
            baseboard_color = Color(0.45, 0.30, 0.18)
        else:
            wall_top_color = Color(0.40, 0.45, 0.50)  # グレー系（リビング）
            wall_btm_color = Color(0.30, 0.35, 0.40)
            molding_color  = Color(0.20, 0.20, 0.25)
            baseboard_color = Color(0.35, 0.24, 0.18)

        # 壁紙 上半分
        var wall_top = ColorRect.new()
        wall_top.color = wall_top_color
        wall_top.position = Vector2(0, -ceil_h_px)
        wall_top.size = Vector2(stage_w_px, ceil_h_px * 0.5)
        wall_bg.add_child(wall_top)

        # 壁紙 下半分
        var wall_btm = ColorRect.new()
        wall_btm.color = wall_btm_color
        wall_btm.position = Vector2(0, -ceil_h_px * 0.5)
        wall_btm.size = Vector2(stage_w_px, ceil_h_px * 0.5)
        wall_bg.add_child(wall_btm)

        # 見切り材（上下の壁紙の境界の帯）
        var molding = ColorRect.new()
        molding.color = molding_color
        molding.position = Vector2(0, -ceil_h_px * 0.5 - 4)
        molding.size = Vector2(stage_w_px, 8)
        wall_bg.add_child(molding)

        # 巾木（床と壁の境界の板）
        var baseboard = ColorRect.new()
        baseboard.color = baseboard_color
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
    
    var is_solid = false
    if type == "overhead":
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
    if o_id == "door_exit":
        # 横から見た出入口
        cr.color = Color(0, 0, 0, 0)
        # 暗い外の空間
        var outside = ColorRect.new()
        outside.color = Color(0.08, 0.08, 0.12)
        outside.position = Vector2(0, -h_px)
        outside.size = Vector2(obs["x2"] * cm_to_px, h_px + 50)
        outside.z_index = -2
        node.add_child(outside)
        # 右縦フレーム（壁端の柱）
        var post = ColorRect.new()
        post.color = Color(0.24, 0.16, 0.12)
        post.position = Vector2(obs["x"] * cm_to_px + w_px * 0.7, -h_px)
        post.size = Vector2(w_px * 0.3, h_px)
        post.z_index = -1
        node.add_child(post)
        # 上部の梁（出入口上の壁）
        var top_wall = ColorRect.new()
        top_wall.color = Color(0.85, 0.82, 0.78)
        top_wall.position = Vector2(0, y_pos)
        top_wall.size = Vector2(obs["x2"] * cm_to_px, h_draw_px + 40)
        top_wall.z_index = -1
        node.add_child(top_wall)

    elif "door" in o_id:
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
        # 天井まで届く四角形（180cm〜240cm）
        cr.color = Color(0.62, 0.62, 0.67)
        cr.position = Vector2(obs["x"] * cm_to_px, -240.0 * cm_to_px)
        cr.size = Vector2(w_px, 60.0 * cm_to_px)
        # 吸気口（底面の暗い帯）
        var hole = ColorRect.new()
        hole.color = Color(0.20, 0.20, 0.22, 0.90)
        hole.size = Vector2(w_px - 8, 14)
        hole.position = Vector2(obs["x"] * cm_to_px + 4, -h_px - 14)
        node.add_child(hole)

    elif o_id == "kitchen_cabinet":
        # 吊り戸棚（180cm〜240cm の範囲に描画）
        cr.color = Color(0, 0, 0, 0)
        var cab_bot_y = - h_px # 180cmライン（下端）
        var cab_h_px = 60.0 * cm_to_px # 60cm高さ
        var cab_top_y = cab_bot_y - cab_h_px # 240cmライン（上端）
        # キャビネット本体
        var cab = ColorRect.new()
        cab.color = Color(0.80, 0.72, 0.60)
        cab.position = Vector2(obs["x"] * cm_to_px, cab_top_y)
        cab.size = Vector2(w_px, cab_h_px)
        cab.z_index = -1
        node.add_child(cab)
        # 扉の仕切り線（中央）
        var divider = ColorRect.new()
        divider.color = Color(0.58, 0.50, 0.40)
        divider.position = Vector2(obs["x"] * cm_to_px + w_px * 0.5 - 1, cab_top_y)
        divider.size = Vector2(2, cab_h_px)
        divider.z_index = -1
        node.add_child(divider)
        # 外枠
        var cab_frame = ReferenceRect.new()
        cab_frame.editor_only = false
        cab_frame.border_color = Color(0.55, 0.47, 0.38)
        cab_frame.border_width = 2.0
        cab_frame.position = cab.position
        cab_frame.size = cab.size
        cab_frame.z_index = -1
        node.add_child(cab_frame)
        # ドアハンドル（2つ）
        for knob_x_ratio in [0.25, 0.75]:
            var knob = ColorRect.new()
            knob.color = Color(0.75, 0.65, 0.20)
            knob.position = Vector2(obs["x"] * cm_to_px + w_px * knob_x_ratio - 3, cab_top_y + cab_h_px * 0.55 - 5)
            knob.size = Vector2(6, 10)
            knob.z_index = -1
            node.add_child(knob)

    elif o_id == "ceiling_light":
        cr.color = Color(0, 0, 0, 0)
        var cx = obs["x"] * cm_to_px + w_px * 0.5
        var bot_y = - h_px # ライト下端 y（200cmライン）
        var ceil_y = -240.0 * cm_to_px # 天井 y（240cmライン）
        var cord_h = 4.0 * cm_to_px
        var shade_top_y = ceil_y + cord_h # シェード上端（コード下端）
        var glow_h = 3.0 * cm_to_px
        var shade_bot_y = bot_y - glow_h # シェード下端（発光面の上 = 203cmライン）

        # コード（天井から吊り下げ）
        var cord = Line2D.new()
        cord.add_point(Vector2(cx, ceil_y))
        cord.add_point(Vector2(cx, shade_top_y))
        cord.width = 3.0
        cord.default_color = Color(0.45, 0.45, 0.50)
        cord.z_index = -1
        node.add_child(cord)

        # 台形シェード（上が細く、下が広い）
        var top_hw = w_px * 0.15
        var bot_hw = w_px * 0.44
        var shade = Polygon2D.new()
        shade.polygon = PackedVector2Array([
            Vector2(cx - top_hw, shade_top_y),
            Vector2(cx + top_hw, shade_top_y),
            Vector2(cx + bot_hw, shade_bot_y),
            Vector2(cx - bot_hw, shade_bot_y),
        ])
        shade.color = Color(0.80, 0.77, 0.73)
        shade.z_index = -1
        node.add_child(shade)

        # 発光面（シェード底面）
        var glow = ColorRect.new()
        glow.color = Color(1.0, 0.97, 0.82, 0.95)
        glow.position = Vector2(cx - bot_hw, shade_bot_y)
        glow.size = Vector2(bot_hw * 2.0, glow_h)
        glow.z_index = -1
        node.add_child(glow)

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

    elif o_id == "refrigerator":
        cr.color = Color(0.9, 0.9, 0.92) # 白
        # 冷凍庫と冷蔵庫の仕切り線（上から30%）
        var divider = ColorRect.new()
        divider.color = Color(0.6, 0.6, 0.65)
        divider.position = Vector2(cr.position.x, cr.position.y + h_draw_px * 0.3)
        divider.size = Vector2(w_px, 4)
        node.add_child(divider)
        # 上部ハンドル（冷凍庫）
        var handle1 = ColorRect.new()
        handle1.color = Color(0.7, 0.7, 0.75)
        handle1.position = Vector2(cr.position.x + w_px * 0.75, cr.position.y + h_draw_px * 0.1)
        handle1.size = Vector2(8, h_draw_px * 0.15)
        node.add_child(handle1)
        # 下部ハンドル（冷蔵庫）
        var handle2 = ColorRect.new()
        handle2.color = Color(0.7, 0.7, 0.75)
        handle2.position = Vector2(cr.position.x + w_px * 0.75, cr.position.y + h_draw_px * 0.4)
        handle2.size = Vector2(8, h_draw_px * 0.25)
        node.add_child(handle2)

    elif o_id == "bathtub":
        cr.color = Color(0.85, 0.9, 0.95) # 水色
        var rim = ReferenceRect.new()
        rim.editor_only = false
        rim.border_color = Color(0.7, 0.8, 0.85)
        rim.border_width = 6.0
        rim.position = cr.position
        rim.size = cr.size
        node.add_child(rim)
        var water = ColorRect.new()
        water.color = Color(0.6, 0.8, 0.9, 0.5)
        water.position = cr.position + Vector2(8, 8)
        water.size = Vector2(w_px - 16, h_draw_px * 0.55)
        node.add_child(water)

    elif o_id == "shower_nozzle":
        cr.color = Color(0, 0, 0, 0)
        var pole_cx = obs["x"] * cm_to_px + w_px * 0.5

        # シャワーヘッド本体（丸型ディスク）- 上端を180cmラインに合わせる
        var head_d = min(w_px * 0.75, 20.0 * cm_to_px)
        var head_x = pole_cx - head_d * 0.5
        var head_y = - h_px # 上端を180cmラインに合わせる

        # 縦ポール（ヘッド下端から床方向へ）
        var pole = ColorRect.new()
        pole.color = Color(0.78, 0.78, 0.82)
        pole.position = Vector2(pole_cx - 3, head_y + head_d)
        pole.size = Vector2(6, -20.0 * cm_to_px - (head_y + head_d))
        pole.z_index = -1
        node.add_child(pole)

        var head_panel = Panel.new()
        var style = StyleBoxFlat.new()
        style.bg_color = Color(0.82, 0.82, 0.88)
        style.border_color = Color(0.60, 0.60, 0.68)
        style.border_width_left = 2
        style.border_width_right = 2
        style.border_width_top = 2
        style.border_width_bottom = 2
        var r = int(head_d * 0.5)
        style.corner_radius_top_left = r
        style.corner_radius_top_right = r
        style.corner_radius_bottom_left = r
        style.corner_radius_bottom_right = r
        head_panel.add_theme_stylebox_override("panel", style)
        head_panel.position = Vector2(head_x, head_y)
        head_panel.size = Vector2(head_d, head_d)
        head_panel.z_index = -1
        node.add_child(head_panel)

        # 散水面（内側の暗い円）
        var face_d = head_d * 0.65
        var face_panel = Panel.new()
        var face_style = StyleBoxFlat.new()
        face_style.bg_color = Color(0.50, 0.50, 0.58)
        var fr = int(face_d * 0.5)
        face_style.corner_radius_top_left = fr
        face_style.corner_radius_top_right = fr
        face_style.corner_radius_bottom_left = fr
        face_style.corner_radius_bottom_right = fr
        face_panel.add_theme_stylebox_override("panel", face_style)
        face_panel.position = Vector2(pole_cx - face_d * 0.5, head_y + (head_d - face_d) * 0.5)
        face_panel.size = Vector2(face_d, face_d)
        face_panel.z_index = -1
        node.add_child(face_panel)

    elif o_id == "bath_stool":
        cr.color = Color(0, 0, 0, 0)
        var seat = ColorRect.new()
        seat.color = Color(0.85, 0.92, 0.95)
        seat.position = cr.position
        seat.size = Vector2(w_px, 8)
        node.add_child(seat)
        var leg1 = ColorRect.new()
        leg1.color = Color(0.75, 0.85, 0.88)
        leg1.position = cr.position + Vector2(5, 8)
        leg1.size = Vector2(6, h_draw_px - 8)
        node.add_child(leg1)
        var leg2 = ColorRect.new()
        leg2.color = Color(0.75, 0.85, 0.88)
        leg2.position = cr.position + Vector2(w_px - 11, 8)
        leg2.size = Vector2(6, h_draw_px - 8)
        node.add_child(leg2)

    elif o_id == "bathroom_wall":
        cr.color = Color(0.82, 0.88, 0.93)
        # タイル模様（横線）
        for i in range(0, int(h_draw_px), 30):
            var tl = Line2D.new()
            tl.add_point(Vector2(cr.position.x, cr.position.y + i))
            tl.add_point(Vector2(cr.position.x + w_px, cr.position.y + i))
            tl.width = 1
            tl.default_color = Color(0.65, 0.75, 0.82, 0.6)
            node.add_child(tl)

    elif o_id == "bathroom_bg":
        cr.color = Color(0, 0, 0, 0) # ベース透明
        # 壁面（青系タイル）
        var wall = ColorRect.new()
        wall.color = Color(0.6, 0.8, 0.9, 0.85)
        wall.position = Vector2(obs["x"] * cm_to_px, -h_draw_px)
        wall.size = Vector2(w_px, h_draw_px)
        wall.z_index = -2
        node.add_child(wall)
        # タイル模様（横線）
        for i in range(0, int(h_draw_px), 40):
            var tl = Line2D.new()
            tl.add_point(Vector2(obs["x"] * cm_to_px, -h_draw_px + i))
            tl.add_point(Vector2(obs["x2"] * cm_to_px, -h_draw_px + i))
            tl.width = 1
            tl.default_color = Color(0.45, 0.65, 0.75, 0.6)
            node.add_child(tl)
        # 浴室の床（段差の上、青系）
        var floor_rect = ColorRect.new()
        floor_rect.color = Color(0.5, 0.72, 0.82)
        floor_rect.position = Vector2(obs["x"] * cm_to_px, -30 * cm_to_px)
        floor_rect.size = Vector2(w_px, 30 * cm_to_px + 100)
        floor_rect.z_index = -2
        node.add_child(floor_rect)

    elif o_id == "bathroom_ceiling":
        # overhead の cr（梁）は既に描画されているが、天井が低く見えるよう追加描画
        cr.color = Color(0.7, 0.85, 0.9)
        # 240cm から 200cm の差分（40cm）を天井として塗る
        var ceiling_fill = ColorRect.new()
        ceiling_fill.color = Color(0.7, 0.85, 0.9)
        ceiling_fill.position = Vector2(obs["x"] * cm_to_px, -240 * cm_to_px)
        ceiling_fill.size = Vector2(w_px, 40 * cm_to_px)
        ceiling_fill.z_index = -1
        node.add_child(ceiling_fill)

    elif o_id == "bed":
        cr.color = Color(0, 0, 0, 0)
        # フレーム（木製・茶色）
        var bed_frame = ColorRect.new()
        bed_frame.color = Color(0.40, 0.25, 0.15)
        bed_frame.position = cr.position
        bed_frame.size = cr.size
        node.add_child(bed_frame)
        # マットレス
        var mattress = ColorRect.new()
        mattress.color = Color(0.93, 0.90, 0.85)
        mattress.position = cr.position + Vector2(6, 6)
        mattress.size = Vector2(w_px - 22, h_draw_px - 6)
        node.add_child(mattress)
        # 枕（右端＝ヘッドボード側）
        var pillow = ColorRect.new()
        pillow.color = Color(0.98, 0.96, 0.90)
        var p_w = w_px * 0.18
        pillow.position = cr.position + Vector2(w_px - p_w - 16, 8)
        pillow.size = Vector2(p_w, h_draw_px * 0.55)
        node.add_child(pillow)
        # ヘッドボード（右端の縦板）
        var headboard = ColorRect.new()
        headboard.color = Color(0.35, 0.22, 0.12)
        headboard.position = Vector2(obs["x"] * cm_to_px + w_px - 16, cr.position.y - 35)
        headboard.size = Vector2(16, h_draw_px + 35)
        node.add_child(headboard)
        # フットボード（左端の短い縦板）
        var footboard = ColorRect.new()
        footboard.color = Color(0.35, 0.22, 0.12)
        footboard.position = Vector2(obs["x"] * cm_to_px, cr.position.y - 15)
        footboard.size = Vector2(14, h_draw_px + 15)
        node.add_child(footboard)

    elif o_id == "bookshelf":
        cr.color = Color(0.45, 0.30, 0.18)
        # 棚板（4枚）
        var shelf_count = 4
        var shelf_spacing = h_draw_px / (shelf_count + 1)
        for i in range(1, shelf_count + 1):
            var shelf = ColorRect.new()
            shelf.color = Color(0.55, 0.38, 0.22)
            shelf.position = Vector2(cr.position.x, cr.position.y + shelf_spacing * i)
            shelf.size = Vector2(w_px, 5)
            node.add_child(shelf)
        # 本（固定パターン）
        var book_colors_shelf = [Color(0.75, 0.15, 0.15), Color(0.15, 0.45, 0.75), Color(0.15, 0.65, 0.25), Color(0.85, 0.65, 0.10), Color(0.55, 0.15, 0.70)]
        var book_widths_arr = [10, 8, 12, 9, 11, 8]
        for i in range(shelf_count + 1):
            var sy = cr.position.y + shelf_spacing * i + (0.0 if i == 0 else 5.0)
            var ey = cr.position.y + (shelf_spacing * (i + 1) if i < shelf_count else h_draw_px)
            var bh = ey - sy - 4.0
            var bx = cr.position.x + 5.0
            for j in range(book_widths_arr.size()):
                var bw = float(book_widths_arr[j])
                if bx + bw > cr.position.x + w_px - 5.0:
                    break
                var book = ColorRect.new()
                book.color = book_colors_shelf[(i + j) % book_colors_shelf.size()]
                book.position = Vector2(bx, sy + 3.0)
                book.size = Vector2(bw, bh)
                node.add_child(book)
                bx += bw + 1.0

    elif o_id == "desk_myroom":
        cr.color = Color(0, 0, 0, 0)
        # 天板
        var desk_top = ColorRect.new()
        desk_top.color = Color(0.65, 0.45, 0.25)
        desk_top.position = cr.position
        desk_top.size = Vector2(w_px, 12)
        node.add_child(desk_top)
        # 脚（左右）
        for leg_x_offset in [8.0, w_px - 18.0]:
            var leg = ColorRect.new()
            leg.color = Color(0.50, 0.32, 0.18)
            leg.position = Vector2(cr.position.x + leg_x_offset, cr.position.y + 12)
            leg.size = Vector2(10, h_draw_px - 12)
            node.add_child(leg)
        # 引き出し（右側）
        var drawer = ColorRect.new()
        drawer.color = Color(0.58, 0.40, 0.22)
        drawer.position = Vector2(cr.position.x + w_px * 0.55, cr.position.y + 18)
        drawer.size = Vector2(w_px * 0.38, h_draw_px * 0.5)
        node.add_child(drawer)
        # 引き出しの取っ手
        var desk_handle = ColorRect.new()
        desk_handle.color = Color(0.75, 0.65, 0.20)
        desk_handle.position = drawer.position + Vector2(drawer.size.x * 0.35, drawer.size.y * 0.38)
        desk_handle.size = Vector2(10, 5)
        node.add_child(desk_handle)

    elif o_id == "randoseru":
        cr.color = Color(0, 0, 0, 0)
        # メインボディ（赤）
        var rand_body = ColorRect.new()
        rand_body.color = Color(0.75, 0.10, 0.10)
        rand_body.position = cr.position
        rand_body.size = cr.size
        node.add_child(rand_body)
        # フラップ（上部、少し暗い赤）
        var flap = ColorRect.new()
        flap.color = Color(0.60, 0.08, 0.08)
        flap.position = cr.position
        flap.size = Vector2(w_px, h_draw_px * 0.38)
        node.add_child(flap)
        # バックル（フラップ中央）
        var buckle = ColorRect.new()
        buckle.color = Color(0.85, 0.70, 0.10)
        buckle.position = cr.position + Vector2(w_px * 0.35, h_draw_px * 0.33)
        buckle.size = Vector2(w_px * 0.30, 5)
        node.add_child(buckle)
        # 外枠
        var rand_outline = ReferenceRect.new()
        rand_outline.editor_only = false
        rand_outline.border_color = Color(0.45, 0.05, 0.05)
        rand_outline.border_width = 2.0
        rand_outline.position = cr.position
        rand_outline.size = cr.size
        node.add_child(rand_outline)

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
        "door_exit":
            if h > oh:
                return "出入口（高さ%dcm）。\nあなた（%dcm）は%dcm頭が当たります！" % [oh, h, round(h - oh)]
            else:
                return "外への出入口（%dcm）。余裕でくぐれます。" % oh
        "door_left", "door_right", "side_door", "school_door_1", "door_1", "door_2", "door_3", "door_4", "door_to_room":
            if h > oh:
                return "ドア（高さ%dcm）。あなた（%dcm）は%dcm頭が当たります！" % [oh, h, round(h - oh)]
            else:
                return "ドア（高さ%dcm）を余裕でくぐれます（余裕%dcm）。" % [oh, round(oh - h)]
        "kitchen_cabinet":
            if h > oh:
                return "吊り戸棚（下端%dcm）。\nあなた（%dcm）は頭が当たってしまいます！" % [oh, h]
            else:
                return "吊り戸棚（下端%dcm）。\nあなたの身長なら丁度良く手が届きますね。" % oh
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
        "refrigerator":
            if h > 170:
                return "冷蔵庫（%dcm）。\n上の棚に楽々手が届いて便利ですね。" % oh
            else:
                return "冷蔵庫（%dcm）。" % oh
        "bathtub":
            return "浴槽（%dcm）。\n背が高いと浴槽の縁をまたぐのが少し大変です。" % oh
        "shower_nozzle":
            if h > oh:
                return "シャワーヘッド（%dcm）。\nあなた（%dcm）より低い！肩にしかお湯が当たりません。" % [oh, h]
            else:
                return "シャワーヘッド（%dcm）。丁度いい高さですね。" % oh
        "bath_stool":
            return "風呂スツール（%dcm）。\n背が高いと低くてかがむのが大変です。" % oh
        "bathroom_wall":
            return "浴室の仕切り壁です。"
        "bathroom_bg":
            return "" # コメントなし（背景要素）
        "bathroom_ceiling":
            if h > oh:
                return "浴室の天井（%dcm）。\nあなた（%dcm）は%dcm頭が当たります！" % [oh, h, round(h - oh)]
            else:
                return "浴室の天井（%dcm）。低めの天井ですね。" % oh
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
        "bed":
            return "自分のベッド（高さ%dcm）。\n背が高いと足がはみ出してしまいますね。" % oh
        "bookshelf":
            if h > oh:
                return "本棚（高さ%dcm）。\nあなた（%dcm）より低い！上の棚まで余裕で手が届きますね。" % [oh, h]
            else:
                return "本棚（高さ%dcm）。\n上の棚に少し背伸びが必要かもしれません。" % oh
        "desk_myroom":
            if h > 170:
                return "学習机（高さ%dcm）。\n少し低く感じるかもしれません。" % oh
            else:
                return "学習机（高さ%dcm）です。" % oh
        "randoseru":
            return "ランドセル。\n小学校の頃を思い出しますね。"

    if h > oh:
        return "オブジェクト（高さ%dcm）。\nあなた（%dcm）は%dcm頭が当たります！" % [oh, h, math_round(h - oh)]
    return "オブジェクト（高さ%dcm）。" % oh

static func math_round(val: float) -> int:
    return int(round(val))
