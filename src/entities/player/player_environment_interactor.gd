extends Area2D

## 플레이어 주변 환경 오브젝트 감지 + 상호작용 키 처리.
## Area2D로 환경 오브젝트 진입/이탈을 수신하고, 가장 가까운 오브젝트를 선택한다.
## 키 입력 시점에 해당 오브젝트의 interact()를 호출한다.

var _nearby: Array = []  # Array[Node2D] - "environment_objects" 그룹
var _current_target: Node2D = null


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(_delta: float) -> void:
	_refresh_target()
	if Input.is_action_just_pressed("interact_environment"):
		if _current_target and _current_target.has_method("interact"):
			_current_target.interact()


# --- 내부 ---

func _refresh_target() -> void:
	var nearest: Node2D = null
	var min_dist: float = INF
	var origin: Vector2 = global_position
	for obj in _nearby:
		if not is_instance_valid(obj):
			continue
		var d: float = origin.distance_squared_to(obj.global_position)
		if d < min_dist:
			min_dist = d
			nearest = obj
	if nearest == _current_target:
		return
	if _current_target and _current_target.has_method("set_highlight"):
		_current_target.set_highlight(false)
	_current_target = nearest
	if _current_target and _current_target.has_method("set_highlight"):
		_current_target.set_highlight(true)


func _register(node: Node) -> void:
	if not (node is Node2D):
		return
	if not node.is_in_group("environment_objects"):
		return
	if _nearby.has(node):
		return
	_nearby.append(node)
	if node.has_method("notify_player_nearby"):
		node.notify_player_nearby(true)


func _unregister(node: Node) -> void:
	if not _nearby.has(node):
		return
	_nearby.erase(node)
	if node.has_method("notify_player_nearby"):
		node.notify_player_nearby(false)
	if node == _current_target:
		if _current_target and _current_target.has_method("set_highlight"):
			_current_target.set_highlight(false)
		_current_target = null


func _on_area_entered(area: Area2D) -> void:
	_register(area.get_parent())


func _on_area_exited(area: Area2D) -> void:
	_unregister(area.get_parent())


func _on_body_entered(body: Node) -> void:
	_register(body)


func _on_body_exited(body: Node) -> void:
	_unregister(body)
