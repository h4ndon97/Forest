extends CanvasLayer

## 새 게임 시작 시 스토리 인트로 텍스트를 페이드 시퀀스로 표시.
## EventBus.game_start_requested(is_new_game=true) 구독. 이어하기는 스킵.
## ui_accept / ui_cancel 로 언제든 스킵 가능.

const LINES := [
	"봉인이 균열을 일으키고,",
	"선조는 숲의 시간을 멈추었다.",
	"그리고 오랜 세월이 흘렀다.",
]
const LINE_FADE_IN := 0.7
const LINE_HOLD := 1.5
const LINE_FADE_OUT := 0.6
const BG_FADE_OUT := 0.9
const SKIP_LABEL_FADE := 0.25
const SKIP_BG_FADE := 0.5
const BG_COLOR := Color(0, 0, 0, 1)
const TEXT_COLOR := Color(0.92, 0.88, 0.75)
const LABEL_SIZE := Vector2(520, 40)

var _bg: ColorRect
var _label: Label
var _tween: Tween
var _active: bool = false


func _ready() -> void:
	layer = 95
	visible = false
	_build_ui()
	EventBus.game_start_requested.connect(_on_game_start_requested)


func _process(_delta: float) -> void:
	if not _active:
		return
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_cancel"):
		_skip()


func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.name = "BG"
	_bg.color = BG_COLOR
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	_label = Label.new()
	_label.name = "Line"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", TEXT_COLOR)
	_label.modulate.a = 0.0
	_label.size = LABEL_SIZE
	_label.position = Vector2(320.0 - LABEL_SIZE.x / 2.0, 180.0 - LABEL_SIZE.y / 2.0)
	add_child(_label)


func _on_game_start_requested(is_new_game: bool) -> void:
	if not is_new_game:
		return
	_play()


func _play() -> void:
	_active = true
	visible = true
	_bg.color = BG_COLOR
	_label.modulate.a = 0.0
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	for line: String in LINES:
		_tween.tween_callback(_set_line.bind(line))
		_tween.tween_property(_label, "modulate:a", 1.0, LINE_FADE_IN)
		_tween.tween_interval(LINE_HOLD)
		_tween.tween_property(_label, "modulate:a", 0.0, LINE_FADE_OUT)
	_tween.tween_property(_bg, "color:a", 0.0, BG_FADE_OUT)
	_tween.tween_callback(_finish)


func _set_line(text: String) -> void:
	_label.text = text


func _skip() -> void:
	if not _active:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_label, "modulate:a", 0.0, SKIP_LABEL_FADE)
	_tween.tween_property(_bg, "color:a", 0.0, SKIP_BG_FADE)
	_tween.tween_callback(_finish)


func _finish() -> void:
	_active = false
	visible = false
