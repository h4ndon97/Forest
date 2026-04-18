extends Area2D

## 월드맵 포탈. 거점 씬에 배치되며, 상호작용 키로 월드맵 UI를 연다.
## 플레이어가 영역 안에서 interact 키를 누르면 월드맵을 개방한다.

var _player_in_area: bool = false
var _cooldown: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	EventBus.world_map_closed.connect(_on_world_map_closed)


func _process(_delta: float) -> void:
	if not _player_in_area or _cooldown:
		return
	if Input.is_action_just_pressed("interact"):
		EventBus.world_map_opened.emit()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_area = true
		_notify_visual(true)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_area = false
		_notify_visual(false)


func _notify_visual(nearby: bool) -> void:
	var visual := get_node_or_null("PortalVisual")
	if visual and visual.has_method("set_player_nearby"):
		visual.set_player_nearby(nearby)


func _on_world_map_closed() -> void:
	_cooldown = true
	await get_tree().process_frame
	_cooldown = false
