extends "res://src/entities/enemies/base/behaviors/attack_behavior_base.gd"

## 지면 고정 촉수 공격 (zone2 marsh_tendril 등 고정형 적용).
## telegraph 후 긴 사거리 hitbox 활성. ranged의 telegraph + melee의 hitbox 합성.
## telegraph 길이: stats_data.projectile_telegraph 재사용.
## 의도: 적은 이동하지 않고(base_speed=0), 사거리 안에 들어온 플레이어를 공격.

const _DEFAULT_ACTIVE_DURATION := 0.4

var _telegraph_timer: float = 0.0
var _pending_strike: bool = false
var _current_attack_area: Area2D = null


func on_attack_enter() -> void:
	_cancel_current_attack()
	_telegraph_timer = 0.0
	_pending_strike = true


func on_attack_exit() -> void:
	_pending_strike = false
	_cancel_current_attack()


func on_state_update(delta: float) -> void:
	if not _pending_strike:
		return
	_telegraph_timer += delta
	if _telegraph_timer < _stats_data.projectile_telegraph:
		return
	_pending_strike = false
	_strike()


func _strike() -> void:
	var spec := AttackSpec.new()
	spec.attacker = _enemy_root
	spec.source_group = "enemy_attack"
	spec.shape_type = "rect"
	spec.hitbox_size = _stats_data.hitbox_size
	spec.hitbox_offset = Vector2(
		absf(_stats_data.hitbox_offset.x) * _enemy_root.movement_comp.facing,
		_stats_data.hitbox_offset.y,
	)
	spec.active_duration = (
		_stats_data.hitbox_active_duration
		if _stats_data.hitbox_active_duration > 0.0
		else _DEFAULT_ACTIVE_DURATION
	)
	spec.damage = _enemy_root.stats_comp.get_attack()
	spec.is_finish = false
	spec.attribute = "shadow"
	spec.tags = PackedStringArray(["enemy_melee", "ground_tether"])

	_current_attack_area = CombatSystem.request_attack(spec)


func _cancel_current_attack() -> void:
	if _current_attack_area != null and is_instance_valid(_current_attack_area):
		CombatSystem.cancel_attack(_current_attack_area)
	_current_attack_area = null
