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

# === 힛 플래시 — 피니시 속성별 (Pass 2에서 사용, Pass 1은 값만 보유) ===
@export_subgroup("Finish Attribute Colors (Pass 2)")
@export var finish_color_light: Color = Color(2.5, 2.5, 2.5, 1.0)
@export var finish_color_dark: Color = Color(1.6, 0.4, 2.2, 1.0)
@export var finish_color_fire: Color = Color(2.5, 1.4, 0.4, 1.0)

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

# === 접근성 (Phase 5-2에서 UI 노출) ===
@export_group("Accessibility")
## 0.0 = 쉐이크 OFF
@export_range(0.0, 2.0, 0.05) var shake_intensity_mult: float = 1.0
@export var hitstop_enabled: bool = true
## 0.0 = 플래시 OFF
@export_range(0.0, 2.0, 0.05) var flash_intensity_mult: float = 1.0
