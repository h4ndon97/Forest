extends CanvasLayer

## 시간 HUD — B-5 궤도 시계 + B-6 일식 링 + B-7 전파 배지.
## 드로잉은 TimeCoreRenderer Control에 위임, 본 스크립트는 EventBus 시그널 라우팅 담당.
## UI_IMPLEMENTATION_PLAN.md §1.4 (Pass 1 placeholder — 도형 draw_arc/draw_circle 기반).

const TimeStateMachine = preload("res://src/systems/time/time_state_machine.gd")
const TimeCoreRendererScript = preload("res://src/ui/hud/time_core_renderer.gd")

## 디지털 시각 라벨 — 시계 클러스터(클럭링+일식링+전파배지) 아래 정렬.
## 명세는 잠정(UI 설계 가변), Pass 5 재검토 시 위치/폰트 재조정.
const HOUR_LABEL_POSITION := Vector2(575, 100)
const HOUR_LABEL_SIZE := Vector2(40, 14)
const HOUR_LABEL_FONT_SIZE: int = 10
const HOUR_LABEL_COLOR_DAY := Color(0.949, 0.8, 0.4, 0.95)  # 낮(해): 금색
const HOUR_LABEL_COLOR_NIGHT := Color(0.75, 0.7, 0.9, 0.95)  # 밤(달): 연보라
const HOUR_LABEL_COLOR_STOPPED := Color(0.55, 0.55, 0.6, 0.7)
const HOUR_LABEL_COLOR_MANIPULATING := Color(0.3, 0.5, 1.0, 0.95)
const NIGHT_START_HOUR: float = 18.0
const NIGHT_END_HOUR: float = 6.0

var _hour_value: float = 12.0
var _time_state: int = TimeStateMachine.TimeState.STOPPED
var _resource_current: float = 100.0
var _resource_max: float = 100.0
var _is_origin: bool = false
var _flow_rate: float = 1.0
var _recovery_tween: Tween
var _renderer: Control
var _hour_label: Label


func _ready() -> void:
	layer = 10
	_build_renderer()
	_build_hour_label()

	EventBus.current_hour_changed.connect(_on_hour_changed)
	EventBus.time_resource_changed.connect(_on_resource_changed)
	EventBus.time_state_changed.connect(_on_state_changed)
	EventBus.flow_rate_changed.connect(_on_flow_rate_changed)
	EventBus.propagation_origin_changed.connect(_on_origin_changed)
	EventBus.full_recovery_requested.connect(_on_full_recovery)


func _build_renderer() -> void:
	_renderer = Control.new()
	_renderer.set_script(TimeCoreRendererScript)
	_renderer.name = "TimeCoreRenderer"
	_renderer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_renderer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_renderer)
	_sync_renderer()


func _build_hour_label() -> void:
	_hour_label = Label.new()
	_hour_label.name = "HourLabel"
	_hour_label.position = HOUR_LABEL_POSITION
	_hour_label.size = HOUR_LABEL_SIZE
	_hour_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hour_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_hour_label.add_theme_font_size_override("font_size", HOUR_LABEL_FONT_SIZE)
	_hour_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hour_label)
	_update_hour_label_text()
	_update_hour_label_color()


func _update_hour_label_text() -> void:
	if _hour_label == null:
		return
	var hours: int = int(floor(_hour_value)) % 24
	var minutes: int = int(floor((_hour_value - floor(_hour_value)) * 60.0))
	_hour_label.text = "%02d:%02d" % [hours, minutes]


func _update_hour_label_color() -> void:
	if _hour_label == null:
		return
	var color: Color
	match _time_state:
		TimeStateMachine.TimeState.FLOWING:
			color = HOUR_LABEL_COLOR_NIGHT if _is_night() else HOUR_LABEL_COLOR_DAY
		TimeStateMachine.TimeState.MANIPULATING:
			color = HOUR_LABEL_COLOR_MANIPULATING
		_:
			color = HOUR_LABEL_COLOR_STOPPED
	_hour_label.add_theme_color_override("font_color", color)


func _is_night() -> bool:
	return _hour_value < NIGHT_END_HOUR or _hour_value >= NIGHT_START_HOUR


func _sync_renderer() -> void:
	if _renderer == null:
		return
	_renderer.hour_value = _hour_value
	_renderer.time_state = _time_state
	_renderer.resource_ratio = _resource_ratio()
	_renderer.is_origin = _is_origin
	_renderer.flow_rate = _flow_rate
	_renderer.queue_redraw()


func _resource_ratio() -> float:
	if _resource_max <= 0.0:
		return 0.0
	return clamp(_resource_current / _resource_max, 0.0, 1.0)


# === 시그널 핸들러 ===


func _on_hour_changed(hour: float) -> void:
	_hour_value = hour
	_sync_renderer()
	_update_hour_label_text()
	_update_hour_label_color()


func _on_resource_changed(current: float, max_val: float) -> void:
	_resource_max = max_val if max_val > 0.0 else _resource_max
	if _recovery_tween and _recovery_tween.is_running():
		return
	_resource_current = current
	_sync_renderer()


func _on_state_changed(_old_state: int, new_state: int) -> void:
	_time_state = new_state
	_sync_renderer()
	_update_hour_label_color()


func _on_flow_rate_changed(rate: float) -> void:
	_flow_rate = rate
	_sync_renderer()


func _on_origin_changed(is_origin: bool) -> void:
	_is_origin = is_origin
	_sync_renderer()


func _on_full_recovery() -> void:
	if _recovery_tween:
		_recovery_tween.kill()
	# Pass 1 placeholder — 즉시 만충. Pass 2에서 tween 추가.
	_resource_current = _resource_max
	_sync_renderer()
