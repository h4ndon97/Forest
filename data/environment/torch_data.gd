class_name TorchData
extends EnvironmentObjectData

## 횃불(Torch) 환경 오브젝트 데이터.
## STOPPED 중 interact()로 점화 ↔ 소화 토글.
## 점화 시 같은 stage 안 보스 약점 노출 — `EventBus.boss_weak_point_exposed.emit` (Lens 답습).
## zone4 Lord Remnant 약점 트리거 인프라 (lens_focus 임시 사용 4번째 누적 회피).

@export_group("본체 비주얼")
## 본체 fallback 사이즈 (px) — 세로 긴 횃불대 형태
@export var body_size: Vector2 = Vector2(24, 56)
## 소화 상태 색상 (어두운 갈색, 잠긴 횃불대)
@export var unlit_color: Color = Color(0.30, 0.20, 0.16, 1.0)
## 점화 상태 색상 (황금 발광)
@export var lit_color: Color = Color(0.95, 0.65, 0.30, 0.95)
