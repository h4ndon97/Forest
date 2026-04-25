class_name EffectCue
extends Resource

## 타임라인 내 단일 이펙트 발사 1건 = "언제, 무엇을, 어떤 파라미터로".
## 실행 분기는 EffectsTimelineDispatch가 담당, 본 Resource는 데이터만 보유.
## 스펙: docs/refactor/EFFECT_TIMELINE_SPEC.md §2.2.

@export var offset_sec: float = 0.0
@export_enum(
	"hit_flash", "shake", "hitstop", "screen_flash", "afterimage", "hit_particle", "event_emit"
)
var cue_type: String = "hit_flash"

# === 공통 게이트 ===
## 실행 전 확인 조건. 빈 문자열이면 무조건 실행. 예: "is_finish", "attribute==light".
@export var condition: String = ""
## 활성화 확률 (0.0~1.0). 1.0=항상.
@export_range(0.0, 1.0, 0.01) var probability: float = 1.0

# === 타입별 파라미터 (해당 cue_type만 읽음) ===

@export_group("Hit Flash")
## -1.0이면 config.default_flash_duration 사용.
@export var flash_duration: float = -1.0
## alpha==0.0이면 config.default_flash_color 사용(또는 flash_use_finish_color 경로).
@export var flash_color: Color = Color(0, 0, 0, 0)
## "context.target" 외 중첩 키 허용. 빈 값이면 context.target.
@export var flash_target_path: String = ""
## true면 context.finish_attribute로 EffectsSystem.get_finish_color() 적용.
@export var flash_use_finish_color: bool = false

@export_group("Shake")
@export_enum("light", "medium", "heavy", "finish", "custom", "from_context")
var shake_preset: String = "medium"
## shake_preset == "custom" 시 사용. 0 이하면 무시.
@export var shake_trauma_override: float = -1.0

@export_group("Hitstop")
@export_enum("hit", "critical", "finish", "custom") var hitstop_preset: String = "hit"
@export var hitstop_duration_override: float = -1.0
@export var hitstop_scale_override: float = -1.0

@export_group("Screen Flash")
@export var screen_flash_color: Color = Color(1, 1, 1, 0.6)
@export var screen_flash_duration: float = 0.1
## true면 context.finish_attribute로 EffectsSystem.get_finish_color() 적용 (screen_flash_color 무시).
@export var screen_flash_use_finish_color: bool = false

@export_group("Afterimage")
## -1.0이면 config.time_stop_afterimage_count 사용.
@export var afterimage_count: int = -1
@export var afterimage_interval: float = -1.0
@export var afterimage_fade: float = -1.0
## 빈 값이면 context.afterimage_source 사용.
@export var afterimage_source_path: String = ""

@export_group("Hit Particle")
@export_enum("organic", "mineral", "shadow", "resolve_from_context")
var particle_category: String = "resolve_from_context"
@export var particle_is_finish: bool = false
## 빈 문자열이면 context.finish_attribute 사용.
@export var particle_attribute_override: String = ""

@export_group("Event Emit")
@export var event_name: StringName = &""
## EventBus 시그널 페이로드. Step 1 범위: 단순 형태(string/float/Vector2).
@export var event_args: Array = []
