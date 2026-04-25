class_name EffectsAfterimage
extends RefCounted

## Phase 3-7 Pass 3 Step 4 — 잔상(afterimage) 범용 헬퍼.
## Sprite2D/AnimatedSprite2D 의 현재 프레임을 Sprite2D 복제본으로 스폰하고
## modulate.a 를 페이드한다. 시간 정지 해제 + 향후 Light Dash 등 재사용 대상.

const DEFAULT_TINT: Color = Color(1.0, 1.0, 1.0, 0.6)

var _host: Node


func _init(host: Node) -> void:
	_host = host


## source 의 현재 프레임으로 잔상 count 장을 interval 간격 스폰.
## 각 복제본은 fade 시간 동안 modulate.a 를 0 으로 Tween 후 queue_free.
## 부모는 current_scene(Stage) — Player 이동과 분리되어 잔상이 월드 좌표에 고정.
## (이전 버그: source.get_parent()=Player였어서 잔상이 Player 자식으로 따라다녀 trail 효과 소실).
func spawn(
	source: Node2D, count: int, interval: float, fade: float, tint: Color = DEFAULT_TINT
) -> void:
	if source == null or not is_instance_valid(source) or count <= 0 or fade <= 0.0:
		return
	var parent: Node = _host.get_tree().current_scene
	if parent == null:
		# 폴백: 비정상 상황(scene 미로드)에서도 동작 보장.
		parent = source.get_parent()
		if parent == null:
			return
	for i in range(count):
		var delay: float = float(i) * maxf(interval, 0.0)
		_schedule_spawn(source, parent, delay, fade, tint)


# === 내부 ===


func _schedule_spawn(source: Node2D, parent: Node, delay: float, fade: float, tint: Color) -> void:
	if delay <= 0.0:
		_spawn_one(source, parent, fade, tint)
		return
	var tree: SceneTree = _host.get_tree()
	if tree == null:
		return
	# process_always=true + ignore_time_scale=true → pause/힛스톱 중에도 스케줄 유지
	var timer: SceneTreeTimer = tree.create_timer(delay, true, false, true)
	timer.timeout.connect(func() -> void: _spawn_one(source, parent, fade, tint))


func _spawn_one(source: Node2D, parent: Node, fade: float, tint: Color) -> void:
	if not is_instance_valid(source) or not is_instance_valid(parent):
		return
	var texture: Texture2D = _resolve_texture(source)
	if texture == null:
		return
	var ghost: Sprite2D = Sprite2D.new()
	ghost.texture = texture
	ghost.global_position = source.global_position
	ghost.global_rotation = source.global_rotation
	ghost.global_scale = source.global_scale
	ghost.modulate = tint
	ghost.texture_filter = source.texture_filter
	ghost.z_index = source.z_index - 1
	_copy_flip_and_offset(source, ghost)
	parent.add_child(ghost)
	var end_color: Color = tint
	end_color.a = 0.0
	var tween: Tween = ghost.create_tween().set_ignore_time_scale(true)
	tween.tween_property(ghost, "modulate", end_color, fade)
	tween.tween_callback(ghost.queue_free)


func _copy_flip_and_offset(source: Node2D, ghost: Sprite2D) -> void:
	if source is AnimatedSprite2D:
		var anim: AnimatedSprite2D = source
		ghost.flip_h = anim.flip_h
		ghost.flip_v = anim.flip_v
		ghost.offset = anim.offset
	elif source is Sprite2D:
		var sp: Sprite2D = source
		ghost.flip_h = sp.flip_h
		ghost.flip_v = sp.flip_v
		ghost.offset = sp.offset


func _resolve_texture(source: Node2D) -> Texture2D:
	if source is AnimatedSprite2D:
		var anim: AnimatedSprite2D = source
		if anim.sprite_frames == null:
			return null
		return anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
	if source is Sprite2D:
		return (source as Sprite2D).texture
	return null
