extends Node2D

## 거점 씬 공통 베이스.
## - stage_entered + spawn_point_set 방송
## - 플레이어 카메라를 StageData.room_size에 맞춰 고정
## - BG/Ground 텍스처 fallback 적용 (리소스 있을 때만)
##
## 진입 시 완전 회복 + 세이브는 StageSystem이 is_checkpoint 플래그로 자동 처리한다.
## 파생 스크립트가 필요 없으면 씬 루트에 이 스크립트를 직접 붙여도 된다.

const GROUND_SIZE: Vector2 = Vector2(640, 64)
const GROUND_POSITION: Vector2 = Vector2(0, 328)
const PLAYER_SCENE_PATH := "res://src/entities/player/Player.tscn"

@export var stage_id: String = ""
@export var spawn_point: Vector2 = Vector2(320, 320)
@export var bg_path: String = ""
@export var ground_tile_path: String = ""


func _ready() -> void:
	if stage_id.is_empty():
		push_error("CheckpointBase: stage_id가 비어 있다. 씬 인스펙터에서 설정.")
		return
	_ensure_player_spawned()
	EventBus.stage_entered.emit(stage_id)
	EventBus.spawn_point_set.emit(spawn_point)
	StageCamera.apply(stage_id)
	_try_apply_background()
	_try_apply_ground()


## 씬 트리에 Player가 없으면(타이틀→체크포인트 첫 진입) 생성해 배치한다.
func _ensure_player_spawned() -> void:
	if get_tree().get_first_node_in_group("player") != null:
		return
	var player_scene: PackedScene = load(PLAYER_SCENE_PATH) as PackedScene
	if not player_scene:
		push_warning("CheckpointBase: Player.tscn 로드 실패")
		return
	var player: CharacterBody2D = player_scene.instantiate() as CharacterBody2D
	player.global_position = spawn_point
	add_child(player)


func _try_apply_background() -> void:
	if bg_path.is_empty() or not ResourceLoader.exists(bg_path):
		return
	var tex: Texture2D = load(bg_path)
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
	if ground_tile_path.is_empty() or not ResourceLoader.exists(ground_tile_path):
		return
	var tex: Texture2D = load(ground_tile_path)
	if not tex:
		return
	var tex_rect := TextureRect.new()
	tex_rect.texture = tex
	tex_rect.stretch_mode = TextureRect.STRETCH_TILE
	tex_rect.size = GROUND_SIZE
	tex_rect.position = GROUND_POSITION
	add_child(tex_rect)
	var floor_sprite := get_node_or_null("Floor/FloorSprite")
	if floor_sprite:
		floor_sprite.visible = false
