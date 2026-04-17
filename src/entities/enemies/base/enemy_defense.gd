extends Node

## 적 방어 컴포넌트.
## 피격 데미지 감산 및 경직 저항 확률을 처리한다.

var _stats_data: EnemyStatsData


func setup(stats_data: EnemyStatsData) -> void:
	_stats_data = stats_data


## 들어온 데미지에 감산을 적용. 최소 1 보장.
func apply_damage_reduction(amount: float) -> float:
	if _stats_data == null:
		return amount
	var reduced: float = amount - _stats_data.damage_reduction_flat
	return maxf(reduced, 1.0)


## 피격 시 HURT 상태에 진입할지 여부.
## true면 경직, false면 저항하여 공격 흐름 유지.
func should_enter_hurt_state() -> bool:
	if _stats_data == null:
		return true
	if _stats_data.hurt_resistance_chance >= 1.0:
		return true
	if _stats_data.hurt_resistance_chance <= 0.0:
		return false
	return randf() < _stats_data.hurt_resistance_chance
