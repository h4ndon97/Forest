extends Node2D

## 2-4 '거울 늪' — ReflectiveFloor 본격, ENVIRONMENT 잠금(stage_2_3 sensor 활성화 필요).
## 14시(낮), 적 4 (weeping_willow + miasma_lily + drowned_pillar + marsh_tendril).
## 환경: ReflectiveFloor 2개 — 빛 반사 학습 본격.

const STAGE_ID := "stage_2_4"
const SPAWN_POSITION := Vector2(80, 320)
const BG_PATH := "res://assets/backgrounds/bg_stage_2_4.png"
const GROUND_TILE_PATH := "res://assets/tiles/tile_ground_zone2.png"
const PLATFORM_TILE_PATH := "res://assets/tiles/tile_platform_zone2.png"


func _ready() -> void:
	EventBus.stage_enemies_sync_requested.connect(_on_enemies_sync)
	EventBus.stage_entered.emit(STAGE_ID)
	EventBus.spawn_point_set.emit(SPAWN_POSITION)
	StageCamera.apply(STAGE_ID)
	_try_apply_background()
	_try_apply_ground()
	_try_apply_platforms()


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
	tex_rect.size = Vector2(640, 64)
	tex_rect.position = Vector2(0, 328)
	add_child(tex_rect)
	$Floor/FloorSprite.visible = false


func _try_apply_platforms() -> void:
	if not ResourceLoader.exists(PLATFORM_TILE_PATH):
		return
	var tex: Texture2D = load(PLATFORM_TILE_PATH)
	if not tex:
		return
	for platform_name in ["Platform1", "Platform2"]:
		var platform: Node2D = get_node_or_null(platform_name)
		if not platform:
			continue
		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.offset.y = 24
		platform.add_child(sprite)
		platform.get_node("PlatformSprite").visible = false


func _on_enemies_sync(stage_id: String, killed_names: Array) -> void:
	if stage_id != STAGE_ID:
		return
	var enemies_node := get_node_or_null("Enemies")
	if not enemies_node:
		return
	for enemy_name in killed_names:
		var enemy := enemies_node.get_node_or_null(String(enemy_name))
		if enemy:
			enemy.queue_free()
