extends "res://src/entities/enemies/base/behaviors/death_behavior_base.gd"

## 꽃 분열 행동. 사망 시 spore_count만큼 분열체를 spore_spread_radius 반경 내에 스폰.
## 분열체 자신은 is_spore=true로 재분열 차단 (base_enemy._inject_behaviors에서 강제 none).

const BASE_ENEMY_SCENE := "res://src/entities/enemies/base/BaseEnemy.tscn"


func on_death() -> void:
	if _stats_data == null:
		return
	var spore_path: String = _stats_data.spore_stats_path
	if spore_path == "" or not ResourceLoader.exists(spore_path):
		return
	var spore_stats: EnemyStatsData = load(spore_path) as EnemyStatsData
	if spore_stats == null:
		return
	if not ResourceLoader.exists(BASE_ENEMY_SCENE):
		return
	var base_scene: PackedScene = load(BASE_ENEMY_SCENE) as PackedScene
	var parent: Node = _enemy_root.get_parent()
	if parent == null:
		return

	var count: int = _stats_data.spore_count
	var radius: float = _stats_data.spore_spread_radius
	var origin: Vector2 = _enemy_root.global_position
	for i in count:
		var spore: Node = base_scene.instantiate()
		spore.stats_data = spore_stats
		spore.global_position = origin + _random_offset(radius)
		parent.add_child(spore)

	EventBus.enemy_split_spawned.emit(origin, count)


func _random_offset(radius: float) -> Vector2:
	var angle: float = randf() * TAU
	var dist: float = sqrt(randf()) * radius
	return Vector2(cos(angle) * dist, -abs(sin(angle) * dist * 0.3))
