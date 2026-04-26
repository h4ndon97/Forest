extends Node2D

## 3-3 '옛 빛탑' — LIGHT 잠금(등불 ON 강제), 22시 밤.
## 적 4 (zone3 4종 — withered_sentinel + toppled_statue + ash_lily + old_sentinel).
## Lens + LightSensor(sensor_3_4_arch) 배치 — 회전으로 다음 3-4 잠금 활성화.

const STAGE_ID := "stage_3_3"
const SPAWN_POSITION := Vector2(80, 320)
const BG_PATH := "res://assets/backgrounds/bg_stage_3_3.png"
const GROUND_TILE_PATH := "res://assets/tiles/tile_ground_zone3.png"
const PLATFORM_TILE_PATH := "res://assets/tiles/tile_platform_zone3.png"


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
