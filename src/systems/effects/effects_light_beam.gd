class_name EffectsLightBeam
extends RefCounted

## REC-MECH-007 — 거울 반사 빛 빔 시각 효과.
## finish_light.gd가 거울 위치/각도로 spawn 호출.
## hitbox는 finish_light가 별도로 생성(AttackSpec) — 본 헬퍼는 시각만 담당.
##
## 시각 구조:
##   - 회전된 직사각형 Polygon2D (거울 위치 기준 +x 방향)
##   - 발광 색 (config.light_beam_color)
##   - Tween: alpha → 0, scale.y → 0.5 (얇아지며 사라짐)
##   - duration 후 자동 queue_free

var _host: Node
var _config: EffectsConfigData


func _init(host: Node, config: EffectsConfigData) -> void:
	_host = host
	_config = config


## 거울 위치 + 회전 각도로 빛 빔 spawn.
## start_pos: 거울의 global_position (Node2D 좌표계).
## angle: 거울 회전 각도 (rad). 0 = +x 방향.
## duration <= 0 이면 config.light_beam_fade_duration 사용.
func spawn(start_pos: Vector2, angle: float, duration: float = -1.0) -> void:
	if _host == null:
		return
	var scene_root: Node = _host.get_tree().current_scene
	if scene_root == null:
		return
	var dur: float = duration if duration > 0.0 else _config.light_beam_fade_duration
	if dur <= 0.0:
		return
	var node: Node2D = _build_visual(start_pos, angle)
	scene_root.add_child(node)
	_play_fade(node, dur)


# === 내부 ===


func _build_visual(start_pos: Vector2, angle: float) -> Node2D:
	var root := Node2D.new()
	root.name = "LightBeam"
	root.global_position = start_pos
	root.rotation = angle

	# 직사각형 빔 — 거울에서 +x 방향으로 length만큼 연장.
	var length: float = _config.light_beam_length
	var half_w: float = _config.light_beam_width * 0.5
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array(
		[
			Vector2(0.0, -half_w),
			Vector2(length, -half_w),
			Vector2(length, half_w),
			Vector2(0.0, half_w),
		]
	)
	var color: Color = _config.light_beam_color
	color.a = _config.light_beam_alpha
	poly.color = color
	root.add_child(poly)

	return root


func _play_fade(node: Node2D, duration: float) -> void:
	var tween: Tween = node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "modulate:a", 0.0, duration)
	tween.tween_property(node, "scale:y", 0.5, duration)
	tween.chain().tween_callback(node.queue_free)
