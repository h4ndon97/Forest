extends Node

## 강화 포인트 / 프로퍼티 포인트의 잔고와 투자 이력을 관리한다.
## 포인트 획득, 투자, 리스펙 로직을 담당.
## Memory Shard(REC-MECH-001) 잔고도 자원 카운터 도메인 일관성을 위해 함께 관리.

const GrowthConfigData = preload("res://data/growth/growth_config_data.gd")

var available_growth: int = 0
var available_property: int = 0
var light_invested: int = 0
var shadow_invested: int = 0
var property_invested: int = 0
var memory_shards: int = 0

var _config: GrowthConfigData
var _hybrid_unlocked: bool = false


func setup(config: GrowthConfigData) -> void:
	_config = config


func earn_growth_points(amount: int, source: String) -> void:
	available_growth += amount
	EventBus.points_earned.emit(amount, source)
	EventBus.growth_points_changed.emit(available_growth, available_property)


func earn_property_points(amount: int, source: String) -> void:
	available_property += amount
	EventBus.points_earned.emit(amount, source)
	EventBus.growth_points_changed.emit(available_growth, available_property)


func invest_light(amount: int) -> bool:
	if amount <= 0 or available_growth < amount:
		return false
	available_growth -= amount
	light_invested += amount
	EventBus.growth_invested.emit("light", light_invested)
	EventBus.growth_points_changed.emit(available_growth, available_property)
	_check_hybrid_unlock()
	return true


func invest_shadow(amount: int) -> bool:
	if amount <= 0 or available_growth < amount:
		return false
	available_growth -= amount
	shadow_invested += amount
	EventBus.growth_invested.emit("shadow", shadow_invested)
	EventBus.growth_points_changed.emit(available_growth, available_property)
	_check_hybrid_unlock()
	return true


func invest_property(amount: int) -> bool:
	if amount <= 0 or available_property < amount:
		return false
	available_property -= amount
	property_invested += amount
	EventBus.growth_invested.emit("property", property_invested)
	EventBus.growth_points_changed.emit(available_growth, available_property)
	return true


func can_respec() -> bool:
	var total_invested: int = light_invested + shadow_invested
	if total_invested <= 0:
		return false
	var cost: int = ceili(total_invested * _config.respec_cost_ratio)
	return available_growth >= cost


func respec() -> bool:
	var total_invested: int = light_invested + shadow_invested
	if total_invested <= 0:
		return false
	var cost: int = ceili(total_invested * _config.respec_cost_ratio)
	if available_growth < cost:
		return false

	available_growth -= cost
	available_growth += total_invested
	light_invested = 0
	shadow_invested = 0
	_hybrid_unlocked = false
	EventBus.growth_respec_completed.emit()
	EventBus.growth_points_changed.emit(available_growth, available_property)
	return true


func is_hybrid_unlocked() -> bool:
	return _hybrid_unlocked


func get_total_growth_invested() -> int:
	return light_invested + shadow_invested


func add_memory_shards(amount: int) -> void:
	if amount <= 0:
		return
	memory_shards += amount
	EventBus.memory_shard_changed.emit(memory_shards)


func get_save_data() -> Dictionary:
	return {
		"available_growth": available_growth,
		"available_property": available_property,
		"light_invested": light_invested,
		"shadow_invested": shadow_invested,
		"property_invested": property_invested,
		"hybrid_unlocked": _hybrid_unlocked,
		"memory_shards": memory_shards,
	}


func load_save_data(data: Dictionary) -> void:
	available_growth = data.get("available_growth", 0)
	available_property = data.get("available_property", 0)
	light_invested = data.get("light_invested", 0)
	shadow_invested = data.get("shadow_invested", 0)
	property_invested = data.get("property_invested", 0)
	_hybrid_unlocked = data.get("hybrid_unlocked", false)
	memory_shards = data.get("memory_shards", 0)


func _check_hybrid_unlock() -> void:
	if _hybrid_unlocked:
		return
	var threshold: int = _config.hybrid_unlock_threshold
	if light_invested >= threshold and shadow_invested >= threshold:
		_hybrid_unlocked = true
		EventBus.hybrid_unlocked.emit()
