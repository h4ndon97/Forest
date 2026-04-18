class_name ReflectiveFloorData
extends EnvironmentObjectData

## 반사 바닥 환경 오브젝트 데이터.
## 정적/비상호작용. 영역 내 적 강도에 reflect_multiplier를 곱해 상시 약화 (이중 약화).

@export_group("강도 오버라이드")
## 영역 내 적 baseline 강도에 곱하는 계수. 0.5 = 이중 약화 (baseline * 0.5).
## Cover/Lens와 달리 multiplier 방식 — "아래에서도 빛"이라는 GDD 컨셉의 배가 약화 표현.
@export_range(0.0, 1.0, 0.05) var reflect_multiplier: float = 0.5

@export_group("본체 비주얼")
## 본체 fallback 크기 (가로 긴 수면 영역).
@export var body_size: Vector2 = Vector2(192, 32)
## 본체 fallback 색상 (수면 청록, 반투명).
@export var body_color: Color = Color(0.165, 0.29, 0.353, 0.65)
