extends "res://src/entities/objects/environment/base/environment_object.gd"

## 반사 바닥(Reflective Floor) 환경 오브젝트.
## 정적/비상호작용 — interact 없음, STOPPED 게이팅 없음. can_interact=false.
## 영역 내 적 baseline 강도에 reflect_multiplier를 곱해 상시 약화 (이중 약화).
## Cover(max)/Lens(min)와 달리 multiplier 방식.

@export var reflective_floor_data: ReflectiveFloorData

var _affected_enemies: Dictionary = {}

@onready var _influence_zone: Area2D = $InfluenceZone
@onready var _floor_collision: CollisionShape2D = $InfluenceZone/CollisionShape2D
@onready var _floor_visual: ColorRect = $InfluenceZone/FloorVisual
@onready var _light_emitter_zone: Area2D = $LightEmitterZone
@onready var _emitter_collision: CollisionShape2D = $LightEmitterZone/CollisionShape2D


func _ready() -> void:
	super._ready()
	if reflective_floor_data == null:
		push_warning("ReflectiveFloor: reflective_floor_data 미설정")
		return
	data = reflective_floor_data

	_setup_visual()

	_influence_zone.enemy_entered.connect(_on_enemy_entered)
	_influence_zone.enemy_exited.connect(_on_enemy_exited)

	# REFLECTION 빛 방출: 낮이거나 등불 ON일 때만 monitorable (센서 감지 가능).
	if _light_emitter_zone != null:
		EventBus.day_night_changed.connect(_on_day_night_changed_for_emitter)
		EventBus.lantern_toggled.connect(_on_lantern_toggled_for_emitter)
		_refresh_emitter_state()


func _process(_delta: float) -> void:
	if reflective_floor_data == null:
		return
	# 매 프레임 override 재적용 (EnemySystem 브로드캐스트가 덮어쓰는 것을 무효화)
	if not _affected_enemies.is_empty():
		_reapply_override_to_all()


# --- 내부 ---


func _setup_visual() -> void:
	var size: Vector2 = reflective_floor_data.body_size
	if _floor_collision and _floor_collision.shape is RectangleShape2D:
		(_floor_collision.shape as RectangleShape2D).size = size
	if _floor_visual:
		_floor_visual.size = size
		_floor_visual.position = -size * 0.5
		_floor_visual.color = reflective_floor_data.body_color
	if _emitter_collision and _emitter_collision.shape is RectangleShape2D:
		(_emitter_collision.shape as RectangleShape2D).size = size


func _refresh_emitter_state() -> void:
	if _light_emitter_zone == null:
		return
	var emitting: bool = ShadowSystem.is_day_mode() or ShadowSystem.is_lantern_active()
	_light_emitter_zone.monitorable = emitting


func _on_day_night_changed_for_emitter(_is_day: bool) -> void:
	_refresh_emitter_state()


func _on_lantern_toggled_for_emitter(_is_on: bool, _pos: Vector2) -> void:
	_refresh_emitter_state()


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
	# 이중 약화: baseline 강도 × multiplier. baseline은 낮=전역, 밤+등불=위치 기반.
	var base: float = _get_baseline_intensity(enemy)
	var target: float = clampf(base * reflective_floor_data.reflect_multiplier, 0.0, 1.0)
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
	var restore: float = _get_baseline_intensity(enemy)
	enemy.update_intensity(restore)


func _get_baseline_intensity(enemy: Node) -> float:
	var val: float = EnemySystem.get_current_intensity()
	if not ShadowSystem.is_day_mode() and ShadowSystem.is_lantern_active():
		val = ShadowSystem.get_intensity_at(enemy.global_position)
	return val
