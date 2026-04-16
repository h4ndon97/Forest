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
@export var respawn_delay: float = 1.0
