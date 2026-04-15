extends Node

## 적 스탯 관리 컴포넌트.
## 그림자 강도 배율에 따라 실시간으로 HP/공격력/속도를 조정한다.

signal health_changed(current_hp: float, max_hp: float)
signal died

var _stats_data: EnemyStatsData
var _intensity_multiplier: float = 1.0
var _max_hp: float = 100.0
var _current_hp: float = 100.0
var _revive_hp_ratio: float = 1.0
var _revive_attack_ratio: float = 1.0
var _reinforce_hp_ratio: float = 1.0
var _reinforce_attack_ratio: float = 1.0


func setup(
	stats_data: EnemyStatsData,
	initial_intensity: float,
	revive_hp_ratio: float = 1.0,
	revive_attack_ratio: float = 1.0
) -> void:
	_stats_data = stats_data
	_revive_hp_ratio = revive_hp_ratio
	_revive_attack_ratio = revive_attack_ratio
	update_intensity(initial_intensity)
	_current_hp = _max_hp


func update_intensity(global_intensity: float) -> void:
	var config := EnemySystem.get_config()
	var old_multiplier := _intensity_multiplier
	_intensity_multiplier = EnemyIntensity.remap_intensity(global_intensity, _stats_data, config)

	# HP 비율 유지하며 최대 HP 갱신
	_recalculate_hp()

	health_changed.emit(_current_hp, _max_hp)


func take_damage(amount: float) -> void:
	_current_hp = maxf(_current_hp - amount, 0.0)
	health_changed.emit(_current_hp, _max_hp)
	if _current_hp <= 0.0:
		died.emit()


func reset_hp() -> void:
	_current_hp = _max_hp
	health_changed.emit(_current_hp, _max_hp)


func is_dead() -> bool:
	return _current_hp <= 0.0


func get_attack() -> float:
	var base: float = EnemyIntensity.apply_multiplier(
		_stats_data.base_attack, _intensity_multiplier
	)
	return base * _revive_attack_ratio * _reinforce_attack_ratio


func get_speed() -> float:
	return EnemyIntensity.apply_multiplier(_stats_data.base_speed, _intensity_multiplier)


func get_patrol_speed() -> float:
	return EnemyIntensity.apply_multiplier(_stats_data.patrol_speed, _intensity_multiplier)


func get_current_hp() -> float:
	return _current_hp


func get_max_hp() -> float:
	return _max_hp


func get_multiplier() -> float:
	return _intensity_multiplier


## 땅거미 도착 시 강화 배율을 적용한다.
func reinforce(hp_mult: float, atk_mult: float) -> void:
	_reinforce_hp_ratio = hp_mult
	_reinforce_attack_ratio = atk_mult
	_recalculate_hp()
	health_changed.emit(_current_hp, _max_hp)


func _recalculate_hp() -> void:
	var hp_ratio := _current_hp / _max_hp if _max_hp > 0.0 else 1.0
	var base_hp: float = EnemyIntensity.apply_multiplier(_stats_data.base_hp, _intensity_multiplier)
	_max_hp = base_hp * _revive_hp_ratio * _reinforce_hp_ratio
	_current_hp = _max_hp * hp_ratio
