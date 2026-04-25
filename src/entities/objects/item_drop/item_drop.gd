extends Area2D

## 드롭/배치 아이템 엔티티.
## 플레이어 접촉 + interact 키로 획득.
## 맵 고정 배치 또는 적 드롭으로 생성된다.

const ItemDataClass = preload("res://data/items/item_data.gd")
const SIZE := Vector2(12, 12)
const COLOR_COMMON := Color(0.7, 0.7, 0.7, 0.9)
const COLOR_RARE := Color(0.3, 0.5, 0.9, 0.9)
const COLOR_UNIQUE := Color(0.9, 0.7, 0.2, 0.9)

@export var item_id: String = ""
@export var one_time_only: bool = true

var _player_in_range: bool = false
var _collected: bool = false


func _ready() -> void:
	collision_layer = 0
	# Player CharacterBody2D는 collision_layer = 2 (Player.tscn).
	collision_mask = 2
	# 적 사망 콜백 도중 spawn되면 physics query flushing 중이라 즉시 변경 불가 → deferred.
	set_deferred("monitoring", true)
	set_deferred("monitorable", false)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_setup_visual()
	_setup_collision.call_deferred()
	# spawn 시 이미 player가 area 안에 있으면 body_entered가 안 뜸 — 직접 검사.
	_check_initial_overlap.call_deferred()


## 적이 player 가까이에서 죽으면 ItemDrop이 player 위에 spawn될 수 있다.
## body_entered는 진입 시에만 emit하므로 이미 안에 있는 body는 직접 검사해야 한다.
func _check_initial_overlap() -> void:
	# collision shape + monitoring 적용 대기 (set_deferred / call_deferred로 등록됨).
	await get_tree().physics_frame
	await get_tree().physics_frame
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			_player_in_range = true
			return


func _process(_delta: float) -> void:
	if _collected or not _player_in_range:
		return
	if Input.is_action_just_pressed("interact"):
		_pickup()


func setup_drop(drop_item_id: String, drop_position: Vector2) -> void:
	item_id = drop_item_id
	global_position = drop_position


func _pickup() -> void:
	if _collected:
		return
	_collected = true
	var success: bool = InventorySystem.acquire_item(item_id)
	if success:
		queue_free()
	else:
		_collected = false


func _setup_visual() -> void:
	var rect := ColorRect.new()
	rect.name = "Visual"
	rect.size = SIZE
	rect.position = -SIZE / 2
	rect.color = _get_rarity_color()
	add_child(rect)

	if item_id != "":
		var label := Label.new()
		label.name = "ItemLabel"
		label.text = "!"
		label.add_theme_font_size_override("font_size", 8)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size = SIZE
		label.position = -SIZE / 2
		add_child(label)


func _setup_collision() -> void:
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	# 픽업 영역을 시각 박스보다 넉넉히 — 옆에 살짝 떨어져도 감지.
	shape.size = SIZE * 3.0
	shape_node.shape = shape
	add_child(shape_node)


func _get_rarity_color() -> Color:
	var data: Resource = InventorySystem.get_item_data(item_id)
	if data == null:
		return COLOR_COMMON
	match data.rarity:
		ItemDataClass.ItemRarity.RARE:
			return COLOR_RARE
		ItemDataClass.ItemRarity.UNIQUE:
			return COLOR_UNIQUE
	return COLOR_COMMON


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
