extends CanvasLayer

## 시간 HUD — B-5 궤도 시계 + B-6 일식 링 + B-7 전파 배지.
## 드로잉은 TimeCoreRenderer Control에 위임, 본 스크립트는 EventBus 시그널 라우팅 담당.
## UI_IMPLEMENTATION_PLAN.md §1.4 (Pass 1 placeholder — 도형 draw_arc/draw_circle 기반).

const TimeStateMachine = preload("res://src/systems/time/time_state_machine.gd")
const TimeCoreRendererScript = preload("res://src/ui/hud/time_core_renderer.gd")

var _hour_value: float = 12.0
var _time_state: int = TimeStateMachine.TimeState.STOPPED
var _resource_current: float = 100.0
var _resource_max: float = 100.0
var _is_origin: bool = false
var _flow_rate: float = 1.0
var _recovery_tween: Tween
var _renderer: Control


func _ready() -> void:
	layer = 10
	_build_renderer()

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


func _on_resource_changed(current: float, max_val: float) -> void:
	_resource_max = max_val if max_val > 0.0 else _resource_max
	if _recovery_tween and _recovery_tween.is_running():
		return
	_resource_current = current
	_sync_renderer()


func _on_state_changed(_old_state: int, new_state: int) -> void:
	_time_state = new_state
	_sync_renderer()


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
