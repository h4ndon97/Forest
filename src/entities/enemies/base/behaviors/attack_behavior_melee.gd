extends "res://src/entities/enemies/base/behaviors/attack_behavior_base.gd"

## 근접 공격 행동.
## Phase 4-0 #1 Step 3: 자체 Hitbox 의존 제거 → CombatSystem.request_attack(AttackSpec) 위임.
## hitbox_active_duration > 0이면 spec.active_duration으로 사용. 0이면 _DEFAULT_ACTIVE_DURATION
## 상한 + on_attack_exit이 cancel하는 방식으로 ATTACK 상태 동안만 유효 유지.

const _DEFAULT_ACTIVE_DURATION := 0.5

## ATTACK 중도 이탈 시 잔존 히트 방지용 안전장치.
var _current_attack_area: Area2D = null


func on_attack_enter() -> void:
	_cancel_current_attack()

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
	spec.attribute = "none"
	spec.tags = PackedStringArray(["enemy_melee"])

	_current_attack_area = CombatSystem.request_attack(spec)


func on_attack_exit() -> void:
	_cancel_current_attack()


func _cancel_current_attack() -> void:
	if _current_attack_area != null and is_instance_valid(_current_attack_area):
		CombatSystem.cancel_attack(_current_attack_area)
	_current_attack_area = null
