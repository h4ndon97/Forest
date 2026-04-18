class_name PlayerStatsData
extends Resource

## 이동
@export var run_speed: float = 120.0
@export var friction: float = 800.0

## 점프
@export var jump_velocity: float = -280.0
@export var jump_cut_multiplier: float = 0.4
@export var max_air_jumps: int = 1
@export var coyote_time: float = 0.1
@export var gravity_scale: float = 1.0
@export var fall_gravity_scale: float = 1.5

## 대시
@export var dash_speed: float = 250.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.6

## 빛 대시 (Phase 3-3-d 보스 보상 능력)
@export var light_dash_speed: float = 320.0
@export var light_dash_duration: float = 0.18
@export var light_dash_cooldown: float = 0.9
## 빛 대시 진입 시 부여되는 무적 시간(s). 보통 duration과 같거나 약간 더 김.
@export var light_dash_iframe: float = 0.22
