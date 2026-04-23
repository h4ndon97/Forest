extends Node2D

## 두 번째 테스트 스테이지. 포탈 전환 테스트용.
## 아트 리소스가 있으면 로드하여 적용, 없으면 ColorRect 플레이스홀더 유지.


func _ready() -> void:
	EventBus.stage_enemies_sync_requested.connect(_on_enemies_sync)
	EventBus.stage_entered.emit("test_stage_2")
	EventBus.spawn_point_set.emit(Vector2(48, 320))
	StageCamera.apply("test_stage_2")


func _on_enemies_sync(stage_id: String, killed_names: Array) -> void:
	if stage_id != "test_stage_2":
		return
	var enemies_node := get_node_or_null("Enemies")
	if not enemies_node:
		return
	for enemy_name in killed_names:
		var enemy := enemies_node.get_node_or_null(String(enemy_name))
		if enemy:
			enemy.queue_free()
