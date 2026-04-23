extends Node2D

## 다섯 번째 테스트 스테이지. 심야(03시), LIGHT 잠금, 적 1.
## 가변 룸 데모 — 1280x360 (가로 2화면). 카메라 스크롤 동작 확인용.
## room_size는 test_stage_5.tres에서, 바닥 타일 폭은 ARENA_WIDTH 상수와 동기 유지.

const ARENA_WIDTH := 1280
const BG_PATH := "res://assets/backgrounds/bg_test_stage_5.png"
const GROUND_TILE_PATH := "res://assets/tiles/tile_ground_test.png"


func _ready() -> void:
	EventBus.stage_enemies_sync_requested.connect(_on_enemies_sync)
	EventBus.stage_entered.emit("test_stage_5")
	EventBus.spawn_point_set.emit(Vector2(560, 320))
	StageCamera.apply("test_stage_5")
	_try_apply_background()
	_try_apply_ground()


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
	$BG.visible = false


func _try_apply_ground() -> void:
	if not ResourceLoader.exists(GROUND_TILE_PATH):
		return
	var tex: Texture2D = load(GROUND_TILE_PATH)
	if not tex:
		return
	var tex_rect := TextureRect.new()
	tex_rect.texture = tex
	tex_rect.stretch_mode = TextureRect.STRETCH_TILE
	tex_rect.size = Vector2(ARENA_WIDTH, 64)
	tex_rect.position = Vector2(0, 328)
	add_child(tex_rect)
	$Floor/FloorSprite.visible = false


func _on_enemies_sync(stage_id: String, killed_names: Array) -> void:
	if stage_id != "test_stage_5":
		return
	var enemies_node := get_node_or_null("Enemies")
	if not enemies_node:
		return
	for enemy_name in killed_names:
		var enemy := enemies_node.get_node_or_null(String(enemy_name))
		if enemy:
			enemy.queue_free()
