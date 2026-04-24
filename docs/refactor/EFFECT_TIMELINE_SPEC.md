# 이펙트 타임라인 / Cue Resource 시스템 — 구현 스펙

> **상태**: 설계 확정 (2026-04-22) — 사용자 합의 완료, 권장안 그대로 채택
> **타이밍**: Phase 4-0 #1 CombatSystem 리팩토링과 병행 (Step 1 scaffolding은 #1 어느 단계와도 독립, Step 2 전환은 #1 Step 6 완료 이후)
> **관련 문서**:
> - [EFFECTS.md](../EFFECTS.md) — 이펙트 설계 전문 (Pass 1~4 구현 완료)
> - [refactor/COMBAT_SYSTEM_REFACTOR.md](COMBAT_SYSTEM_REFACTOR.md) — Phase 4-0 #1 상세 스펙
> - [art_specs/effects_pass3_step4_inari_ref.md](../art_specs/effects_pass3_step4_inari_ref.md) — Pass 5 INARI 매핑 (timeline의 향후 적용 대상)

---

## 0. 결정 확정 내역 (2026-04-22)

본 스펙은 Plan 에이전트가 산출한 설계안을 사용자가 권장안 그대로 확정한 것이다.

| ID | 결정 | 채택값 | 비고 |
|---|---|---|---|
| **D1** | Resource 분리 방식 | **B**: `EffectTimeline` + 중첩 `Array[EffectCue]` (sub_resource) | 인스펙터 편집성 + 타입 안전 우선 |
| **D2** | finish id 매핑 위치 | **a**: `damage_resolver` 함수 | 매핑 변경 빈도 보고 b/c로 승격 가능 |
| **D3** | Context 전달 방식 | **Dictionary + 상수 키** | `EffectsTimelinePlayer`에 `const CTX_*` 노출 |
| **D4** | Resource class 파일 위치 | `src/systems/effects/resources/` | 스크립트는 `src/`, 데이터는 `data/` |
| **D5** | Player 구현 | **Node + PROCESS_MODE_ALWAYS** | `EffectsHitstop`/`EffectsAfterimage` 패턴 일관 |
| **D6** | Track(병렬 레인) 도입 | **flat array** (병렬은 동일 offset cue 다수로 표현) | 10+ cue timeline 등장 시 재검토 |
| **D7** | `event_emit` cue 타입 | 포함 | 시간정지 해제 AI 깨움 같은 로직 훅 수용 |
| **D8** | timeline_id 네이밍 | **StringName** | EventBus/preset 컨벤션 일관 |
| **D9** | Step 3 범위 | **time_stop_release만 우선**, 나머지 보류 | 체감 보고 결정 |
| **D10** | 복합 매크로 cue | **미도입** | timeline 자체로 컴포지션 표현 |

**가변성**: 본 결정은 구현 중 명백한 문제가 발견되면 재조정 가능. 단 D1·D5·D6은 구조적 결정이라 변경 비용 큼 — Step 1 산출물 검토 후 잠금.

---

## 1. 개념 다이어그램

```
                         ┌───────────────────────────────────────┐
                         │  EffectTimeline (Resource, .tres)     │
                         │  ─ 이름, 총 길이, 시간 정지 정책       │
                         │  ─ Array[EffectCue] cues              │
                         └─────────────────────┬─────────────────┘
                                               │ 1..N
                                               ▼
                         ┌───────────────────────────────────────┐
                         │  EffectCue (Resource, .tres)          │
                         │  ─ offset_sec (트랙 위 시작 지점)      │
                         │  ─ cue_type (enum)                    │
                         │  ─ 타입별 파라미터 슬롯                │
                         └─────────────────────┬─────────────────┘
                                               │ 타입별로
                                               ▼
                                 ┌──────────────────────────┐
                                 │  EffectsSystem.request_*  │
                                 │  (기존 API 그대로 재사용)  │
                                 └──────────────────────────┘

       [트리거(호출자)]              [플레이어(러너)]             [버스(기존)]
  CombatSystem.play_fx("finish_light", ctx)
        │
        ▼
  EffectsSystem.request_timeline(timeline_res, ctx)
        │
        ▼
  EffectsTimelinePlayer (Node, child of EffectsSystem)
        │── SceneTreeTimer(ignore_time_scale=true) 다수 예약
        │
        └──▶ (각 cue.offset 도달)──▶ EffectsSystem 내부 dispatcher
                                     ├─ hit_flash  → EffectsHitFlash
                                     ├─ shake      → EventBus.screen_shake_requested
                                     ├─ hitstop    → EffectsHitstop
                                     ├─ screen_flash → OverlaySystem.flash_screen
                                     ├─ afterimage → EffectsAfterimage
                                     └─ hit_particle → EffectsHitParticle
```

### 용어

| 용어 | 정의 |
|---|---|
| **Timeline** | 한 번의 "연출 단위"(피니시 연출, 피격 반응 등). N개 cue를 시간 순서로 담는다. |
| **Cue** | 단일 이펙트 발사(hit_flash, shake 등) + 발사 시점(offset). |
| **Trigger** | 호출처(CombatSystem, SkillSystem, base_enemy 등) — timeline을 이름/리소스로 지정. |
| **Context** | 런타임 인자(target node, world position, finish_attribute 등) — `.tres`에 저장 불가한 값. |
| **Player/Runner** | timeline 1건의 실행을 담당하는 런타임 인스턴스 (cue 큐 + 타이머). |
| **Track** | (장래 확장) 한 timeline 내 병렬 레인. Step 1에서는 도입하지 않음 — D6 결정. |

---

## 2. Resource 스키마

### 2.1 `EffectTimeline` 스키마 (의사 GDScript)

```gdscript
class_name EffectTimeline
extends Resource

## 이펙트 시퀀스 1건. offset 기반 cue 배열.
@export var display_name: String = ""
## 시간 정지 정책 — 이 timeline이 Engine.time_scale/paused 영향을 받는지.
##   "ignore_time_scale": 힛스톱/pause 중에도 진행 (피니시/시간정지 해제 연출이 이쪽)
##   "respect_time_scale": time_scale에 따라 늦춰짐 (앰비언트성 연출, 거의 미사용)
@export_enum("ignore_time_scale", "respect_time_scale") var time_policy: String = "ignore_time_scale"
## 총 예상 길이(참고용, 에디터 시각화/정합성 체크). 실제 실행은 cue offset이 기준.
@export var expected_duration: float = 0.0
## PauseMenu(get_tree().paused=true) 중에도 재생 허용 여부. 기본 false (안전).
@export var allow_during_pause: bool = false
## 시간 순 정렬이 아니어도 플레이어가 내부 정렬. 사용자가 offset을 뒤죽박죽 넣어도 동작.
@export var cues: Array[EffectCue] = []
```

### 2.2 `EffectCue` 스키마 (의사 GDScript)

```gdscript
class_name EffectCue
extends Resource

## cue 1건 = "언제, 무엇을, 어떤 파라미터로" 발사.
@export var offset_sec: float = 0.0
@export_enum(
    "hit_flash", "shake", "hitstop",
    "screen_flash", "afterimage", "hit_particle",
    "event_emit"
) var cue_type: String = "hit_flash"

# --- 공통 강도/게이트 ---
## 이 cue 실행 전에 확인할 조건. 예: "is_finish", "attribute==light".
## 빈 문자열이면 무조건 실행.
@export var condition: String = ""
## 다수 인스턴스 모드에서 활성화 확률 (0.0~1.0). 1.0 = 항상.
@export_range(0.0, 1.0, 0.01) var probability: float = 1.0

# --- 타입별 파라미터 (하나의 cue는 해당 타입 필드만 읽음) ---
@export_group("Hit Flash")
@export var flash_duration: float = -1.0      # -1 = config 기본값
@export var flash_color: Color = Color(0, 0, 0, 0)  # alpha==0 → config.default_flash_color
## "context.target" | "context.extra.finish_target" 같은 경로. 빈 값 → context.target.
@export var flash_target_path: String = ""
## true면 context의 finish_attribute로 color 덮어쓰기 (기존 get_finish_color 경로 재사용).
@export var flash_use_finish_color: bool = false

@export_group("Shake")
@export_enum("light", "medium", "heavy", "finish", "custom") var shake_preset: String = "medium"
@export var shake_trauma_override: float = -1.0  # custom이면 이 값 사용

@export_group("Hitstop")
@export_enum("hit", "critical", "finish", "custom") var hitstop_preset: String = "hit"
@export var hitstop_duration_override: float = -1.0
@export var hitstop_scale_override: float = -1.0

@export_group("Screen Flash")
@export var screen_flash_color: Color = Color(1, 1, 1, 0.6)
@export var screen_flash_duration: float = 0.1

@export_group("Afterimage")
@export var afterimage_count: int = -1
@export var afterimage_interval: float = -1.0
@export var afterimage_fade: float = -1.0
@export var afterimage_source_path: String = "" # 빈 값 → context.afterimage_source

@export_group("Hit Particle")
@export_enum("organic", "mineral", "shadow", "resolve_from_context") var particle_category: String = "resolve_from_context"
@export var particle_is_finish: bool = false
## 빈 문자열 → context.finish_attribute 사용.
@export var particle_attribute_override: String = ""

@export_group("Event Emit")
@export var event_name: StringName = &""
## EventBus 시그널 페이로드. 단순 형태만 (string/float/Vector2). 복합은 Step 2+ 이월.
@export var event_args: Array = []
```

### 2.3 설계 노트

- **태그 유니언 방식 (`cue_type` + 타입별 그룹)**: Godot Resource에는 sealed union이 없으므로 모든 필드를 한 Resource에 담고 type별로 읽는 그룹을 분기. CLAUDE.md 300줄 제한에 맞게 `EffectCue`는 의도적으로 **데이터만**(30~60줄), 실행 분기는 `EffectsTimelinePlayer`가 담당.
- **`-1.0` sentinel**: 기존 `request_afterimage(-1)` 패턴 그대로. config 기본값 폴백을 cue 파라미터 레벨까지 일관 유지.
- **Array[EffectCue]**: Godot 4의 typed array는 Resource 배열도 sub_resource로 깔끔히 기록된다.

---

## 3. Cue 종류 정의

### 3.1 1차 타입 (EffectsSystem의 7개 API에 1:1 매핑)

| cue_type | 매핑 API | context 요구 |
|---|---|---|
| `hit_flash` | `request_hit_flash(target, color, dur)` | `context.target` (CanvasItem). `flash_target_path`로 nested 조회 가능 |
| `shake` | `request_shake(preset)` / `request_shake_amount(trauma)` | 없음 |
| `hitstop` | `request_hitstop(preset)` / `request_hitstop_duration(dur, scale)` | 없음 |
| `screen_flash` | `request_screen_flash(color, dur)` | 없음 |
| `afterimage` | `request_afterimage(source, count, interval, fade)` | `context.afterimage_source` (Node2D). 또는 `source_path` |
| `hit_particle` | `request_hit_particle(world_pos, category, is_finish, attr)` | `context.world_pos`, `context.finish_attribute` |
| `event_emit` | EventBus.`<event_name>`.emit(args...) | 없음 |

### 3.2 복합 cue: 도입하지 않음 (D10 확정)

- 현재 복합은 **timeline 자체로 표현됨** — macro cue는 timeline-of-cues를 cue로 압축한 것이라 의미 중복.
- 단계 축소가 필요하면 timeline를 그대로 정의하면 되고, "한 줄로 피니시" 편의는 이름 있는 timeline 리소스(`finish_light.tres`) 자체가 제공.

### 3.3 `event_emit`의 존재 이유 (D7 확정)

기존 `request_*` 7개로는 "시간정지 해제 창에서 0.3초 후 AI 깨움 시그널" 같은 비이펙트-신호를 표현 못 한다. `event_emit` cue는 timeline 안에서 게임로직 훅을 시간축에 넣는 **탈출구** — 단, 남용 방지를 위해 Step 1에서는 **페이로드 단순형**(문자열/float/Vector2) 한정.

---

## 4. EffectsSystem 통합 방식

### 4.1 신규 API

```gdscript
## EffectsSystem.gd 내 신규 메서드 (기존 request_* 와 동급).
## timeline 1건을 재생하고 핸들(Player 인스턴스)을 반환한다.
func request_timeline(timeline: EffectTimeline, context: Dictionary = {}) -> EffectsTimelinePlayer
func request_timeline_by_id(timeline_id: StringName, context: Dictionary = {}) -> EffectsTimelinePlayer
func cancel_timeline(handle: EffectsTimelinePlayer) -> void
```

두 형태 제공:
- **`request_timeline(timeline_res, ctx)`**: 호출자가 `preload` 또는 `@export` Timeline을 직접 넘김 (CombatSystem config 같은 상위 Resource가 필드에 Timeline을 보유).
- **`request_timeline_by_id(&"finish_light", ctx)`**: 런타임 문자열로 조회 — 이름→`.tres` 매핑은 `EffectsTimelineRegistry`(§8)가 담당. 속성 피니시처럼 런타임에 선택 분기가 필요한 곳에 적합.

### 4.2 Context Dictionary 스키마 (D3 확정)

| 키 | 타입 | 의미 | 기본값 |
|---|---|---|---|
| `target` | Node (CanvasItem) | 힛플래시 타겟. enemy sprite 등 | null |
| `world_pos` | Vector2 | 파티클/번호 스폰 위치 | Vector2.ZERO |
| `afterimage_source` | Node2D | 잔상 소스(보통 AnimatedSprite2D) | null |
| `finish_attribute` | String | "light" / "shadow" / "hybrid" / "neutral" | "" |
| `is_finish` | bool | 피니시 여부 (cue condition에서 참조) | false |
| `extra` | Dictionary | cue별 임의 확장 (예: `extra.direction`) | {} |

키는 `EffectsTimelinePlayer` 스크립트에 `const CTX_TARGET := &"target"` 등으로 노출해 오타 방지.

### 4.3 기존 `request_*` API와의 관계

**하위 호환 100% 유지**. 3층 관계:

```
┌─────────────────────────────────────────────────────┐
│  Layer 3 (신규): request_timeline(timeline, ctx)     │ ← Step 2+ 클라이언트
├─────────────────────────────────────────────────────┤
│  Layer 2 (기존): request_hit_flash/shake/...         │ ← Step 1 이후 점진 마이그레이션
├─────────────────────────────────────────────────────┤
│  Layer 1 (기존): EffectsHitFlash/EffectsHitstop/...  │ ← 변경 없음
└─────────────────────────────────────────────────────┘
```

- Layer 3은 Layer 2를 호출 (중복 분기 방지).
- Layer 2는 Layer 1 헬퍼를 직접 호출 (기존 그대로).
- Layer 2 API는 **영구 보존**. 일부 호출처(예: `player_health.gd`의 피격 반응)는 단일 cue + 1회성이라 timeline으로 감싸는 가치가 낮다 — Layer 2로 남긴다.

### 4.4 점진 마이그레이션 원칙

1. **Step 1**: Layer 3 스캐폴딩 — 호출자 0. 레거시 코드 변경 없음.
2. **Step 2**: `damage_resolver._apply_effects` 1곳을 timeline 호출로 교체 (피니시 연출 `finish_light/shadow/hybrid/neutral.tres` 4종 신규).
3. **Step 3**: `EffectsTimeStop._trigger_release_fx` (D9: `time_stop_release`만 우선).
4. 각 마이그레이션은 **독립 커밋**. 롤백 단위 명확화.

---

## 5. Player/Runner 헬퍼 구조

### 5.1 결정 (D5): **Node + PROCESS_MODE_ALWAYS**

- EffectsSystem(Autoload Node)의 자식으로 `add_child`.
- 완료 시 자동 `queue_free`. 취소는 `queue_free()`로 단일화.
- RefCounted 헬퍼 패턴을 위반하지 않는다 — 기존 헬퍼(RefCounted)는 "상태 없는 실행기"이고, Player는 "상태 보유 + 생명주기 있는 실행 인스턴스"라 역할이 다르다.

### 5.2 타이머/트윈 전략

| 시나리오 | 메커니즘 |
|---|---|
| cue offset 스케줄링 | `SceneTreeTimer(delay, process_always=true, ignore_time_scale=<policy>)` cue마다 1개 |
| 힛플래시 Tween | 기존 `EffectsHitFlash.play()`가 내부 Tween — 그대로 재사용 |
| 스크린플래시 Tween | `OverlaySystem.flash_screen()` 내부 Tween — 그대로 재사용 |
| cue condition 평가 | cue firing 시점에 player가 ctx와 cue.condition을 조회 |

즉 Player 자체는 **Tween을 직접 만들지 않는다**. offset 타이머만 관리하고, 타이머 도달 시 EffectsSystem의 기존 Layer 2 API를 호출 → Layer 2가 내부에서 Tween 생성.

### 5.3 시간 정지 정책

`EffectTimeline.time_policy`에 따른 분기:

| 값 | 동작 | 용도 |
|---|---|---|
| `ignore_time_scale` (기본) | 모든 cue timer가 `ignore_time_scale=true`. 힛스톱/pause 중에도 정확히 offset 발화. | 피니시 연출, 시간정지 해제 |
| `respect_time_scale` | timer `ignore_time_scale=false`. hitstop 중 실질 정지, time_scale 느림 시 늘어짐. | (현재 사용처 없음. 미래 앰비언트성 연출용 예약) |

`get_tree().paused=true`(PauseMenu) 중에는 `EffectTimeline.allow_during_pause=false`(기본)이면 Player가 즉시 `queue_free`. 안전 기본값.

### 5.4 동시 재생 관리

- 같은 timeline을 단시간에 여러 번 호출해도 **각 호출이 독립 Player**. 중첩 실행.
- **상한**: EffectsSystem에 `const MAX_CONCURRENT_TIMELINES := 8` 등 하드 리밋. 초과 시 가장 오래된 Player를 `queue_free`.
- **동일 cue 중첩**: 예를 들어 피니시 2번 연속 → shake finish가 겹침. 이는 기존 `EffectsHitstop`/`EffectsHitFlash`가 이미 중첩 정책(누적 금지, 갱신)을 각자 구현 → Player는 단순 위임, 자연스럽게 올바른 결과.
- **취소 시맨틱**: `cancel_timeline(handle)` → Player `queue_free`. 이미 발화한 이펙트는 취소 불가(위임됐으므로). 남은 미발화 cue 타이머만 무효화.

### 5.5 Player 내부 구조 (의사 GDScript, ~120줄 예상)

```gdscript
class_name EffectsTimelinePlayer
extends Node

const CTX_TARGET := &"target"
const CTX_WORLD_POS := &"world_pos"
const CTX_AFTERIMAGE_SOURCE := &"afterimage_source"
const CTX_FINISH_ATTRIBUTE := &"finish_attribute"
const CTX_IS_FINISH := &"is_finish"
const CTX_EXTRA := &"extra"

var _host: Node  # EffectsSystem
var _timeline: EffectTimeline
var _context: Dictionary
var _pending_timers: Array = []  # 미발화 SceneTreeTimer 참조 (취소용)

func setup(host: Node, timeline: EffectTimeline, ctx: Dictionary) -> void:
    _host = host
    _timeline = timeline
    _context = ctx
    process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
    if get_tree().paused and not _timeline.allow_during_pause:
        queue_free()
        return
    _schedule_cues()

func _schedule_cues() -> void:
    var ignore_ts: bool = _timeline.time_policy == "ignore_time_scale"
    var sorted_cues: Array = _timeline.cues.duplicate()
    sorted_cues.sort_custom(func(a, b): return a.offset_sec < b.offset_sec)
    var max_offset: float = 0.0
    for cue in sorted_cues:
        max_offset = maxf(max_offset, cue.offset_sec)
        if cue.offset_sec <= 0.0:
            _fire_cue(cue)
        else:
            var timer := get_tree().create_timer(cue.offset_sec, true, false, ignore_ts)
            timer.timeout.connect(_fire_cue.bind(cue))
            _pending_timers.append(timer)
    # 모든 cue 종료 후 자신 해제 (max_offset + 여유)
    var cleanup := get_tree().create_timer(max_offset + 1.0, true, false, ignore_ts)
    cleanup.timeout.connect(queue_free)

func _fire_cue(cue: EffectCue) -> void:
    if not _check_condition(cue):
        return
    if cue.probability < 1.0 and randf() > cue.probability:
        return
    # cue_type에 따라 EffectsSystem Layer 2 API 디스패치
    match cue.cue_type:
        "hit_flash": _fire_hit_flash(cue)
        "shake":     _fire_shake(cue)
        "hitstop":   _fire_hitstop(cue)
        # ... (타입별 분기, 각 5줄 내외)
```

300줄 이내 유지를 위해 cue 디스패치가 너무 커지면 **`effects_timeline_dispatch.gd` 정적 헬퍼**로 분리(Step 1 말미 판단).

---

## 6. CombatSystem 통합 지점

### 6.1 Phase 4-0 #1 리팩터링과의 정합

Phase 4-0 #1은 `damage_resolver.gd`가 타격 시 이펙트 체인을 발화하는 구조로 수렴한다([COMBAT_SYSTEM_REFACTOR.md](COMBAT_SYSTEM_REFACTOR.md) §4.5). 타임라인은 **damage_resolver의 이펙트 발행 부분을 치환**하는 포지션.

**현재(Pass 2~4 기준)**:
```gdscript
# damage_resolver._apply_effects (현 구현 · 단순화)
_play_target_flash(target, flash_color)
if spec.is_finish:
    EffectsSystem.request_shake(EffectsSystem.PRESET_FINISH)
    EffectsSystem.request_hitstop(EffectsSystem.PRESET_FINISH)
else:
    EffectsSystem.request_shake(EffectsSystem.PRESET_LIGHT)
    EffectsSystem.request_hitstop(EffectsSystem.PRESET_HIT)
EffectsSystem.request_hit_particle(world_pos, category, spec.is_finish, spec.attribute)
```

**타임라인 적용 후**:
```gdscript
# damage_resolver._apply_effects (Step 2 전환)
var timeline_id: StringName = _resolve_timeline_id(spec)  # "hit_normal" / "finish_light" 등
var ctx := {
    &"target": _resolve_flash_target(target),
    &"world_pos": (target as Node2D).global_position + _DAMAGE_NUMBER_OFFSET,
    &"finish_attribute": spec.attribute,
    &"is_finish": spec.is_finish,
    &"afterimage_source": _resolve_afterimage_source(target),
}
EffectsSystem.request_timeline_by_id(timeline_id, ctx)
```

### 6.2 타임라인 ID 매핑 (D2 확정 — damage_resolver 함수)

| spec 조건 | timeline_id | `.tres` 경로 |
|---|---|---|
| `is_finish=false`, `attribute in {none, neutral}` | `hit_normal` | `data/effects/timelines/hit_normal.tres` |
| `is_finish=true`, `attribute=light` | `finish_light` | `data/effects/timelines/finish_light.tres` |
| `is_finish=true`, `attribute=shadow` | `finish_shadow` | `data/effects/timelines/finish_shadow.tres` |
| `is_finish=true`, `attribute=hybrid` | `finish_hybrid` | `data/effects/timelines/finish_hybrid.tres` |
| `is_finish=true`, `attribute=neutral` | `finish_neutral` | `data/effects/timelines/finish_neutral.tres` |

매핑 로직은 `damage_resolver` 정적 함수 `_resolve_timeline_id(spec) -> StringName`로 구현. 매핑 변경이 잦아지면 CombatConfigData `Dictionary` export로 승격 (D2 후속).

### 6.3 CombatConfig와의 관계

`data/combat/combat_config.tres` (`CombatConfigData`)는 **데이터 수치**(데미지, 콤보 윈도우) 담당. Timeline은 **연출 수치**(플래시 색, shake trauma, cue offset) 담당 → 독립 폴더/리소스로 분리 (`data/effects/timelines/`). CombatConfig가 timeline 리소스 자체를 참조하지는 않는다(결합도 하향).

### 6.4 CombatSystem 자체는 타임라인 모름

`CombatSystem.request_attack(spec)` API는 변경 없음. 타임라인 호출은 `damage_resolver` 쪽에만 들어간다. 이로써:
- CombatSystem 공개 계약 불변 → Phase 4-0 #1 Step 2~5가 타임라인과 독립 진행 가능.
- damage_resolver는 "이펙트 디스패처" 역할로 명확해짐 — Phase 4-0 #1 Step 6 이동 작업과 동시/직후에 타임라인 전환이 가능하다.

---

## 7. 단계적 도입 계획

### Step 1 — Scaffolding (호출자 0)

**산출물**:
- `src/systems/effects/resources/effect_timeline.gd` (`class_name EffectTimeline`)
- `src/systems/effects/resources/effect_cue.gd` (`class_name EffectCue`)
- `src/systems/effects/effects_timeline_player.gd` (`class_name EffectsTimelinePlayer extends Node`)
- `src/systems/effects/effects_timeline_registry.gd` (`class_name EffectsTimelineRegistry extends RefCounted`) — id→Timeline 매핑 홀더, Autoload 아님 (EffectsSystem이 멤버로 보유)
- `src/systems/effects/effects_timeline_dispatch.gd` (정적 헬퍼, cue→Layer 2 API 분기)
- `data/effects/timelines/` 폴더 생성. `.gitkeep` 또는 placeholder `_readme.md` — **실제 tres는 Step 2에서 작성**
- `EffectsSystem`에 `request_timeline()` / `request_timeline_by_id()` / `cancel_timeline()` 3개 API 추가
- `EffectsDebug` 키 추가: **F3** = 테스트 timeline 1회 재생 (`hit_normal` placeholder)

**검증**:
1. `gdlint` 신규 5파일 클린.
2. `--editor --headless --quit` 캐시 갱신 → `--headless --quit` 로드 클린.
3. F3 누름 → 빈 timeline이라도 "schedule→cleanup→queue_free" 흐름 로그 확인.
4. 기존 F6~F9/F12 이펙트 디버그 키 regression 없음.
5. 이전 호출처(`damage_resolver._apply_effects`, `player_health`, `base_boss` 등) 그대로 — 이펙트 체감 동일.

### Step 2 — 첫 timeline 정의 + damage_resolver 전환

**산출물**:
- `data/effects/timelines/hit_normal.tres` — shake light(0s) + hitstop hit(0s) + particle(0s) + hit_flash(0s)
- `data/effects/timelines/finish_light.tres` — 피니시 속성별 풀 시퀀스 (아래 §7.5 예시)
- `finish_shadow.tres`, `finish_hybrid.tres`, `finish_neutral.tres` 3종
- `damage_resolver._apply_effects` 전환: 직접 `request_*` → `request_timeline_by_id`
- timeline id 매핑 함수 (damage_resolver `_resolve_timeline_id` 정적 함수)

**검증**:
1. 플레이어 → 적 1타: `hit_normal` 재생. 스크린 쉐이크/힛스톱/파티클 체감 기존 동일.
2. 4타 피니시 (속성별): 각 `finish_*` 재생. shake/hitstop/flash 체감 기존 동일 + cue offset 명시 가능성(현재 0s지만 스펙 가능).
3. 기존 스크립트(`base_enemy`, `base_boss`, `enemy_feedback`)는 변경 없음 — damage_resolver 경로만 바뀜.
4. 이전 커밋 revert 없이 timeline .tres만 수정해 튜닝 가능함을 증명 (예: finish_light의 shake offset 2프레임 후로 바꿔 재실행).

### Step 3 — 확산 (D9: time_stop_release만 우선)

**산출물**:
- `data/effects/timelines/time_stop_release.tres` — 현재 하드코딩된 블루 펄스 + 잔상 시퀀스를 timeline화. `EffectsTimeStop._trigger_release_fx` 내부 `request_screen_flash` + `request_afterimage` 2줄 → `request_timeline_by_id(&"time_stop_release", ctx)` 1줄

**보류 (체감 보고 결정)**:
- `data/effects/timelines/player_hit.tres` — player_health 피격 반응
- `data/effects/timelines/light_dash.tres` — Light Dash 잔상

**검증**: time_stop_release 전환 후 F12 디버그 토글 체감 동일 + .tres만 편집해 펄스 색/잔상 수 튜닝 가능.

### Step 4 — 에디터 플러그인 (선택, 추후)

- @tool 스크립트로 timeline 미리보기(cue offset 막대그래프)
- 필요성: Step 3까지 `.tres` 수작업으로 감당되면 보류. cue 수가 10개 넘어가는 timeline이 등장하면 착수.

### 7.5 예시: `finish_light.tres` (개념)

```
EffectTimeline
  display_name: "Finish — Light"
  time_policy: ignore_time_scale
  expected_duration: 0.30
  cues:
    - [0.00s] hit_flash (use_finish_color=true, target=ctx.target)
    - [0.00s] hit_particle (category=resolve_from_context, is_finish=true)
    - [0.03s] shake (preset=finish)    # 약 2프레임 지연
    - [0.07s] hitstop (preset=finish)  # 약 4프레임 지연
    - [0.20s] afterimage (count=-1, source=ctx.afterimage_source)
    - [0.27s] screen_flash (color=<white 0.5>, dur=0.1)
```

현재 호출 순서가 그대로 timeline에 나열되며, offset 숫자 수정만으로 타이밍 튜닝이 가능해진다.

---

## 8. 폴더/파일 구조 (D4 확정)

```
src/systems/effects/
├── effects_system.gd                     # [수정] request_timeline* 3메서드 추가
├── effects_hit_flash.gd                  # 변경 없음
├── effects_hitstop.gd                    # 변경 없음
├── effects_hit_particle.gd               # 변경 없음
├── effects_time_stop.gd                  # [Step 3] _trigger_release_fx 내부만 timeline 호출로 교체
├── effects_freezable.gd                  # 변경 없음
├── effects_afterimage.gd                 # 변경 없음
├── effects_dusk_warning.gd               # 변경 없음
├── effects_debug.gd                      # [수정] F3 키 추가
├── effects_timeline_player.gd            # [신규] ~120줄 (§5.5)
├── effects_timeline_registry.gd          # [신규] ~40줄 (id→Timeline 로드/캐시)
├── effects_timeline_dispatch.gd          # [신규, 선택] cue→Layer 2 분기 정적 헬퍼 (~80줄)
└── resources/
    ├── effect_timeline.gd                # [신규] class_name EffectTimeline (~25줄)
    └── effect_cue.gd                     # [신규] class_name EffectCue (~60줄)

data/effects/
├── effects_config.tres                   # 변경 없음
├── particle_presets.tres                 # 변경 없음
└── timelines/                            # [신규 폴더]
    ├── hit_normal.tres                   # Step 2
    ├── finish_light.tres                 # Step 2
    ├── finish_shadow.tres                # Step 2
    ├── finish_hybrid.tres                # Step 2
    ├── finish_neutral.tres               # Step 2
    └── time_stop_release.tres            # Step 3
```

**특기 사항**:
- Resource 클래스 스크립트는 `src/systems/effects/resources/`에 격리 — 데이터-스크립트 혼재 회피.
- `.tres` 파일은 모두 `data/effects/timelines/`에 수평 나열 (예: 스테이지·보스별 서브폴더는 수 증가 시 추가).
- `EffectsTimelineRegistry`는 Autoload 아님 — EffectsSystem이 `_ready`에서 인스턴스화해 보유 (`EffectsHitstop` 패턴 동일).

---

## 9. 트레이드오프 및 위험

### 9.1 시간 정지 + Tween 기반 timeline

- **위험**: `EffectsHitFlash`·`OverlaySystem.flash_screen`이 내부에서 `create_tween().set_ignore_time_scale(true)` 이미 사용 중. Player가 offset timer로 호출 시점만 늦추면 Layer 2의 Tween이 알아서 처리.
- **완화**: `time_policy=ignore_time_scale` 기본값 유지. `respect_time_scale`은 향후 예약 필드로 두되 Step 1에서 미사용.
- **엣지**: pause 중 timeline 호출 → `get_tree().paused`가 Player의 process_mode와 관계없이 SceneTreeTimer 진행/정지 정책 결정. `process_always=true`로 진행하면 **PauseMenu 중에도 피니시 연출이 나옴** → 원하지 않음. 해결: Player `_ready`에서 `if get_tree().paused and not _timeline.allow_during_pause: queue_free()`. `allow_during_pause` 필드 추가 (기본 false).

### 9.2 다수 동시 timeline 메모리/성능

- **피니시 2회 연속 호출 시**: Player 2개 동시 존재. 각 Player는 ~6개 SceneTreeTimer 보유 → 12개. Godot 4에서 SceneTreeTimer 비용은 무시 가능 수준 (수백 개도 허용).
- **우려**: 잘못된 호출처에서 `request_timeline`을 매 프레임 연속 호출하면 Player 누적 → GC 전까지 메모리 잔여.
- **완화**: `MAX_CONCURRENT_TIMELINES`(기본 8) 상한. 초과 시 가장 오래된 Player `queue_free`. 디버그 빌드에서 상한 초과 시 `push_warning`.

### 9.3 `.tres` 직접 편집 vs 에디터 플러그인

- **초기(Step 1~3)**: 인스펙터 직접 편집. cue 5~7개 timeline은 충분히 감당.
- **위험**: cue offset을 시각적 막대그래프 없이 숫자로만 편집하면 타이밍 감각을 잃기 쉬움.
- **완화**: Step 2 완료 후 사용자 피드백 확인. 필요 시 Step 4에서 @tool 플러그인(단일 TextureRect + 막대 렌더) 200줄 정도로 소화 가능.

### 9.4 Layer 2와 Layer 3의 이중 경로

- **문제**: 같은 이펙트가 두 경로로 호출 가능 → 어느 쪽이 표준인지 혼란.
- **원칙**:
  - **"다단 시퀀스(2+ cue)"는 Layer 3(timeline)**
  - **"즉시 1회 단일 효과"는 Layer 2(`request_*`)**
  - `EffectsDebug` F6~F9 같은 디버그 키는 Layer 2 유지 (테스트 용이성)
- **검증**: Step 3 확산 후 '어디서 Layer 2를 여전히 쓰는지' 리스트업. 단일 호출만 남으면 이중 경로 문제 해소.

### 9.5 Phase 4-0 #1과의 동시 진행

- **위험**: `damage_resolver`가 Phase 4-0 #1 Step 6에서 완성되는데 그 타이밍에 맞춰 timeline을 끼워 넣으면 커밋이 복잡해짐.
- **완화**: timeline Step 2 전환은 **Phase 4-0 #1 Step 6 완료 이후**에 배치. 혹은 Phase 4-0 #1 Step 6 자체에 timeline 전환을 묶어 넣는다(PR 분기). 두 가지 모두 가능 — 사용자 판단.
- **권장**: timeline Step 1 scaffolding은 Phase 4-0 #1 어느 Step과도 독립. 지금 착수 가능. Step 2 전환만 Phase 4-0 #1 Step 6 완료를 기다림.

### 9.6 Resource `.tres` 마이그레이션

- 향후 `EffectCue`에 필드를 추가/삭제하면 기존 `.tres`가 에디터에서 기본값/누락 필드로 로드된다. Godot은 무손실 로드(드롭된 필드 경고만)라 실무 부담 낮음.
- **완화**: Step 1에서 cue 스키마 최대한 넉넉하게 — `Screen Flash`·`Event Emit` 필드를 미사용이어도 미리 추가.

### 9.7 시그널 버스 정책 위반 우려

- `damage_resolver`는 기존 설계에서 EventBus.`hit_flash_requested`/`hitstop_requested`로 전환 예정(Phase 4-0 #1 Step 6).
- timeline 경로에서는 Player가 EffectsSystem Layer 2를 **직접 호출**한다 — Autoload 같은 Autoload 간 호출이라 `feedback_direct_ref_policy.md`의 "Config 읽기·계산 함수 호출" 허용 범주.
- EventBus 시그널화는 Player→EffectsSystem이 아니라, "요청 발행(damage_resolver→timeline) vs 실행(EffectsSystem 내부)"의 발행 축에서만 적용된다. 이중 경계 금지 원칙을 지킨다.

---

## 10. 성공 지표 (Step 2 완료 기준)

1. `damage_resolver._apply_effects`가 10줄 이하 (기존 20줄 → timeline id 해결 + 1회 호출).
2. 피니시 속성 튜닝이 `.tres` 편집만으로 가능 — 코드 커밋 필요 없음.
3. 기존 F6~F9 디버그 키 체감 동일, 4타 피니시 체감 동일.
4. `gdlint` 클린, 헤드리스 로드 클린.
5. "같은 피니시 연출"이 `finish_light.tres` 하나에 한눈에 보이고, 2프레임 shake 지연 등 시간차 구조가 **timeline 편집에서 그대로 눈에 들어옴** (현 분산 호출 대비 최대 개선점).

---

## 11. 변경 이력

| 날짜 | 내용 |
|---|---|
| 2026-04-22 | 초안 작성 (Plan 에이전트 산출 + 사용자 권장안 그대로 확정). D1~D10 결정 완료. 구현 착수 대기 — Phase 4-0 #1과의 일정 조율 후 Timeline Step 1 시작 |
