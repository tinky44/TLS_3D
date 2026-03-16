extends RefCounted
class_name StageBuilder

const STAGES = {
    "room": {
        "name": "家の中",
        "width": 2000,
        "ceiling_height": 240,
        "obstacles": [
            {"id": "door_to_outdoor", "x": 100, "x2": 180, "height": 200, "type": "overhead"},
            {"id": "ceiling_light", "x": 280, "x2": 380, "height": 200, "type": "overhead"},
            {"id": "refrigerator", "x": 380, "x2": 440, "height": 180, "type": "background"},
            {"id": "kitchen_cabinet", "x": 440, "x2": 550, "height": 180, "type": "background"},
            {"id": "kitchen_counter", "x": 440, "x2": 640, "height": 80, "type": "ground"},
            {"id": "range_hood", "x": 550, "x2": 640, "height": 180, "type": "overhead"},
            {"id": "wall_clock", "x": 650, "x2": 690, "height": 200, "type": "background"},
            {"id": "chair_left", "x": 700, "x2": 740, "height": 45, "type": "ground"},
            {"id": "table", "x": 760, "x2": 900, "height": 70, "type": "ground"},
            {"id": "chair_right", "x": 910, "x2": 950, "height": 45, "type": "ground"},
            {"id": "door_to_myroom", "x": 1080, "x2": 1155, "height": 200, "type": "overhead"},
            {"id": "side_door", "x": 1375, "x2": 1405, "height": 200, "type": "overhead"},
            {"id": "washstand", "x": 1450, "x2": 1550, "height": 180, "type": "background"},
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
            {"id": "door_to_platform", "x": 50, "x2": 230, "height": 185, "type": "overhead"},
            {"id": "door_to_gakuenmae", "x": 580, "x2": 760, "height": 185, "type": "overhead"},
            {"id": "door_3", "x": 1220, "x2": 1400, "height": 185, "type": "overhead"},
            {"id": "door_4", "x": 1770, "x2": 1950, "height": 185, "type": "overhead"},
            {"id": "train_seat_1", "x": 240, "x2": 560, "height": 45, "type": "ground"},
            {"id": "train_seat_2", "x": 790, "x2": 1190, "height": 45, "type": "ground"},
            {"id": "train_seat_3", "x": 1440, "x2": 1740, "height": 45, "type": "ground"},
            {"id": "strap_1", "x": 280, "x2": 320, "height": 163, "type": "background"},
            {"id": "strap_2", "x": 380, "x2": 420, "height": 163, "type": "background"},
            {"id": "strap_3", "x": 480, "x2": 520, "height": 163, "type": "background"},
            {"id": "strap_4", "x": 830, "x2": 870, "height": 163, "type": "background"},
            {"id": "strap_5", "x": 930, "x2": 970, "height": 163, "type": "background"},
            {"id": "strap_6", "x": 1030, "x2": 1070, "height": 163, "type": "background"},
            {"id": "strap_7", "x": 1130, "x2": 1170, "height": 163, "type": "background"},
            {"id": "strap_8", "x": 1480, "x2": 1520, "height": 163, "type": "background"},
            {"id": "strap_9", "x": 1580, "x2": 1620, "height": 163, "type": "background"},
            {"id": "strap_10", "x": 1680, "x2": 1720, "height": 163, "type": "background"}
        ]
    },
    "platform": {
        "name": "ホーム",
        "width": 2200,
        "ceiling_height": null,
        "obstacles": [
            {"id": "platform_column_1", "x": 520, "x2": 575, "height": 250, "type": "background"},
            {"id": "platform_bench", "x": 860, "x2": 1060, "height": 42, "type": "ground"},
            {"id": "platform_column_2", "x": 1340, "x2": 1395, "height": 250, "type": "background"},
            {"id": "door_to_train", "x": 1880, "x2": 2060, "height": 185, "type": "overhead"}
        ]
    },
    "gakuenmae": {
        "name": "学園前駅",
        "width": 1700,
        "ceiling_height": null,
        "obstacles": [
            {"id": "door_to_train", "x": 70, "x2": 230, "height": 185, "type": "overhead"},
            {"id": "station_sign_gakuenmae", "x": 520, "x2": 760, "height": 160, "type": "background"},
            {"id": "platform_bench_small", "x": 940, "x2": 1100, "height": 42, "type": "ground"},
            {"id": "ticket_gate", "x": 1150, "x2": 1400, "height": 100, "type": "ground"},
            {"id": "door_to_gakuenmachi", "x": 1450, "x2": 1600, "height": 190, "type": "overhead"}
        ]
    },
    "gakuenmachi": {
        "name": "学園街",
        "width": 2200,
        "ceiling_height": null,
        "obstacles": [
            {"id": "door_to_gakuenmae", "x": 80, "x2": 220, "height": 200, "type": "overhead"},
            {"id": "bus", "x": 250, "x2": 560, "height": 300, "type": "background"},
            {"id": "shop_awning", "x": 620, "x2": 860, "height": 200, "type": "background"},
            {"id": "notice_board_town", "x": 980, "x2": 1130, "height": 180, "type": "background"},
            {"id": "vending_machine", "x": 1280, "x2": 1360, "height": 183, "type": "ground"},
            {"id": "school_gate_high", "x": 1820, "x2": 1980, "height": 180, "type": "background"},
            {"id": "door_to_school_hallway_high", "x": 1980, "x2": 2140, "height": 200, "type": "overhead"}
        ]
    },
    "adjacent_town": {
        "name": "隣町",
        "width": 1500,
        "ceiling_height": null,
        "obstacles": [
            {"id": "town_tree", "x": 260, "x2": 340, "height": 220, "type": "background"},
            {"id": "town_bench", "x": 620, "x2": 800, "height": 42, "type": "ground"},
            {"id": "school_gate_middle", "x": 1120, "x2": 1260, "height": 210, "type": "background"},
            {"id": "door_to_school_hallway_middle", "x": 1260, "x2": 1410, "height": 200, "type": "overhead"}
        ]
    },
    "outdoor": {
        "name": "屋外",
        "width": 1500,
        "ceiling_height": null,
        "obstacles": [
            {"id": "door_to_room", "x": 50, "x2": 130, "height": 200, "type": "overhead"},
            {"id": "mailbox", "x": 200, "x2": 235, "height": 119, "type": "background"},
            {"id": "traffic_signal", "x": 290, "x2": 318, "height": 250, "type": "background"},
            {"id": "vending_machine", "x": 450, "x2": 530, "height": 183, "type": "ground"},
            {"id": "door_to_station", "x": 650, "x2": 750, "height": 200, "type": "overhead"},
            {"id": "car", "x": 760, "x2": 930, "height": 150, "type": "background"},
            {"id": "bus_stop_sign", "x": 940, "x2": 968, "height": 250, "type": "background"},
            {"id": "door_to_school_hallway_elementary", "x": 1050, "x2": 1150, "height": 200, "type": "overhead"}
        ]
    },
    "school_hallway": {
        "name": "学校の廊下",
        "width": 3000,
        "ceiling_height": 280,
        "obstacles": [
            {"id": "door_to_outdoor", "x": 100, "x2": 240, "height": 200, "type": "overhead"},
            {"id": "shoes_locker", "x": 350, "x2": 550, "height": 180, "type": "background"},
            {"id": "bulletin_board", "x": 800, "x2": 1050, "height": 180, "type": "background"},
            {"id": "door_to_school", "x": 1300, "x2": 1440, "height": 200, "type": "overhead"},
            {"id": "fire_hydrant", "x": 1800, "x2": 1860, "height": 120, "type": "background"},
            {"id": "door_to_schoolyard", "x": 1950, "x2": 2090, "height": 200, "type": "overhead"},
            {"id": "door_to_infirmary", "x": 2200, "x2": 2340, "height": 200, "type": "overhead"},
            {"id": "door_to_gymnasium", "x": 2600, "x2": 2740, "height": 200, "type": "overhead"}
        ]
    },
    "infirmary": {
        "name": "保健室",
        "width": 1400,
        "ceiling_height": 270,
        "obstacles": [
            {"id": "door_to_school_hallway", "x": 80, "x2": 220, "height": 200, "type": "overhead"},
            {"id": "medicine_cabinet", "x": 280, "x2": 420, "height": 200, "type": "background"},
            {"id": "height_scale", "x": 500, "x2": 560, "height": 220, "type": "background"},
            {"id": "weight_scale", "x": 580, "x2": 640, "height": 10, "type": "ground"},
            {"id": "infirmary_desk", "x": 730, "x2": 900, "height": 72, "type": "ground"},
            {"id": "infirmary_bed", "x": 1000, "x2": 1280, "height": 60, "type": "ground"},
            {"id": "infirmary_curtain", "x": 980, "x2": 1000, "height": 220, "type": "background"}
        ]
    },
    "school": {
        "name": "学校",
        "width": 1600,
        "ceiling_height": 300,
        "obstacles": [
            {"id": "door_to_school_hallway", "x": 100, "x2": 240, "height": 200, "type": "overhead"},
            {"id": "blackboard", "x": 300, "x2": 800, "height": 210, "type": "background"},
            {"id": "teacher_desk", "x": 840, "x2": 990, "height": 100, "type": "ground"},
            {"id": "desk_1", "x": 1100, "x2": 1160, "height": 75, "type": "ground"},
            {"id": "student_chair_1", "x": 1180, "x2": 1220, "height": 45, "type": "ground"},
            {"id": "desk_2", "x": 1350, "x2": 1410, "height": 75, "type": "ground"},
            {"id": "student_chair_2", "x": 1430, "x2": 1470, "height": 45, "type": "ground"}
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
    },
    "schoolyard": {
        "name": "校庭",
        "width": 2500,
        "ceiling_height": null,
        "obstacles": [
            {"id": "door_to_school_hallway", "x": 80, "x2": 220, "height": 200, "type": "overhead"},
            {"id": "horizontal_bar_low", "x": 500, "x2": 700, "height": 130, "type": "overhead"},
            {"id": "horizontal_bar_high", "x": 750, "x2": 950, "height": 150, "type": "overhead"},
            {"id": "jungle_gym", "x": 900, "x2": 1100, "height": 200, "type": "background"},
            {"id": "basketball_hoop", "x": 1350, "x2": 1415, "height": 260, "type": "background"},
            {"id": "soccer_goal_post", "x": 2000, "x2": 2200, "height": 244, "type": "background"}
        ]
    },
    "gymnasium": {
        "name": "体育館",
        "width": 3200,
        "ceiling_height": 400,
        "obstacles": [
            {"id": "door_to_school_hallway", "x": 80, "x2": 220, "height": 200, "type": "overhead"},
            {"id": "gym_storage", "x": 280, "x2": 450, "height": 200, "type": "background"},
            {"id": "volleyball_net", "x": 1550, "x2": 1850, "height": 243, "type": "overhead"},
            {"id": "gym_bench", "x": 2200, "x2": 2500, "height": 42, "type": "ground"},
            {"id": "gym_window_1", "x": 600, "x2": 780, "height": 500, "type": "background"},
            {"id": "gym_window_2", "x": 900, "x2": 1080, "height": 500, "type": "background"},
            {"id": "basketball_board", "x": 2800, "x2": 2920, "height": 350, "type": "background"}
        ]
    },
    "school_hallway_elementary": {
        "name": "小学校の廊下",
        "width": 3000,
        "ceiling_height": 280,
        "obstacles": []
    },
    "school_hallway_middle": {
        "name": "中学校の廊下",
        "width": 3000,
        "ceiling_height": 280,
        "obstacles": []
    },
    "school_hallway_high": {
        "name": "高校の廊下",
        "width": 3000,
        "ceiling_height": 280,
        "obstacles": []
    },
    "school_elementary": {
        "name": "小学校",
        "width": 1600,
        "ceiling_height": 300,
        "obstacles": []
    },
    "school_middle": {
        "name": "中学校",
        "width": 1600,
        "ceiling_height": 300,
        "obstacles": []
    },
    "school_high": {
        "name": "高校",
        "width": 1600,
        "ceiling_height": 300,
        "obstacles": []
    },
    "schoolyard_elementary": {
        "name": "小学校の校庭",
        "width": 2500,
        "ceiling_height": null,
        "obstacles": []
    },
    "schoolyard_middle": {
        "name": "中学校の校庭",
        "width": 2500,
        "ceiling_height": null,
        "obstacles": []
    },
    "schoolyard_high": {
        "name": "高校の校庭",
        "width": 2500,
        "ceiling_height": null,
        "obstacles": []
    },
    "infirmary_elementary": {
        "name": "小学校の保健室",
        "width": 1400,
        "ceiling_height": 270,
        "obstacles": []
    },
    "infirmary_middle": {
        "name": "中学校の保健室",
        "width": 1400,
        "ceiling_height": 270,
        "obstacles": []
    },
    "infirmary_high": {
        "name": "高校の保健室",
        "width": 1400,
        "ceiling_height": 270,
        "obstacles": []
    },
    "gymnasium_elementary": {
        "name": "小学校の体育館",
        "width": 3200,
        "ceiling_height": 400,
        "obstacles": []
    },
    "gymnasium_middle": {
        "name": "中学校の体育館",
        "width": 3200,
        "ceiling_height": 400,
        "obstacles": []
    },
    "gymnasium_high": {
        "name": "高校の体育館",
        "width": 3200,
        "ceiling_height": 400,
        "obstacles": []
    },
    "station": {
        "name": "駅",
        "width": 2200,
        "ceiling_height": 280,
        "obstacles": [
            {"id": "door_to_outdoor", "x": 50, "x2": 190, "height": 200, "type": "overhead"},
            {"id": "ticket_gate", "x": 350, "x2": 700, "height": 100, "type": "ground"},
            {"id": "station_bench", "x": 900, "x2": 1100, "height": 42, "type": "ground"},
            {"id": "timetable", "x": 1150, "x2": 1250, "height": 200, "type": "background"},
            {"id": "station_vending", "x": 1380, "x2": 1460, "height": 183, "type": "ground"},
            {"id": "station_name_sign", "x": 1600, "x2": 1800, "height": 200, "type": "background"}
        ]
    }
}

static func build_stage(stage_id: String, parent_node: Node2D, cm_to_px: float, age: int = 0) -> void:
    stage_id = resolve_stage_id(stage_id, age)
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
    if stage_id == "room" or stage_id == "myroom" or is_school_classroom_stage(stage_id):
        floor_rect.color = Color(0.45, 0.35, 0.25) # フローリング風
    elif is_school_hallway_stage(stage_id):
        floor_rect.color = Color(0.50, 0.55, 0.50) # リノリウム風グレーグリーン
    elif is_infirmary_stage(stage_id):
        floor_rect.color = Color(0.82, 0.88, 0.82) # 明るい薄緑（保健室リノリウム）
    elif stage_id == "outdoor" or stage_id == "adjacent_town" or stage_id == "gakuenmachi":
        floor_rect.color = Color(0.55, 0.53, 0.50) # アスファルト
    elif is_schoolyard_stage(stage_id):
        floor_rect.color = Color(0.68, 0.62, 0.48) # 砂地（校庭）
    elif is_gymnasium_stage(stage_id):
        floor_rect.color = Color(0.66, 0.49, 0.29) # 体育館フロア
    elif stage_id == "station" or stage_id == "platform" or stage_id == "gakuenmae":
        floor_rect.color = Color(0.58, 0.57, 0.55) # コンクリート（駅）
    else: # train
        floor_rect.color = Color(0.32, 0.32, 0.35) # 電車の床
    floor_rect.position = Vector2(0, 0)
    floor_rect.size = Vector2(stage_data["width"] * cm_to_px, 100)
    floor_body.add_child(floor_rect)
    
    parent_node.add_child(floor_body)

    # 左右の見えない壁（ステージ端から落ちないようにする）
    var _edge_w_px: float = stage_data["width"] * cm_to_px
    var wall_positions: Array[float] = []
    if stage_id != "adjacent_town":
        wall_positions.append(0.0)
    if stage_id != "outdoor":
        wall_positions.append(_edge_w_px)
    for wall_x in wall_positions:
        var wall_body = StaticBody2D.new()
        wall_body.set_meta("is_stage_obj", true)
        var wall_shape = CollisionShape2D.new()
        var wall_rect = RectangleShape2D.new()
        wall_rect.size = Vector2(20, 2000)
        wall_shape.shape = wall_rect
        wall_shape.position = Vector2(wall_x, -500)
        wall_body.add_child(wall_shape)
        parent_node.add_child(wall_body)
    if stage_id == "outdoor":
        _add_edge_trigger(parent_node, "RightEdgeTrigger", _edge_w_px, "adjacent_town")
    elif stage_id == "adjacent_town":
        _add_edge_trigger(parent_node, "LeftEdgeTrigger", 0.0, "outdoor")
    elif stage_id == "station":
        # 駅右端 → ホーム（右端から150cm手前でトリガー、壁は端に残す）
        _add_edge_trigger(parent_node, "RightEdgeTrigger", (_edge_w_px - 150 * cm_to_px), "platform")
    elif stage_id == "platform":
        # ホーム左端 → 駅（左端から150cm手前でトリガー、壁は端に残す）
        _add_edge_trigger(parent_node, "LeftEdgeTrigger", (150 * cm_to_px), "station")

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
            wall_top_color = Color(0.90, 0.85, 0.78) # 温かみのあるクリーム
            wall_btm_color = Color(0.80, 0.75, 0.68)
            molding_color = Color(0.65, 0.55, 0.40)
            baseboard_color = Color(0.45, 0.30, 0.18)
        else:
            wall_top_color = Color(0.40, 0.45, 0.50) # グレー系（リビング）
            wall_btm_color = Color(0.30, 0.35, 0.40)
            molding_color = Color(0.20, 0.20, 0.25)
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

    # 電車ステージ: 車内背景
    elif stage_id == "train" and stage_data.get("ceiling_height") != null:
        var train_bg = Node2D.new()
        train_bg.set_meta("is_stage_obj", true)
        train_bg.z_index = -5
        var ceil_h_px = stage_data["ceiling_height"] * cm_to_px
        var stage_w_px = stage_data["width"] * cm_to_px
        # 壁（アイボリー上部）
        var tw_top = ColorRect.new()
        tw_top.color = Color(0.90, 0.88, 0.84)
        tw_top.position = Vector2(0, -ceil_h_px)
        tw_top.size = Vector2(stage_w_px, ceil_h_px * 0.55)
        train_bg.add_child(tw_top)
        # 腰壁（青みグレー）
        var tw_btm = ColorRect.new()
        tw_btm.color = Color(0.45, 0.52, 0.60)
        tw_btm.position = Vector2(0, -ceil_h_px * 0.45)
        tw_btm.size = Vector2(stage_w_px, ceil_h_px * 0.45)
        train_bg.add_child(tw_btm)
        # 見切り材
        var tw_mold = ColorRect.new()
        tw_mold.color = Color(0.35, 0.38, 0.42)
        tw_mold.position = Vector2(0, -ceil_h_px * 0.45 - 5)
        tw_mold.size = Vector2(stage_w_px, 10)
        train_bg.add_child(tw_mold)
        # 窓（ドア間3か所）
        for wx in [320, 900, 1490]:
            var win_w = 200 * cm_to_px
            var win_h = 85 * cm_to_px
            var win_y = -185 * cm_to_px
            var wf = ColorRect.new()
            wf.color = Color(0.38, 0.40, 0.43)
            wf.position = Vector2(wx * cm_to_px - 5, win_y - 5)
            wf.size = Vector2(win_w + 10, win_h + 10)
            train_bg.add_child(wf)
            var wg = ColorRect.new()
            wg.color = Color(0.55, 0.70, 0.88, 0.72)
            wg.position = Vector2(wx * cm_to_px, win_y)
            wg.size = Vector2(win_w, win_h)
            train_bg.add_child(wg)
            var wsky = ColorRect.new()
            wsky.color = Color(0.62, 0.82, 0.98, 0.5)
            wsky.position = Vector2(wx * cm_to_px + 5, win_y + 5)
            wsky.size = Vector2(win_w - 10, win_h * 0.55)
            train_bg.add_child(wsky)
            # 窓の中桟
            var wmid = ColorRect.new()
            wmid.color = Color(0.38, 0.40, 0.43)
            wmid.position = Vector2(wx * cm_to_px, win_y + win_h * 0.55 - 2)
            wmid.size = Vector2(win_w, 5)
            train_bg.add_child(wmid)
        # 蛍光灯帯（天井）
        for lx in [180, 600, 1020, 1440, 1800]:
            var fl = ColorRect.new()
            fl.color = Color(1.0, 0.98, 0.90)
            fl.position = Vector2(lx * cm_to_px, -ceil_h_px + 2)
            fl.size = Vector2(200 * cm_to_px, 10)
            train_bg.add_child(fl)
        # 広告パネル（窓上）
        for ax in [320, 900, 1490]:
            var ad = ColorRect.new()
            ad.color = Color(0.82, 0.82, 0.86)
            ad.position = Vector2(ax * cm_to_px, -215 * cm_to_px)
            ad.size = Vector2(200 * cm_to_px, 25 * cm_to_px)
            train_bg.add_child(ad)
        # 広告パネル（ドア上）
        for door_cx in [140, 670, 1310, 1860]:
            var dad = ColorRect.new()
            dad.color = Color(0.90, 0.88, 0.92)
            dad.position = Vector2((door_cx - 85) * cm_to_px, -210 * cm_to_px)
            dad.size = Vector2(170 * cm_to_px, 22 * cm_to_px)
            train_bg.add_child(dad)
            # 広告の色帯（左端）
            var dad_accent = ColorRect.new()
            dad_accent.color = Color(0.25, 0.45, 0.75)
            dad_accent.position = Vector2((door_cx - 85) * cm_to_px, -210 * cm_to_px)
            dad_accent.size = Vector2(6 * cm_to_px, 22 * cm_to_px)
            train_bg.add_child(dad_accent)
        # 吊り革バー
        var bar = ColorRect.new()
        bar.color = Color(0.48, 0.50, 0.55)
        bar.position = Vector2(250 * cm_to_px, - (stage_data["ceiling_height"] - 67) * cm_to_px)
        bar.size = Vector2(1500 * cm_to_px, 5)
        train_bg.add_child(bar)
        parent_node.add_child(train_bg)

    # 屋外ステージ: 空と建物の背景
    elif stage_id == "outdoor":
        var out_bg = Node2D.new()
        out_bg.set_meta("is_stage_obj", true)
        out_bg.z_index = -10
        var stage_w_px = stage_data["width"] * cm_to_px
        # 空（上）
        var sky_top = ColorRect.new()
        sky_top.color = Color(0.42, 0.68, 0.96)
        sky_top.position = Vector2(0, -600 * cm_to_px)
        sky_top.size = Vector2(stage_w_px, 400 * cm_to_px)
        out_bg.add_child(sky_top)
        # 空（下・薄く）
        var sky_btm = ColorRect.new()
        sky_btm.color = Color(0.62, 0.82, 0.98)
        sky_btm.position = Vector2(0, -200 * cm_to_px)
        sky_btm.size = Vector2(stage_w_px, 200 * cm_to_px)
        out_bg.add_child(sky_btm)
        # ===== 家の外観（左端、door_to_roomの右隣） =====
        var house_x = 130 * cm_to_px
        var house_w = 290 * cm_to_px
        var house_h = 240 * cm_to_px
        var h_wall = ColorRect.new()
        h_wall.color = Color(0.92, 0.88, 0.80)
        h_wall.position = Vector2(house_x, -house_h)
        h_wall.size = Vector2(house_w, house_h)
        out_bg.add_child(h_wall)
        # 屋根（三角形）
        var roof = Polygon2D.new()
        roof.polygon = PackedVector2Array([
            Vector2(house_x - 15, -house_h),
            Vector2(house_x + house_w + 15, -house_h),
            Vector2(house_x + house_w * 0.5, - (house_h + 110 * cm_to_px)),
        ])
        roof.color = Color(0.50, 0.20, 0.10)
        out_bg.add_child(roof)
        # 家の窓2つ
        for hwin_x_off in [20.0, house_w - 80.0]:
            var hw = ColorRect.new()
            hw.color = Color(0.68, 0.83, 1.0, 0.85)
            hw.position = Vector2(house_x + hwin_x_off * cm_to_px, - (house_h - 45 * cm_to_px))
            hw.size = Vector2(55 * cm_to_px, 65 * cm_to_px)
            out_bg.add_child(hw)
            var hwf = ReferenceRect.new()
            hwf.editor_only = false
            hwf.border_color = Color(0.50, 0.45, 0.38)
            hwf.border_width = 3.0
            hwf.position = hw.position
            hwf.size = hw.size
            out_bg.add_child(hwf)
        # 家の外壁の巾木
        var hbase = ColorRect.new()
        hbase.color = Color(0.70, 0.60, 0.48)
        hbase.position = Vector2(house_x, -15 * cm_to_px)
        hbase.size = Vector2(house_w, 15 * cm_to_px)
        out_bg.add_child(hbase)
        # ===== 駅ビル（door_to_station の背後） =====
        var st_x = 620 * cm_to_px
        var st_w = 180 * cm_to_px
        var st_h = 320 * cm_to_px
        var st_wall = ColorRect.new()
        st_wall.color = Color(0.72, 0.74, 0.78)
        st_wall.position = Vector2(st_x, -st_h)
        st_wall.size = Vector2(st_w, st_h)
        out_bg.add_child(st_wall)
        # 駅の看板
        var st_sign = ColorRect.new()
        st_sign.color = Color(0.12, 0.28, 0.62)
        st_sign.position = Vector2(st_x + 8 * cm_to_px, - (st_h - 15 * cm_to_px))
        st_sign.size = Vector2(st_w - 16 * cm_to_px, 28 * cm_to_px)
        out_bg.add_child(st_sign)
        # 駅の窓
        for stw_x in [0, 1]:
            var stw = ColorRect.new()
            stw.color = Color(0.55, 0.72, 0.90, 0.75)
            stw.position = Vector2(st_x + (15 + stw_x * 90) * cm_to_px, - (st_h - 60 * cm_to_px))
            stw.size = Vector2(60 * cm_to_px, 80 * cm_to_px)
            out_bg.add_child(stw)
        # ===== 学校（door_to_school の背後） =====
        var sc_x = 980 * cm_to_px
        var sc_w = 560 * cm_to_px
        var sc_h = 380 * cm_to_px
        var sc_wall = ColorRect.new()
        sc_wall.color = Color(0.82, 0.80, 0.72)
        sc_wall.position = Vector2(sc_x, -sc_h)
        sc_wall.size = Vector2(sc_w, sc_h)
        out_bg.add_child(sc_wall)
        # 学校の窓（格子状）
        for row in range(3):
            for col in range(4):
                var scw = ColorRect.new()
                scw.color = Color(0.58, 0.74, 0.90, 0.78)
                scw.position = Vector2(sc_x + (24 + col * 112) * cm_to_px, - (sc_h - (30 + row * 110) * cm_to_px))
                scw.size = Vector2(60 * cm_to_px, 80 * cm_to_px)
                out_bg.add_child(scw)
        var sc_gate = ColorRect.new()
        sc_gate.color = Color(0.34, 0.40, 0.50)
        sc_gate.position = Vector2(1200 * cm_to_px, -220 * cm_to_px)
        sc_gate.size = Vector2(120 * cm_to_px, 220 * cm_to_px)
        out_bg.add_child(sc_gate)
        var sc_fence = ColorRect.new()
        sc_fence.color = Color(0.70, 0.72, 0.76)
        sc_fence.position = Vector2(1320 * cm_to_px, -120 * cm_to_px)
        sc_fence.size = Vector2(180 * cm_to_px, 12 * cm_to_px)
        out_bg.add_child(sc_fence)
        parent_node.add_child(out_bg)

    elif stage_id == "adjacent_town":
        var town_bg = Node2D.new()
        town_bg.set_meta("is_stage_obj", true)
        town_bg.z_index = -10
        var town_w_px = stage_data["width"] * cm_to_px
        var town_sky_top = ColorRect.new()
        town_sky_top.color = Color(0.46, 0.72, 0.98)
        town_sky_top.position = Vector2(0, -600 * cm_to_px)
        town_sky_top.size = Vector2(town_w_px, 400 * cm_to_px)
        town_bg.add_child(town_sky_top)
        var town_sky_btm = ColorRect.new()
        town_sky_btm.color = Color(0.67, 0.84, 0.99)
        town_sky_btm.position = Vector2(0, -200 * cm_to_px)
        town_sky_btm.size = Vector2(town_w_px, 200 * cm_to_px)
        town_bg.add_child(town_sky_btm)
        for house_data in [
            {"x": 180.0, "w": 220.0, "h": 240.0, "color": Color(0.88, 0.83, 0.76), "roof": Color(0.52, 0.30, 0.24)},
            {"x": 470.0, "w": 180.0, "h": 210.0, "color": Color(0.80, 0.82, 0.88), "roof": Color(0.35, 0.30, 0.28)},
        ]:
            var hx = float(house_data["x"]) * cm_to_px
            var hw = float(house_data["w"]) * cm_to_px
            var hh = float(house_data["h"]) * cm_to_px
            var house = ColorRect.new()
            house.color = house_data["color"]
            house.position = Vector2(hx, -hh)
            house.size = Vector2(hw, hh)
            town_bg.add_child(house)
            # 三角屋根
            var overhang = 8.0 * cm_to_px
            var roof = Polygon2D.new()
            roof.polygon = PackedVector2Array([
                Vector2(hx - overhang, -hh),
                Vector2(hx + hw + overhang, -hh),
                Vector2(hx + hw * 0.5, -hh - 50.0 * cm_to_px),
            ])
            roof.color = house_data["roof"]
            town_bg.add_child(roof)
            # 窓（左右2つ）
            for wx_off in [0.15, 0.60]:
                var win = ColorRect.new()
                win.color = Color(0.62, 0.78, 0.90, 0.6)
                win.position = Vector2(hx + hw * wx_off, -hh * 0.6)
                win.size = Vector2(hw * 0.18, hh * 0.2)
                town_bg.add_child(win)
        var school_wall = ColorRect.new()
        school_wall.color = Color(0.78, 0.80, 0.84)
        school_wall.position = Vector2(1070 * cm_to_px, -320 * cm_to_px)
        school_wall.size = Vector2(260 * cm_to_px, 320 * cm_to_px)
        town_bg.add_child(school_wall)
        # 学校建物の窓（2列 × 2行）
        for sw_row in range(2):
            for sw_col in range(2):
                var swin = ColorRect.new()
                swin.color = Color(0.62, 0.78, 0.90, 0.55)
                swin.position = Vector2((1095 + sw_col * 100) * cm_to_px, -(265 - sw_row * 90) * cm_to_px)
                swin.size = Vector2(50 * cm_to_px, 60 * cm_to_px)
                town_bg.add_child(swin)
        var school_gate = ColorRect.new()
        school_gate.color = Color(0.32, 0.38, 0.48)
        school_gate.position = Vector2(1160 * cm_to_px, -220 * cm_to_px)
        school_gate.size = Vector2(120 * cm_to_px, 220 * cm_to_px)
        town_bg.add_child(school_gate)
        parent_node.add_child(town_bg)

    elif stage_id == "platform":
        var platform_bg = Node2D.new()
        platform_bg.set_meta("is_stage_obj", true)
        platform_bg.z_index = -10
        var platform_w_px = stage_data["width"] * cm_to_px
        var pf_sky_top = ColorRect.new()
        pf_sky_top.color = Color(0.42, 0.68, 0.94)
        pf_sky_top.position = Vector2(0, -600 * cm_to_px)
        pf_sky_top.size = Vector2(platform_w_px, 400 * cm_to_px)
        platform_bg.add_child(pf_sky_top)
        var pf_sky_btm = ColorRect.new()
        pf_sky_btm.color = Color(0.66, 0.84, 0.98)
        pf_sky_btm.position = Vector2(0, -200 * cm_to_px)
        pf_sky_btm.size = Vector2(platform_w_px, 200 * cm_to_px)
        platform_bg.add_child(pf_sky_btm)
        var canopy = ColorRect.new()
        canopy.color = Color(0.72, 0.75, 0.80)
        canopy.position = Vector2(180 * cm_to_px, -250 * cm_to_px)
        canopy.size = Vector2(1500 * cm_to_px, 28 * cm_to_px)
        platform_bg.add_child(canopy)
        for pillar_x in [260, 720, 1180, 1640]:
            var pillar = ColorRect.new()
            pillar.color = Color(0.58, 0.60, 0.64)
            pillar.position = Vector2(pillar_x * cm_to_px, -250 * cm_to_px)
            pillar.size = Vector2(20 * cm_to_px, 250 * cm_to_px)
            platform_bg.add_child(pillar)
        var rails = ColorRect.new()
        rails.color = Color(0.28, 0.28, 0.32)
        rails.position = Vector2(0, 18)
        rails.size = Vector2(platform_w_px, 18)
        platform_bg.add_child(rails)
        var tactile = ColorRect.new()
        tactile.color = Color(0.92, 0.82, 0.15)
        tactile.position = Vector2(0, -8)
        tactile.size = Vector2(platform_w_px, 8)
        platform_bg.add_child(tactile)
        # ===== 電車（右側に停車）=====
        var tr_x = 1600 * cm_to_px
        var tr_w = platform_w_px - tr_x
        var tr_h = 230 * cm_to_px
        # 車体メイン（シルバーホワイト）
        var tr_body = ColorRect.new()
        tr_body.color = Color(0.88, 0.88, 0.90)
        tr_body.position = Vector2(tr_x, -tr_h)
        tr_body.size = Vector2(tr_w, tr_h)
        platform_bg.add_child(tr_body)
        # 前面パネル（左端）
        var tr_front = ColorRect.new()
        tr_front.color = Color(0.76, 0.76, 0.80)
        tr_front.position = Vector2(tr_x, -tr_h)
        tr_front.size = Vector2(10 * cm_to_px, tr_h)
        platform_bg.add_child(tr_front)
        # 青帯
        var tr_stripe = ColorRect.new()
        tr_stripe.color = Color(0.18, 0.48, 0.82)
        tr_stripe.position = Vector2(tr_x, -tr_h * 0.58)
        tr_stripe.size = Vector2(tr_w, tr_h * 0.09)
        platform_bg.add_child(tr_stripe)
        # 窓（ドアエリア x:1880-2060 を避けて配置）
        var win_top_y = -tr_h + tr_h * 0.08
        var win_h_px = tr_h * 0.30
        var win_w_px = 80 * cm_to_px
        for wi in range(6):
            var wx = tr_x + (20 + wi * 100) * cm_to_px
            var wx_cm = wx / cm_to_px
            if wx_cm >= 1860 and wx_cm <= 2070:
                continue
            if wx + win_w_px > platform_w_px:
                continue
            var win_rect = ColorRect.new()
            win_rect.color = Color(0.50, 0.68, 0.88, 0.75)
            win_rect.position = Vector2(wx, win_top_y)
            win_rect.size = Vector2(win_w_px, win_h_px)
            platform_bg.add_child(win_rect)
        # ドア上梁（door_to_train の上、車体ライン合わせ）
        var tr_door_x = 1880 * cm_to_px
        var tr_door_w = 180 * cm_to_px
        var tr_door_beam_h = tr_h - 185 * cm_to_px
        var tr_door_beam = ColorRect.new()
        tr_door_beam.color = Color(0.86, 0.86, 0.88)
        tr_door_beam.position = Vector2(tr_door_x, -tr_h)
        tr_door_beam.size = Vector2(tr_door_w, tr_door_beam_h)
        platform_bg.add_child(tr_door_beam)
        # 下部フレームライン
        var tr_underline = ColorRect.new()
        tr_underline.color = Color(0.35, 0.35, 0.38)
        tr_underline.position = Vector2(tr_x, 0)
        tr_underline.size = Vector2(tr_w, 8)
        platform_bg.add_child(tr_underline)
        parent_node.add_child(platform_bg)

    elif stage_id == "gakuenmae":
        var gakuenmae_bg = Node2D.new()
        gakuenmae_bg.set_meta("is_stage_obj", true)
        gakuenmae_bg.z_index = -10
        var gakuenmae_w_px = stage_data["width"] * cm_to_px
        var gm_sky_top = ColorRect.new()
        gm_sky_top.color = Color(0.44, 0.70, 0.96)
        gm_sky_top.position = Vector2(0, -600 * cm_to_px)
        gm_sky_top.size = Vector2(gakuenmae_w_px, 400 * cm_to_px)
        gakuenmae_bg.add_child(gm_sky_top)
        var gm_sky_btm = ColorRect.new()
        gm_sky_btm.color = Color(0.72, 0.88, 0.99)
        gm_sky_btm.position = Vector2(0, -200 * cm_to_px)
        gm_sky_btm.size = Vector2(gakuenmae_w_px, 200 * cm_to_px)
        gakuenmae_bg.add_child(gm_sky_btm)
        var sign_base = ColorRect.new()
        sign_base.color = Color(0.12, 0.45, 0.28)
        sign_base.position = Vector2(520 * cm_to_px, -190 * cm_to_px)
        sign_base.size = Vector2(260 * cm_to_px, 44 * cm_to_px)
        gakuenmae_bg.add_child(sign_base)
        var fence = ColorRect.new()
        fence.color = Color(0.75, 0.78, 0.82)
        fence.position = Vector2(1080 * cm_to_px, -120 * cm_to_px)
        fence.size = Vector2(450 * cm_to_px, 12 * cm_to_px)
        gakuenmae_bg.add_child(fence)
        var tactile_small = ColorRect.new()
        tactile_small.color = Color(0.92, 0.82, 0.15)
        tactile_small.position = Vector2(0, -8)
        tactile_small.size = Vector2(gakuenmae_w_px, 8)
        gakuenmae_bg.add_child(tactile_small)
        # ===== 電車（左側に停車）=====
        var gm_tr_x = 0.0
        var gm_tr_w = 280 * cm_to_px
        var gm_tr_h = 230 * cm_to_px
        # 車体メイン
        var gm_tr_body = ColorRect.new()
        gm_tr_body.color = Color(0.88, 0.88, 0.90)
        gm_tr_body.position = Vector2(gm_tr_x, -gm_tr_h)
        gm_tr_body.size = Vector2(gm_tr_w, gm_tr_h)
        gakuenmae_bg.add_child(gm_tr_body)
        # 後面パネル（右端）
        var gm_tr_back = ColorRect.new()
        gm_tr_back.color = Color(0.76, 0.76, 0.80)
        gm_tr_back.position = Vector2(gm_tr_w - 10 * cm_to_px, -gm_tr_h)
        gm_tr_back.size = Vector2(10 * cm_to_px, gm_tr_h)
        gakuenmae_bg.add_child(gm_tr_back)
        # 青帯
        var gm_tr_stripe = ColorRect.new()
        gm_tr_stripe.color = Color(0.18, 0.48, 0.82)
        gm_tr_stripe.position = Vector2(gm_tr_x, -gm_tr_h * 0.58)
        gm_tr_stripe.size = Vector2(gm_tr_w, gm_tr_h * 0.09)
        gakuenmae_bg.add_child(gm_tr_stripe)
        # 窓（ドアエリア x:70-230 を避けて配置）
        var gm_win_top_y = -gm_tr_h + gm_tr_h * 0.08
        var gm_win_h_px = gm_tr_h * 0.30
        var gm_win_w_px = 80 * cm_to_px
        for wi in range(2):
            var wx = (wi * 100) * cm_to_px
            var wx_cm = wx / cm_to_px
            if wx_cm < 240:
                continue
            if wx + gm_win_w_px > gm_tr_w:
                continue
            var gm_win = ColorRect.new()
            gm_win.color = Color(0.50, 0.68, 0.88, 0.75)
            gm_win.position = Vector2(wx, gm_win_top_y)
            gm_win.size = Vector2(gm_win_w_px, gm_win_h_px)
            gakuenmae_bg.add_child(gm_win)
        # ドア上梁（door_to_train の上）
        var gm_door_beam_h = gm_tr_h - 185 * cm_to_px
        var gm_door_beam = ColorRect.new()
        gm_door_beam.color = Color(0.86, 0.86, 0.88)
        gm_door_beam.position = Vector2(70 * cm_to_px, -gm_tr_h)
        gm_door_beam.size = Vector2(160 * cm_to_px, gm_door_beam_h)
        gakuenmae_bg.add_child(gm_door_beam)
        # 下部フレームライン
        var gm_tr_underline = ColorRect.new()
        gm_tr_underline.color = Color(0.35, 0.35, 0.38)
        gm_tr_underline.position = Vector2(gm_tr_x, 0)
        gm_tr_underline.size = Vector2(gm_tr_w, 8)
        gakuenmae_bg.add_child(gm_tr_underline)
        parent_node.add_child(gakuenmae_bg)

    elif stage_id == "gakuenmachi":
        var town_arcade = Node2D.new()
        town_arcade.set_meta("is_stage_obj", true)
        town_arcade.z_index = -10
        var arcade_w_px = stage_data["width"] * cm_to_px
        var arcade_sky_top = ColorRect.new()
        arcade_sky_top.color = Color(0.48, 0.72, 0.96)
        arcade_sky_top.position = Vector2(0, -600 * cm_to_px)
        arcade_sky_top.size = Vector2(arcade_w_px, 400 * cm_to_px)
        town_arcade.add_child(arcade_sky_top)
        var arcade_sky_btm = ColorRect.new()
        arcade_sky_btm.color = Color(0.76, 0.89, 0.99)
        arcade_sky_btm.position = Vector2(0, -200 * cm_to_px)
        arcade_sky_btm.size = Vector2(arcade_w_px, 200 * cm_to_px)
        town_arcade.add_child(arcade_sky_btm)
        for shop in [
            {"x": 260.0, "w": 280.0, "h": 250.0, "body": Color(0.86, 0.80, 0.74), "awning": Color(0.82, 0.34, 0.26)},
            {"x": 620.0, "w": 260.0, "h": 230.0, "body": Color(0.78, 0.84, 0.90), "awning": Color(0.26, 0.48, 0.78)},
            {"x": 980.0, "w": 250.0, "h": 240.0, "body": Color(0.88, 0.84, 0.78), "awning": Color(0.28, 0.60, 0.42)},
        ]:
            var sx = float(shop["x"]) * cm_to_px
            var sw2 = float(shop["w"]) * cm_to_px
            var sh = float(shop["h"]) * cm_to_px
            var shop_body = ColorRect.new()
            shop_body.color = shop["body"]
            shop_body.position = Vector2(sx, -sh)
            shop_body.size = Vector2(sw2, sh)
            town_arcade.add_child(shop_body)
            var awning = ColorRect.new()
            awning.color = shop["awning"]
            awning.position = Vector2(sx, -(float(shop["h"]) - 32.0) * cm_to_px)
            awning.size = Vector2(sw2, 26 * cm_to_px)
            town_arcade.add_child(awning)
            # 店舗ガラス窓（2つ）
            for wi in range(2):
                var shop_win = ColorRect.new()
                shop_win.color = Color(0.65, 0.82, 0.93, 0.58)
                shop_win.position = Vector2(sx + sw2 * (0.12 + wi * 0.48), -sh * 0.56)
                shop_win.size = Vector2(sw2 * 0.32, sh * 0.28)
                town_arcade.add_child(shop_win)
        var high_gate_bg = ColorRect.new()
        high_gate_bg.color = Color(0.32, 0.36, 0.46)
        high_gate_bg.position = Vector2(1810 * cm_to_px, -260 * cm_to_px)
        high_gate_bg.size = Vector2(140 * cm_to_px, 260 * cm_to_px)
        town_arcade.add_child(high_gate_bg)
        parent_node.add_child(town_arcade)

    # 学校ステージ: 廊下背景
    elif is_school_hallway_stage(stage_id) and stage_data.get("ceiling_height") != null:
        var hw_bg = Node2D.new()
        hw_bg.set_meta("is_stage_obj", true)
        hw_bg.z_index = -5
        var ceil_h_px = stage_data["ceiling_height"] * cm_to_px
        var stage_w_px = stage_data["width"] * cm_to_px
        var hallway_suffix = _get_stage_suffix_from_stage_id(stage_id)
        var hall_top_col = Color(0.95, 0.93, 0.88)
        var hall_bottom_col = Color(0.70, 0.65, 0.55)
        var hall_mold_col = Color(0.45, 0.40, 0.33)
        if hallway_suffix == "middle":
            hall_top_col = Color(0.92, 0.92, 0.90)
            hall_bottom_col = Color(0.60, 0.65, 0.72)
            hall_mold_col = Color(0.36, 0.40, 0.48)
        elif hallway_suffix == "high":
            hall_top_col = Color(0.90, 0.91, 0.93)
            hall_bottom_col = Color(0.58, 0.60, 0.66)
            hall_mold_col = Color(0.30, 0.34, 0.42)
        # 壁（上部 オフホワイト）
        var hw_top = ColorRect.new()
        hw_top.color = hall_top_col
        hw_top.position = Vector2(0, -ceil_h_px)
        hw_top.size = Vector2(stage_w_px, ceil_h_px * 0.55)
        hw_bg.add_child(hw_top)
        # 腰壁（やや暗めの木目調またはアイボリー）
        var hw_btm = ColorRect.new()
        hw_btm.color = hall_bottom_col
        hw_btm.position = Vector2(0, -ceil_h_px * 0.45)
        hw_btm.size = Vector2(stage_w_px, ceil_h_px * 0.45)
        hw_bg.add_child(hw_btm)
        # 見切り材
        var hw_mold = ColorRect.new()
        hw_mold.color = hall_mold_col
        hw_mold.position = Vector2(0, -ceil_h_px * 0.45 - 5)
        hw_mold.size = Vector2(stage_w_px, 10)
        hw_bg.add_child(hw_mold)
        # 巾木
        var hw_base = ColorRect.new()
        hw_base.color = Color(0.35, 0.25, 0.15)
        hw_base.position = Vector2(0, -15)
        hw_base.size = Vector2(stage_w_px, 15)
        hw_bg.add_child(hw_base)
        # 窓（左側の外が見える窓等）
        for wx_cm in [600, 1500, 2100]:
            if wx_cm > stage_data["width"] - 200: continue
            var win_w = 180 * cm_to_px
            var win_h = 130 * cm_to_px
            var win_y = -220 * cm_to_px
            var hwf2 = ColorRect.new()
            hwf2.color = Color(0.55, 0.52, 0.45)
            hwf2.position = Vector2(wx_cm * cm_to_px - 5, win_y - 5)
            hwf2.size = Vector2(win_w + 10, win_h + 10)
            hw_bg.add_child(hwf2)
            var hwg2 = ColorRect.new()
            hwg2.color = Color(0.62, 0.80, 0.95, 0.72)
            hwg2.position = Vector2(wx_cm * cm_to_px, win_y)
            hwg2.size = Vector2(win_w, win_h)
            hw_bg.add_child(hwg2)
            var hsky2 = ColorRect.new()
            hsky2.color = Color(0.48, 0.72, 0.98, 0.45)
            hsky2.position = Vector2(wx_cm * cm_to_px + 5, win_y + 5)
            hsky2.size = Vector2(win_w - 10, win_h * 0.65)
            hw_bg.add_child(hsky2)
            # 中桟
            var hmid2 = ColorRect.new()
            hmid2.color = Color(0.55, 0.52, 0.45)
            hmid2.position = Vector2(wx_cm * cm_to_px, win_y + win_h * 0.65 - 3)
            hmid2.size = Vector2(win_w, 6)
            hw_bg.add_child(hmid2)
        parent_node.add_child(hw_bg)

    # 学校ステージ: 教室背景（年齢で小/中/高を切り替え）
    elif is_school_classroom_stage(stage_id) and stage_data.get("ceiling_height") != null:
        var sch_bg = Node2D.new()
        sch_bg.set_meta("is_stage_obj", true)
        sch_bg.z_index = -5
        var ceil_h_px = stage_data["ceiling_height"] * cm_to_px
        var stage_w_px = stage_data["width"] * cm_to_px
        var classroom_suffix = _get_stage_suffix_from_stage_id(stage_id)
        # 年齢別の壁色
        var wall_top_col: Color
        var wall_btm_col: Color
        var mold_col: Color
        var base_col: Color
        if classroom_suffix == "elementary":
            wall_top_col = Color(0.97, 0.95, 0.84)
            wall_btm_col = Color(0.55, 0.78, 0.45)
            mold_col     = Color(0.40, 0.62, 0.32)
            base_col     = Color(0.35, 0.25, 0.15)
        elif classroom_suffix == "middle":
            wall_top_col = Color(0.91, 0.91, 0.88)
            wall_btm_col = Color(0.42, 0.55, 0.70)
            mold_col     = Color(0.32, 0.42, 0.55)
            base_col     = Color(0.28, 0.28, 0.35)
        else:
            wall_top_col = Color(0.88, 0.88, 0.88)
            wall_btm_col = Color(0.55, 0.55, 0.58)
            mold_col     = Color(0.40, 0.40, 0.42)
            base_col     = Color(0.28, 0.28, 0.30)
        var sw_top = ColorRect.new()
        sw_top.color = wall_top_col
        sw_top.position = Vector2(0, -ceil_h_px)
        sw_top.size = Vector2(stage_w_px, ceil_h_px * 0.60)
        sch_bg.add_child(sw_top)
        var sw_btm = ColorRect.new()
        sw_btm.color = wall_btm_col
        sw_btm.position = Vector2(0, -ceil_h_px * 0.40)
        sw_btm.size = Vector2(stage_w_px, ceil_h_px * 0.40)
        sch_bg.add_child(sw_btm)
        var sw_mold = ColorRect.new()
        sw_mold.color = mold_col
        sw_mold.position = Vector2(0, -ceil_h_px * 0.40 - 5)
        sw_mold.size = Vector2(stage_w_px, 10)
        sch_bg.add_child(sw_mold)
        var sw_base = ColorRect.new()
        sw_base.color = base_col
        sw_base.position = Vector2(0, -15)
        sw_base.size = Vector2(stage_w_px, 15)
        sch_bg.add_child(sw_base)
        # 小学校: 掲示板（カラフルな装飾帯）
        if classroom_suffix == "elementary":
            var disp = ColorRect.new()
            disp.color = Color(0.95, 0.85, 0.30, 0.70)
            disp.position = Vector2(stage_w_px * 0.55, -ceil_h_px * 0.85)
            disp.size = Vector2(stage_w_px * 0.38, ceil_h_px * 0.20)
            sch_bg.add_child(disp)
        # 窓（等間隔・右壁側）
        for wx_cm in [850, 1200]:
            var win_w = 240 * cm_to_px
            var win_h = 140 * cm_to_px
            var win_y = -280 * cm_to_px
            var wf2 = ColorRect.new()
            wf2.color = mold_col
            wf2.position = Vector2(wx_cm * cm_to_px - 5, win_y - 5)
            wf2.size = Vector2(win_w + 10, win_h + 10)
            sch_bg.add_child(wf2)
            var wg2 = ColorRect.new()
            wg2.color = Color(0.62, 0.80, 0.95, 0.72)
            wg2.position = Vector2(wx_cm * cm_to_px, win_y)
            wg2.size = Vector2(win_w, win_h)
            sch_bg.add_child(wg2)
            var wsky2 = ColorRect.new()
            wsky2.color = Color(0.48, 0.72, 0.98, 0.45)
            wsky2.position = Vector2(wx_cm * cm_to_px + 5, win_y + 5)
            wsky2.size = Vector2(win_w - 10, win_h * 0.65)
            sch_bg.add_child(wsky2)
            var wmid2 = ColorRect.new()
            wmid2.color = mold_col
            wmid2.position = Vector2(wx_cm * cm_to_px, win_y + win_h * 0.65 - 3)
            wmid2.size = Vector2(win_w, 6)
            sch_bg.add_child(wmid2)
        parent_node.add_child(sch_bg)

    # 保健室ステージ: 白い壁と清潔感のある背景
    elif is_infirmary_stage(stage_id) and stage_data.get("ceiling_height") != null:
        var inf_bg = Node2D.new()
        inf_bg.set_meta("is_stage_obj", true)
        inf_bg.z_index = -5
        var ceil_h_px = stage_data["ceiling_height"] * cm_to_px
        var stage_w_px = stage_data["width"] * cm_to_px
        var infirmary_suffix = _get_stage_suffix_from_stage_id(stage_id)
        var inf_wall_col = Color(0.96, 0.97, 0.95)
        var inf_lower_col = Color(0.78, 0.90, 0.78)
        var inf_mold_col = Color(0.55, 0.70, 0.55)
        if infirmary_suffix == "middle":
            inf_wall_col = Color(0.94, 0.96, 0.97)
            inf_lower_col = Color(0.74, 0.84, 0.88)
            inf_mold_col = Color(0.48, 0.60, 0.68)
        elif infirmary_suffix == "high":
            inf_wall_col = Color(0.95, 0.95, 0.97)
            inf_lower_col = Color(0.80, 0.84, 0.90)
            inf_mold_col = Color(0.50, 0.56, 0.66)
        # 壁（白系）
        var iw_top = ColorRect.new()
        iw_top.color = inf_wall_col
        iw_top.position = Vector2(0, -ceil_h_px)
        iw_top.size = Vector2(stage_w_px, ceil_h_px)
        inf_bg.add_child(iw_top)
        # 腰壁（薄い緑）
        var iw_btm = ColorRect.new()
        iw_btm.color = inf_lower_col
        iw_btm.position = Vector2(0, -ceil_h_px * 0.40)
        iw_btm.size = Vector2(stage_w_px, ceil_h_px * 0.40)
        inf_bg.add_child(iw_btm)
        # 見切り材
        var iw_mold = ColorRect.new()
        iw_mold.color = inf_mold_col
        iw_mold.position = Vector2(0, -ceil_h_px * 0.40 - 5)
        iw_mold.size = Vector2(stage_w_px, 10)
        inf_bg.add_child(iw_mold)
        # 巾木
        var iw_base = ColorRect.new()
        iw_base.color = inf_mold_col
        iw_base.position = Vector2(0, -15)
        iw_base.size = Vector2(stage_w_px, 15)
        inf_bg.add_child(iw_base)
        # 窓（右側に2つ）
        for wx_cm in [900, 1150]:
            var win_w = 200 * cm_to_px
            var win_h = 120 * cm_to_px
            var win_y = -230 * cm_to_px
            var iwf = ColorRect.new()
            iwf.color = Color(0.55, 0.60, 0.55)
            iwf.position = Vector2(wx_cm * cm_to_px - 5, win_y - 5)
            iwf.size = Vector2(win_w + 10, win_h + 10)
            inf_bg.add_child(iwf)
            var iwg = ColorRect.new()
            iwg.color = Color(0.62, 0.85, 0.75, 0.68)
            iwg.position = Vector2(wx_cm * cm_to_px, win_y)
            iwg.size = Vector2(win_w, win_h)
            inf_bg.add_child(iwg)
            # 窓の中桟
            var iwmid = ColorRect.new()
            iwmid.color = Color(0.55, 0.60, 0.55)
            iwmid.position = Vector2(wx_cm * cm_to_px, win_y + win_h * 0.6 - 3)
            iwmid.size = Vector2(win_w, 5)
            inf_bg.add_child(iwmid)
        # 天井の蛍光灯（白い帯）
        for lx_cm in [300, 700, 1100]:
            var fl = ColorRect.new()
            fl.color = Color(1.0, 1.0, 0.95, 0.9)
            fl.position = Vector2(lx_cm * cm_to_px, -ceil_h_px)
            fl.size = Vector2(200 * cm_to_px, 8)
            inf_bg.add_child(fl)
        parent_node.add_child(inf_bg)

    # 校庭ステージ: 空と砂地と学校外観の背景
    elif is_schoolyard_stage(stage_id):
        var sy_bg = Node2D.new()
        sy_bg.set_meta("is_stage_obj", true)
        sy_bg.z_index = -10
        var stage_w_px = stage_data["width"] * cm_to_px
        var yard_suffix = _get_stage_suffix_from_stage_id(stage_id)
        var yard_sky = Color(0.48, 0.72, 0.98)
        var yard_ground = Color(0.65, 0.84, 0.99)
        var yard_building = Color(0.82, 0.80, 0.72)
        if yard_suffix == "middle":
            yard_sky = Color(0.45, 0.68, 0.95)
            yard_ground = Color(0.61, 0.79, 0.94)
            yard_building = Color(0.76, 0.78, 0.82)
        elif yard_suffix == "high":
            yard_sky = Color(0.42, 0.64, 0.92)
            yard_ground = Color(0.58, 0.76, 0.92)
            yard_building = Color(0.72, 0.74, 0.80)
        # 空（上）: 400cm以上は上空の青
        var sy_sky = ColorRect.new()
        sy_sky.color = yard_sky
        sy_sky.position = Vector2(0, -800 * cm_to_px)
        sy_sky.size = Vector2(stage_w_px, 400 * cm_to_px)
        sy_bg.add_child(sy_sky)
        # 地平線付近の空: 0〜400cmを地面色グラデーション的に見せる（描画高さ400cm確保）
        var sy_sky_btm = ColorRect.new()
        sy_sky_btm.color = yard_ground
        sy_sky_btm.position = Vector2(0, -400 * cm_to_px)
        sy_sky_btm.size = Vector2(stage_w_px, 400 * cm_to_px)
        sy_bg.add_child(sy_sky_btm)
        # 学校校舎（左端、door_to_school_hallway の背後）
        var sc_x = 40 * cm_to_px
        var sc_w = 260 * cm_to_px
        var sc_h = 320 * cm_to_px
        var sc_wall = ColorRect.new()
        sc_wall.color = yard_building
        sc_wall.position = Vector2(sc_x, -sc_h)
        sc_wall.size = Vector2(sc_w, sc_h)
        sy_bg.add_child(sc_wall)
        # 校舎の窓（格子状）
        for row in range(2):
            for col in range(3):
                var scw = ColorRect.new()
                scw.color = Color(0.58, 0.74, 0.90, 0.78)
                scw.position = Vector2(sc_x + (15 + col * 80) * cm_to_px, -(sc_h - (30 + row * 110) * cm_to_px))
                scw.size = Vector2(50 * cm_to_px, 70 * cm_to_px)
                sy_bg.add_child(scw)
        # 遠景の木（右側）
        for tx in [1400, 1700, 2100, 2350]:
            var trunk = ColorRect.new()
            trunk.color = Color(0.40, 0.28, 0.15)
            trunk.position = Vector2(tx * cm_to_px - 6, -120 * cm_to_px)
            trunk.size = Vector2(12, 120 * cm_to_px)
            sy_bg.add_child(trunk)
            var foliage = ColorRect.new()
            foliage.color = Color(0.25, 0.60, 0.20)
            foliage.position = Vector2((tx - 40) * cm_to_px, -200 * cm_to_px)
            foliage.size = Vector2(80 * cm_to_px, 80 * cm_to_px)
            sy_bg.add_child(foliage)
        parent_node.add_child(sy_bg)

    # 体育館ステージ: 壁・天井の背景
    elif is_gymnasium_stage(stage_id) and stage_data.get("ceiling_height") != null:
        var gym_bg = Node2D.new()
        gym_bg.set_meta("is_stage_obj", true)
        gym_bg.z_index = -5
        var ceil_h_px = stage_data["ceiling_height"] * cm_to_px
        var stage_w_px = stage_data["width"] * cm_to_px
        # 上部（天井付近）: 濃いグレー
        var gym_upper = ColorRect.new()
        gym_upper.color = Color(0.35, 0.35, 0.38)
        gym_upper.position = Vector2(0, -ceil_h_px)
        gym_upper.size = Vector2(stage_w_px, ceil_h_px * 0.25)
        gym_bg.add_child(gym_upper)
        # 下部（壁面）: 明るいグレー
        var gym_wall = ColorRect.new()
        gym_wall.color = Color(0.72, 0.72, 0.70)
        gym_wall.position = Vector2(0, -ceil_h_px * 0.75)
        gym_wall.size = Vector2(stage_w_px, ceil_h_px * 0.75)
        gym_bg.add_child(gym_wall)
        # 天井ライン（梁の雰囲気）
        var gym_beam = ColorRect.new()
        gym_beam.color = Color(0.28, 0.28, 0.30)
        gym_beam.position = Vector2(0, -ceil_h_px)
        gym_beam.size = Vector2(stage_w_px, 6)
        gym_bg.add_child(gym_beam)
        # 壁と天井部の見切り線
        var gym_molding = ColorRect.new()
        gym_molding.color = Color(0.50, 0.50, 0.52)
        gym_molding.position = Vector2(0, -ceil_h_px * 0.75 - 3)
        gym_molding.size = Vector2(stage_w_px, 6)
        gym_bg.add_child(gym_molding)
        parent_node.add_child(gym_bg)

    # 駅ステージ: 改札・ホームの背景
    elif stage_id == "station" and stage_data.get("ceiling_height") != null:
        var st_bg = Node2D.new()
        st_bg.set_meta("is_stage_obj", true)
        st_bg.z_index = -5
        var ceil_h_px = stage_data["ceiling_height"] * cm_to_px
        var stage_w_px = stage_data["width"] * cm_to_px
        # 壁（上部 明るいグレー）
        var stw_top = ColorRect.new()
        stw_top.color = Color(0.90, 0.90, 0.92)
        stw_top.position = Vector2(0, -ceil_h_px)
        stw_top.size = Vector2(stage_w_px, ceil_h_px * 0.55)
        st_bg.add_child(stw_top)
        # 腰壁（暗めグレー）
        var stw_btm = ColorRect.new()
        stw_btm.color = Color(0.68, 0.69, 0.72)
        stw_btm.position = Vector2(0, -ceil_h_px * 0.45)
        stw_btm.size = Vector2(stage_w_px, ceil_h_px * 0.45)
        st_bg.add_child(stw_btm)
        # 見切り材
        var stw_mold = ColorRect.new()
        stw_mold.color = Color(0.48, 0.49, 0.52)
        stw_mold.position = Vector2(0, -ceil_h_px * 0.45 - 5)
        stw_mold.size = Vector2(stage_w_px, 10)
        st_bg.add_child(stw_mold)
        # 巾木
        var stw_base = ColorRect.new()
        stw_base.color = Color(0.35, 0.35, 0.38)
        stw_base.position = Vector2(0, -15)
        stw_base.size = Vector2(stage_w_px, 15)
        st_bg.add_child(stw_base)
        # 駅名サイン（青い帯）
        for sx_cm in [250, 850, 1450]:
            var st_sign = ColorRect.new()
            st_sign.color = Color(0.10, 0.28, 0.65)
            st_sign.position = Vector2(sx_cm * cm_to_px, -255 * cm_to_px)
            st_sign.size = Vector2(220 * cm_to_px, 32 * cm_to_px)
            st_bg.add_child(st_sign)
            var sign_txt_line = ColorRect.new()
            sign_txt_line.color = Color(1.0, 1.0, 1.0, 0.5)
            sign_txt_line.position = Vector2(sx_cm * cm_to_px + 8, -255 * cm_to_px + 8)
            sign_txt_line.size = Vector2(204 * cm_to_px, 6)
            st_bg.add_child(sign_txt_line)
        # 蛍光灯（天井）
        for lx_cm in [150, 500, 900, 1300, 1700]:
            if lx_cm > stage_data["width"] - 150: continue
            var fl = ColorRect.new()
            fl.color = Color(1.0, 1.0, 0.95, 0.90)
            fl.position = Vector2(lx_cm * cm_to_px, -ceil_h_px + 2)
            fl.size = Vector2(200 * cm_to_px, 10)
            st_bg.add_child(fl)
        # ホーム境界線（黄色の点字ブロック）
        var tactile = ColorRect.new()
        tactile.color = Color(0.90, 0.80, 0.10)
        tactile.position = Vector2(0, -8)
        tactile.size = Vector2(stage_w_px, 8)
        st_bg.add_child(tactile)
        parent_node.add_child(st_bg)

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
        
        # 天井高さを示す黄色線
        var c_line = Line2D.new()
        c_line.add_point(Vector2(0, -ceil_h_px))
        c_line.add_point(Vector2(stage_data["width"] * cm_to_px, -ceil_h_px))
        c_line.width = 3.0
        c_line.default_color = Color(1.0, 1.0, 0.2, 0.9) # やや明るい黄色
        c_line.z_as_relative = false
        c_line.z_index = 10
        ceiling_body.add_child(c_line)
        
        # 表示タイミングによっては見えないため、複数箇所にラベルを配置する
        for lx in [300, 1000, 1700]:
            if lx > stage_data["width"]:
                break
            var c_label = Label.new()
            c_label.text = "Ceiling Height\n%d cm" % int(stage_data["ceiling_height"])
            c_label.add_theme_color_override("font_color", Color.WHITE)
            c_label.add_theme_color_override("font_outline_color", Color.BLACK)
            c_label.add_theme_constant_override("outline_size", 4)
            c_label.add_theme_font_size_override("font_size", 14)
            c_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            c_label.size = Vector2(400 * cm_to_px, 40)
            c_label.position = Vector2((lx - 200) * cm_to_px, -ceil_h_px - 45)
            c_label.z_as_relative = false
            c_label.z_index = 10
            ceiling_body.add_child(c_label)

        parent_node.add_child(ceiling_body)

    # 障害物の生成
    for obs in get_obstacles(stage_id, age):
        _build_obstacle(obs, parent_node, cm_to_px, stage_id)

static func _add_edge_trigger(parent_node: Node2D, trigger_name: String, trigger_x: float, target_stage: String) -> void:
    var edge_area = Area2D.new()
    edge_area.name = trigger_name
    edge_area.set_meta("is_stage_obj", true)
    edge_area.set_meta("edge_target_stage", target_stage)
    edge_area.monitoring = true
    edge_area.monitorable = true
    var col = CollisionShape2D.new()
    var rect = RectangleShape2D.new()
    rect.size = Vector2(24, 2000)
    col.position = Vector2(trigger_x, -500)
    col.shape = rect
    edge_area.add_child(col)
    parent_node.add_child(edge_area)

static func _build_obstacle(obs: Dictionary, parent: Node2D, cm_to_px: float, stage_id: String = "") -> void:
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
    if o_id == "door_to_outdoor":
        cr.color = Color(0, 0, 0, 0)
        var door_x = obs["x"] * cm_to_px
        if stage_id == "train":
            # 電車のスライドドア（ステンレス製）
            var d_frame = ColorRect.new()
            d_frame.color = Color(0.70, 0.72, 0.75)
            d_frame.position = Vector2(door_x, -h_px)
            d_frame.size = Vector2(w_px, h_px)
            d_frame.z_index = -1
            node.add_child(d_frame)
            # ガラス部分（上62%）
            var glass_h = h_px * 0.62
            var glass = ColorRect.new()
            glass.color = Color(0.58, 0.70, 0.84, 0.62)
            glass.position = Vector2(door_x + 8, -h_px + 8)
            glass.size = Vector2(w_px - 16, glass_h - 8)
            glass.z_index = -1
            node.add_child(glass)
            # 不透明パネル（下38%）
            var panel = ColorRect.new()
            panel.color = Color(0.62, 0.65, 0.70)
            panel.position = Vector2(door_x + 8, -h_px + glass_h)
            panel.size = Vector2(w_px - 16, h_px - glass_h - 8)
            panel.z_index = -1
            node.add_child(panel)
            # 横桟（ガラスとパネルの境界）
            var h_bar = ColorRect.new()
            h_bar.color = Color(0.55, 0.57, 0.60)
            h_bar.position = Vector2(door_x + 8, -h_px + glass_h - 4)
            h_bar.size = Vector2(w_px - 16, 8)
            h_bar.z_index = -1
            node.add_child(h_bar)
            # 中央のゴムパッキン（縦線）
            var center_gask = ColorRect.new()
            center_gask.color = Color(0.18, 0.18, 0.20)
            center_gask.position = Vector2(door_x + w_px * 0.5 - 3, -h_px)
            center_gask.size = Vector2(6, h_px)
            center_gask.z_index = -1
            node.add_child(center_gask)
            # 戸先ゴム（左右端）
            for gx in [door_x + 3, door_x + w_px - 6]:
                var gask = ColorRect.new()
                gask.color = Color(0.15, 0.15, 0.18)
                gask.position = Vector2(gx, -h_px)
                gask.size = Vector2(3, h_px)
                gask.z_index = -1
                node.add_child(gask)
        elif is_school_hallway_stage(stage_id):
            # 学校の入り口（四角い校門）
            var gate_x = obs["x"] * cm_to_px
            # コンクリートの左柱
            var left_post = ColorRect.new()
            left_post.color = Color(0.65, 0.63, 0.58)
            left_post.position = Vector2(gate_x, -h_px)
            left_post.size = Vector2(w_px * 0.18, h_px)
            left_post.z_index = -1
            node.add_child(left_post)
            # コンクリートの右柱
            var right_post = ColorRect.new()
            right_post.color = Color(0.65, 0.63, 0.58)
            right_post.position = Vector2(gate_x + w_px * 0.82, -h_px)
            right_post.size = Vector2(w_px * 0.18, h_px)
            right_post.z_index = -1
            node.add_child(right_post)
            # 上の梁（コンクリート）
            var top_beam = ColorRect.new()
            top_beam.color = Color(0.60, 0.58, 0.53)
            top_beam.position = Vector2(gate_x, -h_px)
            top_beam.size = Vector2(w_px, h_px * 0.12)
            top_beam.z_index = -1
            node.add_child(top_beam)
            # 開口部（暗い外の空間）
            var opening = ColorRect.new()
            opening.color = Color(0.55, 0.70, 0.85, 0.25)
            opening.position = Vector2(gate_x + w_px * 0.18, -(h_px * 0.88))
            opening.size = Vector2(w_px * 0.64, h_px * 0.88)
            opening.z_index = -1
            node.add_child(opening)
        elif is_school_classroom_stage(stage_id):
            # 学校の出口ドア（ガラス入り引き戸）
            var d_frame2 = ColorRect.new()
            d_frame2.color = Color(0.28, 0.20, 0.14)
            d_frame2.position = Vector2(door_x, -h_px)
            d_frame2.size = Vector2(w_px, h_px)
            d_frame2.z_index = -1
            node.add_child(d_frame2)
            # ガラス上半分
            var glass2 = ColorRect.new()
            glass2.color = Color(0.62, 0.78, 0.90, 0.58)
            glass2.position = Vector2(door_x + 10, -h_px + 10)
            glass2.size = Vector2(w_px - 20, h_px * 0.52)
            glass2.z_index = -1
            node.add_child(glass2)
            # 中間横桟
            var h_bar2 = ColorRect.new()
            h_bar2.color = Color(0.22, 0.16, 0.10)
            h_bar2.position = Vector2(door_x, -h_px + h_px * 0.52 + 8)
            h_bar2.size = Vector2(w_px, 8)
            h_bar2.z_index = -1
            node.add_child(h_bar2)
            # ドアノブ
            var knob_sc = ColorRect.new()
            knob_sc.color = Color(0.78, 0.68, 0.18)
            knob_sc.position = Vector2(door_x + w_px * 0.78, -h_px * 0.52)
            knob_sc.size = Vector2(10, 18)
            knob_sc.z_index = -1
            node.add_child(knob_sc)
        else: # room stage: 家の玄関（暗い外の空間）
            var outside = ColorRect.new()
            outside.color = Color(0.08, 0.08, 0.12)
            outside.position = Vector2(0, -h_px)
            outside.size = Vector2(obs["x2"] * cm_to_px, h_px + 50)
            outside.z_index = -2
            node.add_child(outside)
            var post = ColorRect.new()
            post.color = Color(0.24, 0.16, 0.12)
            post.position = Vector2(obs["x"] * cm_to_px + w_px * 0.7, -h_px)
            post.size = Vector2(w_px * 0.3, h_px)
            post.z_index = -1
            node.add_child(post)
            var top_wall = ColorRect.new()
            top_wall.color = Color(0.85, 0.82, 0.78)
            top_wall.position = Vector2(0, y_pos)
            top_wall.size = Vector2(obs["x2"] * cm_to_px, h_draw_px + 40)
            top_wall.z_index = -1
            node.add_child(top_wall)

    elif (stage_id == "train" or ((stage_id == "platform" or stage_id == "gakuenmae") and o_id == "door_to_train")) and "door" in o_id:
        # 電車のスライドドア（door_2 / door_3 / door_4）
        cr.color = Color(0, 0, 0, 0)
        var tdoor_x = obs["x"] * cm_to_px
        var td_frame = ColorRect.new()
        td_frame.color = Color(0.70, 0.72, 0.75)
        td_frame.position = Vector2(tdoor_x, -h_px)
        td_frame.size = Vector2(w_px, h_px)
        td_frame.z_index = -1
        node.add_child(td_frame)
        var tglass_h = h_px * 0.62
        var tglass = ColorRect.new()
        tglass.color = Color(0.58, 0.70, 0.84, 0.62)
        tglass.position = Vector2(tdoor_x + 8, -h_px + 8)
        tglass.size = Vector2(w_px - 16, tglass_h - 8)
        tglass.z_index = -1
        node.add_child(tglass)
        var tpanel = ColorRect.new()
        tpanel.color = Color(0.62, 0.65, 0.70)
        tpanel.position = Vector2(tdoor_x + 8, -h_px + tglass_h)
        tpanel.size = Vector2(w_px - 16, h_px - tglass_h - 8)
        tpanel.z_index = -1
        node.add_child(tpanel)
        var th_bar = ColorRect.new()
        th_bar.color = Color(0.55, 0.57, 0.60)
        th_bar.position = Vector2(tdoor_x + 8, -h_px + tglass_h - 4)
        th_bar.size = Vector2(w_px - 16, 8)
        th_bar.z_index = -1
        node.add_child(th_bar)
        var tc_gask = ColorRect.new()
        tc_gask.color = Color(0.18, 0.18, 0.20)
        tc_gask.position = Vector2(tdoor_x + w_px * 0.5 - 3, -h_px)
        tc_gask.size = Vector2(6, h_px)
        tc_gask.z_index = -1
        node.add_child(tc_gask)
        for tgx in [tdoor_x + 3, tdoor_x + w_px - 6]:
            var tgask = ColorRect.new()
            tgask.color = Color(0.15, 0.15, 0.18)
            tgask.position = Vector2(tgx, -h_px)
            tgask.size = Vector2(3, h_px)
            tgask.z_index = -1
            node.add_child(tgask)

    elif (o_id == "door_to_adjacent_town" or o_id == "door_to_gakuenmachi") and is_school_hallway_stage(stage_id):
        # 学校の入り口（四角い校門）
        cr.color = Color(0, 0, 0, 0)
        var gate_x2 = obs["x"] * cm_to_px
        var left_post2 = ColorRect.new()
        left_post2.color = Color(0.65, 0.63, 0.58)
        left_post2.position = Vector2(gate_x2, -h_px)
        left_post2.size = Vector2(w_px * 0.18, h_px)
        left_post2.z_index = -1
        node.add_child(left_post2)
        var right_post2 = ColorRect.new()
        right_post2.color = Color(0.65, 0.63, 0.58)
        right_post2.position = Vector2(gate_x2 + w_px * 0.82, -h_px)
        right_post2.size = Vector2(w_px * 0.18, h_px)
        right_post2.z_index = -1
        node.add_child(right_post2)
        var top_beam2 = ColorRect.new()
        top_beam2.color = Color(0.60, 0.58, 0.53)
        top_beam2.position = Vector2(gate_x2, -h_px)
        top_beam2.size = Vector2(w_px, h_px * 0.12)
        top_beam2.z_index = -1
        node.add_child(top_beam2)
        var opening2 = ColorRect.new()
        opening2.color = Color(0.55, 0.70, 0.85, 0.25)
        opening2.position = Vector2(gate_x2 + w_px * 0.18, -(h_px * 0.88))
        opening2.size = Vector2(w_px * 0.64, h_px * 0.88)
        opening2.z_index = -1
        node.add_child(opening2)

    elif o_id == "side_door":
        # 側面から見たドア（細長い茶色の線）
        # 背景を透明にする
        cr.color = Color(0, 0, 0, 0)
        
        # ドア本体（細い線）
        var door_line = ColorRect.new()
        door_line.color = Color(0.36, 0.25, 0.20) # ドアパネルと同じ茶色
        # w_px の中央付近に少しだけ幅を持たせて配置（幅は適当に10px程度）
        var door_w = min(10.0, w_px)
        
        # 床(y=0)からドアの高さ(-h_px)までの線として描画する
        door_line.position = Vector2(obs["x"] * cm_to_px + (w_px - door_w) * 0.5, -h_px)
        door_line.size = Vector2(door_w, h_px)
        door_line.z_index = -1
        node.add_child(door_line)
        
        # ドアノブ
        var knob_w = 12.0
        var knob_h = 6.0
        var d_knob = ColorRect.new()
        d_knob.color = Color(0.7, 0.7, 0.7) # シルバー
        # 床から約 90cm の位置に配置する
        var knob_y = -90.0 * cm_to_px
        d_knob.position = Vector2(obs["x"] * cm_to_px + (w_px - knob_w) * 0.5, knob_y)
        d_knob.size = Vector2(knob_w, knob_h)
        d_knob.z_index = -1
        node.add_child(d_knob)

    elif o_id == "school_gate_high" or o_id == "school_gate_middle":
        # 鉄製の校門（柵）
        cr.color = Color(0, 0, 0, 0)
        var fence_x = obs["x"] * cm_to_px
        var fence_color = Color(0.20, 0.22, 0.28)
        var post_color = Color(0.25, 0.25, 0.32)
        # 左右の太い支柱
        for px_off in [0.0, w_px - 12.0]:
            var big_post = ColorRect.new()
            big_post.color = post_color
            big_post.position = Vector2(fence_x + px_off, -h_px)
            big_post.size = Vector2(12, h_px)
            big_post.z_index = -1
            node.add_child(big_post)
        # 上横桟
        var top_rail = ColorRect.new()
        top_rail.color = fence_color
        top_rail.position = Vector2(fence_x, -h_px)
        top_rail.size = Vector2(w_px, 8)
        top_rail.z_index = -1
        node.add_child(top_rail)
        # 中横桟
        var mid_rail = ColorRect.new()
        mid_rail.color = fence_color
        mid_rail.position = Vector2(fence_x, -h_px * 0.55)
        mid_rail.size = Vector2(w_px, 6)
        mid_rail.z_index = -1
        node.add_child(mid_rail)
        # 縦棒（等間隔）
        var bar_count = int(w_px / (14 * 1.0)) - 1
        for bi in range(bar_count):
            var bx = fence_x + 12 + bi * (w_px - 24) / bar_count
            var vbar = ColorRect.new()
            vbar.color = fence_color
            vbar.position = Vector2(bx, -h_px)
            vbar.size = Vector2(5, h_px)
            vbar.z_index = -1
            node.add_child(vbar)
            # 縦棒の先端（上）は尖っている
            var tip = ColorRect.new()
            tip.color = fence_color
            tip.position = Vector2(bx, -h_px - 6)
            tip.size = Vector2(5, 6)
            tip.z_index = -1
            node.add_child(tip)

    elif o_id == "shoes_locker":
        cr.color = Color(0.75, 0.73, 0.68)
        var cols = 5
        var rows = 8
        var cell_w = w_px / cols
        var cell_h = h_draw_px / rows
        for r in range(rows):
            for c in range(cols):
                var frame = ReferenceRect.new()
                frame.editor_only = false
                frame.border_color = Color(0.5, 0.48, 0.42)
                frame.border_width = 2
                frame.position = Vector2(c * cell_w, r * cell_h)
                frame.size = Vector2(cell_w, cell_h)
                cr.add_child(frame)
                
    elif o_id == "bulletin_board":
        var board_suffix = _get_stage_suffix_from_stage_id(stage_id)
        var board_color = Color(0.35, 0.55, 0.35)
        var paper_palette = [
            Color(0.95, 0.95, 0.90),
            Color(0.98, 0.88, 0.64),
            Color(0.86, 0.94, 0.72),
            Color(0.92, 0.84, 0.96),
        ]
        if board_suffix == "middle":
            board_color = Color(0.34, 0.44, 0.56)
            paper_palette = [
                Color(0.96, 0.96, 0.92),
                Color(0.88, 0.92, 0.98),
                Color(0.92, 0.90, 0.82),
                Color(0.94, 0.88, 0.88),
            ]
        elif board_suffix == "high":
            board_color = Color(0.30, 0.34, 0.42)
            paper_palette = [
                Color(0.95, 0.95, 0.95),
                Color(0.90, 0.93, 0.98),
                Color(0.96, 0.90, 0.82),
                Color(0.92, 0.92, 0.86),
            ]
        cr.color = board_color
        var frame = ReferenceRect.new()
        frame.editor_only = false
        frame.border_color = Color(0.6, 0.45, 0.25)
        frame.border_width = 8
        frame.position = Vector2(0, 0)
        frame.size = Vector2(w_px, h_draw_px)
        cr.add_child(frame)
        for i in range(4):
            var paper = ColorRect.new()
            paper.color = paper_palette[i % paper_palette.size()]
            paper.position = Vector2(20 + i * (w_px / 4.0), 20 + (i % 2) * 10)
            paper.size = Vector2((w_px - 40) / 4.0 - 10, h_draw_px * 0.7)
            cr.add_child(paper)

    elif o_id == "fire_hydrant":
        cr.color = Color(0.85, 0.2, 0.2)
        var frame = ReferenceRect.new()
        frame.editor_only = false
        frame.border_color = Color(0.6, 0.1, 0.1)
        frame.border_width = 3
        frame.position = Vector2(0, 0)
        frame.size = Vector2(w_px, h_draw_px)
        cr.add_child(frame)
        var lamp = ColorRect.new()
        lamp.color = Color(1.0, 0.4, 0.4)
        lamp.position = Vector2(w_px * 0.5 - 12, 12)
        lamp.size = Vector2(24, 24)
        cr.add_child(lamp)
        var door_line = ColorRect.new()
        door_line.color = Color(0.6, 0.1, 0.1)
        door_line.position = Vector2(w_px * 0.5 - 2, 45)
        door_line.size = Vector2(4, h_draw_px - 45)
        cr.add_child(door_line)

    elif "vending" in o_id:
        cr.color = Color(0, 0, 0, 0)
        
        # 本体 (白系ベース)
        var body = ColorRect.new()
        body.color = Color(0.92, 0.92, 0.95)
        body.position = cr.position
        body.size = cr.size
        node.add_child(body)
        
        # 上部の看板部分 (LEDで光るイメージ)
        var ad_panel = ColorRect.new()
        ad_panel.color = Color(0.85, 0.90, 1.0)
        ad_panel.position = cr.position + Vector2(w_px * 0.05, h_draw_px * 0.02)
        ad_panel.size = Vector2(w_px * 0.9, h_draw_px * 0.08)
        node.add_child(ad_panel)
        
        # 商品ディスプレイ窓
        var display = ColorRect.new()
        display.color = Color(0.12, 0.12, 0.18)
        var disp_w = w_px * 0.86
        var disp_h = h_draw_px * 0.45
        display.position = cr.position + Vector2(w_px * 0.07, h_draw_px * 0.12)
        display.size = Vector2(disp_w, disp_h)
        node.add_child(display)
        
        # 窓の光沢/ガラス感
        var glass = ColorRect.new()
        glass.color = Color(0.8, 0.9, 1.0, 0.15)
        glass.position = display.position
        glass.size = display.size
        node.add_child(glass)
        
        # 商品のダミー並べ (ランダムな色でジュース缶を表現)
        var rows = 3
        var cols = 5
        var item_w = disp_w * 0.12
        var item_h = disp_h * 0.22
        for r in range(rows):
            # 各段に棚を引く
            var shelf = ColorRect.new()
            shelf.color = Color(0.4, 0.4, 0.45)
            shelf.position = display.position + Vector2(0, (r + 1) * (disp_h / rows) - 10)
            shelf.size = Vector2(disp_w, 4)
            node.add_child(shelf)
            
            for c in range(cols):
                var drink = ColorRect.new()
                drink.color = Color(randf_range(0.2, 0.9), randf_range(0.2, 0.9), randf_range(0.2, 0.9))
                var dx = 10 + c * (disp_w / float(cols))
                var dy = 10 + r * (disp_h / float(rows))
                drink.position = display.position + Vector2(dx, dy)
                drink.size = Vector2(item_w, item_h)
                node.add_child(drink)
                # 押しボタン
                var btn = ColorRect.new()
                btn.color = Color(0.8, 0.8, 0.8) if randi() % 2 == 0 else Color(0.8, 0.2, 0.2)
                btn.position = drink.position + Vector2(0, drink.size.y + 6)
                btn.size = Vector2(item_w, 6)
                node.add_child(btn)

        # お札/硬貨投入口
        var slot_panel = ColorRect.new()
        slot_panel.color = Color(0.2, 0.2, 0.25)
        slot_panel.position = cr.position + Vector2(w_px * 0.72, h_draw_px * 0.6)
        slot_panel.size = Vector2(w_px * 0.2, h_draw_px * 0.12)
        node.add_child(slot_panel)
        
        var coin_slot = ColorRect.new()
        coin_slot.color = Color(0.05, 0.05, 0.05)
        coin_slot.position = slot_panel.position + Vector2(5, 5)
        coin_slot.size = Vector2(4, 15)
        node.add_child(coin_slot)
        
        # 取り出し口
        var out_box_frame = ColorRect.new()
        out_box_frame.color = Color(0.2, 0.2, 0.22)
        out_box_frame.position = cr.position + Vector2(w_px * 0.15, h_draw_px * 0.82)
        out_box_frame.size = Vector2(w_px * 0.7, h_draw_px * 0.12)
        node.add_child(out_box_frame)
        
        var out_box = ColorRect.new()
        out_box.color = Color(0.05, 0.05, 0.05)
        out_box.position = out_box_frame.position + Vector2(5, 5)
        out_box.size = Vector2(out_box_frame.size.x - 10, out_box_frame.size.y - 10)
        node.add_child(out_box)
        
        # 自販機の影/立体感
        var shadow = ColorRect.new()
        shadow.color = Color(0, 0, 0, 0.15)
        shadow.position = cr.position + Vector2(w_px * 0.9, 0)
        shadow.size = Vector2(w_px * 0.1, h_draw_px)
        node.add_child(shadow)

    elif "door" in o_id and stage_id == "gakuenmae":
        # 学園前駅のガラス自動ドア（駅スタイル）
        cr.color = Color(0, 0, 0, 0)
        var adoor_x = obs["x"] * cm_to_px
        # 銀色フレーム
        var adoor_frame = ColorRect.new()
        adoor_frame.color = Color(0.68, 0.70, 0.74)
        adoor_frame.position = Vector2(adoor_x, -h_px)
        adoor_frame.size = Vector2(w_px, h_px)
        adoor_frame.z_index = -1
        node.add_child(adoor_frame)
        # ガラス上部（半透明ブルー）
        var adoor_glass_h = h_px * 0.65
        var adoor_glass = ColorRect.new()
        adoor_glass.color = Color(0.60, 0.76, 0.90, 0.55)
        adoor_glass.position = Vector2(adoor_x + 10, -h_px + 10)
        adoor_glass.size = Vector2(w_px - 20, adoor_glass_h - 10)
        adoor_glass.z_index = -1
        node.add_child(adoor_glass)
        # 下パネル（グレー）
        var adoor_panel = ColorRect.new()
        adoor_panel.color = Color(0.58, 0.60, 0.65)
        adoor_panel.position = Vector2(adoor_x + 10, -h_px + adoor_glass_h)
        adoor_panel.size = Vector2(w_px - 20, h_px - adoor_glass_h - 10)
        adoor_panel.z_index = -1
        node.add_child(adoor_panel)
        # 中央縦線（スライドドア合わせ目）
        var adoor_center = ColorRect.new()
        adoor_center.color = Color(0.50, 0.52, 0.56)
        adoor_center.position = Vector2(adoor_x + w_px * 0.5 - 2, -h_px)
        adoor_center.size = Vector2(4, h_px)
        adoor_center.z_index = -1
        node.add_child(adoor_center)

    elif o_id.begins_with("door_to_school_hallway") and stage_id == "adjacent_town":
        # 隣町側から見た中学校ドア（コンクリート校門形）
        cr.color = Color(0, 0, 0, 0)
        var adj_gate_x = obs["x"] * cm_to_px
        var adj_left_post = ColorRect.new()
        adj_left_post.color = Color(0.65, 0.63, 0.58)
        adj_left_post.position = Vector2(adj_gate_x, -h_px)
        adj_left_post.size = Vector2(w_px * 0.18, h_px)
        adj_left_post.z_index = -1
        node.add_child(adj_left_post)
        var adj_right_post = ColorRect.new()
        adj_right_post.color = Color(0.65, 0.63, 0.58)
        adj_right_post.position = Vector2(adj_gate_x + w_px * 0.82, -h_px)
        adj_right_post.size = Vector2(w_px * 0.18, h_px)
        adj_right_post.z_index = -1
        node.add_child(adj_right_post)
        var adj_top_beam = ColorRect.new()
        adj_top_beam.color = Color(0.60, 0.58, 0.53)
        adj_top_beam.position = Vector2(adj_gate_x, -h_px)
        adj_top_beam.size = Vector2(w_px, h_px * 0.12)
        adj_top_beam.z_index = -1
        node.add_child(adj_top_beam)
        var adj_opening = ColorRect.new()
        adj_opening.color = Color(0.55, 0.70, 0.85, 0.25)
        adj_opening.position = Vector2(adj_gate_x + w_px * 0.18, -(h_px * 0.88))
        adj_opening.size = Vector2(w_px * 0.64, h_px * 0.88)
        adj_opening.z_index = -1
        node.add_child(adj_opening)

    elif o_id.begins_with("door_to_school_hallway"):
        # 学校のガラス引き戸ドア（学校内部スタイル）
        cr.color = Color(0, 0, 0, 0)
        var sch_x = obs["x"] * cm_to_px
        # ドア枠（暗い木/アルミ）
        var sd_frame = ColorRect.new()
        sd_frame.color = Color(0.28, 0.20, 0.14)
        sd_frame.position = Vector2(sch_x, -h_px)
        sd_frame.size = Vector2(w_px, h_px)
        sd_frame.z_index = -1
        node.add_child(sd_frame)
        # ガラス上半分
        var sd_glass = ColorRect.new()
        sd_glass.color = Color(0.62, 0.78, 0.90, 0.58)
        sd_glass.position = Vector2(sch_x + 10, -h_px + 10)
        sd_glass.size = Vector2(w_px - 20, h_px * 0.52)
        sd_glass.z_index = -1
        node.add_child(sd_glass)
        # 中間横桟
        var sd_bar = ColorRect.new()
        sd_bar.color = Color(0.22, 0.16, 0.10)
        sd_bar.position = Vector2(sch_x, -h_px + h_px * 0.52 + 8)
        sd_bar.size = Vector2(w_px, 8)
        sd_bar.z_index = -1
        node.add_child(sd_bar)
        # ドアノブ
        var sd_knob = ColorRect.new()
        sd_knob.color = Color(0.78, 0.68, 0.18)
        sd_knob.position = Vector2(sch_x + w_px * 0.78, -h_px * 0.52)
        sd_knob.size = Vector2(10, 18)
        sd_knob.z_index = -1
        node.add_child(sd_knob)

    elif o_id == "door_to_gakuenmae":
        # 学園街から学園前駅へのガラスドア
        cr.color = Color(0, 0, 0, 0)
        var gm_door_x = obs["x"] * cm_to_px
        # 銀色フレーム
        var gm_frame = ColorRect.new()
        gm_frame.color = Color(0.68, 0.70, 0.74)
        gm_frame.position = Vector2(gm_door_x, -h_px)
        gm_frame.size = Vector2(w_px, h_px)
        gm_frame.z_index = -1
        node.add_child(gm_frame)
        # ガラス上部（半透明ブルー）
        var gm_glass_h = h_px * 0.65
        var gm_glass = ColorRect.new()
        gm_glass.color = Color(0.60, 0.76, 0.90, 0.55)
        gm_glass.position = Vector2(gm_door_x + 10, -h_px + 10)
        gm_glass.size = Vector2(w_px - 20, gm_glass_h - 10)
        gm_glass.z_index = -1
        node.add_child(gm_glass)
        # 下パネル（グレー）
        var gm_panel = ColorRect.new()
        gm_panel.color = Color(0.58, 0.60, 0.65)
        gm_panel.position = Vector2(gm_door_x + 10, -h_px + gm_glass_h)
        gm_panel.size = Vector2(w_px - 20, h_px - gm_glass_h - 10)
        gm_panel.z_index = -1
        node.add_child(gm_panel)
        # 中央縦線（スライドドア合わせ目）
        var gm_center = ColorRect.new()
        gm_center.color = Color(0.50, 0.52, 0.56)
        gm_center.position = Vector2(gm_door_x + w_px * 0.5 - 2, -h_px)
        gm_center.size = Vector2(4, h_px)
        gm_center.z_index = -1
        node.add_child(gm_center)

    elif o_id == "door_to_station":
        # 屋外から見た駅の入口（コンクリートの門＋看板）
        cr.color = Color(0, 0, 0, 0)
        var st_gate_x = obs["x"] * cm_to_px
        var st_pillar_color = Color(0.62, 0.62, 0.65)
        # 左右の太いコンクリート柱
        var st_left_pillar = ColorRect.new()
        st_left_pillar.color = st_pillar_color
        st_left_pillar.position = Vector2(st_gate_x, -h_px)
        st_left_pillar.size = Vector2(w_px * 0.22, h_px)
        st_left_pillar.z_index = -1
        node.add_child(st_left_pillar)
        var st_right_pillar = ColorRect.new()
        st_right_pillar.color = st_pillar_color
        st_right_pillar.position = Vector2(st_gate_x + w_px * 0.78, -h_px)
        st_right_pillar.size = Vector2(w_px * 0.22, h_px)
        st_right_pillar.z_index = -1
        node.add_child(st_right_pillar)
        # 上部梁（コンクリート）
        var st_top_beam = ColorRect.new()
        st_top_beam.color = Color(0.58, 0.58, 0.62)
        st_top_beam.position = Vector2(st_gate_x, -h_px)
        st_top_beam.size = Vector2(w_px, h_px * 0.16)
        st_top_beam.z_index = -1
        node.add_child(st_top_beam)
        # 開口部（薄い青）
        var st_opening = ColorRect.new()
        st_opening.color = Color(0.58, 0.74, 0.90, 0.18)
        st_opening.position = Vector2(st_gate_x + w_px * 0.22, -(h_px * 0.84))
        st_opening.size = Vector2(w_px * 0.56, h_px * 0.84)
        st_opening.z_index = -1
        node.add_child(st_opening)
        # 梁の上に駅看板（緑地）
        var st_sign_w = w_px * 1.3
        var st_sign_h = h_px * 0.28
        var st_sign_x = st_gate_x - w_px * 0.15
        var st_sign_bg = ColorRect.new()
        st_sign_bg.color = Color(0.10, 0.40, 0.22)
        st_sign_bg.position = Vector2(st_sign_x, -h_px - st_sign_h)
        st_sign_bg.size = Vector2(st_sign_w, st_sign_h)
        st_sign_bg.z_index = -1
        node.add_child(st_sign_bg)
        # 看板の白ライン（駅名）
        var st_sign_line = ColorRect.new()
        st_sign_line.color = Color(0.95, 0.95, 0.95)
        st_sign_line.position = Vector2(st_sign_x + st_sign_w * 0.12, -h_px - st_sign_h + st_sign_h * 0.32)
        st_sign_line.size = Vector2(st_sign_w * 0.76, st_sign_h * 0.33)
        st_sign_line.z_index = -1
        node.add_child(st_sign_line)
        # 看板の小ライン（ふりがな）
        var st_sign_ruby = ColorRect.new()
        st_sign_ruby.color = Color(0.80, 0.80, 0.80, 0.75)
        st_sign_ruby.position = Vector2(st_sign_x + st_sign_w * 0.12, -h_px - st_sign_h + st_sign_h * 0.13)
        st_sign_ruby.size = Vector2(st_sign_w * 0.76, st_sign_h * 0.13)
        st_sign_ruby.z_index = -1
        node.add_child(st_sign_ruby)

    elif o_id == "door_to_school" or o_id == "door_to_schoolyard" or o_id == "door_to_infirmary" or o_id == "door_to_gymnasium":
        # 学校廊下内の各出入口ドア（ガラス入りアルミ引き戸スタイル）
        cr.color = Color(0, 0, 0, 0)
        var hs_x = obs["x"] * cm_to_px
        # ドア枠（アルミ系暗い色）
        var hs_frame = ColorRect.new()
        hs_frame.color = Color(0.30, 0.22, 0.16)
        hs_frame.position = Vector2(hs_x, -h_px)
        hs_frame.size = Vector2(w_px, h_px)
        hs_frame.z_index = -1
        node.add_child(hs_frame)
        # ガラス上半分（半透明）
        var hs_glass = ColorRect.new()
        hs_glass.color = Color(0.62, 0.78, 0.90, 0.58)
        hs_glass.position = Vector2(hs_x + 10, -h_px + 10)
        hs_glass.size = Vector2(w_px - 20, h_px * 0.52)
        hs_glass.z_index = -1
        node.add_child(hs_glass)
        # 中間横桟
        var hs_bar = ColorRect.new()
        hs_bar.color = Color(0.22, 0.16, 0.10)
        hs_bar.position = Vector2(hs_x, -h_px + h_px * 0.52 + 8)
        hs_bar.size = Vector2(w_px, 8)
        hs_bar.z_index = -1
        node.add_child(hs_bar)
        # ドアノブ
        var hs_knob = ColorRect.new()
        hs_knob.color = Color(0.78, 0.68, 0.18)
        hs_knob.position = Vector2(hs_x + w_px * 0.22, -h_px * 0.52)
        hs_knob.size = Vector2(10, 18)
        hs_knob.z_index = -1
        node.add_child(hs_knob)

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
        var _knob_radius = 8.0
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
        
    elif "train_seat" in o_id:
        # 電車のロングシート（壁際ベンチ）
        cr.color = Color(0, 0, 0, 0)
        # 背もたれ（座面の上に積み上がる）
        var backrest = ColorRect.new()
        backrest.color = Color(0.25, 0.45, 0.28) # 緑色ファブリック（暗め）
        backrest.position = Vector2(cr.position.x, cr.position.y - 36 * cm_to_px)
        backrest.size = Vector2(w_px, 36 * cm_to_px)
        node.add_child(backrest)
        # 座面
        var cushion = ColorRect.new()
        cushion.color = Color(0.32, 0.55, 0.35) # 緑色ファブリック
        cushion.position = cr.position
        cushion.size = cr.size
        node.add_child(cushion)
        # 座面上の縫い目ライン（意匠）
        var seam_count = int(w_px / (30 * cm_to_px))
        for si in range(1, seam_count):
            var seam = ColorRect.new()
            seam.color = Color(0.20, 0.40, 0.22)
            seam.position = Vector2(cr.position.x + si * (w_px / seam_count), cr.position.y + 4 * cm_to_px)
            seam.size = Vector2(2, cr.size.y - 6 * cm_to_px)
            node.add_child(seam)
        # 座席仕切り板（両端と中間）
        var divider_count = int(w_px / (60 * cm_to_px)) + 1
        for di in range(divider_count):
            var divider = ColorRect.new()
            divider.color = Color(0.55, 0.55, 0.60)
            divider.position = Vector2(cr.position.x + di * (w_px / (divider_count - 1)) - 2, cr.position.y - 36 * cm_to_px)
            divider.size = Vector2(4, (36 + 45) * cm_to_px)
            node.add_child(divider)

    elif "strap" in o_id:
        cr.color = Color(0, 0, 0, 0)
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
        ring_hole.color = Color(0, 0, 0, 0)
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
        # chair_left は背もたれを左側（外側）に配置
        if "chair_left" in o_id:
            back.position = Vector2(cr.position.x, cr.position.y - 40)
        else:
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
        cr.color = Color(0, 0, 0, 0)
        var frame_color = Color(0.45, 0.30, 0.18)
        var shelf_color = Color(0.52, 0.35, 0.20)
        var ft = 7.0 # フレーム厚
        var st = 5.0 # 棚板厚
        var shelf_count = 4 # 棚板4枚 = 5段

        # 左右のパネル（正面から見た柱）
        for dx in [0.0, w_px - ft]:
            var panel = ColorRect.new()
            panel.color = frame_color
            panel.position = Vector2(cr.position.x + dx, cr.position.y)
            panel.size = Vector2(ft, h_draw_px)
            node.add_child(panel)

        # 上下のパネル
        for dy in [0.0, h_draw_px - ft]:
            var plank = ColorRect.new()
            plank.color = frame_color
            plank.position = Vector2(cr.position.x, cr.position.y + dy)
            plank.size = Vector2(w_px, ft)
            node.add_child(plank)

        # 背板（少し暗い茶色）
        var back = ColorRect.new()
        back.color = Color(0.30, 0.20, 0.12)
        back.position = Vector2(cr.position.x + ft, cr.position.y + ft)
        back.size = Vector2(w_px - ft * 2, h_draw_px - ft * 2)
        node.add_child(back)

        # 棚板（横仕切り）
        var inner_h = h_draw_px - ft * 2
        var section_h = inner_h / (shelf_count + 1)
        for i in range(1, shelf_count + 1):
            var shelf = ColorRect.new()
            shelf.color = shelf_color
            shelf.position = Vector2(cr.position.x + ft, cr.position.y + ft + section_h * i)
            shelf.size = Vector2(w_px - ft * 2, st)
            node.add_child(shelf)

        # 本（各段に左右対称に詰めて配置）
        var book_colors_shelf = [Color(0.80, 0.15, 0.15), Color(0.15, 0.40, 0.80), Color(0.15, 0.65, 0.25), Color(0.85, 0.65, 0.10), Color(0.55, 0.15, 0.70), Color(0.85, 0.45, 0.10)]
        var book_widths_arr = [9, 7, 11, 8, 10, 7, 9, 11, 8]
        var inner_x = cr.position.x + ft + 1.0
        var inner_w = w_px - ft * 2 - 2.0
        for i in range(shelf_count + 1):
            var book_top: float
            var book_h: float
            if i == 0:
                book_top = cr.position.y + ft + 2.0
                book_h = section_h - 4.0
            else:
                book_top = cr.position.y + ft + section_h * i + st + 2.0
                book_h = section_h - st - 4.0
            var bx = inner_x
            var c_idx = i * 3
            while bx < inner_x + inner_w - 5.0:
                var bw = float(book_widths_arr[c_idx % book_widths_arr.size()])
                if bx + bw > inner_x + inner_w - 1.0:
                    break
                var book = ColorRect.new()
                book.color = book_colors_shelf[c_idx % book_colors_shelf.size()]
                book.position = Vector2(bx, book_top)
                book.size = Vector2(bw, book_h)
                node.add_child(book)
                bx += bw + 1.0
                c_idx += 1

    elif o_id == "blackboard":
        # 床から100cm〜高さ(210cm)までの範囲とする
        var bottom_cm = 100.0
        var board_h_cm = h_cm - bottom_cm
        
        cr.color = Color(0.18, 0.35, 0.22) # 深草色（黒板の緑）
        cr.position.y = - h_px # 上端
        cr.size.y = board_h_cm * cm_to_px
        
        # 木枠
        var frame = ReferenceRect.new()
        frame.editor_only = false
        frame.border_color = Color(0.45, 0.28, 0.15)
        frame.border_width = 6.0
        frame.position = cr.position
        frame.size = cr.size
        node.add_child(frame)
        
        # 粉受け（チョーク置き）を黒板下端に配置
        var chalk_tray = ColorRect.new()
        chalk_tray.color = Color(0.40, 0.22, 0.12)
        chalk_tray.position = Vector2(cr.position.x - 4, cr.position.y + cr.size.y)
        chalk_tray.size = Vector2(cr.size.x + 8, 6)
        node.add_child(chalk_tray)
        var board_suffix = _get_stage_suffix_from_stage_id(stage_id)
        var board_text = "がんばろう！"
        if board_suffix == "middle":
            board_text = "今日の目標"
        elif board_suffix == "high":
            board_text = "○日 センター試験"
        var board_label = Label.new()
        board_label.text = board_text
        board_label.add_theme_font_size_override("font_size", 18)
        board_label.add_theme_color_override("font_color", Color(0.88, 0.94, 0.88))
        board_label.position = Vector2(cr.position.x + 18, cr.position.y + 18)
        board_label.size = Vector2(cr.size.x - 36, 28)
        node.add_child(board_label)

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

    elif o_id == "height_scale":
        # 身長計（壁付きの目盛り付き板）
        cr.color = Color(0.90, 0.88, 0.80) # ベージュ系の板
        var scale_x = obs["x"] * cm_to_px
        # 外枠
        var sc_frame = ReferenceRect.new()
        sc_frame.editor_only = false
        sc_frame.border_color = Color(0.55, 0.42, 0.28)
        sc_frame.border_width = 3.0
        sc_frame.position = cr.position
        sc_frame.size = cr.size
        node.add_child(sc_frame)
        # 目盛り線（10cm刻み、100cm〜210cmの範囲）
        for mark_cm in range(100, 221, 10):
            var mark_y = - float(mark_cm) * cm_to_px
            var mark_w = w_px * (0.6 if mark_cm % 50 == 0 else (0.45 if mark_cm % 10 == 0 else 0.3))
            var mark_line = ColorRect.new()
            mark_line.color = Color(0.25, 0.15, 0.08)
            mark_line.position = Vector2(scale_x + w_px - mark_w, mark_y - 1)
            mark_line.size = Vector2(mark_w, 2)
            node.add_child(mark_line)
            # 50cm刻みにラベル
            if mark_cm % 50 == 0 or mark_cm % 10 == 0:
                var mark_label = Label.new()
                mark_label.text = "%d" % mark_cm
                mark_label.add_theme_font_size_override("font_size", 9)
                mark_label.add_theme_color_override("font_color", Color(0.15, 0.08, 0.02))
                mark_label.position = Vector2(scale_x, mark_y - 8)
                mark_label.size = Vector2(w_px * 0.6, 16)
                node.add_child(mark_label)
        # 赤い水平バー（頭部を当てるスライダー）- 220cmラインに配置
        var slider = ColorRect.new()
        slider.color = Color(0.85, 0.15, 0.15)
        slider.position = Vector2(scale_x - w_px * 0.3, -h_px - 4)
        slider.size = Vector2(w_px * 1.3, 8)
        node.add_child(slider)

    elif o_id == "weight_scale":
        # 体重計（床に置く薄い台）
        cr.color = Color(0.88, 0.90, 0.92)
        var ws_frame = ReferenceRect.new()
        ws_frame.editor_only = false
        ws_frame.border_color = Color(0.60, 0.62, 0.65)
        ws_frame.border_width = 2.0
        ws_frame.position = cr.position
        ws_frame.size = cr.size
        node.add_child(ws_frame)
        # デジタル表示部
        var display = ColorRect.new()
        display.color = Color(0.10, 0.12, 0.10)
        display.position = cr.position + Vector2(w_px * 0.25, cr.size.y * 0.1)
        display.size = Vector2(w_px * 0.5, cr.size.y * 0.6)
        node.add_child(display)

    elif o_id == "infirmary_bed":
        # 保健室のベッド（白いシーツ）
        cr.color = Color(0, 0, 0, 0)
        # フレーム
        var ib_frame = ColorRect.new()
        ib_frame.color = Color(0.75, 0.78, 0.80)
        ib_frame.position = cr.position
        ib_frame.size = cr.size
        node.add_child(ib_frame)
        # マットレス・シーツ（白）
        var ib_sheet = ColorRect.new()
        ib_sheet.color = Color(0.97, 0.97, 0.97)
        ib_sheet.position = cr.position + Vector2(6, 4)
        ib_sheet.size = Vector2(w_px - 12, h_draw_px - 4)
        node.add_child(ib_sheet)
        # 枕（右端）
        var ib_pillow = ColorRect.new()
        ib_pillow.color = Color(0.93, 0.93, 0.93)
        ib_pillow.position = cr.position + Vector2(w_px - w_px * 0.22 - 10, 6)
        ib_pillow.size = Vector2(w_px * 0.22, h_draw_px * 0.65)
        node.add_child(ib_pillow)
        # 緑のラインシーツ（清潔感）
        var ib_accent = ColorRect.new()
        ib_accent.color = Color(0.55, 0.80, 0.60)
        ib_accent.position = cr.position + Vector2(6, 4)
        ib_accent.size = Vector2(w_px * 0.05, h_draw_px - 4)
        node.add_child(ib_accent)

    elif o_id == "infirmary_curtain":
        # カーテン（薄い白・仕切り）
        cr.color = Color(0.90, 0.92, 0.90, 0.85)
        var ic_frame = ReferenceRect.new()
        ic_frame.editor_only = false
        ic_frame.border_color = Color(0.65, 0.72, 0.65)
        ic_frame.border_width = 2.0
        ic_frame.position = cr.position
        ic_frame.size = cr.size
        node.add_child(ic_frame)

    elif o_id == "medicine_cabinet":
        # 薬棚（白い棚）
        cr.color = Color(0.92, 0.94, 0.92)
        var mc_frame = ReferenceRect.new()
        mc_frame.editor_only = false
        mc_frame.border_color = Color(0.60, 0.65, 0.60)
        mc_frame.border_width = 3.0
        mc_frame.position = cr.position
        mc_frame.size = cr.size
        node.add_child(mc_frame)
        # 棚板（3段）
        for si in range(1, 4):
            var shelf_pl = ColorRect.new()
            shelf_pl.color = Color(0.72, 0.76, 0.72)
            shelf_pl.position = Vector2(cr.position.x + 5, cr.position.y + h_draw_px * (float(si) / 4.0))
            shelf_pl.size = Vector2(w_px - 10, 4)
            node.add_child(shelf_pl)
        # 中の薬（小さな色付きボックス）
        var med_colors = [Color(0.85, 0.2, 0.2), Color(0.2, 0.5, 0.85), Color(0.2, 0.75, 0.35), Color(0.90, 0.75, 0.1)]
        for row in range(3):
            var item_y = cr.position.y + h_draw_px * (float(row) / 4.0) + 8
            var item_x = cr.position.x + 8
            for col in range(4):
                var med = ColorRect.new()
                med.color = med_colors[col % med_colors.size()]
                med.position = Vector2(item_x + col * (w_px - 16) / 4.0, item_y)
                med.size = Vector2((w_px - 16) / 4.0 - 4, h_draw_px / 4.0 - 12)
                node.add_child(med)

    elif o_id == "infirmary_desk":
        # 保健室の先生の机（白系）
        cr.color = Color(0, 0, 0, 0)
        var id_top = ColorRect.new()
        id_top.color = Color(0.88, 0.90, 0.88)
        id_top.position = cr.position
        id_top.size = Vector2(w_px, 14)
        node.add_child(id_top)
        var id_frame = ReferenceRect.new()
        id_frame.editor_only = false
        id_frame.border_color = Color(0.60, 0.65, 0.60)
        id_frame.border_width = 2.0
        id_frame.position = cr.position
        id_frame.size = Vector2(w_px, 14)
        node.add_child(id_frame)
        # 脚
        for leg_dx in [8.0, w_px - 18.0]:
            var id_leg = ColorRect.new()
            id_leg.color = Color(0.70, 0.74, 0.70)
            id_leg.position = Vector2(cr.position.x + leg_dx, cr.position.y + 14)
            id_leg.size = Vector2(10, h_draw_px - 14)
            node.add_child(id_leg)

    elif o_id == "mailbox":
        # 郵便ポスト（赤いポスト）
        cr.color = Color(0, 0, 0, 0)
        var mb_x = obs["x"] * cm_to_px
        # ポール（細い支柱）
        var mb_pole = ColorRect.new()
        mb_pole.color = Color(0.55, 0.55, 0.58)
        mb_pole.position = Vector2(mb_x + w_px * 0.42, -h_px)
        mb_pole.size = Vector2(w_px * 0.16, h_px * 0.35)
        mb_pole.z_index = -1
        node.add_child(mb_pole)
        # ポスト本体（円柱を矩形で近似）
        var mb_body = ColorRect.new()
        mb_body.color = Color(0.85, 0.12, 0.12)
        mb_body.position = Vector2(mb_x + w_px * 0.08, -h_px)
        mb_body.size = Vector2(w_px * 0.84, h_px * 0.68)
        mb_body.z_index = -1
        node.add_child(mb_body)
        # ポスト上蓋（丸型、少し暗い赤）
        var mb_cap = ColorRect.new()
        mb_cap.color = Color(0.70, 0.08, 0.08)
        mb_cap.position = Vector2(mb_x + w_px * 0.08, -h_px)
        mb_cap.size = Vector2(w_px * 0.84, h_px * 0.12)
        mb_cap.z_index = -1
        node.add_child(mb_cap)
        # 投函口（白い横スリット）
        var mb_slot = ColorRect.new()
        mb_slot.color = Color(0.92, 0.92, 0.92)
        mb_slot.position = Vector2(mb_x + w_px * 0.12, -h_px * 0.72)
        mb_slot.size = Vector2(w_px * 0.76, h_px * 0.06)
        mb_slot.z_index = -1
        node.add_child(mb_slot)

    elif o_id == "traffic_signal":
        # 歩行者用信号機
        cr.color = Color(0, 0, 0, 0)
        var ts_x = obs["x"] * cm_to_px
        var cx_ts = ts_x + w_px * 0.5
        # ポール
        var ts_pole = ColorRect.new()
        ts_pole.color = Color(0.48, 0.48, 0.50)
        ts_pole.position = Vector2(cx_ts - 4, -h_px)
        ts_pole.size = Vector2(8, h_px * 0.78)
        ts_pole.z_index = -1
        node.add_child(ts_pole)
        # 信号機ボックス（黒）
        var ts_box = ColorRect.new()
        ts_box.color = Color(0.12, 0.12, 0.14)
        ts_box.position = Vector2(ts_x, -h_px)
        ts_box.size = Vector2(w_px, h_px * 0.22)
        ts_box.z_index = -1
        node.add_child(ts_box)
        # 上（赤ランプ）
        var ts_red = ColorRect.new()
        ts_red.color = Color(0.88, 0.15, 0.15)
        ts_red.position = Vector2(ts_x + w_px * 0.15, -h_px + h_px * 0.04)
        ts_red.size = Vector2(w_px * 0.70, h_px * 0.08)
        ts_red.z_index = -1
        node.add_child(ts_red)
        # 下（緑ランプ、暗め）
        var ts_green = ColorRect.new()
        ts_green.color = Color(0.10, 0.55, 0.10, 0.5)
        ts_green.position = Vector2(ts_x + w_px * 0.15, -h_px + h_px * 0.12)
        ts_green.size = Vector2(w_px * 0.70, h_px * 0.08)
        ts_green.z_index = -1
        node.add_child(ts_green)

    elif o_id == "car":
        # 軽自動車（横から見た）
        cr.color = Color(0, 0, 0, 0)
        var car_x = obs["x"] * cm_to_px
        # 車体下部（ボディ）
        var car_body = ColorRect.new()
        car_body.color = Color(0.30, 0.45, 0.72) # 青系
        car_body.position = Vector2(car_x, -h_px)
        car_body.size = Vector2(w_px, h_px * 0.65)
        car_body.z_index = -1
        node.add_child(car_body)
        # 屋根（キャビン）
        var car_roof = Polygon2D.new()
        var rx = car_x + w_px * 0.22
        var ry = -(h_px)
        car_roof.polygon = PackedVector2Array([
            Vector2(rx, ry),
            Vector2(rx + w_px * 0.56, ry),
            Vector2(rx + w_px * 0.68, ry + h_px * 0.40),
            Vector2(rx - w_px * 0.12, ry + h_px * 0.40),
        ])
        car_roof.color = Color(0.22, 0.34, 0.58)
        car_roof.z_index = -1
        node.add_child(car_roof)
        # フロントガラス
        var car_fg = Polygon2D.new()
        car_fg.polygon = PackedVector2Array([
            Vector2(car_x + w_px * 0.22, -(h_px)),
            Vector2(car_x + w_px * 0.45, -(h_px)),
            Vector2(car_x + w_px * 0.47, -(h_px) + h_px * 0.40),
            Vector2(car_x + w_px * 0.10, -(h_px) + h_px * 0.40),
        ])
        car_fg.color = Color(0.62, 0.80, 0.95, 0.70)
        car_fg.z_index = -1
        node.add_child(car_fg)
        # リアガラス
        var car_rg = Polygon2D.new()
        car_rg.polygon = PackedVector2Array([
            Vector2(car_x + w_px * 0.55, -(h_px)),
            Vector2(car_x + w_px * 0.78, -(h_px)),
            Vector2(car_x + w_px * 0.80, -(h_px) + h_px * 0.40),
            Vector2(car_x + w_px * 0.53, -(h_px) + h_px * 0.40),
        ])
        car_rg.color = Color(0.62, 0.80, 0.95, 0.70)
        car_rg.z_index = -1
        node.add_child(car_rg)
        # タイヤ（前・後）
        for wheel_x_off in [0.18, 0.72]:
            var wheel_panel = Panel.new()
            var wheel_style = StyleBoxFlat.new()
            wheel_style.bg_color = Color(0.15, 0.15, 0.17)
            var wheel_r = int(h_px * 0.22)
            wheel_style.corner_radius_top_left = wheel_r
            wheel_style.corner_radius_top_right = wheel_r
            wheel_style.corner_radius_bottom_left = wheel_r
            wheel_style.corner_radius_bottom_right = wheel_r
            wheel_panel.add_theme_stylebox_override("panel", wheel_style)
            var wd = h_px * 0.44
            wheel_panel.position = Vector2(car_x + w_px * wheel_x_off - wd * 0.5, -wd)
            wheel_panel.size = Vector2(wd, wd)
            wheel_panel.z_index = -1
            node.add_child(wheel_panel)

    elif o_id == "bus":
        # 路線バス
        cr.color = Color(0, 0, 0, 0)
        var bus_x = obs["x"] * cm_to_px
        var bus_body_color = Color(0.18, 0.55, 0.28)  # 路線バス緑
        var bus_white = Color(0.92, 0.92, 0.92)
        # 車体
        var body = ColorRect.new()
        body.color = bus_body_color
        body.position = Vector2(bus_x, -h_px)
        body.size = Vector2(w_px, h_px)
        body.z_index = -1
        node.add_child(body)
        # 車体上部の白帯
        var white_band = ColorRect.new()
        white_band.color = bus_white
        white_band.position = Vector2(bus_x, -h_px)
        white_band.size = Vector2(w_px, h_px * 0.12)
        white_band.z_index = -1
        node.add_child(white_band)
        # 行き先表示（前面）
        var dest_sign = ColorRect.new()
        dest_sign.color = Color(0.08, 0.08, 0.12)
        dest_sign.position = Vector2(bus_x + w_px * 0.60, -h_px + h_px * 0.04)
        dest_sign.size = Vector2(w_px * 0.35, h_px * 0.10)
        dest_sign.z_index = -1
        node.add_child(dest_sign)
        # 窓（側面）
        var win_count = 4
        var win_w = w_px * 0.13
        var win_h = h_px * 0.22
        for wi in range(win_count):
            var bwin = ColorRect.new()
            bwin.color = Color(0.62, 0.78, 0.90, 0.72)
            bwin.position = Vector2(bus_x + w_px * 0.05 + wi * (w_px * 0.18), -h_px + h_px * 0.16)
            bwin.size = Vector2(win_w, win_h)
            bwin.z_index = -1
            node.add_child(bwin)
        # ドア（乗降口）
        var door_w2 = w_px * 0.16
        var bus_door = ColorRect.new()
        bus_door.color = Color(0.50, 0.72, 0.55)
        bus_door.position = Vector2(bus_x + w_px * 0.78, -h_px * 0.70)
        bus_door.size = Vector2(door_w2, h_px * 0.65)
        bus_door.z_index = -1
        node.add_child(bus_door)
        # ドアの縦線（2枚折り戸）
        var door_div = ColorRect.new()
        door_div.color = Color(0.30, 0.55, 0.38)
        door_div.position = Vector2(bus_x + w_px * 0.86, -h_px * 0.70)
        door_div.size = Vector2(3, h_px * 0.65)
        door_div.z_index = -1
        node.add_child(door_div)
        # タイヤ（2つ）
        for tyre_x_off in [w_px * 0.12, w_px * 0.72]:
            var tyre = ColorRect.new()
            tyre.color = Color(0.15, 0.15, 0.18)
            tyre.position = Vector2(bus_x + tyre_x_off - 15, -22)
            tyre.size = Vector2(30, 22)
            tyre.z_index = -1
            node.add_child(tyre)
        # 車体下部の黒帯
        var lower_band = ColorRect.new()
        lower_band.color = Color(0.20, 0.20, 0.22)
        lower_band.position = Vector2(bus_x, -22)
        lower_band.size = Vector2(w_px, 22)
        lower_band.z_index = -1
        node.add_child(lower_band)

    elif o_id == "bus_stop_sign":
        # バス停標識
        cr.color = Color(0, 0, 0, 0)
        var bs_x = obs["x"] * cm_to_px
        var cx_bs = bs_x + w_px * 0.5
        # ポール
        var bs_pole = ColorRect.new()
        bs_pole.color = Color(0.55, 0.55, 0.58)
        bs_pole.position = Vector2(cx_bs - 4, -h_px)
        bs_pole.size = Vector2(8, h_px)
        bs_pole.z_index = -1
        node.add_child(bs_pole)
        # 標識板（青地）
        var bs_board = ColorRect.new()
        bs_board.color = Color(0.10, 0.30, 0.72)
        bs_board.position = Vector2(bs_x - w_px * 0.5, -h_px)
        bs_board.size = Vector2(w_px * 2.0, h_px * 0.22)
        bs_board.z_index = -1
        node.add_child(bs_board)
        # 白いライン（テキスト表現）
        for li in range(2):
            var bs_line = ColorRect.new()
            bs_line.color = Color(1.0, 1.0, 1.0, 0.80)
            bs_line.position = Vector2(bs_x - w_px * 0.4, -h_px + h_px * (0.04 + li * 0.08))
            bs_line.size = Vector2(w_px * 1.8, 4)
            bs_line.z_index = -1
            node.add_child(bs_line)

    elif o_id == "horizontal_ladder":
        # うんてい（水平梯子型遊具）
        cr.color = Color(0, 0, 0, 0)
        var hl_x = obs["x"] * cm_to_px
        var pipe_color = Color(0.55, 0.58, 0.65)
        var support_color = Color(0.48, 0.52, 0.58)
        # 左右の支柱（地面から高さまで）
        for sx_off in [0.0, w_px - 10.0]:
            var support = ColorRect.new()
            support.color = support_color
            support.position = Vector2(hl_x + sx_off, -h_px)
            support.size = Vector2(10, h_px)
            support.z_index = -1
            node.add_child(support)
        # 左右の縦フレーム（両側、斜め補強）
        for side_x in [hl_x + 10, hl_x + w_px - 20]:
            var diag = ColorRect.new()
            diag.color = support_color
            diag.position = Vector2(side_x, -h_px * 0.60)
            diag.size = Vector2(10, h_px * 0.60)
            diag.z_index = -1
            node.add_child(diag)
        # 上の2本レール（両端から渡す）
        for rail_y_off in [0.0, 8 * cm_to_px]:
            var top_rail = ColorRect.new()
            top_rail.color = pipe_color
            top_rail.position = Vector2(hl_x, -h_px + rail_y_off)
            top_rail.size = Vector2(w_px, 7)
            top_rail.z_index = -1
            node.add_child(top_rail)
        # 横棒（ラダーバー、等間隔）
        var rung_count = int(w_px / (20 * cm_to_px))
        for ri in range(rung_count + 1):
            var rung = ColorRect.new()
            rung.color = pipe_color
            rung.position = Vector2(hl_x + ri * (w_px / rung_count) - 4, -h_px + 5)
            rung.size = Vector2(8, 8 * cm_to_px + 10)
            rung.z_index = -1
            node.add_child(rung)

    elif "horizontal_bar" in o_id:
        # 鉄棒（支柱2本 + 横バー）
        cr.color = Color(0, 0, 0, 0)
        var hb_x = obs["x"] * cm_to_px
        # 左支柱
        var hb_left = ColorRect.new()
        hb_left.color = Color(0.60, 0.60, 0.65)
        hb_left.position = Vector2(hb_x + w_px * 0.10, -h_px)
        hb_left.size = Vector2(6, h_px)
        hb_left.z_index = -1
        node.add_child(hb_left)
        # 右支柱
        var hb_right = ColorRect.new()
        hb_right.color = Color(0.60, 0.60, 0.65)
        hb_right.position = Vector2(hb_x + w_px * 0.80, -h_px)
        hb_right.size = Vector2(6, h_px)
        hb_right.z_index = -1
        node.add_child(hb_right)
        # 横バー（上端）
        var hb_bar = ColorRect.new()
        hb_bar.color = Color(0.72, 0.72, 0.78)
        hb_bar.position = Vector2(hb_x + w_px * 0.05, -h_px - 5)
        hb_bar.size = Vector2(w_px * 0.90, 10)
        hb_bar.z_index = -1
        node.add_child(hb_bar)
        # 地面への固定金具（支柱の足元）
        for fx in [hb_x + w_px * 0.05, hb_x + w_px * 0.75]:
            var foot = ColorRect.new()
            foot.color = Color(0.45, 0.45, 0.48)
            foot.position = Vector2(fx, -10)
            foot.size = Vector2(14, 10)
            foot.z_index = -1
            node.add_child(foot)

    elif o_id == "jungle_gym":
        # ジャングルジム（格子状の鉄骨）
        cr.color = Color(0, 0, 0, 0)
        var jg_x = obs["x"] * cm_to_px
        var cols_jg = 4
        var rows_jg = 4
        var cell_w_jg = w_px / cols_jg
        var cell_h_jg = h_draw_px / rows_jg
        # 縦棒
        for c in range(cols_jg + 1):
            var vbar = ColorRect.new()
            vbar.color = Color(0.55, 0.58, 0.62)
            vbar.position = Vector2(jg_x + c * cell_w_jg - 3, -h_draw_px)
            vbar.size = Vector2(6, h_draw_px)
            vbar.z_index = -1
            node.add_child(vbar)
        # 横棒
        for r in range(rows_jg + 1):
            var hbar = ColorRect.new()
            hbar.color = Color(0.55, 0.58, 0.62)
            hbar.position = Vector2(jg_x, -h_draw_px + r * cell_h_jg - 3)
            hbar.size = Vector2(w_px, 6)
            hbar.z_index = -1
            node.add_child(hbar)

    elif o_id == "basketball_hoop":
        # バスケゴール（支柱＋バックボード＋リング）
        cr.color = Color(0, 0, 0, 0)
        var bk_x = obs["x"] * cm_to_px
        # ポール（右側、地面から頂点まで）
        var bk_pole = ColorRect.new()
        bk_pole.color = Color(0.48, 0.48, 0.50)
        bk_pole.position = Vector2(bk_x + w_px * 0.82, -h_px)
        bk_pole.size = Vector2(12, h_px)
        bk_pole.z_index = -1
        node.add_child(bk_pole)
        # ポールの土台（右側）
        var bk_base = ColorRect.new()
        bk_base.color = Color(0.40, 0.40, 0.42)
        bk_base.position = Vector2(bk_x + w_px * 0.78, -20)
        bk_base.size = Vector2(w_px * 0.22, 20)
        bk_base.z_index = -1
        node.add_child(bk_base)
        # 横アーム（ポール頂上からボード方向へ左に延伸）
        var bk_arm = ColorRect.new()
        bk_arm.color = Color(0.48, 0.48, 0.50)
        bk_arm.position = Vector2(bk_x + w_px * 0.48, -h_px)
        bk_arm.size = Vector2(w_px * 0.34 + 12, 10)
        bk_arm.z_index = -1
        node.add_child(bk_arm)
        # バックボード（アーム左端、リングの真後ろ）
        var board_w = w_px * 0.16
        var board_h = h_px * 0.22
        var bk_board = ColorRect.new()
        bk_board.color = Color(0.92, 0.92, 0.95)
        bk_board.position = Vector2(bk_x + w_px * 0.48, -h_px - board_h * 0.28)
        bk_board.size = Vector2(board_w, board_h)
        bk_board.z_index = -1
        node.add_child(bk_board)
        var bk_board_frame = ReferenceRect.new()
        bk_board_frame.editor_only = false
        bk_board_frame.border_color = Color(0.60, 0.60, 0.65)
        bk_board_frame.border_width = 3.0
        bk_board_frame.position = bk_board.position
        bk_board_frame.size = bk_board.size
        bk_board_frame.z_index = -1
        node.add_child(bk_board_frame)
        # ボードのシューティングスクエア
        var sq = ReferenceRect.new()
        sq.editor_only = false
        sq.border_color = Color(0.50, 0.50, 0.55)
        sq.border_width = 2.0
        sq.position = bk_board.position + Vector2(board_w * 0.15, board_h * 0.28)
        sq.size = Vector2(board_w * 0.70, board_h * 0.42)
        sq.z_index = -1
        node.add_child(sq)
        # リング（ボードの前面から左へ）
        var ring_y = -h_px
        var ring_w = w_px * 0.38
        var bk_ring = ColorRect.new()
        bk_ring.color = Color(0.92, 0.42, 0.08)
        bk_ring.position = Vector2(bk_x + w_px * 0.48 - ring_w, ring_y - 3)
        bk_ring.size = Vector2(ring_w, 7)
        bk_ring.z_index = -1
        node.add_child(bk_ring)
        # ネット（白い縦線）
        for ni in range(6):
            var net_line = ColorRect.new()
            net_line.color = Color(0.88, 0.88, 0.88, 0.80)
            net_line.position = Vector2(bk_x + w_px * 0.48 - ring_w + ni * (ring_w / 5.0), ring_y + 4)
            net_line.size = Vector2(2, h_px * 0.12)
            net_line.z_index = -1
            node.add_child(net_line)

    elif o_id == "soccer_goal_post":
        # サッカーゴール（正面から見た）
        cr.color = Color(0, 0, 0, 0)
        var sg_x = obs["x"] * cm_to_px
        # 左ポスト
        var sg_left = ColorRect.new()
        sg_left.color = Color(0.92, 0.92, 0.95)
        sg_left.position = Vector2(sg_x, -h_px)
        sg_left.size = Vector2(8, h_px)
        sg_left.z_index = -1
        node.add_child(sg_left)
        # 右ポスト
        var sg_right = ColorRect.new()
        sg_right.color = Color(0.92, 0.92, 0.95)
        sg_right.position = Vector2(sg_x + w_px - 8, -h_px)
        sg_right.size = Vector2(8, h_px)
        sg_right.z_index = -1
        node.add_child(sg_right)
        # クロスバー
        var sg_bar = ColorRect.new()
        sg_bar.color = Color(0.92, 0.92, 0.95)
        sg_bar.position = Vector2(sg_x, -h_px)
        sg_bar.size = Vector2(w_px, 8)
        sg_bar.z_index = -1
        node.add_child(sg_bar)
        # ネット（縦線）
        var net_cols = 8
        for ni in range(net_cols + 1):
            var nl = ColorRect.new()
            nl.color = Color(0.80, 0.80, 0.82, 0.55)
            nl.position = Vector2(sg_x + ni * (w_px / net_cols), -h_px + 8)
            nl.size = Vector2(2, h_px * 0.65)
            nl.z_index = -1
            node.add_child(nl)
        # ネット（横線）
        for ri in range(4):
            var rl = ColorRect.new()
            rl.color = Color(0.80, 0.80, 0.82, 0.55)
            rl.position = Vector2(sg_x, -h_px + 8 + ri * (h_px * 0.65 / 3.0))
            rl.size = Vector2(w_px, 2)
            rl.z_index = -1
            node.add_child(rl)

    elif o_id == "ticket_gate":
        # 自動改札機（複数機並ぶ）
        cr.color = Color(0.28, 0.30, 0.35)
        var tg_x = obs["x"] * cm_to_px
        var gate_count = 4
        var gate_w = w_px / gate_count
        for gi in range(gate_count):
            var gx = tg_x + gi * gate_w
            # 改札機本体
            var gate_body = ColorRect.new()
            gate_body.color = Color(0.72, 0.74, 0.78)
            gate_body.position = Vector2(gx + gate_w * 0.05, -h_px)
            gate_body.size = Vector2(gate_w * 0.38, h_px)
            node.add_child(gate_body)
            # 通路（右側）
            var gate_pass = ColorRect.new()
            gate_pass.color = Color(0.50, 0.52, 0.55)
            gate_pass.position = Vector2(gx + gate_w * 0.45, -h_px)
            gate_pass.size = Vector2(gate_w * 0.50, h_px)
            node.add_child(gate_pass)
            # パネル上部（ICカード読み取り部）
            var gate_reader = ColorRect.new()
            gate_reader.color = Color(0.10, 0.45, 0.85)
            gate_reader.position = Vector2(gx + gate_w * 0.06, -h_px + 6)
            gate_reader.size = Vector2(gate_w * 0.36, h_px * 0.18)
            node.add_child(gate_reader)

    elif o_id == "volleyball_net":
        # バレーボールネット（縦横の格子）
        cr.color = Color(0, 0, 0, 0)
        var vn_x = obs["x"] * cm_to_px
        # 左右のポール（支柱）
        for pole_off in [0.0, w_px - 8.0]:
            var vn_pole = ColorRect.new()
            vn_pole.color = Color(0.55, 0.55, 0.58)
            vn_pole.position = Vector2(vn_x + pole_off, -h_px - 20 * cm_to_px)
            vn_pole.size = Vector2(8, h_px + 20 * cm_to_px)
            vn_pole.z_index = -1
            node.add_child(vn_pole)
        # ネット本体（白）
        var net_h = h_px * 0.35
        var net_y = -h_px
        # 横線（4本）
        for ri in range(5):
            var hline = ColorRect.new()
            hline.color = Color(0.90, 0.90, 0.88, 0.85)
            hline.position = Vector2(vn_x + 8, net_y + ri * (net_h / 4.0))
            hline.size = Vector2(w_px - 16, 2)
            hline.z_index = -1
            node.add_child(hline)
        # 縦線（等間隔）
        var col_count = int((w_px - 16) / (8 * cm_to_px)) + 1
        for ci in range(col_count + 1):
            var vline = ColorRect.new()
            vline.color = Color(0.90, 0.90, 0.88, 0.70)
            vline.position = Vector2(vn_x + 8 + ci * ((w_px - 16) / col_count), net_y)
            vline.size = Vector2(2, net_h)
            vline.z_index = -1
            node.add_child(vline)
        # 上帯（白い太帯）
        var top_band = ColorRect.new()
        top_band.color = Color(0.92, 0.90, 0.88)
        top_band.position = Vector2(vn_x + 8, net_y)
        top_band.size = Vector2(w_px - 16, 5)
        top_band.z_index = -1
        node.add_child(top_band)

    elif o_id == "station_name_sign":
        # 駅名標（吊り下げ型）
        cr.color = Color(0, 0, 0, 0)
        var sn_x = obs["x"] * cm_to_px
        # 支柱（2本）
        for post_off in [w_px * 0.15, w_px * 0.75]:
            var sn_post = ColorRect.new()
            sn_post.color = Color(0.55, 0.55, 0.58)
            sn_post.position = Vector2(sn_x + post_off - 4, -h_px)
            sn_post.size = Vector2(8, h_px)
            sn_post.z_index = -1
            node.add_child(sn_post)
        # 看板本体（緑）
        var sign_h = h_px * 0.28
        var sign_y = -h_px + h_px * 0.10
        var sn_bg = ColorRect.new()
        sn_bg.color = Color(0.10, 0.42, 0.22)
        sn_bg.position = Vector2(sn_x, sign_y)
        sn_bg.size = Vector2(w_px, sign_h)
        sn_bg.z_index = -1
        node.add_child(sn_bg)
        var sn_frame = ReferenceRect.new()
        sn_frame.editor_only = false
        sn_frame.border_color = Color(0.08, 0.30, 0.15)
        sn_frame.border_width = 3.0
        sn_frame.position = sn_bg.position
        sn_frame.size = sn_bg.size
        sn_frame.z_index = -1
        node.add_child(sn_frame)
        # テキスト代わりの白い横線（「〇〇駅」の雰囲気）
        var txt_line1 = ColorRect.new()
        txt_line1.color = Color(0.95, 0.95, 0.95)
        txt_line1.position = Vector2(sn_x + w_px * 0.12, sign_y + sign_h * 0.25)
        txt_line1.size = Vector2(w_px * 0.76, sign_h * 0.22)
        txt_line1.z_index = -1
        node.add_child(txt_line1)
        # ふりがなの小さい白線
        var txt_ruby = ColorRect.new()
        txt_ruby.color = Color(0.80, 0.80, 0.80, 0.80)
        txt_ruby.position = Vector2(sn_x + w_px * 0.12, sign_y + sign_h * 0.12)
        txt_ruby.size = Vector2(w_px * 0.76, sign_h * 0.10)
        txt_ruby.z_index = -1
        node.add_child(txt_ruby)
        # 隣駅表示（両サイドの小さい看板）
        for side_off in [0.0, w_px - w_px * 0.20]:
            var adj_sign = ColorRect.new()
            adj_sign.color = Color(0.12, 0.45, 0.25)
            adj_sign.position = Vector2(sn_x + side_off, sign_y + sign_h * 0.05)
            adj_sign.size = Vector2(w_px * 0.18, sign_h * 0.90)
            adj_sign.z_index = -1
            node.add_child(adj_sign)

    elif o_id == "station_bench":
        # 駅のホームベンチ
        cr.color = Color(0, 0, 0, 0)
        # 背もたれ
        var sb_back = ColorRect.new()
        sb_back.color = Color(0.55, 0.42, 0.30)
        sb_back.position = Vector2(cr.position.x, cr.position.y - 38 * cm_to_px)
        sb_back.size = Vector2(w_px, 6)
        node.add_child(sb_back)
        # 座面（木製スラット風）
        var slat_count = int(w_px / (8 * cm_to_px))
        for si in range(slat_count):
            var slat = ColorRect.new()
            slat.color = Color(0.62, 0.48, 0.34)
            slat.position = cr.position + Vector2(si * (w_px / slat_count) + 1, 0)
            slat.size = Vector2(w_px / slat_count - 2, 8)
            node.add_child(slat)
        # 脚（3本）
        var leg_count = 3
        for li in range(leg_count):
            var sb_leg = ColorRect.new()
            sb_leg.color = Color(0.45, 0.45, 0.50)
            sb_leg.position = cr.position + Vector2(li * (w_px / (leg_count - 1)) - 4 if li < leg_count - 1 else w_px - 8, 8)
            sb_leg.size = Vector2(8, h_draw_px - 8)
            node.add_child(sb_leg)

    elif o_id == "basketball_board":
        # 体育館のバスケゴール（天井からぶら下がる）
        cr.color = Color(0, 0, 0, 0)
        var gym_bk_x = obs["x"] * cm_to_px
        var ceil_h_cm = 400.0  # 体育館の天井高（400cm）
        # リングの高さは305cm（h_pxはbasketball_boardの高さ350cmなのでオフセット計算）
        # basketball_boardのheight=350、リング高さ305cm → h_pxはボード上端
        var ring_height_cm = 305.0
        var ring_y = -ring_height_cm * cm_to_px
        # 天井からのロープ/チェーン（2本）
        for chain_x_off in [w_px * 0.15, w_px * 0.85]:
            var chain = ColorRect.new()
            chain.color = Color(0.55, 0.52, 0.48)
            chain.position = Vector2(gym_bk_x + chain_x_off - 2, -(ceil_h_cm * cm_to_px))
            chain.size = Vector2(4, (ceil_h_cm - ring_height_cm - 30) * cm_to_px)
            chain.z_index = -1
            node.add_child(chain)
        # バックボード（白く目立つ色に変更して視認性向上）
        var gym_board_h = 60 * cm_to_px
        var gym_board_w = w_px * 0.85
        var gym_bk_board = ColorRect.new()
        gym_bk_board.color = Color(0.96, 0.96, 0.96, 0.95)  # ほぼ白で視認しやすく
        gym_bk_board.position = Vector2(gym_bk_x + w_px * 0.075, ring_y - gym_board_h * 0.6)
        gym_bk_board.size = Vector2(gym_board_w, gym_board_h)
        gym_bk_board.z_index = -1
        node.add_child(gym_bk_board)
        var gym_bk_frame = ReferenceRect.new()
        gym_bk_frame.editor_only = false
        gym_bk_frame.border_color = Color(0.15, 0.15, 0.20)  # 濃い枠線で輪郭を強調
        gym_bk_frame.border_width = 4.0
        gym_bk_frame.position = gym_bk_board.position
        gym_bk_frame.size = gym_bk_board.size
        gym_bk_frame.z_index = -1
        node.add_child(gym_bk_frame)
        # リング（オレンジ色を鮮やかにし、太さも増して目立つようにする）
        var gym_ring = ColorRect.new()
        gym_ring.color = Color(1.0, 0.38, 0.0)  # より鮮やかなオレンジ
        gym_ring.position = Vector2(gym_bk_x + w_px * 0.1, ring_y - 6)
        gym_ring.size = Vector2(w_px * 0.80, 12)  # 高さを8→12に増やして目立つように
        gym_ring.z_index = -1
        node.add_child(gym_ring)
        # ネット
        for ni in range(7):
            var gym_net = ColorRect.new()
            gym_net.color = Color(0.85, 0.85, 0.85, 0.70)
            gym_net.position = Vector2(gym_bk_x + w_px * 0.1 + ni * (w_px * 0.80 / 6.0), ring_y + 4)
            gym_net.size = Vector2(2, 28 * cm_to_px)
            gym_net.z_index = -1
            node.add_child(gym_net)

    elif o_id == "timetable":
        # 時刻表ボード
        cr.color = Color(0.92, 0.94, 0.90)
        var tt_frame = ReferenceRect.new()
        tt_frame.editor_only = false
        tt_frame.border_color = Color(0.40, 0.38, 0.32)
        tt_frame.border_width = 4.0
        tt_frame.position = cr.position
        tt_frame.size = cr.size
        node.add_child(tt_frame)
        # ヘッダ（青帯）
        var tt_header = ColorRect.new()
        tt_header.color = Color(0.10, 0.28, 0.65)
        tt_header.position = cr.position + Vector2(4, 4)
        tt_header.size = Vector2(w_px - 8, h_draw_px * 0.14)
        node.add_child(tt_header)
        # 時刻の行（横線で表現）
        for ri in range(6):
            var row_line = ColorRect.new()
            row_line.color = Color(0.65, 0.65, 0.68)
            row_line.position = cr.position + Vector2(4, h_draw_px * (0.18 + ri * 0.13))
            row_line.size = Vector2(w_px - 8, 2)
            node.add_child(row_line)
            # 数字のダミー点（灰色の小矩形）
            for ci in range(5):
                var dot = ColorRect.new()
                dot.color = Color(0.30, 0.30, 0.32)
                dot.position = cr.position + Vector2(8 + ci * (w_px - 16) / 5.0, h_draw_px * (0.19 + ri * 0.13))
                dot.size = Vector2((w_px - 16) / 5.0 - 4, h_draw_px * 0.08)
                node.add_child(dot)

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
    if obs_id.begins_with("door_to_school_hallway"):
        if h > oh:
            return "学校の廊下への入口（高さ%dcm）。\nあなた（%dcm）は%dcm頭が当たります！" % [oh, h, round(h - oh)]
        return "学校の廊下へ続く入口（%dcm）。" % oh
    if obs_id.begins_with("door_to_schoolyard_"):
        if h > oh:
            return "校庭への出口（高さ%dcm）。\nあなた（%dcm）は%dcm頭が当たります！" % [oh, h, round(h - oh)]
        return "校庭への出口（%dcm）。外で遊びましょう！" % oh
    if obs_id.begins_with("door_to_infirmary_"):
        if h > oh:
            return "保健室への入口（高さ%dcm）。\nあなた（%dcm）は%dcm頭が当たります！" % [oh, h, round(h - oh)]
        return "保健室への入口（%dcm）。少し休んでいけそうです。" % oh
    if obs_id.begins_with("door_to_gymnasium_"):
        if h > oh:
            return "体育館への入口（高さ%dcm）。\nあなた（%dcm）は%dcm頭が当たります！" % [oh, h, round(h - oh)]
        return "体育館への入口（%dcm）。" % oh
    if obs_id.begins_with("door_to_school_"):
        if h > oh:
            return "教室の入口（高さ%dcm）。\nあなた（%dcm）は%dcm頭が当たります！" % [oh, h, round(h - oh)]
        return "教室の入口（%dcm）。" % oh
    match obs_id:
        "door_to_outdoor":
            if h > oh:
                return "外への出入口（高さ%dcm）。\nあなた（%dcm）は%dcm頭が当たります！" % [oh, h, round(h - oh)]
            else:
                return "外への出入口（%dcm）。余裕でくぐれます。" % oh
        "door_to_room":
            if h > oh:
                return "家の玄関（高さ%dcm）。\nあなた（%dcm）は%dcm頭が当たります！" % [oh, h, round(h - oh)]
            else:
                return "家の玄関（%dcm）。ただいま！" % oh
        "door_to_train":
            if h > oh:
                return "駅の入口（高さ%dcm）。\nあなた（%dcm）は%dcm頭が当たります！" % [oh, h, round(h - oh)]
            else:
                return "駅の入口（%dcm）。電車に乗りましょう。" % oh
        "door_to_platform":
            if h > oh:
                return "ホームへの入口（高さ%dcm）。\nあなた（%dcm）は%dcm頭が当たります！" % [oh, h, round(h - oh)]
            else:
                return "ホームへの入口（%dcm）。電車が見えてきます。" % oh
        "door_to_gakuenmae":
            if h > oh:
                return "学園前駅への出口（高さ%dcm）。\nあなた（%dcm）は%dcm頭が当たります！" % [oh, h, round(h - oh)]
            else:
                return "学園前駅への出口（%dcm）。" % oh
        "door_to_gakuenmachi":
            if h > oh:
                return "学園街への入口（高さ%dcm）。\nあなた（%dcm）は%dcm頭が当たります！" % [oh, h, round(h - oh)]
            else:
                return "学園街への入口（%dcm）。" % oh
        "door_to_adjacent_town":
            if h > oh:
                return "隣町への入口（高さ%dcm）。\nあなた（%dcm）は%dcm頭が当たります！" % [oh, h, round(h - oh)]
            else:
                return "隣町への入口（%dcm）。" % oh
        "door_to_school":
            if h > oh:
                return "学校の入口（高さ%dcm）。\nあなた（%dcm）は%dcm頭が当たります！" % [oh, h, round(h - oh)]
            else:
                return "学校の入口（%dcm）。いってらっしゃい！" % oh
        "door_left", "door_right", "side_door", "door_3", "door_4", "door_to_myroom", "door_to_school_hallway_high":
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
        "chair", "chair_left", "chair_right":
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
        "train_seat_1", "train_seat_2", "train_seat_3":
            return "電車のロングシート（%dcm）。\n長身だと膝が高くなりがちです。" % oh
        "strap_1", "strap_2", "strap_3", "strap_4", "strap_5", "strap_6", "strap_7", "strap_8", "strap_9", "strap_10":
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
        "mailbox":
            if h > oh + 50:
                return "郵便ポスト（%dcm）。\nあなたには膝のあたりの高さですね。" % oh
            elif h > oh:
                return "郵便ポスト（%dcm）。\n昔はちょうど良い高さだったのに…。" % oh
            else:
                return "郵便ポスト（%dcm）。\n投函口はちょうど目線の高さですね。" % oh
        "traffic_signal":
            if h > oh:
                return "歩行者用信号機（%dcm）。\nあなた（%dcm）はもう信号を見下ろす高さです！" % [oh, h]
            else:
                return "歩行者用信号機（%dcm）。\nあなた（%dcm）より%dcm上にあります。" % [oh, h, round(oh - h)]
        "car":
            if h > oh:
                return "軽自動車の屋根（%dcm）。\nあなた（%dcm）は車の屋根より高いです！" % [oh, h]
            else:
                return "軽自動車の屋根（%dcm）。" % oh
        "bus_stop_sign":
            if h > oh * 0.85:
                return "バス停の標識（%dcm）。\n標識とほぼ同じ目線になってきました。" % oh
            else:
                return "バス停（%dcm）。\nバスを待ちましょう。" % oh
        "horizontal_bar_low", "horizontal_bar_high":
            if h > oh:
                return "鉄棒（%dcm）。\nあなた（%dcm）は鉄棒より背が高い！飛び越えそうですね。" % [oh, h]
            elif h > oh * 0.85:
                return "鉄棒（%dcm）。\n楽々と手が届きますね。" % oh
            else:
                return "鉄棒（%dcm）。\n少し背伸びが必要ですね。" % oh
        "jungle_gym":
            if h > oh:
                return "ジャングルジム（%dcm）。\nあなた（%dcm）はてっぺんより高い！" % [oh, h]
            else:
                return "ジャングルジム（%dcm）。\n登ったら最上段から顔が見えそうですね。" % oh
        "basketball_hoop":
            if h > oh:
                return "バスケゴール（%dcm）。\nあなた（%dcm）はリングより高い！ダンクできそうですね！" % [oh, h]
            elif h > oh * 0.92:
                return "バスケゴール（%dcm）。\nあなた（%dcm）…もう少しでリングに届きそう！" % [oh, h]
            else:
                return "バスケゴール（%dcm）。\nリングまで%dcm届きません。" % [oh, round(oh - h)]
        "soccer_goal_post":
            if h > oh:
                return "サッカーゴール（クロスバー%dcm）。\nあなた（%dcm）はゴールより高い！" % [oh, h]
            else:
                return "サッカーゴールのクロスバー（%dcm）。" % oh
        "ticket_gate":
            if h > 170:
                return "自動改札機（%dcm）。\nあなたには腰くらいの高さ。長身だと通りにくいですね。" % oh
            else:
                return "自動改札機（%dcm）。ICカードをタッチしましょう。" % oh
        "table":
            return "家の食卓（%dcm）。\nここで少し休めば、気持ちがほどけるかもしれません。" % oh
        "station_bench":
            return "ホームのベンチ（%dcm）。\n長身だと膝が高く突き出してしまいますね。" % oh
        "platform_bench", "platform_bench_small":
            return "ホームのベンチ（%dcm）。\n電車待ちの時間が少しだけゆっくり流れます。" % oh
        "timetable":
            return "時刻表ボード（%dcm）。\n上の方まで楽々見えますね。" % oh
        "station_vending":
            if h > oh:
                return "駅の自販機（%dcm）より背が高いですね。\nボタンがずいぶん下の方に見えます。" % oh
            else:
                return "駅の自販機（%dcm）。\n電車を待つ間に一本どうぞ。" % oh
        "station_sign_gakuenmae":
            return "駅名看板です。『学園前』の文字が見えます。"
        "station_name_sign":
            return "駅名標です。『〇〇駅』と書いてあります。高さ%dcmの看板が目の前に。" % oh
        "bus":
            if h > oh:
                return "路線バス（高さ%dcm）。\nあなた（%dcm）はバスより背が高い！" % [oh, h]
            else:
                return "路線バス（高さ%dcm）。\nバスの天井すれすれで乗降できるかな？" % oh
        "horizontal_ladder":
            if h > oh:
                return "うんてい（高さ%dcm）。\nあなた（%dcm）はうんていより背が高い！" % [oh, h]
            elif h > oh * 0.85:
                return "うんてい（高さ%dcm）。\n頭がバーに近づいてきた！" % oh
            else:
                return "うんてい（高さ%dcm）。\n小学生の定番遊具です。" % oh
        "basketball_board":
            if h > oh:
                return "体育館のバスケゴール（リング高%dcm）。\nあなた（%dcm）はリングより高い！ダンクできそう！" % [oh, h]
            elif h > oh * 0.85:
                return "体育館のバスケゴール（リング高%dcm）。\nリングがだいぶ低く見えてきた！" % oh
            else:
                return "体育館のバスケゴール（リング高%dcm）。\nステージ右端に設置されています。近づいてみましょう。" % oh
        "notice_board_town":
            return "掲示板です。学園祭や部活の張り紙が目に入ります。"
        "school_gate_middle":
            return "中学校の校門です。朝の生徒たちが行き交っています。"
        "school_gate_high":
            return "高校へ続く門です。制服姿の生徒たちが見えます。"
        "door_to_station":
            if h > oh:
                return "駅の入口（高さ%dcm）。\nあなた（%dcm）は%dcm頭が当たります！" % [oh, h, round(h - oh)]
            else:
                return "駅の入口（%dcm）。電車に乗りましょう。" % oh
        "door_to_schoolyard":
            if h > oh:
                return "校庭への出口（高さ%dcm）。\nあなた（%dcm）は%dcm頭が当たります！" % [oh, h, round(h - oh)]
            else:
                return "校庭への出口（%dcm）。外で遊びましょう！" % oh
        "vending_machine", "station_vending":
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
        "student_chair_1", "student_chair_2":
            return "学校の椅子（%dcm）。\n大人には少し小さく感じますね。" % oh
        "infirmary_desk":
            return "保健室の机。\n座って話せば、少し気持ちが整理できるかもしれません。"
        "bed":
            return "自分のベッド（高さ%dcm）。\n背が高いと足がはみ出してしまいますね。" % oh
        "bookshelf":
            if h > oh:
                return "本棚（高さ%dcm）。\nあなた（%dcm）より低い！上の棚まで余裕で手が届きますね。" % [oh, h]
            else:
                return "本棚（高さ%dcm）。\n上の棚に少し背伸びが必要かもしれません。" % oh
        "washstand":
            return "洗面台の鏡。\n立ち止まると、自分の姿がよく見える。"
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

static func get_head_bump_comment(obs_id: String, obs_height_cm: float) -> String:
    if (
        obs_id.begins_with("door_to_school_hallway")
        or obs_id.begins_with("door_to_school_")
        or obs_id.begins_with("door_to_schoolyard_")
        or obs_id.begins_with("door_to_infirmary_")
        or obs_id.begins_with("door_to_gymnasium_")
    ):
        return "頭上注意。もっとかがまないと通れない。"
    match obs_id:
        "door_to_train":
            return "電車のドア上に頭が当たった。少しかがまないと危ない。"
        "door_to_station":
            return "駅の入口は低い。頭を下げて抜けたい。"
        "door_to_school", "door_to_schoolyard", "door_to_infirmary", "door_to_outdoor", "door_to_room", "door_to_myroom":
            return "頭上注意。もっとかがまないと通れない。"
        "door_left", "door_right", "side_door", "door_3", "door_4", "door_to_school_hallway_high":
            return "低いドア枠に頭をぶつけた。"
        "bathroom_ceiling":
            return "浴室の天井が近い。立つとすぐ頭が当たる。"
        "ceiling_light":
            return "照明に頭が当たった。"
        "range_hood":
            return "レンジフードに頭が当たった。"
        "horizontal_bar_low":
            return "低い遊具に頭をぶつけた。"
        "horizontal_bar_high":
            return "鉄棒に頭をぶつけた。"
        "horizontal_ladder":
            return "うんていのバーに頭をぶつけた。"
        _:
            if obs_id.find("ceiling") >= 0:
                return "低い天井に頭をぶつけた。"
            if obs_id.find("door") >= 0:
                return "頭上注意。もっとかがまないと通れない。"
            if obs_height_cm < 190.0:
                return "低い障害物に頭が当たった。"
            return "頭が当たった。"

static func math_round(val: float) -> int:
    return int(round(val))

# ─── 年齢別ステージ名・障害物 ──────────────────────────────────────

static func get_stage_name(stage_id: String, age: int) -> String:
    var resolved_stage_id = resolve_stage_id(stage_id, age)
    if STAGES.has(resolved_stage_id):
        return STAGES[resolved_stage_id]["name"]
    return STAGES.get(stage_id, {}).get("name", "Unknown")

static func resolve_stage_id(stage_id: String, age: int) -> String:
    match stage_id:
        "school", "school_hallway", "schoolyard", "infirmary", "gymnasium":
            return "%s_%s" % [stage_id, _get_school_stage_suffix(age)]
        _:
            return stage_id

static func is_school_hallway_stage(stage_id: String) -> bool:
    return stage_id.begins_with("school_hallway_")

static func is_school_classroom_stage(stage_id: String) -> bool:
    return stage_id.begins_with("school_") and not is_school_hallway_stage(stage_id) and not stage_id.begins_with("schoolyard_")

static func is_schoolyard_stage(stage_id: String) -> bool:
    return stage_id.begins_with("schoolyard_")

static func is_school_stage(stage_id: String) -> bool:
    return (
        is_school_classroom_stage(stage_id)
        or is_school_hallway_stage(stage_id)
        or is_schoolyard_stage(stage_id)
        or is_infirmary_stage(stage_id)
        or is_gymnasium_stage(stage_id)
    )

static func is_infirmary_stage(stage_id: String) -> bool:
    return stage_id.begins_with("infirmary_")

static func is_gymnasium_stage(stage_id: String) -> bool:
    return stage_id.begins_with("gymnasium_")

static func get_obstacles(stage_id: String, age: int) -> Array:
    var resolved_stage_id = resolve_stage_id(stage_id, age)
    match resolved_stage_id:
        "outdoor":
            return _outdoor_obstacles()
        "station":
            return _station_obstacles(age)
        "school_elementary", "school_middle", "school_high":
            return _school_obstacles(resolved_stage_id)
        "school_hallway_elementary", "school_hallway_middle", "school_hallway_high":
            return _school_hallway_obstacles(resolved_stage_id)
        "schoolyard_elementary", "schoolyard_middle", "schoolyard_high":
            return _schoolyard_obstacles(resolved_stage_id)
        "infirmary_elementary", "infirmary_middle", "infirmary_high":
            return _infirmary_obstacles(resolved_stage_id)
        "gymnasium_elementary", "gymnasium_middle", "gymnasium_high":
            return _gymnasium_obstacles(resolved_stage_id)
        _:
            return STAGES[resolved_stage_id]["obstacles"].duplicate(true) if STAGES.has(resolved_stage_id) else []

static func _outdoor_obstacles() -> Array:
    return STAGES["outdoor"]["obstacles"].duplicate(true)

static func _station_obstacles(_age: int) -> Array:
    return STAGES["station"]["obstacles"].duplicate(true)

static func _school_obstacles(stage_id: String) -> Array:
    var suffix = _get_stage_suffix_from_stage_id(stage_id)
    var desk_h = 60
    var chair_h = 38
    var board_h = 190
    var feature_id = "display_board"
    var feature_height = 185
    if suffix == "middle":
        desk_h = 70
        chair_h = 43
        board_h = 210
        feature_id = "locker"
        feature_height = 180
    elif suffix == "high":
        desk_h = 70
        chair_h = 45
        board_h = 210
        feature_id = "locker_high"
        feature_height = 185
    var obstacles: Array = [
        {"id": "door_to_%s" % _school_stage_id("school_hallway", suffix), "x": 100, "x2": 240, "height": 200, "type": "overhead"},
        {"id": "blackboard", "x": 300, "x2": 800, "height": board_h, "type": "background"},
        {"id": "teacher_desk", "x": 840, "x2": 990, "height": 85 if suffix == "elementary" else 100, "type": "ground"},
        {"id": feature_id, "x": 1010, "x2": 1080 if suffix != "elementary" else 1070, "height": feature_height, "type": "background"},
        {"id": "desk_1", "x": 1100, "x2": 1160, "height": desk_h, "type": "ground"},
        {"id": "student_chair_1", "x": 1180, "x2": 1220, "height": chair_h, "type": "ground"},
        {"id": "desk_2", "x": 1350, "x2": 1410, "height": desk_h, "type": "ground"},
        {"id": "student_chair_2", "x": 1430, "x2": 1470, "height": chair_h, "type": "ground"},
    ]
    if suffix == "high":
        obstacles.append({"id": "window_back", "x": 1490, "x2": 1580, "height": 200, "type": "background"})
    return obstacles

static func _school_hallway_obstacles(stage_id: String) -> Array:
    var suffix = _get_stage_suffix_from_stage_id(stage_id)
    var entry_door = "door_to_outdoor"
    if suffix == "middle":
        entry_door = "door_to_adjacent_town"
    elif suffix == "high":
        entry_door = "door_to_gakuenmachi"
    return [
        {"id": entry_door, "x": 100, "x2": 320, "height": 220, "type": "overhead"},
        {"id": "shoes_locker", "x": 350, "x2": 550, "height": 180, "type": "background"},
        {"id": "bulletin_board", "x": 800, "x2": 1050, "height": 180, "type": "background"},
        {"id": "door_to_%s" % _school_stage_id("school", suffix), "x": 1300, "x2": 1440, "height": 200, "type": "overhead"},
        {"id": "fire_hydrant", "x": 1800, "x2": 1860, "height": 120, "type": "background"},
        {"id": "door_to_%s" % _school_stage_id("schoolyard", suffix), "x": 1950, "x2": 2090, "height": 200, "type": "overhead"},
        {"id": "door_to_%s" % _school_stage_id("infirmary", suffix), "x": 2200, "x2": 2340, "height": 200, "type": "overhead"},
        {"id": "door_to_%s" % _school_stage_id("gymnasium", suffix), "x": 2600, "x2": 2740, "height": 200, "type": "overhead"},
    ]

static func _schoolyard_obstacles(stage_id: String) -> Array:
    var suffix = _get_stage_suffix_from_stage_id(stage_id)
    var hoop_height = 260 if suffix == "elementary" else 305
    var obstacles: Array = [
        {"id": "door_to_%s" % _school_stage_id("school_hallway", suffix), "x": 80, "x2": 220, "height": 200, "type": "overhead"},
        {"id": "basketball_hoop", "x": 1350, "x2": 1470, "height": hoop_height, "type": "background"},
        {"id": "soccer_goal_post", "x": 2000, "x2": 2200, "height": 244, "type": "background"},
    ]
    if suffix == "elementary":
        obstacles.append({"id": "horizontal_bar_low", "x": 500, "x2": 700, "height": 130, "type": "overhead"})
        obstacles.append({"id": "horizontal_bar_high", "x": 750, "x2": 950, "height": 150, "type": "overhead"})
        obstacles.append({"id": "jungle_gym", "x": 900, "x2": 1100, "height": 200, "type": "background"})
        obstacles.append({"id": "horizontal_ladder", "x": 1150, "x2": 1330, "height": 200, "type": "overhead"})
    elif suffix == "middle":
        obstacles.append({"id": "horizontal_bar_high", "x": 700, "x2": 900, "height": 220, "type": "overhead"})
    else:
        obstacles.append({"id": "gym_bench", "x": 900, "x2": 1160, "height": 42, "type": "ground"})
        obstacles.append({"id": "horizontal_bar_high", "x": 700, "x2": 900, "height": 220, "type": "overhead"})
    return obstacles

static func _infirmary_obstacles(stage_id: String) -> Array:
    var suffix = _get_stage_suffix_from_stage_id(stage_id)
    return [
        {"id": "door_to_%s" % _school_stage_id("school_hallway", suffix), "x": 80, "x2": 220, "height": 200, "type": "overhead"},
        {"id": "medicine_cabinet", "x": 280, "x2": 420, "height": 200, "type": "background"},
        {"id": "height_scale", "x": 500, "x2": 560, "height": 220, "type": "background"},
        {"id": "weight_scale", "x": 580, "x2": 640, "height": 10, "type": "ground"},
        {"id": "infirmary_desk", "x": 730, "x2": 900, "height": 72, "type": "ground"},
        {"id": "infirmary_bed", "x": 1000, "x2": 1280, "height": 60, "type": "ground"},
        {"id": "infirmary_curtain", "x": 980, "x2": 1000, "height": 220, "type": "background"}
    ]

static func _gymnasium_obstacles(stage_id: String) -> Array:
    var suffix = _get_stage_suffix_from_stage_id(stage_id)
    var net_x = 1450 if suffix == "elementary" else (1550 if suffix == "middle" else 1650)
    return [
        {"id": "door_to_%s" % _school_stage_id("school_hallway", suffix), "x": 80, "x2": 220, "height": 200, "type": "overhead"},
        {"id": "gym_storage", "x": 280, "x2": 450, "height": 200, "type": "background"},
        {"id": "volleyball_net", "x": net_x, "x2": net_x + 300, "height": 224, "type": "overhead"},
        {"id": "gym_bench", "x": 2200, "x2": 2500, "height": 42, "type": "ground"},
        {"id": "gym_window_1", "x": 600, "x2": 780, "height": 500, "type": "background"},
        {"id": "gym_window_2", "x": 900, "x2": 1080, "height": 500, "type": "background"},
        {"id": "basketball_board", "x": 2800, "x2": 2920, "height": 350, "type": "background"}
    ]

static func _get_school_stage_suffix(age: int) -> String:
    if age <= 11:
        return "elementary"
    elif age <= 14:
        return "middle"
    return "high"

static func _get_stage_suffix_from_stage_id(stage_id: String) -> String:
    if stage_id.ends_with("_elementary"):
        return "elementary"
    if stage_id.ends_with("_middle"):
        return "middle"
    if stage_id.ends_with("_high"):
        return "high"
    return ""

static func _school_stage_id(base_id: String, suffix: String) -> String:
    return "%s_%s" % [base_id, suffix]
