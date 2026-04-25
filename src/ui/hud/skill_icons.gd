class_name SkillIcons
extends RefCounted

## 스킬 아이콘 프로그래밍 드로잉 (폴백).
## SkillData.icon_path가 비어있을 때 CanvasItem._draw에서 호출한다.
## 디자인 기준: 16~20px 중앙 아이콘 (24×24 inner 영역 안).
## ui_design_master.md §A-7 팔레트 준수.

# === 팔레트 (ui_design_master.md §A-7) ===
const COLOR_LIGHT_CORE := Color(0.949, 0.8, 0.4, 1.0)  # #F2CC66 금색
const COLOR_LIGHT_HIGHLIGHT := Color(1.0, 0.957, 0.8, 1.0)  # #FFF4CC 아이보리 (선단)
const COLOR_LIGHT_TRAIL := Color(0.788, 0.604, 0.247, 1.0)  # #C99A3F 오커 (잔광)

const COLOR_SHADOW_CORE := Color(0.545, 0.184, 0.776, 1.0)  # #8B2FC6 보라
const COLOR_SHADOW_HIGHLIGHT := Color(0.788, 0.353, 0.91, 1.0)  # #C95AE8 자홍
const COLOR_SHADOW_DEEP := Color(0.227, 0.051, 0.361, 1.0)  # #3A0D5C 진보라

const COLOR_NEUTRAL := Color(0.541, 0.541, 0.565, 1.0)  # #8A8A90 무채색


## 스킬 ID로 아이콘 드로잉 분기. center는 슬롯 로컬 좌표(보통 16,16).
static func draw(canvas: CanvasItem, skill_id: String, center: Vector2) -> void:
	match skill_id:
		"light_slash":
			_draw_light_slash(canvas, center)
		"shadow_strike":
			_draw_shadow_strike(canvas, center)
		_:
			_draw_empty_placeholder(canvas, center)


## 빛 베기: 북동→남서 방향 초승달 검광(금빛 크레센트 + 아이보리 하이라이트).
static func _draw_light_slash(canvas: CanvasItem, center: Vector2) -> void:
	var outer_r := 7.5
	var inner_r := 4.5
	var arc_start := -PI * 0.35  # 북동 근처
	var arc_end := PI * 0.75  # 남서 근처
	var segments := 14

	var crescent := PackedVector2Array()
	for i in segments + 1:
		var t: float = float(i) / segments
		var a: float = lerp(arc_start, arc_end, t)
		crescent.append(center + Vector2(cos(a), sin(a)) * outer_r)
	for i in segments + 1:
		var t: float = 1.0 - float(i) / segments
		var a: float = lerp(arc_start, arc_end, t)
		crescent.append(center + Vector2(cos(a), sin(a)) * inner_r)
	canvas.draw_colored_polygon(crescent, COLOR_LIGHT_CORE)

	# 선단 하이라이트 (외곽 아크 1px 안쪽 얇은 선)
	var highlight := PackedVector2Array()
	for i in segments + 1:
		var t: float = float(i) / segments
		var a: float = lerp(arc_start, arc_end, t)
		highlight.append(center + Vector2(cos(a), sin(a)) * (outer_r - 0.8))
	canvas.draw_polyline(highlight, COLOR_LIGHT_HIGHLIGHT, 1.0, false)

	# 잔광 점 (호 내측 중앙에 작은 오커 점 2개)
	var mid_angle: float = (arc_start + arc_end) * 0.5
	var trail_a := mid_angle + 0.18
	var trail_b := mid_angle - 0.18
	var trail_r := (outer_r + inner_r) * 0.5
	canvas.draw_circle(
		center + Vector2(cos(trail_a), sin(trail_a)) * trail_r, 0.8, COLOR_LIGHT_TRAIL
	)
	canvas.draw_circle(
		center + Vector2(cos(trail_b), sin(trail_b)) * trail_r, 0.8, COLOR_LIGHT_TRAIL
	)


## 그림자 강타: 방사형 6스파이크 + 중심 2겹 점.
static func _draw_shadow_strike(canvas: CanvasItem, center: Vector2) -> void:
	var spike_count := 6
	var spike_length := 7.5
	var spike_base := 1.6

	for i in spike_count:
		var a: float = float(i) * TAU / float(spike_count) - PI * 0.5  # 12시 시작
		var tip: Vector2 = center + Vector2(cos(a), sin(a)) * spike_length
		var left: Vector2 = center + Vector2(cos(a + PI * 0.5), sin(a + PI * 0.5)) * spike_base
		var right: Vector2 = center + Vector2(cos(a - PI * 0.5), sin(a - PI * 0.5)) * spike_base
		canvas.draw_colored_polygon(PackedVector2Array([tip, right, left]), COLOR_SHADOW_CORE)

	# 중심 2겹: 진보라 → 자홍 점
	canvas.draw_circle(center, 3.0, COLOR_SHADOW_DEEP)
	canvas.draw_circle(center, 1.7, COLOR_SHADOW_HIGHLIGHT)


## 빈 슬롯 플레이스홀더: 회색 작은 원 (장착 전 상태).
static func _draw_empty_placeholder(canvas: CanvasItem, center: Vector2) -> void:
	canvas.draw_circle(center, 3.0, COLOR_NEUTRAL)
