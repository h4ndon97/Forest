class_name BaseNpc
extends Area2D

## NPC 공통 베이스.
## 플레이어 접근 + interact 키 감지 → npc_interacted() 가상 메서드 호출.
## 파생 클래스가 npc_interacted()를 override해 반응을 정의한다.

const DEFAULT_SIZE: Vector2 = Vector2(24, 32)

@export var npc_id: String = ""
@export var visual_color: Color = Color(0.5, 0.5, 0.5, 0.9)
@export var visual_label: String = ""
@export var visual_size: Vector2 = DEFAULT_SIZE

var _player_in_range: bool = false
var _interaction_blocked: bool = false


func _ready() -> void:
	add_to_group("npcs")
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_setup_visual()
	_setup_collision()


func _process(_delta: float) -> void:
	if _interaction_blocked or not _player_in_range:
		return
	if Input.is_action_just_pressed("interact"):
		npc_interacted()


## 파생 클래스가 override. 기본은 no-op.
func npc_interacted() -> void:
	pass


## 대화/UI 진행 중 중복 상호작용 방지용 플래그.
func set_interaction_blocked(blocked: bool) -> void:
	_interaction_blocked = blocked
	var hint := get_node_or_null("HintLabel") as Label
	if hint:
		hint.visible = _player_in_range and not blocked


func _setup_visual() -> void:
	if has_node("Visual"):
		return
	var rect := ColorRect.new()
	rect.name = "Visual"
	rect.size = visual_size
	rect.position = -visual_size / 2
	rect.color = visual_color
	add_child(rect)

	if not visual_label.is_empty():
		var label := Label.new()
		label.name = "NameLabel"
		label.text = visual_label
		label.add_theme_font_size_override("font_size", 7)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size = visual_size
		label.position = -visual_size / 2
		add_child(label)

	var hint := Label.new()
	hint.name = "HintLabel"
	hint.text = "[F]"
	hint.add_theme_font_size_override("font_size", 6)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(-visual_size.x / 2, -visual_size.y / 2 - 10)
	hint.size = Vector2(visual_size.x, 10)
	hint.visible = false
	add_child(hint)


func _setup_collision() -> void:
	if has_node("CollisionShape2D"):
		return
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = visual_size * 2
	shape_node.shape = shape
	add_child(shape_node)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		var hint := get_node_or_null("HintLabel") as Label
		if hint:
			hint.visible = not _interaction_blocked


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		var hint := get_node_or_null("HintLabel") as Label
		if hint:
			hint.visible = false
