extends "res://src/entities/enemies/base/behaviors/attack_behavior_base.gd"

## 원거리 공격 행동.
## ATTACK 상태 진입 → 선딜 경과 후 투사체 1발 발사.
## Phase 4-0 #1 Step 3: BaseEnemy의 자체 Hitbox 노드가 제거되어 강제 비활성 코드도 함께 삭제됨.
## 투사체 발사 자체는 #1 Step 4에서 CombatSystem.request_projectile로 이전 예정.

const DEFAULT_PROJECTILE_PATH := "res://src/entities/enemies/projectile/EnemyProjectile.tscn"

var _projectile_scene: PackedScene
var _telegraph_timer: float = 0.0
var _pending_fire: bool = false


func _on_setup() -> void:
	var path: String = _stats_data.projectile_scene_path
	if path == "":
		path = DEFAULT_PROJECTILE_PATH
	if ResourceLoader.exists(path):
		_projectile_scene = load(path) as PackedScene
	else:
		push_warning("AttackBehaviorRanged: projectile scene not found: %s" % path)


func on_attack_enter() -> void:
	_telegraph_timer = 0.0
	_pending_fire = true


func on_attack_exit() -> void:
	_pending_fire = false


func on_state_update(delta: float) -> void:
	if not _pending_fire:
		return
	_telegraph_timer += delta
	if _telegraph_timer < _stats_data.projectile_telegraph:
		return
	_pending_fire = false
	_fire()


func _fire() -> void:
	if _projectile_scene == null:
		return
	var direction: Vector2 = _resolve_direction()
	var projectile: Node = _projectile_scene.instantiate()
	projectile.global_position = _enemy_root.global_position + Vector2(0.0, -14.0)
	var damage: float = _enemy_root.stats_comp.get_attack()
	if projectile.has_method("setup"):
		projectile.setup(
			direction, _stats_data.projectile_speed, damage, _stats_data.projectile_lifetime
		)
	_enemy_root.get_parent().add_child(projectile)
	EventBus.enemy_projectile_fired.emit(_enemy_root.global_position, direction)


func _resolve_direction() -> Vector2:
	var target: Node2D = _enemy_root.state_machine.get_target()
	if is_instance_valid(target):
		var diff: Vector2 = target.global_position - _enemy_root.global_position
		if diff.length() > 0.1:
			return diff.normalized()
	var facing: float = _enemy_root.movement_comp.facing
	if facing == 0.0:
		facing = 1.0
	return Vector2(facing, 0.0)
