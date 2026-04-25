# Phase 4-0 #2 — SkillSystem 실행 파이프라인 상세 스펙

> 상위 로드맵: [`PHASE_4_0_ENGINE_HARDENING.md`](../PHASE_4_0_ENGINE_HARDENING.md) §4.2
> 관련: [`SKILLS.md`](../SKILLS.md) / [`COMBAT_SYSTEM_REFACTOR.md`](COMBAT_SYSTEM_REFACTOR.md)
> 작성일: 2026-04-24
> 상태: Step 분할 확정, 착수 대기

---

## 1. 목표

> *"`data/skills/new_skill.tres` 1개만 만들면 → 슬롯 장착·입력·쿨다운·자원 소모·CombatSystem 위임까지 코드 수정 없이 자동화."*

Phase 4-0 완료 게이트(§8 검증 시나리오 1번 = 가짜 스킬 1개 .tres로만 슬롯 발동 성공)를 본 Phase에서 달성한다.

---

## 2. 현재 상태 (2026-04-24)

Step 2.5 (`f87ecf9`) 이후 실행 파이프라인 70%가 [player_skill.gd](../../src/entities/player/player_skill.gd)에 선제 배치되어 있음.

**이미 동작**: 입력 → 슬롯/쿨다운/자원 체크 → AttackSpec(rect/circle) → `CombatSystem.request_attack` → `skill_used` emit / melee·aoe 두 타입.

**결핍**:
- `effect_type = "projectile" | "buff" | "custom"` 분기 0
- `SkillData.custom_script: GDScript` 필드 없음
- `SkillData.projectile_scene: PackedScene` 필드 없음
- `skill.path → AttackSpec.attribute` 직결 미실시 ([player_skill.gd:78](../../src/entities/player/player_skill.gd#L78) `"none"` 하드코딩)
- `SKILL_PATHS` 하드코딩 배열 ([skill_system.gd:11-14](../../src/systems/skill/skill_system.gd#L11-L14)) — 새 .tres 추가 시 코드 수정 필요
- Executor 분리 부재 — 향후 타입 증가 시 player_skill이 비대화

---

## 3. 결정 사항 (2026-04-24 확정)

| # | 결정 | 사유 |
|---|---|---|
| D1 | 실행 본체 = `SkillSystem.execute(slot, caster)` + 내부 `SkillExecutor` + `effect_handlers/*.gd` | PHASE_4_0 §4.2 스펙대로. 타입별 격리로 유지보수성 확보 |
| D2 | `projectile_scene`은 `SkillData`에 필드 추가 (별도 리소스 분리 X) | 1 .tres 원칙. 추후 공유 씬은 preload로 처리 |
| D3 | `buff_handler`는 본 Phase에서 `EventBus.skill_buff_requested` emit stub + TODO. BuffSystem은 Phase 4-E | 본 Phase 범위 = 실행 파이프라인만 |
| D4 | `skill.path`(`light`/`shadow`/`hybrid`) → `AttackSpec.attribute`에 직접 매핑. 별도 공격속성 필드 미도입 | 오버엔지니어링 회피. neutral은 콤보 전용 |
| D5 | `SKILL_PATHS` 하드코딩 제거 → `DirAccess`로 `data/skills/*.tres` 런타임 스캔 | Phase 4-0 완료 게이트 달성 필수 |
| D6 | 실패 시(쿨다운 중/자원 부족/빈 슬롯) silent return 유지. 선택적으로 `skill_use_failed(slot, reason)` 시그널만 emit — HUD 구독은 Pass 5 | UI 피드백 범위 분리 |
| D7 | `caster` 인자는 공개 API에 명시하되 현재는 Player 고정 (NPC 스킬은 Forest 설계 밖) | 향후 확장 여지만 남김 |

---

## 4. 목표 구조

### 4.1 파일 트리

```
src/systems/skill/
├── skill_system.gd              (수정: execute() 추가, _load_skills 자동 스캔)
├── skill_slot_manager.gd        (변경 없음)
├── skill_attribute_resolver.gd  (변경 없음)
├── skill_executor.gd            (신규 ~80줄, class_name SkillExecutor)
├── skill_custom_base.gd         (신규 ~20줄, class_name SkillCustomBase)
└── effect_handlers/
    ├── skill_handler_melee.gd       (~40줄)
    ├── skill_handler_aoe.gd         (~35줄)
    ├── skill_handler_projectile.gd  (~45줄)
    └── skill_handler_buff.gd        (~25줄, stub)

data/skills/
└── skill_data.gd                (수정: enum 확장 + 필드 2개 추가)

src/entities/player/
└── player_skill.gd              (116줄 → ~45줄)
```

### 4.2 Public API

```gdscript
# SkillSystem (신규 API)
func execute(slot_index: int, caster: Node) -> bool
    # 성공 시 true. 실패(빈 슬롯/쿨다운/자원 부족) 시 false + skill_use_failed emit (D6).

# SkillData (확장 필드)
@export_enum("melee", "aoe", "projectile", "buff", "custom") var effect_type: String = "melee"
@export var projectile_scene: PackedScene = null  # projectile 전용
@export var custom_script: GDScript = null        # custom 전용
```

### 4.3 Handler 계약

모든 핸들러는 동일 시그니처:

```gdscript
# src/systems/skill/effect_handlers/skill_handler_*.gd
# class_name 없음 (preload 사용)
static func handle(skill: SkillData, ctx: Dictionary) -> void
```

`ctx` Dictionary 키 (StringName 상수):
- `"caster"` : Node (일반적으로 Player CharacterBody2D)
- `"movement"` : Node (facing_direction 접근용, nullable)
- `"sprite"` : AnimatedSprite2D (애니메이션 훅용, nullable)
- `"slot_index"` : int

핸들러 책임:
- 타입별 Spec(`AttackSpec`/`ProjectileSpec`) 빌드 → `CombatSystem.request_*` 호출
- 반환값 없음(수명은 CombatSystem 소유). `_cancel_current_attack` 안전장치는 player_skill이 유지

### 4.4 SkillExecutor 책임

```gdscript
# skill_executor.gd (의사 코드)
static func execute(skill: SkillData, ctx: Dictionary) -> bool:
    # 1. 자원 체크 (TimeSystem.get_resource_data)
    # 2. time_cost 소비 요청 (EventBus.time_resource_consume_flat_requested)
    # 3. 쿨다운 시작 (SkillSystem.start_cooldown)
    # 4. effect_type 분기 → 해당 handler.handle(skill, ctx)
    # 5. _play_skill_animation (ctx.sprite 기반)
    # 6. EventBus.skill_used emit
    # 7. return true
```

슬롯 유효성/쿨다운 체크는 `SkillSystem.execute()` 진입점에서 수행(기존 `can_use_skill` 재사용).

### 4.5 SkillCustomBase 계약

```gdscript
# skill_custom_base.gd
class_name SkillCustomBase
extends RefCounted

## 상속 필수. Dictionary ctx는 handler와 동일 스키마 + skill 인스턴스 포함.
func execute(skill: SkillData, ctx: Dictionary) -> void:
    push_error("SkillCustomBase.execute() must be overridden")
```

`skill_handler_custom.gd`는:
```gdscript
var inst: SkillCustomBase = skill.custom_script.new()
inst.execute(skill, ctx)
```

---

## 5. 단계별 마이그레이션

각 Step은 **독립 회귀 테스트 가능**. 커밋 단위도 동일.

### Step 1 — SkillData 스키마 확장 (회귀 0)

**변경**
- [data/skills/skill_data.gd](../../data/skills/skill_data.gd):
  - `effect_type`에 `@export_enum("melee","aoe","projectile","buff","custom")` 주석 갱신
  - `@export var projectile_scene: PackedScene = null` 추가
  - `@export var custom_script: GDScript = null` 추가

**기존 2 .tres(`light_slash`/`shadow_strike`)**: 필드 값 변경 없음. 새 필드는 기본값 사용.

**검증**: `--editor --headless --quit`로 스키마 캐시 갱신 → `--headless --quit` 로드 에러 0.

### Step 2 — Executor + Handlers scaffolding (회귀 0)

**신규**
- `src/systems/skill/skill_executor.gd` (class_name `SkillExecutor`)
- `src/systems/skill/skill_custom_base.gd` (class_name `SkillCustomBase`)
- `src/systems/skill/effect_handlers/skill_handler_melee.gd`
- `src/systems/skill/effect_handlers/skill_handler_aoe.gd`
- `src/systems/skill/effect_handlers/skill_handler_projectile.gd` (미완 — Step 4에서 실장)
- `src/systems/skill/effect_handlers/skill_handler_buff.gd` (stub)

**수정**
- [skill_system.gd](../../src/systems/skill/skill_system.gd):
  - `const ExecutorScript = preload(...)`
  - `func execute(slot_index: int, caster: Node) -> bool` 공개 API 신설
  - 내부 ctx 구축 시 `caster.get_node_or_null("MovementComponent")` / `caster.get_node_or_null("AnimatedSprite2D")` 사용

**호출자 0**: 이 Step은 API만 신설. player_skill은 Step 3에서 전환.

**검증**: `--headless --quit` 로드 에러 0. gdlint/gdformat clean.

### Step 3 — player_skill.gd 축소 + SKILL_PATHS 자동 스캔 (회귀 중)

**변경**
- [player_skill.gd](../../src/entities/player/player_skill.gd): 116줄 → ~45줄
  - 입력 읽기 + `SkillSystem.execute(slot_index, _parent)` 위임
  - `_cancel_current_attack` 안전장치 유지 (player_died 구독)
  - 단, `_current_attack_area`는 handler가 반환하지 않으므로 **제거 또는 EventBus 경유로 전환**
  - 결정: **제거**. attack_requests 큐가 이미 관리(Step 2 base_enemy 패턴). 사망 시 잔존 히트 위험은 `CombatSystem.cancel_player_attacks()` 신규 API로 일괄 처리 또는 현 큐에서 자동 만료로 충분한지 검증 후 결정.
  - 구현 판단: 현재 콤보(player_combo) 쪽도 같은 상황에서 유지되는지 확인 후 통일.
- [skill_system.gd](../../src/systems/skill/skill_system.gd) `_load_skills`:
  - 하드코딩 배열 제거
  - `DirAccess.open("res://data/skills/")`로 `.tres` 스캔
  - 로드 실패/클래스 불일치는 `push_warning` 후 스킵
  - `skill_data.gd`(클래스 정의)는 .gd 확장자라 자동 제외

**실게임 검증 포인트**
- U → light_slash: 데미지/피격 파티클/쿨다운 UI
- I → shadow_strike: AoE → 다수 적 동시 데미지
- 빈 슬롯(O/P) 입력 → 무동작
- 쿨다운 중 재입력 → 무동작
- 데미지 넘버/힛스톱/플래시 모두 정상
- 이중 히트박스 미발생

**검증**: 수동 플레이 + `--headless --quit`.

### Step 4 — projectile/buff/custom 실장 + 임시 .tres 검증 (회귀 0)

**projectile_handler**
- `ProjectileSpec` 빌드 → `CombatSystem.request_projectile(spec)`
- `spawn_position` = `caster.global_position + facing offset`
- `direction` = `Vector2(movement.facing_direction, 0)`
- `scene` = `skill.projectile_scene`
- 씬 없으면 `push_warning` 후 스킵

**buff_handler (stub)**
- `EventBus.skill_buff_requested.emit(skill.id, skill.active_duration)` (시그널 신규 추가 필요 시 EventBus에 선언)
- **결정**: 본 Phase에서는 EventBus에 신규 시그널 추가하지 않고 `push_warning("buff not yet implemented — Phase 4-E")` 유지. 스킬 발동 자체(애니/쿨다운/자원소모)는 정상 처리.

**custom_handler**
- `skill.custom_script == null` 시 `push_warning` + 스킵
- 정상 시 `inst := skill.custom_script.new(); inst.execute(skill, ctx)`

**검증용 임시 .tres 3개 생성 → 슬롯 장착 → 발동 → 정상 동작 확인 → 삭제(커밋하지 않음)**

### Step 5 — skill.path → spec.attribute 전달 (회귀 소)

**변경**
- `skill_handler_melee.gd`/`skill_handler_aoe.gd`:
  - `spec.attribute = skill.path` (값은 이미 `light`/`shadow`/`hybrid` 중 하나)
  - 단, `SkillData.path`에 "neutral"은 허용 안 됨 → AttackSpec enum에는 존재 → 스킬에선 전달 안 됨 (정상)
- [player_skill.gd:78](../../src/entities/player/player_skill.gd#L78)의 TODO 주석 제거

**영향**
- `damage_resolver._apply_effects`에서 속성별 피격 파티클/플래시 색상 분기가 **스킬 타격 시에도** 작동 시작
- 현재 테스트 2스킬(`light_slash`/`shadow_strike`)에서 체감 변화 발생 → 사용자 확인

---

## 6. 검증 방법

### 헤드리스
- `--editor --headless --quit` (신규 class_name 캐시 갱신: Step 2 후 1회 필수)
- `--headless --quit` 로드 에러 0 (각 Step 후)

### 정적 분석
- `gdlint` 수정·신규 파일 전체 clean
- `gdformat --check` 수정·신규 파일 전체 clean

### 수동 플레이 체크리스트 (Step 3·5 후)
- [ ] U(slot 0) 발동 시 데미지 + 쿨다운 + 피격 연출
- [ ] I(slot 1) AoE 발동 시 다수 적 동시 데미지
- [ ] O/P 빈 슬롯 무동작
- [ ] 쿨다운 중 재입력 무동작
- [ ] 시간 자원 부족 시 무동작
- [ ] 이중 히트박스 미발생 (Step 2.5 회귀 방지)
- [ ] 플레이어 사망 시 잔존 히트박스 안전 해소
- [ ] (Step 5 후) light 스킬 피격 = 노란 파티클, shadow 스킬 피격 = 보라 파티클

### Phase 4-0 완료 게이트 검증 (Step 4 후)
- [ ] 새 `.tres` 1개(예: `data/skills/_test_projectile.tres`) 드롭 → **코드 수정 없이** 자동 등록 → 슬롯 장착·발동 성공
- [ ] 확인 후 `_test_projectile.tres` 삭제

---

## 7. 위험 / 완화

| 위험 | 완화 |
|---|---|
| `_load_skills` 자동 스캔이 `skill_data.gd`(스키마 파일) 로드 시도 | `.tres` 확장자 필터 + `is SkillData` 타입 체크 |
| 커스텀 스크립트가 무한 루프/예외 던지기 | `inst.execute` 실패 시 `push_error`로 노출. try/catch 미도입(GDScript는 예외 전파) |
| Step 3에서 `_current_attack_area` 제거가 잔존 히트 유발 | `attack_requests` 큐의 자동 만료 + `EventBus.player_died` 경로 재검토. 필요 시 `CombatSystem.cancel_attacks_by_source(group)` API 추가 |
| projectile 씬 누락 | `push_warning` + 스킬 발동 실패 반환(쿨다운/자원 소모 롤백은 하지 않음 — 사용자 실수는 에디터에서 즉시 가시화) |
| 자동 스캔이 장래 `data/skills/`에 서브폴더 추가 시 누락 | 재귀 스캔 대신 단일 폴더 규약. 서브폴더 필요해지면 스펙 갱신 |

---

## 8. Phase 4-0 #3(속성 피니시)와의 경계

- #2는 **스킬 실행 파이프라인**만. 콤보 4타 피니시는 #3의 전담 영역.
- `SkillData.path == "hybrid"`인 스킬은 실행 시 `spec.attribute = "hybrid"`로만 전달되며, **피니시 분기와는 무관**(피니시는 콤보 4타에만 적용).
- `finish_attribute_changed` 시그널은 본 Phase에서 사용처 추가 없음 (#3 범위).

---

## 9. 미결 사항

- [ ] Step 3 `_current_attack_area` 안전장치의 정확한 처리 방식 — 실측 후 결정
- [ ] `skill_use_failed` 시그널 도입 여부 — 본 Phase에선 보류, Pass 5에서 HUD 피드백과 함께 결정
- [ ] projectile 스킬의 기본 씬 선택 가이드 — Phase 4-E 16개 스킬 제작 시 결정
