extends Node

## 적 공격 행동 베이스 인터페이스.
## 서브클래스는 on_attack_enter / on_attack_exit / on_state_update를 구현한다.
## BaseEnemy가 ATTACK 상태 진입/종료 시 이 훅을 호출한다.
## Phase 4-0 #1 Step 3: 자체 Hitbox 의존 제거 — CombatSystem.request_attack 위임 패턴.

var _enemy_root: Node2D
var _stats_data: EnemyStatsData


func setup(enemy_root: Node2D, stats_data: EnemyStatsData) -> void:
	_enemy_root = enemy_root
	_stats_data = stats_data
	_on_setup()


## ATTACK 상태 진입 시 호출
func on_attack_enter() -> void:
	pass


## ATTACK 상태 종료 시 호출 (다른 상태로 전이)
func on_attack_exit() -> void:
	pass


## _physics_process 중 ATTACK 상태에서 매 프레임 호출
func on_state_update(_delta: float) -> void:
	pass


# --- 서브클래스 훅 ---


func _on_setup() -> void:
	pass
