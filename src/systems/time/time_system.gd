extends Node

## 시간 시스템 Autoload.
## 자식 컴포넌트(StateMachine, Clock, Resource, Atmosphere)를 생성하고 조율한다.
## 입력을 처리하고 EventBus를 통해 다른 시스템에 시그널을 발신한다.

const TimeStateMachine = preload("res://src/systems/time/time_state_machine.gd")
const TimeClock = preload("res://src/systems/time/time_clock.gd")
const TimeResource = preload("res://src/systems/time/time_resource.gd")
const TimeAtmosphere = preload("res://src/systems/time/time_atmosphere.gd")
const ConsumableDataClass = preload("res://data/items/consumable_data.gd")

const CONFIG_PATH := "res://data/time/time_config.tres"
const HUD_PATH := "res://src/ui/hud/TimeHud.tscn"

var _config: TimeConfigData
var _state_machine: Node
var _clock: Node
var _resource: Node
var _atmosphere: CanvasModulate
var _manipulation_start_hour: float = 0.0
var _did_manipulate: bool = false
var _flow_rate: float = 1.0
var _flow_paused: bool = false
var _input_blocked: bool = false


func _ready() -> void:
	_config = load(CONFIG_PATH) as TimeConfigData

	_state_machine = _create_child("StateMachine", TimeStateMachine)
	_clock = _create_child("Clock", TimeClock)
	_resource = _create_child("Resource", TimeResource)

	_atmosphere = CanvasModulate.new()
	_atmosphere.name = "Atmosphere"
	_atmosphere.set_script(TimeAtmosphere)
	add_child(_atmosphere)

	_clock.setup(_config)
	_resource.setup(_config)

	_state_machine.state_changed.connect(_on_state_changed)
	_clock.day_night_boundary_crossed.connect(_on_day_night_crossed)
	_resource.resource_changed.connect(_on_resource_changed)
	_resource.resource_depleted.connect(_on_resource_depleted)

	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.time_set_requested.connect(_on_time_set_requested)
	EventBus.flow_rate_changed.connect(_on_flow_rate_changed)
	EventBus.time_flow_paused.connect(_on_flow_paused)
	EventBus.time_flow_resumed.connect(_on_flow_resumed)
	EventBus.time_hour_sync_requested.connect(_on_hour_sync_requested)
	EventBus.time_flow_resume_requested.connect(_on_flow_resume_requested)
	EventBus.checkpoint_entered.connect(_on_checkpoint_entered)
	EventBus.checkpoint_exited.connect(_on_checkpoint_exited)
	EventBus.full_recovery_requested.connect(_on_full_recovery_requested)
	EventBus.time_resource_consume_flat_requested.connect(_on_consume_flat_requested)
	EventBus.consumable_used.connect(_on_consumable_used)

	_atmosphere.update_atmosphere(_clock.current_hour, _config)
	EventBus.current_hour_changed.emit(_clock.current_hour)
	EventBus.sun_state_updated.emit(_clock.get_sun_angle(), _clock.is_day())
	EventBus.time_resource_changed.emit(_resource.current, _resource.max_value)

	_load_hud.call_deferred()


func _process(delta: float) -> void:
	var state: int = _state_machine.current_state

	if state == TimeStateMachine.TimeState.MANIPULATING:
		var hours_elapsed: float = _clock.advance_manipulation(delta)
		if _clock.reached_manipulation_limit():
			_state_machine.on_manipulation_limit_reached()
			return
		_resource.consume(hours_elapsed)
		if _resource.is_depleted():
			_state_machine.on_resource_depleted()
		EventBus.current_hour_changed.emit(_clock.current_hour)
		EventBus.sun_state_updated.emit(_clock.get_sun_angle(), _clock.is_day())

	elif state == TimeStateMachine.TimeState.FLOWING:
		if _flow_paused:
			return
		var hours_elapsed: float = _clock.advance_flow(delta, _flow_rate)
		var full_hours: float = _clock.compute_full_flow_hours(delta)
		_resource.recover(full_hours)
		EventBus.current_hour_changed.emit(_clock.current_hour)
		EventBus.sun_state_updated.emit(_clock.get_sun_angle(), _clock.is_day())

	_atmosphere.update_atmosphere(_clock.current_hour, _config)


func _unhandled_input(event: InputEvent) -> void:
	if _input_blocked:
		return
	if event.is_action_pressed("time_manipulate"):
		_on_manipulate_pressed()
	elif event.is_action_released("time_manipulate"):
		_on_manipulate_released()


func get_current_hour() -> float:
	return _clock.current_hour


func get_time_state() -> int:
	return _state_machine.current_state


func is_day() -> bool:
	return _clock.is_day()


func get_sun_angle() -> float:
	return _clock.get_sun_angle()


func get_resource_data() -> Dictionary:
	return {"current": _resource.current, "max_value": _resource.max_value}


# --- 내부 ---


func _on_manipulate_pressed() -> void:
	_manipulation_start_hour = _clock.current_hour
	_did_manipulate = not _resource.is_depleted()
	_state_machine.request_manipulate(_did_manipulate)


func _on_manipulate_released() -> void:
	var from_hour := _manipulation_start_hour
	_state_machine.release_manipulate()
	if _did_manipulate and _clock.current_hour != from_hour:
		EventBus.time_manipulated.emit(from_hour, _clock.current_hour)
	_did_manipulate = false


func _on_state_changed(old_state: int, new_state: int) -> void:
	EventBus.time_state_changed.emit(old_state, new_state)

	if new_state == TimeStateMachine.TimeState.FLOWING:
		EventBus.time_flow_started.emit(_clock.current_hour)
	elif old_state == TimeStateMachine.TimeState.FLOWING:
		_flow_rate = 1.0
		_flow_paused = false
		EventBus.time_flow_stopped.emit(_clock.current_hour)


func _on_resource_changed(current: float, max_val: float) -> void:
	EventBus.time_resource_changed.emit(current, max_val)


func _on_day_night_crossed(is_day_now: bool) -> void:
	_state_machine.unblock_manipulation()
	EventBus.day_night_changed.emit(is_day_now)


func _on_resource_depleted() -> void:
	EventBus.time_resource_depleted.emit()


func _on_time_set_requested(hour: float) -> void:
	_clock.set_hour(hour)

	# 시간 상태를 STOPPED으로 초기화
	if _state_machine.current_state != TimeStateMachine.TimeState.STOPPED:
		_state_machine.transition_to(TimeStateMachine.TimeState.STOPPED)

	_atmosphere.update_atmosphere(hour, _config)
	EventBus.current_hour_changed.emit(hour)
	EventBus.sun_state_updated.emit(_clock.get_sun_angle(), _clock.is_day())
	EventBus.day_night_changed.emit(_clock.is_day())


func _on_flow_rate_changed(rate: float) -> void:
	_flow_rate = rate


func _on_flow_paused() -> void:
	_flow_paused = true


func _on_flow_resumed() -> void:
	_flow_paused = false


## 스테이지 진입 시 자동 재개: 시각과 rate를 설정하고 FLOWING으로 전환한다.
func _on_flow_resume_requested(hour: float, rate: float) -> void:
	_flow_rate = rate
	var was_day: bool = _clock.is_day()
	_clock.set_hour(hour)
	_atmosphere.update_atmosphere(hour, _config)
	if _state_machine.current_state != TimeStateMachine.TimeState.FLOWING:
		_state_machine.transition_to(TimeStateMachine.TimeState.FLOWING)
	EventBus.current_hour_changed.emit(hour)
	EventBus.sun_state_updated.emit(_clock.get_sun_angle(), _clock.is_day())
	if _clock.is_day() != was_day:
		EventBus.day_night_changed.emit(_clock.is_day())


## 시간 상태 변경 없이 시각만 동기화한다 (flow 유지 전환용).
func _on_hour_sync_requested(hour: float) -> void:
	var was_day: bool = _clock.is_day()
	_clock.set_hour(hour)
	_atmosphere.update_atmosphere(hour, _config)
	EventBus.current_hour_changed.emit(hour)
	EventBus.sun_state_updated.emit(_clock.get_sun_angle(), _clock.is_day())
	if _clock.is_day() != was_day:
		EventBus.day_night_changed.emit(_clock.is_day())


func _on_checkpoint_entered(_checkpoint_id: String) -> void:
	_input_blocked = true


func _on_checkpoint_exited(_checkpoint_id: String) -> void:
	_input_blocked = false


func _on_full_recovery_requested() -> void:
	_resource.full_recover()


func _on_consume_flat_requested(amount: float) -> void:
	_resource.consume_flat(amount)


func _on_consumable_used(consumable_type: int, amount: float) -> void:
	if consumable_type != ConsumableDataClass.ConsumableType.TIME_RECOVER:
		return
	_resource.recover_flat(amount)


func _on_enemy_killed(_enemy_id: int, _enemy_name: String) -> void:
	_resource.recover_flat(_config.kill_recover_amount)


func _create_child(child_name: String, script: GDScript) -> Node:
	var node := Node.new()
	node.name = child_name
	node.set_script(script)
	add_child(node)
	return node


func _load_hud() -> void:
	if not ResourceLoader.exists(HUD_PATH):
		return
	var hud_scene: PackedScene = load(HUD_PATH)
	if hud_scene:
		var hud := hud_scene.instantiate()
		get_tree().root.add_child(hud)
