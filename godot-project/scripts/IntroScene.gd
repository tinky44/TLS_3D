extends Node2D

## ゲーム導入シーン（身長計ズームアウト演出）
## キャラクリ完了後に身長計の前でズームアウトし、テキストを表示してMainへ遷移する

const PLAYER_SCENE_PATH = "res://Player.tscn"

# キャラの足元をワールド原点 (0, 0) に、ルーラーの右60pxに配置
const PLAYER_OFFSET_X := 60.0

# カメラ最終位置のX（ルーラーとキャラの間あたり）
const CAM_CENTER_X := 30.0

@onready var _camera: Camera2D = $Camera2D
@onready var _chart: Node2D = $HeightChart
@onready var _fade: ColorRect = $UI/Bg
@onready var _label: Label = $UI/TextLabel

var _player: Node


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.06, 0.04, 0.10, 1.0))

	var global: Node = get_node("/root/Global")
	var h: float = global.current_params.get("height", 160.0)
	var p: float = global.CM_TO_PX  # 2.0 px/cm

	# 身長計を初期化
	_chart.player_height_cm = h
	_chart.cm_to_px = p
	_chart.queue_redraw()

	# プレイヤーをインスタンス化（物理・入力・プロセスを無効化して静止表示）
	_player = load(PLAYER_SCENE_PATH).instantiate()
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	_player.position = Vector2(PLAYER_OFFSET_X, 0.0)
	_player.modulate.a = 0.0
	add_child(_player)

	# カメラ初期位置: キャラの頭部付近にズームイン
	_camera.zoom = Vector2(4.0, 4.0)
	_camera.position = Vector2(CAM_CENTER_X, -(h * p * 0.9))

	_run_sequence(global, h, p)


func _run_sequence(global: Node, h: float, p: float) -> void:
	# (1) 少し待ってからキャラをフェードイン
	await get_tree().create_timer(0.4).timeout

	var tw1 := create_tween()
	tw1.tween_property(_player, "modulate:a", 1.0, 0.5)
	await tw1.finished

	await get_tree().create_timer(0.2).timeout

	# (2) ズームアウト（カメラを引きながら全身を映す）
	var tw2 := create_tween().set_parallel(true)
	tw2.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tw2.tween_property(_camera, "zoom",     Vector2(1.0, 1.0),                   2.0)
	tw2.tween_property(_camera, "position", Vector2(CAM_CENTER_X, -(h * p * 0.5)), 2.0)
	await tw2.finished

	await get_tree().create_timer(0.4).timeout

	# (3) テキスト表示
	_label.text = "%d歳、身長%.0fcm。\n彼女の生活が始まります――" % [global.age, h]
	var tw3 := create_tween()
	tw3.tween_property(_label, "modulate:a", 1.0, 0.5)
	await tw3.finished

	await get_tree().create_timer(2.8).timeout

	var tw4 := create_tween()
	tw4.tween_property(_label, "modulate:a", 0.0, 0.4)
	await tw4.finished

	# (4) 暗転してMain.tscnへ遷移
	_fade.color = Color(0, 0, 0, 0)
	var tw5 := create_tween()
	tw5.tween_property(_fade, "color", Color(0, 0, 0, 1.0), 0.6)
	await tw5.finished

	get_tree().change_scene_to_file("res://Main.tscn")
