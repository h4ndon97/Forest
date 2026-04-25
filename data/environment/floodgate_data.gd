class_name FloodgateData
extends EnvironmentObjectData

## 수문(Floodgate) 환경 오브젝트 데이터.
## STOPPED 중 interact()로 토글 (closed → open / open → closed).
## 토글 시 StateFlags 영속 플래그 set — zone3+ HiddenRevealer가 해당 플래그를 구독하여
## 물 반사면 또는 막힌 통로를 노출.

@export_group("플래그")
## 영속 플래그 ID. open 시 true / closed 시 false로 set.
@export var flag_id: String = "world.zone2.floodgate_opened"

@export_group("본체 비주얼")
## 본체 fallback 사이즈 (px)
@export var body_size: Vector2 = Vector2(40, 64)
## closed 상태 색상 (잠긴 금속 톤)
@export var closed_color: Color = Color(0.32, 0.36, 0.44, 1.0)
## open 상태 색상 (개방 / 물 흐름 톤)
@export var open_color: Color = Color(0.4, 0.55, 0.62, 0.8)
## 본체 테두리 색상
@export var body_border_color: Color = Color(0.18, 0.22, 0.28, 1.0)
