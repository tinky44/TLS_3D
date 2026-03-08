extends Control

# ゲーム導入シーン（MVP）
# キャラクリ完了後に「暗転 → テキスト表示 → 明転」を経てメインシーンへ遷移する

const LINES = [
	"おはよう",
]
const FADE_IN_SEC = 0.8 # テキストフェードイン時間
const HOLD_SEC = 1.4 # テキスト表示維持時間
const FADE_OUT_SEC = 0.6 # 画面フェードアウト時間

var _bg: ColorRect
var _text_label: Label
var _line_index: int = 0

func _ready() -> void:
	# 黒背景
	_bg = ColorRect.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.color = Color(0, 0, 0, 1)
	add_child(_bg)

	# テキストラベル（中央）
	_text_label = Label.new()
	_text_label.set_anchors_preset(Control.PRESET_CENTER)
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text_label.add_theme_font_size_override("font_size", 32)
	_text_label.add_theme_color_override("font_color", Color(1, 1, 1, 0))
	_text_label.text = ""
	add_child(_text_label)

	_play_next_line()

func _play_next_line() -> void:
	if _line_index >= LINES.size():
		_fade_out_and_go()
		return

	_text_label.text = LINES[_line_index]
	_line_index += 1

	# テキストを徐々に表示
	var tween = create_tween()
	tween.tween_method(_set_text_alpha, 0.0, 1.0, FADE_IN_SEC)
	tween.tween_interval(HOLD_SEC)
	tween.tween_method(_set_text_alpha, 1.0, 0.0, FADE_IN_SEC * 0.5)
	tween.tween_callback(_play_next_line)

func _fade_out_and_go() -> void:
	# 画面全体を白くフラッシュしてからMainへ
	_bg.color = Color(0, 0, 0, 0)
	var tween = create_tween()
	tween.tween_property(_bg, "color", Color(0, 0, 0, 1), FADE_OUT_SEC)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://Main.tscn")
	)

func _set_text_alpha(alpha: float) -> void:
	if _text_label:
		_text_label.add_theme_color_override("font_color", Color(1, 1, 1, alpha))
