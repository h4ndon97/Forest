class_name CombatConfigData
extends Resource

## 전투 시스템 설정 데이터.
## data/combat/combat_config.tres에서 수치 조정.

# === 플레이어 HP ===
@export_group("Player HP")
@export var player_max_hp: float = 100.0
@export var invincible_duration: float = 0.5
@export var knockback_force: float = 275.0
@export var knockback_up_force: float = -150.0
@export var knockback_duration: float = 0.35

# === 콤보 ===
@export_group("Combo")
@export var combo_max_hits: int = 4
@export var hit_duration: float = 0.3
@export var combo_window: float = 0.35
@export var combo_reset_time: float = 0.5
@export var attack_movement_factor: float = 0.4

# === 데미지 ===
@export_group("Damage")
@export var base_damage: float = 20.0
@export var finish_damage: float = 40.0
## 스킬 시스템 연결용. 현재는 "neutral" 고정.
@export var finish_attribute: String = "neutral"

# === 히트박스 ===
@export_group("Hitbox")
@export var hitbox_size: Vector2 = Vector2(36, 24)
@export var hitbox_offset: Vector2 = Vector2(24, -14)

# === 허트박스 ===
@export_group("Hurtbox")
@export var hurtbox_size: Vector2 = Vector2(14, 28)
@export var hurtbox_offset: Vector2 = Vector2(0, -14)

# === 자동 회복 ===
@export_group("Auto Heal")
## 시간 정지 중 자동 회복량 (틱당)
@export var auto_heal_amount: float = 2.0
## 자동 회복 간격 (초)
@export var auto_heal_interval: float = 1.0

# === 리스폰 ===
@export_group("Respawn")
## 비-거점 리스폰 fallback 지연 (체크포인트 부재 시 player_respawned 즉시 emit 전 대기).
@export var respawn_delay: float = 1.0
## 죽음 시 검정 오버레이 페이드인 (combat_hud).
@export var respawn_fade_in_duration: float = 0.6
## 검정 풀 알파 상태 유지 시간 (분위기형). _respawn_timer = fade_in + hold.
@export var respawn_hold_duration: float = 1.5
## 거점 리스폰 후 stage_transition 페이드인 시간.
@export var respawn_fade_out_duration: float = 0.4
