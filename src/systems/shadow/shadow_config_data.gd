class_name ShadowConfigData
extends Resource

## 그림자 스케일 범위
@export var min_shadow_scale: float = 0.1
@export var max_shadow_scale: float = 2.0

## 적 강도 범위 (통합 배율)
@export var min_intensity: float = 0.2
@export var max_intensity: float = 1.5

## 매핑 곡선 (null이면 선형)
@export var intensity_curve: Curve

## 밤 기본 강도 (등불 시스템 미구현 시 fallback)
@export var night_fallback_intensity: float = 1.0

## 그림자 스프라이트 기본 투명도
@export var shadow_base_alpha: float = 0.5

## 기본 그림자 방향 (fallback)
@export var default_direction: Vector2 = Vector2(0, 1)
