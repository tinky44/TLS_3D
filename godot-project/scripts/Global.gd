extends Node

const CM_TO_PX: float = 2.0

# プレイヤーの身体パラメータ (初期値として「高身長女性」を設定)
var current_params: Dictionary = {
    "height": 180.0,
    "ratio": 7.5,
    "legRatio": 48.0,
    "sex": "female"
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
    var arm_length: float = head * 2.7
    var hand: float = (h / ratio) * 0.83
    
    var landmarks: Dictionary = {
        "top": h,
        "eye": h - head * 0.5,
        "chin": h - head,
        "shoulder": h - head - 2.0 * neck,
        "nipple": h - head - 2.0 * neck - arm * 0.25,
        "navel": h - head - 2.0 * neck - arm * 0.60,
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
