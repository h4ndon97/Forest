extends Node2D

## 아트 리소스가 있으면 로드하여 적용, 없으면 ColorRect 플레이스홀더 유지.

const BG_PATH := "res://assets/backgrounds/bg_test_stage.png"
const GROUND_TILE_PATH := "res://assets/tiles/tile_ground_test.png"
const PLATFORM_TILE_PATH := "res://assets/tiles/tile_platform_test.png"


func _ready() -> void:
	EventBus.stage_enemies_sync_requested.connect(_on_enemies_sync)
	EventBus.stage_entered.emit("test_stage")
	EventBus.spawn_point_set.emit(Vector2(128, 320))
	StageCamera.apply("test_stage")
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
	# 바닥: 640px 너비를 64x64 타일로 반복. 콜리전 상단(y=328)에 맞춤
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
	for platform_name in ["Platform1", "Platform2", "Platform3"]:
		var platform: Node2D = get_node(platform_name)
		var sprite := Sprite2D.new()
		sprite.texture = tex
		# 플랫폼 스프라이트 상단을 콜리전 상단에 맞춤 (콜리전 높이 16, 타일 높이 64)
		sprite.offset.y = 24
		platform.add_child(sprite)
		platform.get_node("PlatformSprite").visible = false


func _on_enemies_sync(stage_id: String, killed_names: Array) -> void:
	if stage_id != "test_stage":
		return
	var enemies_node := get_node_or_null("Enemies")
	if not enemies_node:
		return
	for enemy_name in killed_names:
		var enemy := enemies_node.get_node_or_null(String(enemy_name))
		if enemy:
			enemy.queue_free()
