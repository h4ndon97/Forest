extends Node

## 적 사망 행동 베이스 인터페이스.
## 서브클래스는 on_death()를 구현하여 사망 시 후처리(분열 등)를 수행한다.

var _enemy_root: Node2D
var _stats_data: EnemyStatsData


func setup(enemy_root: Node2D, stats_data: EnemyStatsData) -> void:
	_enemy_root = enemy_root
	_stats_data = stats_data


## 사망 시 호출. queue_free 직전에 실행된다.
func on_death() -> void:
	pass
