class_name EffectsSlashArc
extends RefCounted

## 슬래시 시점에 발현되는 빛 호(arc) VFX (Phase B 리팩토링 (가)+(A), 2026-05-02).
## 검 자체는 캐릭터 PNG에 상시 포함 — 본 이펙트는 *슬래시 흔적/검기*만 담당.
## 콤보 매 hit (1~4)마다 spawn. 호 fan polygon + 짧은 fade in/hold/out.
## 색은 속성에 따라 4종 (light=금/shadow=보라/neutral=흰/hybrid=백금).
## 부모: current_scene(Stage) — 캐릭터 이동과 분리되어 슬래시 위치에 잔류.

const ATTRIBUTE_COLORS := {
	"light": Color(1.0, 0.82, 0.29, 1.0),
	"shadow": Color(0.55, 0.18, 0.78, 1.0),
	"neutral": Color(0.96, 0.96, 0.91, 1.0),
	"hybrid": Color(0.91, 0.87, 1.0, 1.0),
}

# 표준 경로 자동 탐색 — 흰색 베이스 PNG 권장(속성색은 self_modulate로 입힘).
# PNG 중앙이 손 위치(centered=true), 호는 우측을 향하도록 그릴 것 (코드가 dir에 따라 자동 반전).
const DEFAULT_SPRITE_PATHS := [
	"res://assets/sprites/effects/slash_arc.png",
	"res://assets/sprites/effects/arc.png",
]

const ARC_OUTER_RADIUS: float = 38.0
const ARC_INNER_RADIUS: float = 26.0
const ARC_DEGREES: float = 110.0
const ARC_SEGMENTS: int = 12
const HAND_OFFSET_X: float = 14.0
const HAND_OFFSET_Y: float = -16.0
const FADE_IN_DURATION: float = 0.03
const HOLD_DURATION: float = 0.10
const FADE_OUT_DURATION: float = 0.07

var _host: Node


func _init(host: Node) -> void:
	_host = host


## 슬래시 호 발현. position=캐릭터 global_position, direction=facing(±1), attribute=4종, hit_number=1~4.
func spawn(position: Vector2, direction: int, attribute: String, hit_number: int) -> void:
	var dir: int = direction if direction != 0 else 1
	var parent: Node = _host.get_tree().current_scene
	if parent == null:
		return
	var color: Color = ATTRIBUTE_COLORS.get(attribute, ATTRIBUTE_COLORS["neutral"])
	var arc: Node2D = _create_arc_visual(color)
	arc.global_position = position + Vector2(HAND_OFFSET_X * float(dir), HAND_OFFSET_Y)
	# direction에 따라 좌우 반전.
	arc.scale.x = float(dir)
	# hit_number 교대로 호 수직 반전 — 1·3 위에서 아래, 2·4 아래에서 위 (콤보 시각 다양성).
	if hit_number % 2 == 0:
		arc.scale.y = -1.0
	parent.add_child(arc)
	_animate_arc(arc)


# === 내부 ===


func _create_arc_visual(color: Color) -> Node2D:
	var root: Node2D = Node2D.new()
	var sprite_path: String = _resolve_sprite_path()
	if sprite_path != "":
		var tex: Texture2D = load(sprite_path) as Texture2D
		if tex:
			var sprite: Sprite2D = Sprite2D.new()
			sprite.texture = tex
			sprite.centered = true
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.self_modulate = color
			root.add_child(sprite)
			return root
	# Fallback — 호 fan polygon (외곽 + 내곽 두 반경).
	var poly: Polygon2D = Polygon2D.new()
	poly.polygon = _build_arc_polygon()
	poly.color = color
	root.add_child(poly)
	return root


func _build_arc_polygon() -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var half_arc: float = ARC_DEGREES * 0.5
	var step: float = ARC_DEGREES / float(ARC_SEGMENTS)
	# 외곽 — 호 중심선 = 0도(우측). 위쪽 끝(-half_arc) → 아래쪽 끝(+half_arc).
	for i in range(ARC_SEGMENTS + 1):
		var deg: float = -half_arc + step * float(i)
		var rad: float = deg_to_rad(deg)
		points.append(Vector2(cos(rad), sin(rad)) * ARC_OUTER_RADIUS)
	# 내곽 — 역순으로 닫힘.
	for i in range(ARC_SEGMENTS, -1, -1):
		var deg: float = -half_arc + step * float(i)
		var rad: float = deg_to_rad(deg)
		points.append(Vector2(cos(rad), sin(rad)) * ARC_INNER_RADIUS)
	return points


func _animate_arc(arc: Node2D) -> void:
	arc.modulate.a = 0.0
	var tween: Tween = arc.create_tween().set_ignore_time_scale(true)
	tween.tween_property(arc, "modulate:a", 1.0, FADE_IN_DURATION)
	tween.tween_interval(HOLD_DURATION)
	tween.tween_property(arc, "modulate:a", 0.0, FADE_OUT_DURATION)
	tween.tween_callback(arc.queue_free)


func _resolve_sprite_path() -> String:
	for path in DEFAULT_SPRITE_PATHS:
		if ResourceLoader.exists(path):
			return path
	return ""
