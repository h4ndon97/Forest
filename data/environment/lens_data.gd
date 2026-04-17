class_name LensData
extends EnvironmentObjectData

## 렌즈 환경 오브젝트 데이터.
## STOPPED 중 프리셋 회전으로 집광 방향 조준.
## FocusZone 내 적 강도를 focus_intensity로 상시 override (min 병합 — 약화 방향).

@export_group("회전 프리셋")
## 프리셋 각도 수 (4 = 0/90/180/270도)
@export var preset_count: int = 4
## 시작 프리셋 인덱스
@export var initial_preset_index: int = 0

@export_group("집광 영역")
## 빔 전체 길이 (px). 본체 중심에서 집광점까지의 거리.
@export var beam_length: float = 160.0
## 집광 영역(FocusZone) 길이. 빔 끝단 좁은 구간.
@export var focus_zone_length: float = 48.0
## 집광 영역 폭 (좁을수록 "한 명만 골라 약화" 감각).
@export var focus_zone_width: float = 24.0

@export_group("강도 오버라이드")
## FocusZone 내 적 강제 강도 (0.0~1.0). 0.1=극도 약화. Cover의 대칭 — min() 병합.
@export var focus_intensity: float = 0.1

@export_group("본체 비주얼")
## 본체 fallback 원형 지름
@export var body_size: Vector2 = Vector2(24, 24)
## 본체 fallback 색상 (유리톤)
@export var body_color: Color = Color(0.82, 0.91, 0.94, 1.0)
## 본체 테두리 색상 (금속 테두리)
@export var body_border_color: Color = Color(0.55, 0.48, 0.29, 1.0)
