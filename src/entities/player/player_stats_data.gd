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

## 그림자 발걸음 (지상 텔포, Phase 4-0 #4)
@export var shadow_step_max_target_dist: float = 120.0
## 텔포 후 적의 등 뒤로 떨어지는 오프셋(facing 반대 방향 픽셀).
@export var shadow_step_back_offset: float = 28.0
@export var shadow_step_iframe: float = 0.22
@export var shadow_step_cooldown: float = 0.9

## 빛 도약 (공중 8방향 직선 비행, Phase 4-0 #4) — 진입 시점 입력으로 8방향 capture, 중력 무시.
## 짧은 duration + 빠른 speed로 burst 느낌. 거리 ≈ speed × duration.
@export var light_leap_speed: float = 800.0
@export var light_leap_duration: float = 0.15
@export var light_leap_iframe: float = 0.17
@export var light_leap_cooldown: float = 0.9

## 그림자 잠수 (공중 통과, Phase 4-0 #4)
@export var shadow_phase_speed: float = 260.0
@export var shadow_phase_duration: float = 0.30
@export var shadow_phase_iframe: float = 0.32
@export var shadow_phase_cooldown: float = 0.9
