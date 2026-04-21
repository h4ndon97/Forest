# 시간이 멈춘 숲 — Phase 4-0 엔진 경화 (Engine Hardening)

> 이 문서는 Phase 3 콘텐츠 생산 착수 전, **엔진·시스템 레이어의 구조적 완성**을 위한 로드맵을 정의한다.
> 상위 문서: `DEVELOPMENT_PLAN.md` §Phase 4 / `COMBAT.md` §2·§11 / `SKILLS.md`
> 작성일: 2026-04-21
> **상태**: 로드맵 확정 — 각 Tier 상세 스펙은 착수 직전 `docs/refactor/*.md`로 분할 작성

---

## 1. Phase 포지션

### 1.1 왜 Phase 4-0인가
2026-04-21 수행된 냉정한 프로젝트 평가에서 드러난 현실:

| 레이어 | 완성도 |
|---|---|
| 시스템 인프라 (Autoload 14개) | 85% |
| 엔티티 아키텍처 | 75% |
| **엔티티 콘텐츠 / 게임 데이터 / 아트** | **3~30%** |

**기술적 병목**: 콘텐츠를 양산하려 해도 엔진이 받을 준비가 안 됨 (`CombatSystem` 껍데기, `SkillSystem` 실행 로직 부재, 속성 피니시 미구현). **당면 과제**: 아트·콘텐츠 병목이 실제 1인 개발자 제약이므로, 엔진은 "**`.tres` 하나 만들면 게임에 들어가는 상태**"여야 한다.

즉 Phase 4-0은 **Phase 4(전체 콘텐츠 양산)의 선결 조건**이다. 이 구간이 완성되지 않으면 Phase 4 콘텐츠가 들어가는 족족 `player_*.gd`와 `*_system.gd`에 하드코딩이 누적된다.

### 1.2 Phase 3와의 관계
- Phase 3-7 Pass 5 (슬래시 트레일·피니시 컷인·무적 깜빡임) 등 잔여 이펙트 작업은 **병행 가능**
- Phase 3-8 등 1구역 스프라이트 제작 역시 **병행 가능**
- 단, **Phase 4 콘텐츠 착수 전**에는 Tier 1 3건 완료 필수

### 1.3 진입 조건

| 항목 | 상태 |
|---|---|
| Phase 3-7 Pass 4 Step 3 완료 | ✅ (60232db) |
| IntroSequence Autoload | ✅ (d0128bd) |
| 프로젝트 로드 테스트 통과 | ✅ (ERROR 0 / WARNING 0) |
| 아키텍처 원칙 준수 감사 | ✅ (300줄 초과 2건·gdlint 18건 식별) |
| 문서-구현 정합성 감사 | ✅ (정렬도 25/100 확인) |
| **상위 로드맵 문서화** | **⏳ 본 문서** |

---

## 2. 배경·목적

### 2.1 핵심 가설
> *"아트·콘텐츠는 천천히 진행될 수밖에 없다. 따라서 엔진은 **콘텐츠가 도착하는 속도보다 빨리** 완성되어야 하며, 콘텐츠 도착 시 **코드 수정 없이** 반영되어야 한다."*

### 2.2 성공 정의
Phase 4-0 완료 시 다음 시나리오가 성립해야 한다:

1. 사용자가 `data/skills/new_skill.tres` 1개 만들면 → 게임 스킬 슬롯에 즉시 장착·사용 가능
2. 사용자가 `data/enemies/zone2/*.tres` 4개 만들면 → 2구역 적이 즉시 작동
3. 사용자가 `data/bosses/zone2_boss.tres` 1개 만들면 → 2구역 보스가 페이즈·약점·패턴과 함께 작동
4. 속성 피니시 4종(light/shadow/hybrid/neutral)이 플레이에서 **체감 가능**하게 분기 동작
5. 강화 이동 4종이 플레이에서 사용 가능 (Light Dash 기존 + 3종 신규)

### 2.3 비범위 (이번 Phase에서 하지 않는 것)
- 신규 콘텐츠 생산 (스킬 `.tres`·적·보스·아이템 추가 — Phase 4)
- 아트 자산 제작 (사용자 병목)
- 사운드 시스템 (Phase 3-8 또는 별도)
- UI 추가 (기존 UI로 테스트 가능한 선까지만)

---

## 3. 결정 사항 (2026-04-21 확정)

> 본 Phase의 주요 구조 결정. 세부 수치는 프로토 튜닝 대상.

### A. 속성 피니시 구현 구조 — **Strategy 모듈 분리** ✅
- 속성별 독립 파일(light/shadow/hybrid/neutral)로 분리
- 공통 베이스 `finish_strategy.gd` + 4개 구체 전략
- `player_combo.gd`는 전략 선택·실행만 담당 → 비대화 방지
- [COMBAT.md §2 속성 피니시 거동](COMBAT.md) D1~D5 표 그대로 각 전략에 매핑

### B. SkillData 스키마 — **하이브리드 (기존 스키마 + CUSTOM 탈출구)** ✅
- **기존** [`data/skills/skill_data.gd`](../data/skills/skill_data.gd) 스키마(effect_type: melee/aoe/projectile/buff)는 **유지**
- `effect_type` enum에 `"custom"` 추가 + `custom_script: GDScript` 필드 추가
- 표준 4타입(melee/aoe/projectile/buff)이 18개 예정 스킬의 ~90% 커버
- 특수 스킬(예: HP 교환·시간 역행)만 custom_script 경로로 탈출
- **중요**: SkillSystem 실행 로직 자체가 부재하므로 스키마 확장보다 **엔진 구현이 본체**

### C. 강화 이동 입력 매핑 — **속성 토글형** ✅
- 대시 키는 고정(`ui_dash`), 속성 토글 키 신설(잠정 `Q`, 기존 스킬 슬롯 키맵과 충돌 확인 필요)
- `current_dash_attribute: LIGHT | SHADOW | NEUTRAL` 상태 보유
- 대시 발동 시 (현재 속성 × 해금 여부 × 지상/공중)으로 분기:

| 속성 | 공중 | 지상 | 해금 조건 |
|---|---|---|---|
| NEUTRAL | 기본 대시 | 기본 대시 | 기본 제공 |
| LIGHT | Light Leap (상향 도약) | Light Dash (관통 돌진) | 3구역 / 1구역 보스 |
| SHADOW | Shadow Phase (잠수·통과) | Shadow Step (배후 텔포) | 2구역 / 4구역 보스 |

- 미해금 속성 선택 + 대시 → 기본 대시로 폴백 (UX 일관성)
- UI 피드백: HUD에 현재 속성 아이콘 표시 (Phase 3-7 Pass 5 또는 본 Phase §5에서)

### D. 문서 네이밍·배치 — **`PHASE_4_0_ENGINE_HARDENING.md`** ✅
- 본 문서가 상위 로드맵
- Tier 1 상세 스펙은 `docs/refactor/` 하위 (착수 직전 작성):
  - `docs/refactor/COMBAT_SYSTEM_REFACTOR.md`
  - `docs/refactor/SKILL_EXECUTION_SPEC.md`
  - `docs/refactor/FINISH_ATTRIBUTE_SPEC.md`
- Tier 2/3 상세 스펙은 경량(PR 설명 또는 1페이지 문서)

---

## 4. Tier 1 — 콘텐츠 양산 엔진 (최우선)

> 이 세 작업이 완료되지 않으면 Phase 4의 모든 콘텐츠 작업에서 구조 부채가 누적된다. **순차 진행 권장**.

### 4.1 #1 CombatSystem 리팩토링 — 전투 로직 System 허브화

#### 목표
전투 로직(공격 요청·데미지 계산·히트박스 생성·이펙트 발행)을 `CombatSystem`으로 집중. 플레이어·적·보스는 **입력·의도**만 전달.

#### 현재 상태 (2026-04-21)
- [src/systems/combat/](../src/systems/combat/) 160줄 — 리스폰 타이머·스폰 포인트만 보유
- 실제 전투 로직은 [player_combo.gd](../src/entities/player/), [base_enemy.gd](../src/entities/enemies/base/), [base_boss.gd](../src/entities/bosses/base/)에 분산
- `CombatSystem.get_combo_damage()`가 `GrowthSystem.get_bonus()`·`InventorySystem.get_bonus()`를 **매 프레임 3회** 호출 → 결과적 강결합 (Tier 3 #6으로 별도 해결)

#### 목표 구조

```gdscript
# 신규 리소스: src/systems/combat/attack_spec.gd
class_name AttackSpec extends Resource
@export var attacker: Node
@export var damage: float
@export var hitbox_size: Vector2
@export var hitbox_offset: Vector2
@export var active_duration: float
@export var attribute: String  # "light"/"shadow"/"hybrid"/"neutral"/"none"
@export var is_finish: bool = false
@export var piercing: bool = false
@export var knockback: float = 0.0
@export var multi_hit_count: int = 1
@export var multi_hit_interval: float = 0.0

# CombatSystem 확장 API
func request_attack(spec: AttackSpec) -> Node2D  # 히트박스 Area2D 반환
func request_projectile(spec: ProjectileSpec) -> Node2D
func request_aoe(spec: AoeSpec) -> void
```

#### 파일 트리 (제안)
```
src/systems/combat/
├── combat_system.gd            (기존, 조율자로 축소)
├── attack_spec.gd              (신규, Resource)
├── projectile_spec.gd          (신규, Resource)
├── aoe_spec.gd                 (신규, Resource)
├── hitbox_factory.gd           (신규, 히트박스 Area2D 생성 전담)
├── damage_resolver.gd          (신규, 데미지 + 넉백 계산)
└── attack_requests.gd          (신규, 요청 큐/동시 히트 관리)
```

#### 완료 기준
- [ ] `player_combo.gd`에서 히트박스 직접 생성 코드 제거, `CombatSystem.request_attack(spec)` 호출로 대체
- [ ] 적·보스의 공격 행동도 동일 API 사용 (AttackBehavior 리팩토링)
- [ ] 기존 4타 콤보·적 근접/원거리 공격·보스 페이즈 패턴 모두 회귀 없음
- [ ] `player_combo.gd` LOC 30% 이상 감소
- [ ] `combat_system.gd`가 300줄 이내 유지

#### 검증 방법
- Godot 헤드리스 로드 테스트 (ERROR 0)
- 1-1~1-6 스테이지 수동 플레이 (콤보 타격·적 피격·보스 HP 감소 확인)
- gdlint / gdformat clean

#### 상세 스펙
착수 직전 **`docs/refactor/COMBAT_SYSTEM_REFACTOR.md`** 작성 예정. 포함 내용:
- 현재 전투 로직 위치 전체 인벤토리 (파일·라인 번호)
- API 변경 diff (Before/After)
- 단계별 마이그레이션 커밋 계획 (회귀 방지)
- 이펙트 시그널 연동점 (`hit_flash_requested` 등 고아 시그널 부활 가능성)

---

### 4.2 #2 SkillSystem 실행 로직

#### 목표
`SkillSystem`에 "스킬을 실제로 발동하는" 실행 레이어 추가. 스킬 `.tres` 하나만 만들면 슬롯 장착·입력·쿨다운·자원 소모·CombatSystem 위임까지 전 과정 자동화.

#### 현재 상태
- [skill_system.gd](../src/systems/skill/skill_system.gd) — 슬롯 관리·등록만
- [skill_slot_manager.gd](../src/systems/skill/skill_slot_manager.gd) — 장착/해제
- [skill_attribute_resolver.gd](../src/systems/skill/skill_attribute_resolver.gd) — 피니시 속성 다수결 결정
- 기존 스킬 2종(`light_slash`, `shadow_strike`) — Player 내 하드코딩 테스트 경로
- **부재**: 스킬 입력 → 발동 → 효과 적용까지의 실행 파이프라인

#### 목표 구조

```gdscript
# SkillData 스키마 확장 (기존 파일 수정)
# data/skills/skill_data.gd 에 추가:
@export var custom_script: GDScript = null  # effect_type == "custom"일 때만 사용

# SkillSystem 확장 API
func execute(slot_index: int, caster: Node) -> bool:
    # 1. 슬롯의 SkillData 조회
    # 2. 쿨다운 체크
    # 3. 시간 자원 체크·소모
    # 4. effect_type 분기:
    #    melee/aoe/projectile/buff → CombatSystem.request_* 호출
    #    custom → custom_script.new().execute(caster, data)
    # 5. 쿨다운 시작, 시그널 emit
```

#### 파일 트리 (제안)
```
src/systems/skill/
├── skill_system.gd             (기존, 실행 API 추가)
├── skill_slot_manager.gd       (기존)
├── skill_attribute_resolver.gd (기존)
├── skill_executor.gd           (신규, execute() 본체 + 타입 분기)
└── effect_handlers/            (신규 서브폴더)
    ├── melee_handler.gd
    ├── aoe_handler.gd
    ├── projectile_handler.gd
    └── buff_handler.gd
```

#### 완료 기준
- [ ] 기존 2스킬이 SkillExecutor 경로로 동작 (하드코딩 테스트 경로 제거)
- [ ] 신규 가짜 스킬 1개 `.tres`로만 추가해서 작동 검증 (실제 커밋은 하지 않음, 검증 후 삭제)
- [ ] `custom_script` 경로 테스트 (임시 custom 스크립트 1개)
- [ ] 플레이어 스킬 키 4개 모두 각 슬롯과 연동
- [ ] 쿨다운·자원 소모 UI 연동 (기존 HUD 활용)

#### 검증 방법
- 스킬 슬롯에 `light_slash` 장착 후 입력 → 데미지 적용 확인
- 슬롯에 아무 것도 장착 안 된 상태 입력 → 무동작 확인
- 쿨다운 중 재입력 → 무시 확인
- 시간 자원 부족 시 입력 → 실패 피드백 확인

#### 의존성
- **#1 CombatSystem 선행**: 스킬이 `CombatSystem.request_*`에 위임하려면 그 API가 존재해야 함
- **#3과 병행 가능**: 피니시는 콤보 4타 전용이라 분리

#### 상세 스펙
**`docs/refactor/SKILL_EXECUTION_SPEC.md`** (착수 직전). 포함 내용:
- SkillData 스키마 확장 필드
- 각 effect_type 핸들러의 입력·출력 계약
- "신규 스킬 추가 매뉴얼" (`.tres` 필드 작성 가이드)
- custom_script 인터페이스 (베이스 클래스 정의)

---

### 4.3 #3 속성 피니시 메커닉

#### 목표
[COMBAT.md §2 속성 피니시 거동](COMBAT.md) D1~D5 표를 실제 플레이 가능한 코드로 실장.

#### 현재 상태
- 설계: COMBAT.md에 light/shadow/hybrid/neutral 각 공간 거동·히트 방식·무적·체감 확정
- 구현: 0줄 (4타 피니시는 현재 `finish_attribute` 메타데이터만 부착, 실제 거동 분기 없음)
- 관련 시그널: `finish_attribute_changed` (SkillSystem emit, connect 0회 — 고아 시그널)

#### 목표 구조 (A-2 결정: Strategy 모듈 분리)

```
src/entities/player/finish/
├── finish_strategy.gd          (신규 베이스, 추상 execute())
├── finish_light.gd             (전방 60~80px 돌진 + 관통)
├── finish_shadow.gd            (근거리 적 뒤 텔포 + 3단 다단히트)
├── finish_hybrid.gd            (제자리 80×40 광역)
└── finish_neutral.gd           (일반 4타 + 강넉백)
```

각 전략은 `execute(player: Node, combat_system, attribute_resolver)` 시그니처만 구현.

#### 완료 기준
- [ ] 4개 속성 전략 모두 구현
- [ ] `player_combo.gd`의 피니시 발동 시점에 `finish_strategies[attribute].execute(...)` 호출
- [ ] 각 전략이 `CombatSystem.request_attack(AttackSpec)` 경유 (히트박스 직접 생성 금지 → #1 선행)
- [ ] `EnemySystem.get_nearest_enemy(pos, max_dist)` 신규 API (shadow 피니시 전용) 추가
- [ ] `finish_attribute_changed` 시그널 실제 사용처 확보 (HUD 색상 갱신 등)

#### 수치 (COMBAT.md §2 표 그대로 구현, 프로토 튜닝 대상)

| 속성 | 거리 | 무적 | 다단 | 관통 |
|---|---|---|---|---|
| light | 60~80px | ◯ 돌진 중 | 1 | ◯ |
| shadow | 텔포 ≈0.15s | ◯ 이동 중 | 3 (간격 0.1s) | — |
| hybrid | 제자리 | — | 1 (80×40) | — |
| neutral | 표준 | — | 1 | — (강넉백) |

#### 검증 방법
- 각 속성 피니시 4타 완성 시 거동 육안 확인
- 관통(light): 3체 일렬 배치 시 모두 데미지
- 다단히트(shadow): 단일 적이 3회 데미지 넘버
- 광역(hybrid): 반경 내 다수 적 동시 데미지

#### 의존성
- **#1 CombatSystem 선행**: `AttackSpec`의 `piercing`·`multi_hit_count` 필드가 존재해야 함
- **EffectsSystem 기존 연동 재사용**: `request_screen_flash`·힛스톱 FINISH 프리셋·피격 파티클 속성 swap 모두 이미 작동 중

#### 상세 스펙
**`docs/refactor/FINISH_ATTRIBUTE_SPEC.md`** (착수 직전). 포함 내용:
- 각 전략의 의사 코드
- AttackSpec 필드 매핑 (속성별 어느 필드가 어떻게 세팅되는가)
- shadow 텔포 위치 계산 알고리즘 (`EnemySystem.get_nearest_enemy` 기반)
- 각성 지연 창(C-new, 0.3~0.5s) 연동 가능성

---

## 5. Tier 2 — 인프라 확장

### 5.1 #4 강화 이동 3종 (Shadow Phase / Light Leap / Shadow Step)

#### 목표
[COMBAT.md §11](COMBAT.md) 보스 보상 라인업 중 미구현 3종 + 속성 토글 입력 시스템 구현.

#### 현재 상태
- Light Dash: 구현 완료 (Phase 3-7, 잔상 효과 포함)
- Shadow Phase / Light Leap / Shadow Step: 설계만 존재, 코드 0
- AbilitySystem: 해금 플래그 프레임워크 완성, 실제 능력 0개

#### 구현 범위 (C-4 속성 토글 결정)

```gdscript
# src/entities/player/player_dash.gd (또는 유사)
enum DashAttribute { NEUTRAL, LIGHT, SHADOW }
var current_dash_attribute: DashAttribute = DashAttribute.NEUTRAL

func _on_dash_input() -> void:
    match [current_dash_attribute, AbilitySystem.is_unlocked(...), is_airborne()]:
        [LIGHT, true, true]: _light_leap()
        [LIGHT, true, false]: _light_dash()
        [SHADOW, true, true]: _shadow_phase()
        [SHADOW, true, false]: _shadow_step()
        _: _basic_dash()  # 폴백

func _on_attribute_toggle_input(direction: int) -> void:
    # Q/E 또는 단일 키 순환 (UI 결정에 따라)
    ...
```

#### 상태머신 확장
- Player 상태: `IDLE/RUN/JUMP/FALL/DASH/LIGHT_DASH` → `SHADOW_PHASE`, `LIGHT_LEAP`, `SHADOW_STEP` 추가
- 각 상태: 고유 i-frame·속도 프로파일·종료 조건

#### 후속 공격 연계 ([COMBAT.md §11](COMBAT.md))
- Light Dash: 궤적 끝 자동 돌진 베기 (이미 설계)
- Shadow Step: 텔포 직후 0.25s 유예 내 공격 → 강화 배후 공격
- Light Leap: 상승 정점 후 낙하 중 공격 → 낙하 베기
- Shadow Phase: 잠수 해제 직후 0.25s 유예 내 공격 → 강화 기습

모두 `CombatSystem.request_attack` 경유 (#1 선행 조건).

#### 완료 기준
- [ ] 4종 이동 모두 발동 가능 (해금 상태 무시하고 디버그로 테스트 가능)
- [ ] AbilitySystem 해금 플래그 연동 (미해금 시 기본 대시 폴백)
- [ ] 속성 토글 입력 + HUD 속성 아이콘 (최소한의 임시 UI)
- [ ] 후속 공격 4종 모두 입력 유예 내 발동

#### 의존성
- **#1 CombatSystem 선행** (후속 공격용 AttackSpec)
- **#3 속성 피니시**와 직접 의존성 없으나, 속성 토글 UX를 일관되게 맞추려면 순서상 #3 이후 착수가 자연스러움

---

### 5.2 #5 EventBus 고아 시그널 정리

#### 목표
정의되었으나 emit 또는 connect가 없는 시그널 44개를 3택 분류:
- ① emitter 또는 subscriber 추가 (실제로 필요한 경우)
- ② 제거 (설계 후 불필요해진 경우)
- ③ `# PHASE_X 예약` 주석 (미래 사용)

#### 현재 현황 (2026-04-21 감사)
- 정의 165개 / 활용 121개 / 미사용 44개 (26%)
- 완전 고아 6개: `boss_intro_started/finished`, `boss_spawned`, `hit_flash_requested`, `hitstop_requested`, `screen_flash_requested`
- emit-only 22개 / connect-only 2개

#### 완료 기준
- [ ] 44개 전체에 대한 분류 결정 표 작성
- [ ] EventBus 스크립트 정리 (제거 또는 주석 추가)
- [ ] 부활 가능한 시그널(예: `hit_flash_requested`)은 #1 작업 중 실제 사용처 연결

#### 주목 포인트
- `hit_flash_requested`·`hitstop_requested`·`screen_flash_requested` 3개는 **#1 CombatSystem 리팩토링에서 자연스럽게 부활 가능** — CombatSystem이 이 시그널들을 emit하고 EffectsSystem이 수신하는 방향으로 연결
- 보스 관련 시그널 3개는 Phase 4-A(2구역 보스) 진입 시 부활 예약 권장

---

## 6. Tier 3 — 구조 부채 청소

> 언제든 병행 가능. 낮은 비용, 높은 위생 효과.

### 6.1 #6 매 프레임 Getter 호출 캐싱

- **증상**: `CombatSystem.get_combo_damage()` 내부에서 `GrowthSystem.get_bonus()` + `InventorySystem.get_bonus()` 호출, 60fps × 3회/frame
- **해결**: `growth_stats_changed` / `equipment_stats_changed` 시그널 수신 시점에 캐시 갱신, `get_combo_damage()`는 캐시만 참조
- **공수**: 30분 ~ 1시간
- **의존성**: #1과 충돌 가능성 있으므로 #1 이후 적용 권장

### 6.2 #7 300줄 초과 분해

| 파일 | 현재 | 목표 |
|---|---|---|
| [stage_system.gd](../src/systems/stage/stage_system.gd) | 328줄 | ≤ 300줄 |
| [cover_visual.gd](../src/entities/objects/cover_visual.gd) | 301줄 | ≤ 300줄 |

- `stage_system.gd`는 이미 6개 하위 컴포넌트로 분리된 상태 — 조율 로직 일부를 하위 컴포넌트에 위임
- `cover_visual.gd`는 시각 렌더링 헬퍼 분리

### 6.3 #8 gdlint / gdformat 일괄 정리

- gdlint 18건:
  - class-definitions-order 11건
  - constant-name 1건 ([player_movement.gd](../src/entities/player/player_movement.gd) `State` → `STATE`)
  - unused-argument 2건 ([enemy_system.gd](../src/systems/enemy/enemy_system.gd) 등)
  - max-line-length 1건
  - no-else-return 2건
- gdformat 49파일 재포매팅 (현재 171개 중 29%)
- **순서 권장**: 먼저 gdformat 일괄 적용 → 커밋 → 그 위에서 gdlint 수작업 해결

---

## 7. 진행 순서 / 의존성

### 의존성 그래프
```
#1 CombatSystem
 ├─→ #3 Finish (AttackSpec 필요)
 ├─→ #2 SkillExec (request_* 필요)
 └─→ #4 Enhanced Moves (후속 공격 spec 필요)

#2 SkillExec ──→ (독립, #1 이후 병행)
#3 Finish   ──→ (독립, #1 이후)
#4 Moves    ──→ (#1 + 선호도로 #3 이후)
#5 Orphans  ──→ (#1과 일부 자연 해소, 나머지는 #1 완료 후 마무리)
#6 Cache    ──→ (#1 이후)
#7 300줄    ──→ (언제든)
#8 Lint     ──→ (언제든, 커밋 직전 권장)
```

### 권장 주차 계획

| 주차 | 작업 | 비고 |
|---|---|---|
| Week 1 | **#1 CombatSystem 리팩토링** | `COMBAT_SYSTEM_REFACTOR.md` 선행 작성 |
| Week 2 전반 | **#2 SkillSystem 실행 로직** | `SKILL_EXECUTION_SPEC.md` 선행 |
| Week 2 후반 | **#3 속성 피니시 메커닉** | `FINISH_ATTRIBUTE_SPEC.md` 선행 |
| Week 3 | **#4 강화 이동 3종** + **#5 고아 시그널 정리** | 경량 스펙 문서 |
| Week 4 | **#6 / #7 / #8** 부채 청소 + 회귀 테스트 | |

**총 예상 기간**: 3~4주 (1인 개발·병렬 아트 작업 고려)

---

## 8. 완료 기준 (Phase 4-0 종료 게이트)

다음 모든 조건이 만족되어야 Phase 4 진입:

- [ ] #1~#3 Tier 1 전체 완료
- [ ] #4 강화 이동 4종 모두 플레이 가능
- [ ] #5 고아 시그널 44개 모두 분류 완료
- [ ] #6 매 프레임 getter 캐시 적용
- [ ] #7 300줄 초과 0건
- [ ] #8 gdlint 0건 + gdformat 100% 준수
- [ ] Godot 헤드리스 로드 테스트 통과 (ERROR 0 / WARNING 0)
- [ ] 1-1~1-6 + 1-H + 1-B 전체 스테이지 회귀 플레이 통과
- [ ] **검증 시나리오**: 가짜 스킬 1개를 `.tres`만으로 추가해 슬롯 장착·발동 성공 (후 삭제)
- [ ] **검증 시나리오**: 속성 피니시 4종 모두 체감 분기 확인
- [ ] 관련 문서 갱신: `COMBAT.md`·`SKILLS.md`·`CORE_SYSTEMS.md`

---

## 9. 미결 사항 / 후속 결정 대기

본 Phase 진행 중 추가 결정이 필요한 항목. **프로토 튜닝 단계에서 확정**.

- [ ] 속성 토글 입력 키 (잠정 Q 또는 E 순환)
- [ ] 속성 토글 UI 형태 (HUD 아이콘 / 팝업 휠 / 스킬 슬롯 통합)
- [ ] 후속 공격 유예 프레임 수치 (초안 0.25s)
- [ ] Light Dash / Shadow Step 거리·쿨다운 최종 수치
- [ ] 혼합 필살기(Phase 4-D) 입력 방식 — 자동 궤적 / 수동 입력 (본 Phase에서는 미구현, Phase 4-D 진입 시 결정)
- [ ] 고아 시그널 44개 중 개별 분류 결정 (#5 진행 중 표 생성)
- [ ] `EnemySystem.get_nearest_enemy(pos, max_dist)` API 정확한 시그니처 (#3 진행 중 확정)

---

## 10. 관련 문서

### 상위
- [`DEVELOPMENT_PLAN.md`](DEVELOPMENT_PLAN.md) §Phase 4

### 참조 (설계 원천)
- [`COMBAT.md`](COMBAT.md) §2 속성 피니시·§11 강화 이동
- [`SKILLS.md`](SKILLS.md) 스킬 시스템 개요
- [`CORE_SYSTEMS.md`](CORE_SYSTEMS.md) 시간·자원 수치
- [`EFFECTS.md`](EFFECTS.md) 이펙트 연동점

### 하위 (착수 직전 작성 예정)
- `docs/refactor/COMBAT_SYSTEM_REFACTOR.md` — #1 상세 스펙
- `docs/refactor/SKILL_EXECUTION_SPEC.md` — #2 상세 스펙
- `docs/refactor/FINISH_ATTRIBUTE_SPEC.md` — #3 상세 스펙

### 병행 (진행 중)
- [`PHASE_3_PLAN.md`](PHASE_3_PLAN.md) — Phase 3-7 Pass 5 잔여
- [`art_specs/`](art_specs/) — 1구역 아트 명세 (사용자 작업)
