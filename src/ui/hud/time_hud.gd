extends CanvasLayer

## 시간 HUD — 시계, 상태, 자원 게이지를 표시한다.
## EventBus 시그널만 수신하여 갱신한다.

const TimeStateMachine = preload("res://src/systems/time/time_state_machine.gd")

const STATE_LABELS := {
	TimeStateMachine.TimeState.STOPPED: "STOP",
	TimeStateMachine.TimeState.MANIPULATING: "MANIP",
	TimeStateMachine.TimeState.FLOWING: "FLOW",
}

const STATE_COLORS := {
	TimeStateMachine.TimeState.STOPPED: Color(0.6, 0.6, 0.6),
	TimeStateMachine.TimeState.MANIPULATING: Color(0.3, 0.5, 1.0),
	TimeStateMachine.TimeState.FLOWING: Color(0.3, 0.9, 0.4),
}

@onready var clock_label: Label = $MarginContainer/VBoxContainer/ClockLabel
@onready var state_label: Label = $MarginContainer/VBoxContainer/StateLabel
@onready var resource_gauge: ProgressBar = $MarginContainer/VBoxContainer/ResourceGauge
@onready var resource_label: Label = $MarginContainer/VBoxContainer/ResourceLabel


var _recovery_tween: Tween
var _prev_gauge_value: float = 100.0


func _ready() -> void:
	EventBus.current_hour_changed.connect(_on_hour_changed)
	EventBus.time_resource_changed.connect(_on_resource_changed)
	EventBus.time_state_changed.connect(_on_state_changed)
	EventBus.full_recovery_requested.connect(_on_full_recovery)


func _on_hour_changed(hour: float) -> void:
	var hour_int: int = int(hour) % 24
	var minute_int: int = int((hour - floorf(hour)) * 60.0)
	clock_label.text = "%02d:%02d" % [hour_int, minute_int]


func _on_resource_changed(current: float, max_val: float) -> void:
	resource_label.text = "%d / %d" % [int(current), int(max_val)]
	if _recovery_tween and _recovery_tween.is_running():
		return
	_prev_gauge_value = resource_gauge.value
	if max_val > 0.0:
		resource_gauge.value = current / max_val * 100.0


func _on_full_recovery() -> void:
	if _recovery_tween:
		_recovery_tween.kill()
	var start_value: float = _prev_gauge_value
	resource_gauge.value = start_value
	_recovery_tween = create_tween()
	_recovery_tween.tween_property(resource_gauge, "value", 100.0, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func _on_state_changed(old_state: int, new_state: int) -> void:
	state_label.text = STATE_LABELS.get(new_state, "???")
	state_label.modulate = STATE_COLORS.get(new_state, Color.WHITE)
