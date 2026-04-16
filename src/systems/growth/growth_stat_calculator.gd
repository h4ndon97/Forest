extends Node

## 투자된 포인트로부터 능력치 보너스를 계산한다.
## 순수 계산 전용 — 상태를 소유하지 않고 PointTracker를 참조한다.

const GrowthConfigData = preload("res://data/growth/growth_config_data.gd")

var _config: GrowthConfigData
var _tracker: Node


func setup(config: GrowthConfigData, tracker: Node) -> void:
	_config = config
	_tracker = tracker


# === 빛 투자 보너스 ===


func get_attack_bonus() -> float:
	return _tracker.light_invested * _config.attack_bonus_per_point


func get_lantern_range_bonus() -> float:
	return _tracker.light_invested * _config.lantern_range_bonus_per_point


func get_lantern_brightness_bonus() -> float:
	return _tracker.light_invested * _config.lantern_brightness_bonus_per_point


# === 그림자 투자 보너스 ===


func get_hp_bonus() -> float:
	return _tracker.shadow_invested * _config.hp_bonus_per_point


# === 프로퍼티 투자 보너스 ===


func get_time_max_bonus() -> float:
	return _tracker.property_invested * _config.time_max_bonus_per_point


func get_time_recovery_bonus() -> float:
	return _tracker.property_invested * _config.time_recovery_bonus_per_point


# === 요약 ===


func get_all_bonuses() -> Dictionary:
	return {
		"attack_bonus": get_attack_bonus(),
		"hp_bonus": get_hp_bonus(),
		"lantern_range_bonus": get_lantern_range_bonus(),
		"lantern_brightness_bonus": get_lantern_brightness_bonus(),
		"time_max_bonus": get_time_max_bonus(),
		"time_recovery_bonus": get_time_recovery_bonus(),
	}
