class_name ShadowCrystalData
extends EnvironmentObjectData

## 그림자 결정(ShadowCrystal) 환경 오브젝트 데이터.
## STOPPED 중 interact()로 *한 번만* 활성화 (재사용 불가, 영구 ON).
## 활성화 시 StateFlags 영속 플래그 set — Phase 4-D zone5 *최종 보스실 진입 조건*.
## (zone5 본 진행은 그림자 결정 미발견자도 가능 — 진행 차단 회피)

@export_group("플래그")
## 영속 플래그 ID. 활성화 시 true로 set.
@export var flag_id: String = "world.zone4.shadow_crystal_attuned"

@export_group("본체 비주얼")
## 본체 fallback 사이즈 (px) — 그림자 결정 형태 (sealing_pedestal보다 큼)
@export var body_size: Vector2 = Vector2(64, 48)
## 잠긴 상태 색상 (어두운 보라 결정)
@export var inactive_color: Color = Color(0.18, 0.14, 0.22, 1.0)
## 활성 상태 색상 (발광 보라 — 그림자 결정 동조)
@export var active_color: Color = Color(0.65, 0.40, 0.85, 0.9)
## 본체 테두리 색상
@export var body_border_color: Color = Color(0.10, 0.08, 0.14, 1.0)
