extends RefCounted

## 분열체 스폰 pure helper.
## death_behavior_split (사망 시 분열) / mirror interaction (거울 분열)에서 공용 사용.
## 원본 적은 이 함수에서 제거하지 않는다 — 호출자 책임.

const BASE_ENEMY_SCENE := "res://src/entities/enemies/base/BaseEnemy.tscn"


## 주어진 스폰 파라미터로 분열체를 count만큼 spawn한다.
## spore_stats_path가 비면 fallback_spore_path 사용. 둘 다 없으면 0 반환.
## 반환: 생성된 분열체의 instance_id 배열.
static func spawn_spores(
	source_enemy: Node2D,
	spore_stats_path: String,
	fallback_spore_path: String,
	count: int,
	spread_radius: float
) -> Array:
	var result: Array = []
	if source_enemy == null:
		return result

	var path: String = spore_stats_path
	if path == "" or not ResourceLoader.exists(path):
		path = fallback_spore_path
	if path == "" or not ResourceLoader.exists(path):
		return result

	var spore_stats: EnemyStatsData = load(path) as EnemyStatsData
	if spore_stats == null:
		return result

	if not ResourceLoader.exists(BASE_ENEMY_SCENE):
		return result
	var base_scene: PackedScene = load(BASE_ENEMY_SCENE) as PackedScene

	var parent: Node = source_enemy.get_parent()
	if parent == null:
		return result

	var origin: Vector2 = source_enemy.global_position
	for i in count:
		var spore: Node = base_scene.instantiate()
		spore.stats_data = spore_stats
		spore.global_position = origin + _random_offset(spread_radius)
		# 적 사망 콜백 도중이면 physics query flushing 중 — deferred로 트리 삽입.
		parent.add_child.call_deferred(spore)
		result.append(spore.get_instance_id())

	return result


static func _random_offset(radius: float) -> Vector2:
	var angle: float = randf() * TAU
	var dist: float = sqrt(randf()) * radius
	return Vector2(cos(angle) * dist, -abs(sin(angle) * dist * 0.3))
