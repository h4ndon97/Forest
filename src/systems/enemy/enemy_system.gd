extends Node

## 적 시스템 Autoload.
## 적의 활성화/비활성화, 강도 갱신, 등록/제거를 관리한다.
## 다른 시스템과 직접 참조 없이 EventBus로만 통신한다.

const EnemyRegistryScript = preload("res://src/systems/enemy/enemy_registry.gd")
const TimeStateMachineScript = preload("res://src/systems/time/time_state_machine.gd")
const CONFIG_PATH := "res://data/enemies/enemy_config.tres"

var _config: EnemyConfigData
var _registry: Node
var _current_intensity: float = 0.2
var _enemies_active: bool = false
var _is_night: bool = false
var _lantern_on: bool = false
var _activation_timer: Timer


func _ready() -> void:
	_config = load(CONFIG_PATH) as EnemyConfigData

	_registry = Node.new()
	_registry.name = "Registry"
	_registry.set_script(EnemyRegistryScript)
	add_child(_registry)

	_activation_timer = Timer.new()
	_activation_timer.name = "ActivationTimer"
	_activation_timer.one_shot = true
	_activation_timer.timeout.connect(_on_activation_timeout)
	add_child(_activation_timer)

	EventBus.time_state_changed.connect(_on_time_state_changed)
	EventBus.shadow_params_changed.connect(_on_shadow_params_changed)
	EventBus.shadow_scale_changed.connect(_on_shadow_scale_changed)
	EventBus.day_night_changed.connect(_on_day_night_changed)
	EventBus.lantern_toggled.connect(_on_lantern_toggled)


## 적을 시스템에 등록하고 ID를 반환한다.
func register_enemy(enemy: Node) -> int:
	var id: int = _registry.register(enemy)
	EventBus.enemy_spawned.emit(id)
	return id


## 적 사망 처리. 시그널 발신 + 레지스트리 제거.
## 처치 시점의 낮/밤 상태를 반환한다 (잔류 정화 조건에 사용).
func on_enemy_died(enemy_id: int, death_position: Vector2) -> bool:
	var enemy: Node = _registry.get_enemy(enemy_id)
	var enemy_name: String = enemy.name if enemy else ""
	var killed_during_day: bool = not _is_night
	EventBus.enemy_killed.emit(enemy_id, enemy_name)
	EventBus.residue_left.emit(death_position, killed_during_day)
	_registry.unregister(enemy_id)
	return killed_during_day


## 현재 전역 강도를 반환한다.
func get_current_intensity() -> float:
	return _current_intensity


## 적이 현재 활성 상태인지 반환한다.
func are_enemies_active() -> bool:
	return _enemies_active


## 전역 설정을 반환한다.
func get_config() -> EnemyConfigData:
	return _config


## 활성 적 수를 반환한다.
func get_enemy_count() -> int:
	return _registry.get_count()


# --- 내부 ---

func _on_time_state_changed(_old_state: int, new_state: int) -> void:
	if new_state == TimeStateMachineScript.TimeState.FLOWING:
		_activation_timer.wait_time = _config.activation_delay
		_activation_timer.start()
	else:
		_activation_timer.stop()
		if _enemies_active:
			_deactivate_enemies()


func _on_shadow_params_changed(_direction: Vector2, _scale: float, intensity: float) -> void:
	_current_intensity = intensity
	# 밤+등불 ON 시에는 per-enemy로 처리 (shadow_scale_changed 시그널)
	if _is_night and _lantern_on:
		return
	if _enemies_active:
		_registry.update_all_intensity(intensity)


func _on_shadow_scale_changed(instance_id: int, intensity: float) -> void:
	if not _enemies_active:
		return
	var enemy: Node = _registry.get_enemy_by_instance_id(instance_id)
	if enemy and is_instance_valid(enemy) and enemy.has_method("update_intensity"):
		enemy.update_intensity(intensity)


func _on_day_night_changed(is_day: bool) -> void:
	_is_night = not is_day


func _on_lantern_toggled(is_on: bool, _pos: Vector2) -> void:
	_lantern_on = is_on


func _on_activation_timeout() -> void:
	_activate_enemies()


func _activate_enemies() -> void:
	_enemies_active = true
	_registry.activate_all()
	_registry.update_all_intensity(_current_intensity)


func _deactivate_enemies() -> void:
	_enemies_active = false
	_registry.deactivate_all()
