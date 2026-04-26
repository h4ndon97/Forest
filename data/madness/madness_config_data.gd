class_name MadnessConfigData
extends Resource

## REC-MECH-002 — 그림자 광기 설정 Resource.
## 큰 그림자 영역 장기 노출 시 광기 누적 → 단계별 위협 → 시간 정지 회복.
## 1차 인프라 (2026-04-26): 게이지 + 4단계 + 시그널 발신만. 환영 적 spawn은 후속.

@export_group("Threshold")
## 강도가 이 값 이상일 때만 광기 누적. REC-FX-007과 동일 임계 권장(0.5).
@export_range(0.0, 1.5, 0.01) var intensity_threshold: float = 0.5

@export_group("Rates")
## 강도 1.0 기준 1초당 누적량 (강도 비례). 5.0 = 강도 1.0 영역 20초 머물면 풀.
@export_range(0.0, 50.0, 0.5) var accumulation_rate: float = 5.0
## 시간 정지 중 1초당 회복량. 10.0 = 10초 정지로 풀 회복.
@export_range(0.0, 50.0, 0.5) var recovery_rate: float = 10.0
## 광기 게이지 최대값.
@export var max_value: float = 100.0

@export_group("Stages")
## 각 단계 시작 임계값 (max_value 비율). [safe_end, warning_end, alert_end].
## 0~safe_end = SAFE / safe_end~warning_end = WARNING /
## warning_end~alert_end = ALERT / alert_end~max = CRITICAL.
@export_range(0.0, 1.0, 0.01) var stage_safe_end: float = 0.30
@export_range(0.0, 1.0, 0.01) var stage_warning_end: float = 0.60
@export_range(0.0, 1.0, 0.01) var stage_alert_end: float = 0.85

@export_group("Synergy (REC-FX-007)")
## 광기 단계별 비네트 알파 추가 보정. effects_shadow_vignette가 EventBus 시그널 수신 후 적용.
## 단계 0(SAFE)=0 / 1=warning_boost / 2=alert_boost / 3=critical_boost.
@export_range(0.0, 0.5, 0.01) var vignette_boost_warning: float = 0.05
@export_range(0.0, 0.5, 0.01) var vignette_boost_alert: float = 0.12
@export_range(0.0, 0.5, 0.01) var vignette_boost_critical: float = 0.20
