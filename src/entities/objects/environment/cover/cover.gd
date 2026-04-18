extends "res://src/entities/objects/environment/base/environment_object.gd"

## 차폐물(Cover) 환경 오브젝트.
## STOPPED 중 interact()로 플레이어 반대 방향으로 1스텝 이동 (밀기).
## 영역 내 적의 그림자 강도를 block_intensity로 상시 override (CREATE 모드).
## 투영 영역은 빛 반대 방향(낮: 태양 / 밤: 등불)으로 갱신된다.

@export var cover_data: CoverData

var _initial_x: float = 0.0
var _step_index: int = 0
var _affected_enemies: Dictionary = {}

@onready var _body_visual: ColorRect = $Body/BodyVisual
@onready var _body_collision: CollisionShape2D = $Body/CollisionShape2D
@onready var _projection_zone: Area2D = $ShadowProjectionZone
@onready var _projection_collision: CollisionShape2D = $ShadowProjectionZone/CollisionShape2D
@onready var _projection_visual: ColorRect = $ShadowProjectionZone/ProjectionVisual
@onready var _player_detect_collision: CollisionShape2D = (
		$ShadowProjectionZone/PlayerShadowDetectZone/CollisionShape2D)
@onready var _highlight_node_local: Node2D = $Highlight
@onready var _prompt_node_local: Node2D = $Prompt


func _ready() -> void:
	# 베이스가 export 참조 대신 자식 노드를 직접 바인딩
	highlight_node = _highlight_node_local
	prompt_node = _prompt_node_local
	super._ready()
	if cover_data == null:
		push_warning("Cover: cover_data 미설정")
		return
	data = cover_data
	_initial_x = position.x

	_setup_body_visual()
	_setup_projection_visual()
	_update_projection_transform()

	_projection_zone.enemy_entered.connect(_on_enemy_entered)
	_projection_zone.enemy_exited.connect(_on_enemy_exited)

	EventBus.shadow_params_changed.connect(_on_shadow_params_changed)


func _process(_delta: float) -> void:
	if cover_data == null:
		return
	# 매 프레임 override 재적용 (EnemySystem 브로드캐스트가 덮어쓰는 것을 무효화)
	if not _affected_enemies.is_empty():
		_reapply_override_to_all()


func _on_interact() -> void:
	if cover_data == null:
		return
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	# 플레이어 반대 방향으로 1스텝 이동
	var push_dir: float = 1.0 if player.global_position.x < global_position.x else -1.0
	var new_offset: float = clampf(
			(position.x - _initial_x) + push_dir * cover_data.move_step_pixels,
			cover_data.min_x_offset, cover_data.max_x_offset)
	position.x = _initial_x + new_offset
	_step_index = int(roundf(new_offset / maxf(cover_data.move_step_pixels, 1.0)))
	_update_projection_transform()
	EventBus.environment_interacted.emit(get_instance_id(), _step_index)


# --- 내부 ---

func _setup_body_visual() -> void:
	if _body_visual:
		_body_visual.size = cover_data.body_size
		_body_visual.position = -cover_data.body_size * 0.5
		_body_visual.color = cover_data.body_color
	if _body_collision and _body_collision.shape is RectangleShape2D:
		(_body_collision.shape as RectangleShape2D).size = cover_data.body_size


func _setup_projection_visual() -> void:
	var size := Vector2(cover_data.shadow_projection_length, cover_data.shadow_projection_width)
	if _projection_visual:
		_projection_visual.size = size
		_projection_visual.position = Vector2(0, -size.y * 0.5)
	if _projection_collision and _projection_collision.shape is RectangleShape2D:
		(_projection_collision.shape as RectangleShape2D).size = size
		_projection_collision.position = Vector2(size.x * 0.5, 0)
	if _player_detect_collision:
		_player_detect_collision.position = Vector2(size.x * 0.5, 0)


func _on_shadow_params_changed(_direction: Vector2, _scale: float, _intensity: float) -> void:
	_update_projection_transform()


func _update_projection_transform() -> void:
	if _projection_zone == null or cover_data == null:
		return
	if cover_data.projection_mode == CoverData.ProjectionMode.LOCAL_FIXED:
		_projection_zone.rotation = 0.0
		return
	# LIGHT_OPPOSITE: 빛 반대 방향(=그림자 방향)으로 투영
	var dir: Vector2 = _get_projection_direction()
	if dir == Vector2.ZERO:
		_projection_zone.rotation = 0.0
		return
	_projection_zone.rotation = dir.angle()


func _get_projection_direction() -> Vector2:
	# 낮: 태양 그림자 방향 그대로 사용 (그림자가 빛 반대편에 생김)
	if ShadowSystem.is_day_mode():
		var sd: Vector2 = ShadowSystem.get_shadow_direction()
		if sd.length() > 0.001:
			return sd.normalized()
		return Vector2.ZERO
	# 밤: 등불 OFF면 투영 없음
	if not ShadowSystem.is_lantern_active():
		return Vector2.ZERO
	# 밤: 차폐물 위치에서 등불 반대 방향이 그림자 방향
	var params: Dictionary = ShadowSystem.get_night_shadow_params(global_position)
	if params.is_empty():
		return Vector2.ZERO
	var nd: Vector2 = params.get("direction", Vector2.ZERO)
	if nd.length() > 0.001:
		return nd.normalized()
	return Vector2.ZERO


func _on_enemy_entered(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return
	var id: int = enemy.get_instance_id()
	_affected_enemies[id] = enemy
	_apply_override(enemy)
	EventBus.environment_blocked_shadow.emit(get_instance_id(), id, true)


func _on_enemy_exited(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return
	var id: int = enemy.get_instance_id()
	if not _affected_enemies.has(id):
		return
	_affected_enemies.erase(id)
	_restore_intensity(enemy)
	EventBus.environment_blocked_shadow.emit(get_instance_id(), id, false)


func _apply_override(enemy: Node) -> void:
	if not enemy.has_method("update_intensity"):
		return
	# CREATE 모드: max() 병합 — 더 강한 강도가 적용되도록
	var current: float = EnemySystem.get_current_intensity()
	var target: float = maxf(current, cover_data.block_intensity)
	enemy.update_intensity(target)


func _reapply_override_to_all() -> void:
	var stale: Array[int] = []
	for id in _affected_enemies.keys():
		var enemy: Node = _affected_enemies[id]
		if not is_instance_valid(enemy):
			stale.append(id)
			continue
		_apply_override(enemy)
	for id in stale:
		_affected_enemies.erase(id)


func _restore_intensity(enemy: Node) -> void:
	if not enemy.has_method("update_intensity"):
		return
	var restore: float = EnemySystem.get_current_intensity()
	# 밤+등불 ON일 때는 per-object 위치 기반 강도로 복원
	if not ShadowSystem.is_day_mode() and ShadowSystem.is_lantern_active():
		restore = ShadowSystem.get_intensity_at(enemy.global_position)
	enemy.update_intensity(restore)
