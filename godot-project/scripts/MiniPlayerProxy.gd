extends Node2D

# 測定演出のミニアバター表示用プロキシ
# CharacterDrawer と CharacterPoseCalculator が期待するインターフェースを提供する

var CM_TO_PX: float = 1.5
var m: Dictionary = {}
var dir: int = 1
var facing: String = "front"
var pose: String = "normal"
var is_walking: bool = false
var walk_phase: float = 0.0
var visual_height_cm: float = 160.0
