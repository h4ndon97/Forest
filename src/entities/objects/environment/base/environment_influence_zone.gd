extends Area2D

## 환경 오브젝트의 영향 구역 Area2D.
## 구역 내 ShadowCaster / 적을 추적하고, 베이스 오브젝트가 조회할 수 있게 한다.

var _tracked_enemies: Array = []  # Array[Node] - "enemies" 그룹 Body


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## 현재 구역 내 적 목록. 재분열 가드(is_spore/is_revived)는 호출자 책임.
func get_tracked_enemies() -> Array:
	var alive: Array = []
	for e in _tracked_enemies:
		if is_instance_valid(e):
			alive.append(e)
	return alive


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		if not _tracked_enemies.has(body):
			_tracked_enemies.append(body)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		_tracked_enemies.erase(body)
