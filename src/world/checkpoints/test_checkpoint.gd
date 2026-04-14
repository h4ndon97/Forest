extends Node2D

## 테스트 거점 (간이형). 안전 구역 — 적 없음, 시간 정지 고정.
## 진입 시 완전 회복 + 세이브가 StageSystem에 의해 자동 처리된다.

const BG_PATH := "res://assets/backgrounds/bg_test_checkpoint.png"
const GROUND_TILE_PATH := "res://assets/tiles/tile_ground_test.png"


func _ready() -> void:
	EventBus.stage_entered.emit("test_checkpoint")
	EventBus.spawn_point_set.emit(Vector2(320, 320))
	_setup_camera_limits()
	_try_apply_background()
	_try_apply_ground()


func _setup_camera_limits() -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not player:
		return
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if not camera:
		return
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 640
	camera.limit_bottom = 360


func _try_apply_background() -> void:
	if not ResourceLoader.exists(BG_PATH):
		return
	var tex: Texture2D = load(BG_PATH)
	if not tex:
		return
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.z_index = -10
	sprite.centered = false
	add_child(sprite)
	var bg := get_node_or_null("BG")
	if bg:
		bg.visible = false


func _try_apply_ground() -> void:
	if not ResourceLoader.exists(GROUND_TILE_PATH):
		return
	var tex: Texture2D = load(GROUND_TILE_PATH)
	if not tex:
		return
	var tex_rect := TextureRect.new()
	tex_rect.texture = tex
	tex_rect.stretch_mode = TextureRect.STRETCH_TILE
	tex_rect.size = Vector2(640, 64)
	tex_rect.position = Vector2(0, 328)
	add_child(tex_rect)
	var floor_sprite := get_node_or_null("Floor/FloorSprite")
	if floor_sprite:
		floor_sprite.visible = false
