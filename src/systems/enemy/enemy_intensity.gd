class_name EnemyIntensity
extends RefCounted

## 전역 그림자 강도를 적 유형별 배율로 변환하는 순수 계산 함수.


## 전역 강도(0.2~1.5)를 유형별 범위로 재매핑한다.
## global_intensity: ShadowSystem에서 받은 전역 강도.
## stats: 적 유형 데이터 (min/max_intensity 포함).
## config: 전역 적 설정 (global min/max 포함).
static func remap_intensity(
	global_intensity: float, stats: EnemyStatsData, config: EnemyConfigData
) -> float:
	var g_min := config.global_intensity_min
	var g_max := config.global_intensity_max
	if g_max <= g_min:
		return stats.min_intensity

	var t := clampf((global_intensity - g_min) / (g_max - g_min), 0.0, 1.0)
	return lerpf(stats.min_intensity, stats.max_intensity, t)


## 배율을 적용한 값을 계산한다.
static func apply_multiplier(base_value: float, multiplier: float) -> float:
	return base_value * multiplier
