class_name SkillIcons
extends RefCounted

## 스킬 아이콘 프로그래밍 드로잉 (폴백).
## SkillData.icon_path가 비어있을 때 CanvasItem._draw에서 호출한다.
## 현재는 시안용 단순 원 placeholder — 스킬 컨셉 확정 후 PNG로 교체 예정.
## ui_design_master.md §A-7 팔레트 준수.

# === 팔레트 (ui_design_master.md §A-7) ===
const COLOR_LIGHT_CORE := Color(0.949, 0.8, 0.4, 1.0)  # #F2CC66 금색
const COLOR_SHADOW_CORE := Color(0.545, 0.184, 0.776, 1.0)  # #8B2FC6 보라
const COLOR_NEUTRAL := Color(0.541, 0.541, 0.565, 1.0)  # #8A8A90 무채색

# 시안 placeholder 규격 (24×24 inner safe area에 꽉 차는 단순 원)
const PLACEHOLDER_RADIUS := 12.0


## 스킬 ID로 아이콘 드로잉 분기. center는 슬롯 로컬 좌표(보통 16,16).
## tint는 multiplicative 색 보정 — 자원 부족 등 상태 표시용.
static func draw(
	canvas: CanvasItem, skill_id: String, center: Vector2, tint: Color = Color.WHITE
) -> void:
	match skill_id:
		"light_slash":
			canvas.draw_circle(center, PLACEHOLDER_RADIUS, COLOR_LIGHT_CORE * tint)
		"shadow_strike":
			canvas.draw_circle(center, PLACEHOLDER_RADIUS, COLOR_SHADOW_CORE * tint)
		_:
			_draw_empty_placeholder(canvas, center)


## 빈 슬롯 플레이스홀더: 회색 작은 원 (장착 전 상태). tint 미적용.
static func _draw_empty_placeholder(canvas: CanvasItem, center: Vector2) -> void:
	canvas.draw_circle(center, 3.0, COLOR_NEUTRAL)
