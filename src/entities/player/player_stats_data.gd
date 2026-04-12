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
