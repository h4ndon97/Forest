extends "res://src/entities/enemies/base/base_enemy.gd"

## 땅거미 전투 엔티티.
## BaseEnemy를 확장하여 처치 시 DuskSpiderSystem에 통보한다.
## 잔류를 남기지 않으며, 더 큰 fallback 비주얼을 사용한다.

const SPIDER_FALLBACK_SIZE := Vector2(44, 48)
const SPIDER_COLOR := Color(0.5, 0.1, 0.7, 0.95)

var spider_id: int = -1


func _ready() -> void:
	super._ready()
	_override_fallback_visual()


func _on_died() -> void:
	state_machine.on_death()
	set_physics_process(false)
	hitbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitoring", false)
	EnemySystem.on_enemy_died(enemy_id, global_position)
	if spider_id >= 0:
		EventBus.dusk_spider_defeated.emit(spider_id)
	queue_free()


func _override_fallback_visual() -> void:
	if not animation_comp:
		return
	var fallback: ColorRect = animation_comp.get("_fallback")
	if fallback:
		fallback.size = SPIDER_FALLBACK_SIZE
		fallback.position = Vector2(-SPIDER_FALLBACK_SIZE.x * 0.5, -SPIDER_FALLBACK_SIZE.y)
		fallback.color = SPIDER_COLOR
