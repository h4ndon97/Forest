extends Area2D

## 차폐물 투영 그림자 영역.
## 영역 진입/이탈 적을 부모(Cover)에 위임한다.

signal enemy_entered(enemy: Node)
signal enemy_exited(enemy: Node)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		enemy_entered.emit(body)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		enemy_exited.emit(body)
