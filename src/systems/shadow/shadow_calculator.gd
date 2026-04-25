class_name ShadowCalculator
extends RefCounted

## 순수 계산 함수 모음.
## 태양 각도 → 그림자 방향/스케일, 스케일 → 적 강도 배율.


## 낮 그림자 방향을 계산한다.
## sun_angle: 0°(일출) ~ 180°(일몰). TimeClock.get_sun_angle() 값.
## 반환: 정규화된 방향 벡터 (아침 → 왼쪽, 오후 → 오른쪽)
static func calculate_day_direction(sun_angle: float) -> Vector2:
	var rad := deg_to_rad(sun_angle)
	var dir_x := -cos(rad)
	# 정오(sun_angle=90°): dir_x≈0 → 아래 방향
	if absf(dir_x) < 0.001:
		return Vector2(0, 1).normalized()
	return Vector2(dir_x, 0.5).normalized()


## 낮 그림자 스케일 팩터를 계산한다.
## sun_angle: 0°(일출) ~ 180°(일몰).
## 반환: 0.0(정오, 최소) ~ 1.0(경계, 최대)
static func calculate_day_scale_factor(sun_angle: float) -> float:
	var rad := deg_to_rad(sun_angle)
	return 1.0 - sin(rad)


## 스케일 팩터(0~1)를 실제 그림자 스프라이트 스케일로 변환한다.
static func scale_factor_to_sprite_scale(factor: float, config: ShadowConfigData) -> float:
	return lerpf(config.min_shadow_scale, config.max_shadow_scale, factor)


## 스케일 팩터(0~1)를 적 강도 배율로 변환한다.
## is_day=true: 짧으면 약(0.2), 길면 강(1.5)
## is_day=false: 반전 — 짧으면 강(1.5), 길면 약(0.2)
static func calculate_intensity(
	scale_factor: float, is_day: bool, config: ShadowConfigData
) -> float:
	var t := clampf(scale_factor, 0.0, 1.0)

	# 곡선이 있으면 적용
	if config.intensity_curve:
		t = config.intensity_curve.sample(t)

	if is_day:
		return lerpf(config.min_intensity, config.max_intensity, t)
	return lerpf(config.max_intensity, config.min_intensity, t)


## 밤 그림자 방향을 계산한다 (등불 기반).
## object_pos: 오브젝트 위치, lantern_pos: 등불 위치.
## 반환: 등불에서 멀어지는 방향.
static func calculate_night_direction(object_pos: Vector2, lantern_pos: Vector2) -> Vector2:
	var dir := object_pos - lantern_pos
	if dir.length_squared() < 0.001:
		return Vector2(0, 1).normalized()
	return dir.normalized()


## 밤 그림자 스케일 팩터를 계산한다 (등불 기반).
## distance: 오브젝트와 등불 사이 거리, max_range: 등불 최대 범위.
## 반환: 0.0(등불 바로 옆, 최단) ~ 1.0(범위 끝, 최장)
static func calculate_night_scale_factor(distance: float, max_range: float) -> float:
	if max_range <= 0.0:
		return 1.0
	return clampf(distance / max_range, 0.0, 1.0)
