extends CanvasLayer

## REC-MECH-002 — 광기 게이지 HUD placeholder.
## EventBus.madness_changed/madness_stage_changed 구독 → ProgressBar 갱신.
## 작가 결정(아이콘/팔레트) 시 ProgressBar는 사용자 정의 위젯으로 교체 가능.
## 위치: 좌상단 시간 코어 아래쯤 (잠정, Pass 5 재배치 검토).

const _MARGIN_LEFT: int = 16
const _MARGIN_TOP: int = 80
const _BAR_SIZE: Vector2 = Vector2(80.0, 8.0)
const _LABEL_FONT_SIZE: int = 9

# 단계별 색조 (placeholder — Pass 5에서 일관성 검토).
const _COLOR_SAFE: Color = Color(0.45, 0.30, 0.65, 0.85)
const _COLOR_WARNING: Color = Color(0.65, 0.30, 0.65, 1.0)
const _COLOR_ALERT: Color = Color(0.85, 0.25, 0.45, 1.0)
const _COLOR_CRITICAL: Color = Color(1.0, 0.20, 0.25, 1.0)

var _progress: ProgressBar
var _label: Label


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	EventBus.madness_changed.connect(_on_madness_changed)
	EventBus.madness_stage_changed.connect(_on_madness_stage_changed)


# === 내부 ===


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.name = "MadnessRoot"
	margin.add_theme_constant_override("margin_left", _MARGIN_LEFT)
	margin.add_theme_constant_override("margin_top", _MARGIN_TOP)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "MadnessLayout"
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)

	_label = Label.new()
	_label.name = "MadnessLabel"
	_label.text = "광기 0/100"
	_label.add_theme_font_size_override("font_size", _LABEL_FONT_SIZE)
	_label.add_theme_color_override("font_color", _COLOR_SAFE)
	vbox.add_child(_label)

	_progress = ProgressBar.new()
	_progress.name = "MadnessBar"
	_progress.custom_minimum_size = _BAR_SIZE
	_progress.max_value = 100.0
	_progress.value = 0.0
	_progress.show_percentage = false
	_progress.modulate = _COLOR_SAFE
	vbox.add_child(_progress)


func _on_madness_changed(value: float, max_value: float) -> void:
	if _progress != null:
		_progress.max_value = max_value
		_progress.value = value
	if _label != null:
		_label.text = "광기 %d/%d" % [int(value), int(max_value)]


func _on_madness_stage_changed(_old_stage: int, new_stage: int) -> void:
	if _progress == null or _label == null:
		return
	var color: Color = _resolve_stage_color(new_stage)
	_progress.modulate = color
	_label.add_theme_color_override("font_color", color)


func _resolve_stage_color(stage: int) -> Color:
	match stage:
		1:
			return _COLOR_WARNING
		2:
			return _COLOR_ALERT
		3:
			return _COLOR_CRITICAL
		_:
			return _COLOR_SAFE
