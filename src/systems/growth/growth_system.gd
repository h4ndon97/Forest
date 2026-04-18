extends Node

## 성장 시스템 Autoload.
## 강화 포인트 투자, 능력치 보너스, 리스펙을 관리한다.
## 소비 시스템(HP, 공격력, 등불, 시간자원)은 growth_stats_changed 시그널로 재조회.

const GrowthConfigData = preload("res://data/growth/growth_config_data.gd")
const PointTrackerScript = preload("res://src/systems/growth/growth_point_tracker.gd")
const StatCalculatorScript = preload("res://src/systems/growth/growth_stat_calculator.gd")
const CONFIG_PATH := "res://data/growth/growth_config.tres"

var _config: GrowthConfigData
var _tracker: Node
var _calculator: Node


func _ready() -> void:
	_load_config()
	_create_components()
	_connect_signals()


# === Public API: 포인트 조회 ===


func get_available_growth() -> int:
	return _tracker.available_growth


func get_available_property() -> int:
	return _tracker.available_property


func get_light_invested() -> int:
	return _tracker.light_invested


func get_shadow_invested() -> int:
	return _tracker.shadow_invested


func get_property_invested() -> int:
	return _tracker.property_invested


func is_hybrid_unlocked() -> bool:
	return _tracker.is_hybrid_unlocked()


# === Public API: 포인트 획득 ===


## 외부 시스템(보스 보상 등)이 강화 포인트를 지급할 때 사용.
func earn_growth_points(amount: int, source: String) -> void:
	if amount <= 0:
		return
	_tracker.earn_growth_points(amount, source)


# === Public API: 투자 ===


func invest_light(amount: int = 1) -> bool:
	if not _tracker.invest_light(amount):
		return false
	EventBus.growth_stats_changed.emit()
	return true


func invest_shadow(amount: int = 1) -> bool:
	if not _tracker.invest_shadow(amount):
		return false
	EventBus.growth_stats_changed.emit()
	return true


func invest_property(amount: int = 1) -> bool:
	if not _tracker.invest_property(amount):
		return false
	EventBus.growth_stats_changed.emit()
	return true


# === Public API: 리스펙 ===


func can_respec() -> bool:
	return _tracker.can_respec()


func respec() -> bool:
	if not _tracker.respec():
		return false
	EventBus.growth_stats_changed.emit()
	return true


# === Public API: 보너스 조회 (소비 시스템용) ===


func get_attack_bonus() -> float:
	return _calculator.get_attack_bonus()


func get_hp_bonus() -> float:
	return _calculator.get_hp_bonus()


func get_lantern_range_bonus() -> float:
	return _calculator.get_lantern_range_bonus()


func get_lantern_brightness_bonus() -> float:
	return _calculator.get_lantern_brightness_bonus()


func get_time_max_bonus() -> float:
	return _calculator.get_time_max_bonus()


func get_time_recovery_bonus() -> float:
	return _calculator.get_time_recovery_bonus()


# === Public API: 세이브/로드 ===


func get_save_data() -> Dictionary:
	return _tracker.get_save_data()


func load_save_data(data: Dictionary) -> void:
	_tracker.load_save_data(data)
	EventBus.growth_stats_changed.emit()
	EventBus.growth_points_changed.emit(
		_tracker.available_growth, _tracker.available_property
	)


# === 디버그 (Phase 3 UI 전까지 임시) ===


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	var key_event: InputEventKey = event as InputEventKey
	if key_event.echo:
		return
	match key_event.physical_keycode:
		KEY_F5:
			_debug_earn_points(10)
		KEY_F6:
			_debug_invest_light()
		KEY_F7:
			_debug_invest_shadow()
		KEY_F9:
			_debug_invest_property()


func _debug_earn_points(amount: int) -> void:
	_tracker.earn_growth_points(amount, "debug")
	_tracker.earn_property_points(amount, "debug")
	print("[Growth DEBUG] +%d points (growth: %d, property: %d)" % [
		amount, _tracker.available_growth, _tracker.available_property
	])


func _debug_invest_light() -> void:
	if invest_light():
		print("[Growth DEBUG] Light invested: %d (ATK +%.0f)" % [
			_tracker.light_invested, _calculator.get_attack_bonus()
		])
	else:
		print("[Growth DEBUG] Not enough growth points")


func _debug_invest_shadow() -> void:
	if invest_shadow():
		print("[Growth DEBUG] Shadow invested: %d (HP +%.0f)" % [
			_tracker.shadow_invested, _calculator.get_hp_bonus()
		])
	else:
		print("[Growth DEBUG] Not enough growth points")


func _debug_invest_property() -> void:
	if invest_property():
		print("[Growth DEBUG] Property invested: %d (TimeMax +%.0f)" % [
			_tracker.property_invested, _calculator.get_time_max_bonus()
		])
	else:
		print("[Growth DEBUG] Not enough property points")


# === 내부 ===


func _load_config() -> void:
	if ResourceLoader.exists(CONFIG_PATH):
		_config = load(CONFIG_PATH) as GrowthConfigData
	if _config == null:
		_config = GrowthConfigData.new()


func _create_components() -> void:
	_tracker = _create_child("PointTracker", PointTrackerScript)
	_tracker.setup(_config)
	_calculator = _create_child("StatCalculator", StatCalculatorScript)
	_calculator.setup(_config, _tracker)


func _create_child(child_name: String, script: GDScript) -> Node:
	var node := Node.new()
	node.name = child_name
	node.set_script(script)
	add_child(node)
	return node


func _connect_signals() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.stage_clear_updated.connect(_on_stage_clear_updated)
	EventBus.hybrid_unlocked.connect(_on_hybrid_unlocked)


func _on_enemy_killed(_enemy_id: int, _enemy_name: String) -> void:
	var amount: int = randi_range(_config.kill_points_min, _config.kill_points_max)
	_tracker.earn_growth_points(amount, "kill")


func _on_stage_clear_updated(_stage_id: String, clear_level: int) -> void:
	if clear_level == 2:
		_tracker.earn_growth_points(_config.stage_clear_points, "stage_clear")


func _on_hybrid_unlocked() -> void:
	print("[Growth DEBUG] Hybrid UNLOCKED! (light: %d, shadow: %d)" % [
		_tracker.light_invested, _tracker.shadow_invested
	])
