class_name SealingPedestalData
extends EnvironmentObjectData

## 봉인 제단(SealingPedestal) 환경 오브젝트 데이터.
## STOPPED 중 interact()로 *한 번만* 활성화 (재사용 불가, 영구 ON).
## 활성화 시 StateFlags 영속 플래그 set — Phase 4-C zone4 콘텐츠 작업 시 활용처 결정.
## (예: zone4 진입 보너스 / 숨김 경로 노출 / 추가 환경 활성)

@export_group("플래그")
## 영속 플래그 ID. 활성화 시 true로 set.
@export var flag_id: String = "world.zone3.sealing_altar_opened"

@export_group("본체 비주얼")
## 본체 fallback 사이즈 (px) — 낮고 넓은 제단 형태
@export var body_size: Vector2 = Vector2(56, 40)
## 비활성 상태 색상 (잠긴 어두운 석조 톤)
@export var inactive_color: Color = Color(0.30, 0.27, 0.24, 1.0)
## 활성 상태 색상 (따뜻한 황금빛 — 봉인 해방 톤)
@export var active_color: Color = Color(0.85, 0.75, 0.45, 0.9)
## 본체 테두리 색상
@export var body_border_color: Color = Color(0.18, 0.16, 0.14, 1.0)
