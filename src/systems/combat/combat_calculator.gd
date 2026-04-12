class_name CombatCalculator
extends RefCounted

## 전투 데미지 계산 유틸리티.
## 상태를 갖지 않는 정적 계산 전용 클래스.


## 타수에 따른 기본 데미지 반환.
static func calculate_hit_damage(hit_number: int, config: CombatConfigData) -> float:
	if hit_number >= config.combo_max_hits:
		return config.finish_damage
	return config.base_damage


## 속성 보정 적용. Phase 1-6에서는 그대로 반환.
## 스킬 시스템 구현 시 속성별 배율 적용.
static func calculate_final_damage(base: float, _attribute: String) -> float:
	return base
