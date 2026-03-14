extends Node2D

## 身長計の目盛りを描画するノード
## IntroScene から player_height_cm と cm_to_px を設定して queue_redraw() を呼ぶ

var player_height_cm: float = 160.0
var cm_to_px: float = 2.0

const RULER_X := 0.0
const MIN_CM := 100
const MAX_CM := 230

func _draw() -> void:
	var p := cm_to_px
	var font := ThemeDB.fallback_font

	# 縦のメインライン
	draw_line(
		Vector2(RULER_X, -(MIN_CM * p)),
		Vector2(RULER_X, -(MAX_CM * p)),
		Color(0.8, 0.8, 0.8, 0.5), 2.0
	)

	# 横目盛りとラベル
	for cm in range(MIN_CM, MAX_CM + 1, 10):
		var y := -(cm * p)
		var is_major := cm % 50 == 0
		var tick_len := 28.0 if is_major else 14.0
		var alpha := 0.85 if is_major else 0.45
		var col := Color(0.85, 0.85, 0.85, alpha)
		draw_line(Vector2(RULER_X - tick_len, y), Vector2(RULER_X + 5.0, y), col, 1.5)
		if cm % 20 == 0:
			draw_string(
				font,
				Vector2(RULER_X - tick_len - 48.0, y + 5.0),
				"%dcm" % cm,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col
			)

	# 現在身長を黄色でハイライト
	var hy := -(player_height_cm * p)
	draw_line(
		Vector2(RULER_X - 40.0, hy),
		Vector2(RULER_X + 12.0, hy),
		Color.YELLOW, 2.5
	)
	draw_string(
		font,
		Vector2(RULER_X - 44.0, hy - 6.0),
		"%.0fcm" % player_height_cm,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.YELLOW
	)
