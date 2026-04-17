extends "res://src/entities/enemies/base/behaviors/death_behavior_base.gd"

## 꽃 분열 행동. 사망 시 spore_count만큼 분열체를 spore_spread_radius 반경 내에 스폰.
## 분열체 자신은 is_spore=true로 재분열 차단 (base_enemy._inject_behaviors에서 강제 none).

const SplitSpawnerScript = preload("res://src/entities/enemies/base/behaviors/split_spawner.gd")


func on_death() -> void:
	if _stats_data == null:
		return
	var spawned: Array = SplitSpawnerScript.spawn_spores(
			_enemy_root,
			_stats_data.spore_stats_path,
			"",
			_stats_data.spore_count,
			_stats_data.spore_spread_radius)
	if spawned.size() > 0:
		EventBus.enemy_split_spawned.emit(_enemy_root.global_position, spawned.size())
