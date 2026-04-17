extends "res://src/entities/enemies/base/behaviors/attack_behavior_base.gd"

## 근접 공격 행동.
## stats_data의 hitbox_size/offset/duration으로 히트박스 형상을 파라미터화한다.
## hitbox_active_duration > 0이면 활성 시간 만료 시 자동으로 비활성화.

var _hitbox_shape_node: CollisionShape2D
var _active_timer: float = 0.0
var _is_active: bool = false


func _on_setup() -> void:
	_hitbox_shape_node = _hitbox.get_node_or_null("HitboxShape") as CollisionShape2D
	if _hitbox_shape_node == null:
		push_warning("AttackBehaviorMelee: HitboxShape not found under Hitbox")
		return
	_apply_shape()


func on_attack_enter() -> void:
	_is_active = true
	_active_timer = 0.0
	_hitbox.set_deferred("monitoring", true)
	_hitbox.set_deferred("monitorable", true)


func on_attack_exit() -> void:
	_is_active = false
	_hitbox.set_deferred("monitoring", false)
	_hitbox.set_deferred("monitorable", false)


func on_state_update(delta: float) -> void:
	if not _is_active:
		return
	if _stats_data.hitbox_active_duration <= 0.0:
		return
	_active_timer += delta
	if _active_timer >= _stats_data.hitbox_active_duration:
		_is_active = false
		_hitbox.set_deferred("monitoring", false)
		_hitbox.set_deferred("monitorable", false)


func _apply_shape() -> void:
	var rect := _hitbox_shape_node.shape as RectangleShape2D
	if rect == null:
		rect = RectangleShape2D.new()
		_hitbox_shape_node.shape = rect
	rect.size = _stats_data.hitbox_size
	_hitbox_shape_node.position = _stats_data.hitbox_offset
