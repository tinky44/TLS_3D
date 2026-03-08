extends Node

const CM_TO_PX: float = 2.0

# プレイヤーの身体パラメータ (初期値として「高身長女性」を設定)
var current_params: Dictionary = {
    "height": 180.0,
    "ratio": 7.5,
    "legRatio": 48.0,
    "sex": "female"
}

var current_appearance: Dictionary = {
    "hair_style": "short",
    "hair_color": "#4a3c31",
    "tops_type": "t_shirt",
    "tops_color": "#ab82a8",
    "bottoms_type": "pants",
    "bottoms_color": "#3a5f8a",
    "shoes_type": "sneakers",
    "shoes_color": "#e5d6ba"
}

var current_stage_id: String = "room"
var current_slot: int = -1 # 現在使用中のスロット番号 (-1 = 未選択)
var slot_select_mode: String = "save" # "save" or "load"

const SAVE_PATH = "user://settings.cfg"
const SLOTS_PATH = "user://save_slots.cfg"
const SLOT_COUNT: int = 20

func _ready():
    load_settings()

func load_settings():
    var config = ConfigFile.new()
    var err = config.load(SAVE_PATH)
    if err == OK:
        current_params["height"] = config.get_value("Player", "height", current_params["height"])
        current_params["ratio"] = config.get_value("Player", "ratio", current_params["ratio"])
        current_params["legRatio"] = config.get_value("Player", "legRatio", current_params["legRatio"])
        current_params["sex"] = config.get_value("Player", "sex", current_params["sex"])
        for key in current_appearance.keys():
            current_appearance[key] = config.get_value("Appearance", key, current_appearance[key])

func save_settings():
    var config = ConfigFile.new()
    config.set_value("Player", "height", current_params["height"])
    config.set_value("Player", "ratio", current_params["ratio"])
    config.set_value("Player", "legRatio", current_params["legRatio"])
    config.set_value("Player", "sex", current_params["sex"])
    for key in current_appearance.keys():
        config.set_value("Appearance", key, current_appearance[key])
    config.save(SAVE_PATH)

func save_slot(slot: int) -> void:
    var config = ConfigFile.new()
    config.load(SLOTS_PATH) # 既存スロットを保持したまま上書き
    var section = "slot_%d" % slot
    config.set_value(section, "saved", true)
    config.set_value(section, "height", current_params["height"])
    config.set_value(section, "ratio", current_params["ratio"])
    config.set_value(section, "legRatio", current_params["legRatio"])
    config.set_value(section, "sex", current_params["sex"])
    config.set_value(section, "stage_id", current_stage_id)
    config.set_value(section, "age", 0)
    config.set_value(section, "timestamp", Time.get_datetime_string_from_system())
    for key in current_appearance.keys():
        config.set_value(section, "appearance_" + key, current_appearance[key])
    config.save(SLOTS_PATH)
    current_slot = slot

func load_slot(slot: int) -> bool:
    var config = ConfigFile.new()
    if config.load(SLOTS_PATH) != OK:
        return false
    var section = "slot_%d" % slot
    if not config.get_value(section, "saved", false):
        return false
    current_params["height"] = config.get_value(section, "height", 180.0)
    current_params["ratio"] = config.get_value(section, "ratio", 7.5)
    current_params["legRatio"] = config.get_value(section, "legRatio", 48.0)
    current_params["sex"] = config.get_value(section, "sex", "female")
    current_stage_id = config.get_value(section, "stage_id", "room")
    for key in current_appearance.keys():
        current_appearance[key] = config.get_value(section, "appearance_" + key, current_appearance[key])
    current_slot = slot
    return true

func get_slot_info(slot: int) -> Dictionary:
    var config = ConfigFile.new()
    if config.load(SLOTS_PATH) != OK:
        return {}
    var section = "slot_%d" % slot
    if not config.get_value(section, "saved", false):
        return {}
    return {
        "height": config.get_value(section, "height", 180.0),
        "stage_id": config.get_value(section, "stage_id", "room"),
        "timestamp": config.get_value(section, "timestamp", ""),
        "age": config.get_value(section, "age", 0),
    }

func get_body_measurements() -> Dictionary:
    var h: float = current_params["height"]
    var ratio: float = current_params["ratio"]
    var leg_ratio: float = current_params["legRatio"]
    var sex: String = current_params["sex"]
    
    var head: float = h / ratio
    var head_width: float = head * 0.702
    var neck: float = head * 0.220
    var shoulder: float = head * 1.872 if sex == "female" else head * 1.935
    var leg: float = h * leg_ratio / 100.0
    var arm: float = h - leg - head - 2.0 * neck
    var arm_length: float = arm
    var hand: float = (h / ratio) * 0.83
    
    var landmarks: Dictionary = {
        "top": h,
        "eye": h - head * 0.5,
        "chin": h - head,
        "shoulder": h - head - 2.0 * neck,
        "nipple": h - head - 2.0 * neck - arm * 0.25,
        "navel": h - head - 2.0 * neck - arm * 0.60,
        "hip": h - head - 2.0 * neck - arm * 0.80,
        "crotch": leg,
        "knee": leg * 0.5,
        "foot": 0.0
    }
    
    return {
        "height": h,
        "head": head,
        "headWidth": head_width,
        "neck": neck,
        "shoulder": shoulder,
        "arm": arm,
        "armLength": arm_length,
        "leg": leg,
        "hand": hand,
        "landmarks": landmarks
    }

func get_custom_body_measurements(params: Dictionary) -> Dictionary:
    var h: float = params.get("height", 180.0)
    var ratio: float = params.get("ratio", 7.5)
    var leg_ratio: float = params.get("legRatio", 48.0)
    var sex: String = params.get("sex", "female")
    
    var head: float = h / ratio
    var head_width: float = head * 0.702
    var neck: float = head * 0.220
    var shoulder: float = head * 1.872 if sex == "female" else head * 1.935
    var leg: float = h * leg_ratio / 100.0
    var arm: float = h - leg - head - 2.0 * neck
    var arm_length: float = arm
    var hand: float = (h / ratio) * 0.83
    
    var landmarks: Dictionary = {
        "top": h,
        "eye": h - head * 0.5,
        "chin": h - head,
        "shoulder": h - head - 2.0 * neck,
        "nipple": h - head - 2.0 * neck - arm * 0.25,
        "navel": h - head - 2.0 * neck - arm * 0.60,
        "hip": h - head - 2.0 * neck - arm * 0.80,
        "crotch": leg,
        "knee": leg * 0.5,
        "foot": 0.0
    }
    
    return {
        "height": h,
        "head": head,
        "headWidth": head_width,
        "neck": neck,
        "shoulder": shoulder,
        "arm": arm,
        "armLength": arm_length,
        "leg": leg,
        "hand": hand,
        "landmarks": landmarks
    }
