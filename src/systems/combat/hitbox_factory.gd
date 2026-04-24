class_name HitboxFactory
extends RefCounted

## AttackSpec → Area2D 런타임 생성 전담.
## CombatSystem.request_attack()이 내부적으로 호출한다. 외부 직접 호출 금지.
## Step 1에서는 생성 로직만 구현. 풀링 도입 여부는 §7 미결(성능 측정 후 #6으로 이전 가능).

const _SHAPE_RECT := "rect"
const _SHAPE_CIRCLE := "circle"

const _GROUP_PLAYER_ATTACK := "player_attack"
const _GROUP_ENEMY_ATTACK := "enemy_attack"
const _GROUP_BOSS_ATTACK := "boss_attack"

const _META_ATTACK_SPEC := "attack_spec"


## spec의 형상·레이어·그룹을 반영한 Area2D를 생성해 spec.attacker의 자식으로 부착한다.
## 반환된 Area2D는 monitoring=false 상태 — attack_requests가 telegraph/active 전이 시 ON.
static func create_attack_hitbox(spec: AttackSpec) -> Area2D:
	if spec == null:
		push_warning("HitboxFactory.create_attack_hitbox: spec is null")
		return null
	if spec.attacker == null or not is_instance_valid(spec.attacker):
		push_warning("HitboxFactory.create_attack_hitbox: spec.attacker invalid")
		return null

	var area := Area2D.new()
	area.name = "CombatHitbox"
	area.collision_layer = _resolve_collision_layer(spec.source_group)
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = false
	area.add_to_group(spec.source_group)
	area.set_meta(_META_ATTACK_SPEC, spec)

	var shape_node := CollisionShape2D.new()
	_apply_shape(shape_node, spec)
	area.add_child(shape_node)

	spec.attacker.add_child(area)
	return area


## 런타임에 spec의 형상·위치가 변하면 (예: 플레이어 방향 전환) 재적용.
## Step 2 이후 player_combo가 facing 변경 시 호출할 수 있다.
static func apply_shape(area: Area2D, spec: AttackSpec) -> void:
	if area == null or not is_instance_valid(area):
		return
	var shape_node: CollisionShape2D = _find_shape_node(area)
	if shape_node == null:
		return
	_apply_shape(shape_node, spec)


static func _apply_shape(shape_node: CollisionShape2D, spec: AttackSpec) -> void:
	match spec.shape_type:
		_SHAPE_CIRCLE:
			var circle: CircleShape2D = shape_node.shape as CircleShape2D
			if circle == null:
				circle = CircleShape2D.new()
				shape_node.shape = circle
			circle.radius = spec.circle_radius
			shape_node.position = Vector2.ZERO
		_:
			var rect: RectangleShape2D = shape_node.shape as RectangleShape2D
			if rect == null:
				rect = RectangleShape2D.new()
				shape_node.shape = rect
			rect.size = spec.hitbox_size
			shape_node.position = spec.hitbox_offset


static func _find_shape_node(area: Area2D) -> CollisionShape2D:
	for child in area.get_children():
		if child is CollisionShape2D:
			return child
	return null


static func _resolve_collision_layer(source_group: String) -> int:
	match source_group:
		_GROUP_PLAYER_ATTACK:
			return Constants.LAYER_PLAYER_ATTACK
		_GROUP_ENEMY_ATTACK, _GROUP_BOSS_ATTACK:
			return Constants.LAYER_ENEMY_ATTACK
		_:
			push_warning(
				(
					"HitboxFactory: unknown source_group '%s', defaulting to PLAYER_ATTACK"
					% source_group
				)
			)
			return Constants.LAYER_PLAYER_ATTACK
