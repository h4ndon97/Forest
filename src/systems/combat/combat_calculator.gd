class_name CombatCalculator
extends RefCounted

## 전투 데미지 계산 유틸리티.
## 상태를 갖지 않는 정적 계산 전용 클래스.

## 속성별 데미지 배율. Phase 2-6(성장 시스템)에서 조정.
const ATTRIBUTE_MULTIPLIERS := {
	"neutral": 1.0,
	"light": 1.0,
	"shadow": 1.0,
	"hybrid": 1.0,
}


## 타수에 따른 기본 데미지 반환.
static func calculate_hit_damage(hit_number: int, config: CombatConfigData) -> float:
	if hit_number >= config.combo_max_hits:
		return config.finish_damage
	return config.base_damage


## 속성 보정 적용. 배율 테이블에서 조회.
static func calculate_final_damage(base: float, attribute: String) -> float:
	var multiplier: float = ATTRIBUTE_MULTIPLIERS.get(attribute, 1.0)
	return base * multiplier
