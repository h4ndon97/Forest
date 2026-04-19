extends Area2D

## 광 센서 컴포넌트.
## layer=128(LIGHT_BEAM) Area2D와 겹침 감지 → 점등/소등 토글.
## 이중 용도: (a) HiddenRevealer LIGHT_SENSOR/REFLECTION 소스, (b) ENVIRONMENT α 잠금 validator.
## 복수 빔 입력 시 OR 시맨틱 (어느 하나라도 ON이면 ON).

signal light_sensor_activated(sensor_id: String)
signal light_sensor_deactivated(sensor_id: String)

@export var data: LightSensorData
## 씬 인스턴스별로 덮어쓸 수 있는 식별자. 비어 있으면 data.sensor_id 사용.
@export var sensor_id_override: String = ""

var _active_beam_count: int = 0
var _is_activated: bool = false
## 디바운스 취소용 세대 카운터.
var _pending_generation: int = 0
var _resolved_sensor_id: String = ""

@onready var _visual: Node2D = $Visual if has_node("Visual") else null


func _ready() -> void:
	add_to_group("light_sensors")
	_resolved_sensor_id = sensor_id_override
	if _resolved_sensor_id.is_empty() and data != null:
		_resolved_sensor_id = data.sensor_id
	if _resolved_sensor_id.is_empty():
		push_warning("LightSensor: sensor_id 미설정 (%s)" % name)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	_setup_visual()
	_update_visual()


func _setup_visual() -> void:
	if _visual == null or data == null:
		return
	if _visual.has_method("configure"):
		_visual.configure(data.color_off, data.color_on)


## 현재 점등 상태.
func is_activated() -> bool:
	return _is_activated


func get_sensor_id() -> String:
	return _resolved_sensor_id


## 디버그/세이브 복원용 강제 설정 (시그널 방출 포함).
func force_set_state(activated: bool) -> void:
	_set_activated(activated)


# --- 내부 ---


func _on_area_entered(_area: Area2D) -> void:
	_active_beam_count += 1
	if _active_beam_count == 1:
		_schedule_activation()


func _on_area_exited(_area: Area2D) -> void:
	_active_beam_count = maxi(_active_beam_count - 1, 0)
	if _active_beam_count == 0:
		_schedule_deactivation()


func _schedule_activation() -> void:
	if _is_activated:
		return
	var delay: float = data.activation_delay if data else 0.0
	if delay <= 0.0:
		_set_activated(true)
		return
	_pending_generation += 1
	var my_gen: int = _pending_generation
	await get_tree().create_timer(delay).timeout
	if my_gen != _pending_generation:
		return
	if _active_beam_count > 0 and not _is_activated:
		_set_activated(true)


func _schedule_deactivation() -> void:
	if not _is_activated:
		return
	var delay: float = data.deactivation_delay if data else 0.0
	if delay <= 0.0:
		_set_activated(false)
		return
	_pending_generation += 1
	var my_gen: int = _pending_generation
	await get_tree().create_timer(delay).timeout
	if my_gen != _pending_generation:
		return
	if _active_beam_count == 0 and _is_activated:
		_set_activated(false)


func _set_activated(activated: bool) -> void:
	if _is_activated == activated:
		return
	_is_activated = activated
	_update_visual()
	if _is_activated:
		light_sensor_activated.emit(_resolved_sensor_id)
	else:
		light_sensor_deactivated.emit(_resolved_sensor_id)
	EventBus.light_sensor_toggled.emit(_resolved_sensor_id, _is_activated)


func _update_visual() -> void:
	if _visual == null:
		return
	if _visual.has_method("set_active"):
		_visual.set_active(_is_activated)
