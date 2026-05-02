extends Node2D

## 3-2 '무너진 회랑' — NONE 잠금. 16시 황혼.
## 적 3 (zone3 — withered_sentinel + toppled_statue + ash_lily).
## 옛 회랑 잔해 시각 단서 (인공물 첫 등장 강조). 선조 기록 단편 2 NPC 위치 후보 (Step 7+).
## REC-MECH-001 Echo Nail 시범 부착 (Step 5) — 적/오브젝트/residue 잔상 3종.

const STAGE_ID := "stage_3_2"
const SPAWN_POSITION := Vector2(80, 320)
const BG_PATH := "res://assets/backgrounds/bg_stage_3_2.png"
const GROUND_TILE_PATH := "res://assets/tiles/tile_ground_zone3.png"
const PLATFORM_TILE_PATH := "res://assets/tiles/tile_platform_zone3.png"

const ECHO_ARCHER_PATH := "res://data/echo/echo_zone3_silent_archer.tres"
const ECHO_PEDESTAL_PATH := "res://data/echo/echo_zone3_ruined_pedestal.tres"
const ECHO_VILLAGER_PATH := "res://data/echo/echo_zone3_forgotten_villager.tres"


func _ready() -> void:
	EventBus.stage_enemies_sync_requested.connect(_on_enemies_sync)
	EventBus.stage_entered.emit(STAGE_ID)
	EventBus.spawn_point_set.emit(SPAWN_POSITION)
	StageCamera.apply(STAGE_ID)
	_try_apply_background()
	_try_apply_ground()
	_try_apply_platforms()
	_spawn_echo_targets()


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


func _spawn_echo_targets() -> void:
	# REC-MECH-001 Step 5 placeholder — 3종 시범 부착.
	# 위치는 stage_3_2 좌표계 (Player spawn=(80,320), 바닥 y≈328) 기반 hardcoded.
	# 추후 stage_3_2.tscn에서 노드로 정식 배치하거나, 시체/잔재/오브젝트 entity에
	# EchoTarget을 자식으로 부착하는 패턴으로 이전 가능.
	_spawn_echo_target(Vector2(240, 320), ECHO_ARCHER_PATH, "EchoArcher")
	_spawn_echo_target(Vector2(380, 320), ECHO_PEDESTAL_PATH, "EchoPedestal")
	_spawn_echo_target(Vector2(520, 320), ECHO_VILLAGER_PATH, "EchoVillager")


func _spawn_echo_target(pos: Vector2, data_path: String, target_name: String) -> void:
	if not ResourceLoader.exists(data_path):
		return
	var data: EchoData = load(data_path) as EchoData
	if data == null:
		return
	var target: EchoTarget = EchoTarget.new()
	target.name = target_name
	target.echo_data = data
	target.position = pos
	add_child(target)


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
