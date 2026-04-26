class_name EffectsResidualLight
extends RefCounted

## REC-FX-003 — 빛 피니시 후 적 위치에 1~2초 지속되는 발광 잔류.
## damage_resolver._apply_effects 후속에서 EffectsSystem.spawn_residual_light 호출.
## EffectTimeline의 단발 cue 모델(0~0.12s)에 맞지 않아 후속 거동으로 분리.
##
## 시각 구조 (발광 3레이어 규약 — base 생략, core/halo만):
##   - halo: 큰 반경(22px), 외곽 페이드, finish_color 기반
##   - core: 작은 반경(10px), 내부 밝기, finish_color에 흰색 추가
## Tween: alpha 시작값 → 0, scale 1.0 → end_scale 동시 진행, duration 후 queue_free.

const _CIRCLE_SEGMENTS: int = 24

var _host: Node
var _config: EffectsConfigData


func _init(host: Node, config: EffectsConfigData) -> void:
	_host = host
	_config = config


## world_pos: Node2D 좌표계 위치(보통 적의 global_position).
## attribute: "light"/"shadow"/"hybrid" — get_finish_color 색 결정.
## duration <= 0.0 이면 config.residual_light_duration 사용.
func spawn(world_pos: Vector2, attribute: String, duration: float = -1.0) -> void:
	if _host == null:
		return
	var scene_root: Node = _host.get_tree().current_scene
	if scene_root == null:
		return
	var dur: float = duration if duration > 0.0 else _config.residual_light_duration
	if dur <= 0.0:
		return
	var finish_color: Color = EffectsSystem.get_finish_color(attribute)
	var node: Node2D = _build_visual(world_pos, finish_color)
	scene_root.add_child(node)
	_play_fade(node, dur)


# === 내부 ===


func _build_visual(world_pos: Vector2, finish_color: Color) -> Node2D:
	var root := Node2D.new()
	root.name = "ResidualLight"
	root.global_position = world_pos

	# halo (외곽 발광) — 어두운 base 위에 finish_color
	var halo_color: Color = finish_color
	halo_color.a = _config.residual_light_halo_alpha
	var halo := _make_circle_polygon(_config.residual_light_halo_radius, halo_color)
	halo.name = "Halo"
	root.add_child(halo)

	# core (내부 밝기) — finish_color에 흰색 가산해 더 밝게
	var core_color: Color = finish_color.lerp(Color.WHITE, 0.5)
	core_color.a = _config.residual_light_core_alpha
	var core := _make_circle_polygon(_config.residual_light_core_radius, core_color)
	core.name = "Core"
	root.add_child(core)

	return root


func _make_circle_polygon(radius: float, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	var points := PackedVector2Array()
	for i in range(_CIRCLE_SEGMENTS):
		var angle: float = float(i) * TAU / float(_CIRCLE_SEGMENTS)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	poly.polygon = points
	poly.color = color
	return poly


func _play_fade(node: Node2D, duration: float) -> void:
	var tween: Tween = node.create_tween()
	tween.set_parallel(true)
	# 모든 자식이 modulate를 상속해 한 번에 페이드.
	tween.tween_property(node, "modulate:a", 0.0, duration)
	var end_scale: float = _config.residual_light_end_scale
	tween.tween_property(node, "scale", Vector2(end_scale, end_scale), duration)
	tween.chain().tween_callback(node.queue_free)
