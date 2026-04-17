extends Area2D

## 상점 NPC 엔티티.
## 거점에 배치. 플레이어 접근 + interact 키로 상점 열기.

const SIZE := Vector2(24, 32)

@export var shop_id: String = "default"
@export var shop_items: Array[String] = []

var _player_in_range: bool = false
var _is_shop_open: bool = false


func _ready() -> void:
	add_to_group("shop_keepers")
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	EventBus.shop_closed.connect(func(): _is_shop_open = false)
	_setup_visual()
	_setup_collision()


func _process(_delta: float) -> void:
	if not _player_in_range or _is_shop_open:
		return
	if Input.is_action_just_pressed("interact"):
		_is_shop_open = true
		EventBus.shop_opened.emit(shop_id)


func get_shop_items() -> Array[String]:
	return shop_items


func _setup_visual() -> void:
	var rect := ColorRect.new()
	rect.name = "Visual"
	rect.size = SIZE
	rect.position = -SIZE / 2
	rect.color = Color(0.2, 0.7, 0.3, 0.9)
	add_child(rect)

	var label := Label.new()
	label.name = "ShopLabel"
	label.text = "상점"
	label.add_theme_font_size_override("font_size", 7)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = SIZE
	label.position = -SIZE / 2
	add_child(label)

	var hint := Label.new()
	hint.name = "HintLabel"
	hint.text = "[F]"
	hint.add_theme_font_size_override("font_size", 6)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(-SIZE.x / 2, -SIZE.y / 2 - 10)
	hint.size = Vector2(SIZE.x, 10)
	hint.visible = false
	add_child(hint)


func _setup_collision() -> void:
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = SIZE * 2
	shape_node.shape = shape
	add_child(shape_node)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		$HintLabel.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		$HintLabel.visible = false
