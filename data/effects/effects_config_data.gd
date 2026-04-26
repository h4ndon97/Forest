class_name EffectsConfigData
extends Resource

## Phase 3-7 Pass 1 — 이펙트 시스템 전역 설정.
## 모든 색·세기·시간 수치는 여기서만 변경한다.
## 아트 디렉션(EFFECTS.md §5) 확정 시 .tres 편집만으로 반영 가능.

# === 힛 플래시 ===
@export_group("Hit Flash")
@export var default_flash_color: Color = Color.WHITE
@export var default_flash_duration: float = 0.08
@export var player_hit_color: Color = Color(2.5, 0.8, 0.8, 1.0)
@export var player_hit_duration: float = 0.1
@export var enemy_hit_color: Color = Color(2.5, 2.5, 2.5, 1.0)
@export var enemy_hit_duration: float = 0.08
@export var boss_hit_color: Color = Color(2.5, 2.5, 2.5, 1.0)
@export var boss_hit_duration: float = 0.08
## attack: rise / total = peak 도달 비율 (0~1)
@export_range(0.0, 1.0, 0.05) var flash_attack_ratio: float = 0.25

# === 힛 플래시 — 피니시 속성별 (D7-2 결정: 속성별 분기) ===
# 프로젝트 속성 체계(light/shadow/hybrid)와 일치. HDR(1.5~2.5)로 오버브라이트 연출.
@export_subgroup("Finish Attribute Colors")
@export var finish_color_light: Color = Color(2.5, 2.5, 2.5, 1.0)
@export var finish_color_shadow: Color = Color(1.6, 0.4, 2.2, 1.0)
@export var finish_color_hybrid: Color = Color(2.4, 1.9, 0.6, 1.0)

# === 카메라 쉐이크 ===
@export_group("Camera Shake")
## trauma=1.0일 때 카메라 오프셋 최대값(픽셀). 640x360 기준 보수적 세팅.
@export var shake_max_offset_px: float = 4.0
## trauma 감쇠율 (per second). 1.8 = 약 0.55초 만에 0
@export var shake_decay_per_sec: float = 1.8
@export var shake_preset_light: float = 0.25
@export var shake_preset_medium: float = 0.45
@export var shake_preset_heavy: float = 0.7
@export var shake_preset_finish: float = 1.0

# === 힛스톱 ===
@export_group("Hit Stop")
## 힛스톱 중 적용할 time_scale. 0.0=완전 정지, 0.05=극저속.
@export_range(0.0, 1.0, 0.01) var hitstop_scale: float = 0.0
## 약 3프레임 @60fps
@export var hitstop_preset_hit: float = 0.05
## 약 6프레임 @60fps
@export var hitstop_preset_critical: float = 0.1
## 약 10프레임 @60fps
@export var hitstop_preset_finish: float = 0.17

# === 스크린 플래시 ===
@export_group("Screen Flash")
@export var flash_default_color: Color = Color(1.0, 1.0, 1.0, 0.6)
@export var flash_default_duration: float = 0.08

# === 시간 정지 연출 (Pass 3, D7-1 재조정: 화면 전체 균일 세피아) ===
@export_group("Time Stop (Pass 3)")
@export var time_stop_sepia_tone: Color = Color(0.74, 0.55, 0.33, 1.0)
@export var time_stop_tint_color: Color = Color(0.90, 0.75, 0.55, 1.0)
@export_range(0.0, 1.0, 0.01) var time_stop_saturation_lerp: float = 0.15
## 최대 weight — 접근성 감쇠용 (0.0=OFF, 1.0=풀)
@export_range(0.0, 1.0, 0.01) var time_stop_weight_target: float = 1.0
@export var time_stop_transition_duration: float = 0.30
## LDR 클램프(ColorRect 알파 페이드 기반이라 HDR 채널은 발광하지 않음).
@export var time_stop_blue_pulse_color: Color = Color(0.45, 0.75, 1.00, 0.55)
@export var time_stop_blue_pulse_duration: float = 0.18
@export var time_stop_afterimage_count: int = 3
@export var time_stop_afterimage_interval: float = 0.04
@export var time_stop_afterimage_fade: float = 0.25

# === 빛 대시 잔상 ===
# 시간 정지 해제보다 속도감 강조 (count↑·interval↓·fade↑).
@export_group("Light Dash")
@export var light_dash_afterimage_count: int = 5
@export var light_dash_afterimage_interval: float = 0.025
@export var light_dash_afterimage_fade: float = 0.18

# === 빛 도약 잔상 + burst (Phase 4-0 #4) ===
# Light Dash보다 강화 (count↑↑·fade↑↑) + 진입 시점 mini screen flash로 burst 강조.
@export_group("Light Leap")
@export var light_leap_afterimage_count: int = 5
@export var light_leap_afterimage_interval: float = 0.015
@export var light_leap_afterimage_fade: float = 0.25
## 진입 시점 mini screen flash 지속(s). 0이면 burst 미사용.
@export var light_leap_burst_duration: float = 0.04
## mini flash 색 — 보통 light finish color(흰)에 약간의 알파.
@export var light_leap_burst_color: Color = Color(2.5, 2.5, 2.5, 0.2)

# === 땅거미 공포 비네트 (Pass 4, D7-3 거리 보간 보라→빨강) ===
@export_group("Dusk Warning (Pass 4)")
## 먼 거리 비네트 색 (#8B2FC6 보라 = 그림자 왕가 팔레트).
@export var dusk_vignette_color_far: Color = Color(0.545, 0.184, 0.776, 1.0)
## 근접 비네트 색 (#FF3333 빨강 = 본능적 공포).
@export var dusk_vignette_color_near: Color = Color(1.0, 0.2, 0.2, 1.0)
## 거리 2맵: 먼 보라 약하게.
@export_range(0.0, 1.0, 0.01) var dusk_vignette_alpha_distance_2: float = 0.25
## 거리 1맵: 보라↔빨강 중간, 좀 더 짙게.
@export_range(0.0, 1.0, 0.01) var dusk_vignette_alpha_distance_1: float = 0.45
## 거리 0맵(같은 스테이지 도착): 빨강 풀.
@export_range(0.0, 1.0, 0.01) var dusk_vignette_alpha_distance_0: float = 0.6
## 거리 1맵의 보라→빨강 보간 비율 (0=보라, 1=빨강).
@export_range(0.0, 1.0, 0.01) var dusk_vignette_lerp_distance_1: float = 0.5
## 거리 변경 시 색·알파 Tween 시간.
@export var dusk_vignette_transition_duration: float = 0.5
## 비네트 시작 반경 (짧은 변 절반=0.5 기준). 셰이더 inner_radius.
@export_range(0.0, 1.5, 0.01) var dusk_vignette_inner_radius: float = 0.30
## 비네트 완전 도달 반경 (짧은 변 절반=0.5 기준). 셰이더 outer_radius.
## 1.05+ 권장 — 코너 너머에서 풀 도달해야 가장자리 라인이 안 보임.
@export_range(0.0, 2.0, 0.01) var dusk_vignette_outer_radius: float = 1.10
## 거리 1맵일 때 화면 경계 셰이크 진폭(px). shake_intensity_mult가 곱해진다.
@export_range(0.0, 8.0, 0.5) var dusk_warning_shake_amp_distance_1: float = 1.0
## 거리 0맵(도착)일 때 화면 경계 셰이크 진폭(px).
@export_range(0.0, 8.0, 0.5) var dusk_warning_shake_amp_distance_0: float = 2.0
## 한 사이클 시간(초). 4단계 cycle이라 한 단계 = period/4.
@export_range(0.04, 0.5, 0.01) var dusk_warning_shake_period: float = 0.16

# === 땅거미 발자국 (REC-MECH-005 — Pass 5 후속) ===
# 화면 가장자리에서 안쪽으로 침투하는 발자국 5단계.
# 보라색 맥동 경고는 유지(작은 아이콘), 발자국은 공간 자체를 카운터로.
@export_group("Dusk Footprint (REC-MECH-005)")
## 발자국 풀 크기. 5단계 매핑: 거리2=2개/거리1=4개/거리0=5개+안쪽 이동.
@export_range(3, 10, 1) var footprint_pool_size: int = 5
## 발자국 색 — 어두운 보라 (그림자 왕가 팔레트).
@export var footprint_color: Color = Color(0.3, 0.05, 0.5, 1.0)
## 발자국 placeholder 크기 (sprite 도착 시 자동 교체).
@export var footprint_size: Vector2 = Vector2(12.0, 12.0)
## 가장자리 시작 마진(px) — 화면 좌우 안쪽으로 들어옴.
@export var footprint_edge_margin: float = 24.0
## 거리 1일 때 발자국이 안쪽으로 이동하는 추가 픽셀.
@export var footprint_inward_drift: float = 36.0
## 발자국 fade in/out duration.
@export var footprint_fade_duration: float = 0.45

# === UI 감성 (Pass 5 Step 1) ===
@export_group("UI Feedback (Pass 5)")
## 빈사 크랙 임계 HP 비율 (기본 0.20 = HP 20% 이하).
@export_range(0.0, 1.0, 0.01) var hp_crack_threshold: float = 0.20
## 빈사 크랙 최대 알파(풀 밀도 시점).
@export_range(0.0, 1.0, 0.01) var hp_crack_max_alpha: float = 0.85
## HP 변화 시 크랙 알파 Tween 시간(초).
@export var hp_crack_transition_duration: float = 0.25
## 메뉴/씬 전환 디졸브 기본 duration(초).
@export var dissolve_transition_duration: float = 0.30
## 메뉴 진입/퇴장 플래시의 half duration(총 소요=half×2).
@export var dissolve_flash_half_duration: float = 0.15

# === 피니시 컷인 (Pass 5 Step 4) ===
@export_subgroup("Finish Cutin")
## 줌 목표 스케일 (카메라 zoom property는 "배율의 역수" 개념 — 큰 값=당겨옴).
@export var finish_cutin_zoom_target: Vector2 = Vector2(1.4, 1.4)
## 줌 인/아웃 각 단계 duration(초).
@export var finish_cutin_zoom_duration: float = 0.2
## 슬로우모션 time_scale (0.2=극저속).
@export_range(0.0, 1.0, 0.01) var finish_cutin_slowmo_scale: float = 0.2
## 슬로우모션 유지 시간(초, 실시간).
@export var finish_cutin_slowmo_duration: float = 0.4
## 상·하단 블랙바 두께(px, 640×360 기준).
@export var finish_cutin_bar_thickness: float = 16.0

# === 시간 정지 셔터 (REC-FX-001 — Pass 5 후속) ===
# 시간 정지 발동 순간 0.15초 색수차 + 화면 플래시. 코어 메카닉 첫 인상 강화.
@export_group("Time Stop Shutter (REC-FX-001)")
## 셔터 총 지속(초). 0.15s 권장. 0이면 비활성.
@export var shutter_duration: float = 0.15
## 색수차 절정 강도 (UV 단위, 0.02 ≈ ±13px @640). 0이면 색수차 비활성.
@export_range(0.0, 0.05, 0.001) var shutter_chromatic_max: float = 0.020
## 화면 플래시 색.
@export var shutter_flash_color: Color = Color(1.0, 1.0, 1.0, 1.0)
## 화면 플래시 알파. 0이면 플래시 비활성.
@export_range(0.0, 1.0, 0.01) var shutter_flash_alpha: float = 0.35

# === 그림자 강도 비네트 (REC-FX-007 — Pass 5 후속) ===
# DuskWarning 비활성 시에만 표시. 그림자 강도 임계값 이상부터 가장자리 어두움 점진.
@export_group("Shadow Vignette (REC-FX-007)")
## 비네트 색 — 어두운 보라/검정. 그림자 왕가 팔레트와 톤 맞춤.
@export var shadow_vignette_color: Color = Color(0.05, 0.0, 0.10, 1.0)
## 이 강도 이상부터 비네트 점진 시작 (강도 0~1.5 범위 가정).
@export_range(0.0, 1.5, 0.01) var shadow_vignette_threshold: float = 0.50
## 풀 강도(1.5) 도달 시 비네트 알파.
@export_range(0.0, 1.0, 0.01) var shadow_vignette_alpha_max: float = 0.35
## 강도 변화 시 색·알파 Tween 시간(초).
@export var shadow_vignette_transition_duration: float = 0.30

# === 빛 굴절 콤보 (REC-MECH-007 — Pass 5 후속) ===
# 빛 피니시 시 같은 룸 거울에서 빛 빔 반사. 빔 hitbox는 거울 회전 방향 자동 추적.
@export_group("Light Beam (REC-MECH-007)")
## 빛 빔 길이(px). 거울 위치 기준 한 방향.
@export var light_beam_length: float = 320.0
## 빛 빔 두께(px) — hitbox & 시각.
@export var light_beam_width: float = 18.0
## 빔 active 시간(s). 짧을수록 단발 임팩트.
@export var light_beam_active_duration: float = 0.15
## 시각 페이드 시간(s). active_duration보다 약간 길게 권장.
@export var light_beam_fade_duration: float = 0.22
## 빔 데미지 비율 (빛 피니시 데미지의 %). 0.5 = 50%.
@export_range(0.0, 1.0, 0.05) var light_beam_damage_ratio: float = 0.5
## 빔 발광 색 (HDR 클램프 — Polygon2D는 LDR이라 1.0 이내).
@export var light_beam_color: Color = Color(1.0, 0.95, 0.7, 1.0)
## 빔 시작 알파.
@export_range(0.0, 1.0, 0.01) var light_beam_alpha: float = 0.85

# === 잔류 빛줄기 (REC-FX-003 — Pass 5 후속) ===
# 빛 피니시 후 적 위치에 1~2초 발광 잔류. core(밝음) + halo(외곽 페이드).
@export_group("Residual Light (REC-FX-003)")
## 잔류 지속(초). 0보다 큰 값.
@export var residual_light_duration: float = 1.2
## halo 반경(px).
@export var residual_light_halo_radius: float = 22.0
## core 반경(px). halo의 절반 정도 권장.
@export var residual_light_core_radius: float = 10.0
## halo 시작 알파.
@export_range(0.0, 1.0, 0.01) var residual_light_halo_alpha: float = 0.45
## core 시작 알파.
@export_range(0.0, 1.0, 0.01) var residual_light_core_alpha: float = 0.85
## 종료 시점 스케일 배율 (1.0 = 원본 유지, 1.4 = 살짝 퍼짐).
@export var residual_light_end_scale: float = 1.30

# === 접근성 (Phase 5-2에서 UI 노출) ===
@export_group("Accessibility")
## 0.0 = 쉐이크 OFF
@export_range(0.0, 2.0, 0.05) var shake_intensity_mult: float = 1.0
@export var hitstop_enabled: bool = true
## 0.0 = 플래시 OFF
@export_range(0.0, 2.0, 0.05) var flash_intensity_mult: float = 1.0
