# 시간이 멈춘 숲 — 스킬 시스템

> 이 문서는 플레이어 스킬, 빛/그림자 투자 구조, 능력 해금을 정의한다.
> 스테이지 잠금 구조(STAGES.md)와 연동되며, 전투 시스템 설계의 기반이 된다.

---

## 1. 빛/그림자 투자 구조

### 세 갈래 스킬 경로 (확정)
- **빛 계열** — 빛의 계보로부터 물려받은 힘
- **그림자 계열** — 그림자 왕가로부터 봉인을 통해 얻은 힘
- **혼합 계열** — 두 힘을 함께 다루는 제사장 가문 고유 영역

### 투자 규칙 (확정)
- 세 갈래 모두 투자 가능, **포인트 한정** → 전부 찍을 수 없음, 비율 선택
- **혼합 계열 해금 조건**: 빛과 그림자에 각각 일정 이상 투자 필요
- 자연스러운 빌드 분화: 빛 특화 / 그림자 특화 / 혼합 중심

### 각 갈래의 역할/정체성 (확정)

| 계열 | 공격 성격 | 조작 |
|---|---|---|
| **빛** | 빠르고 날카로운 공격. 빛을 쏘거나 베는 직선적 공세. | 액티브 |
| **그림자** | 묵직하고 넓은 공격. 그림자를 휘두르거나 터뜨리는 범위 공세. | 액티브 |
| **혼합** | 빛+그림자 융합 고유 공격 + 연쇄 콤보 보너스 | 액티브 + 패시브 |

- 혼합 트리 = **융합 공격**(액티브: 직접 사용하는 고유 스킬) + **연쇄 콤보**(패시브: 빛→그림자 또는 그림자→빛 연쇄 시 자동 추가타/보너스)
- 전략적 깊이는 핵심 시스템(시간/그림자/환경)이 담당, 스킬은 **액션 레이어**에 집중
- 기본 공격 + 이동공격 기반, 복잡한 기믹보다 액션감 중시

### 확정 (Phase 2-6 성장 시스템 구현)
- **혼합 해금 임계값**: 빛·그림자 각각 3포인트 이상 투자 시 혼합 계열 해금
- **리스펙**: 거점에서 재분배 가능 (GrowthSystem)

---

## 2. 스킬 구성

### 슬롯 구조 (확정 / ✅ Phase 2-1 프레임워크 구현)
- **기본 공격** 1개 (고정, 자원 소모 없음)
- **스킬 슬롯** 4개 (자유 장착, 트리 제한 없음)
- 쿨타임 기반
- **시간 자원 소모**: 각 스킬 사용 시 `time_cost`만큼 시간 자원 소비 (EventBus 시그널)
- **입력**: U/I/O/P (skill_1~4 InputMap 액션)

### 트리 규모 (확정)
- 트리당 **6개** 스킬 → 총 18개
- 초반 스킬 2개는 후반에 자연스럽게 교체됨
- 트리 내 파워 곡선: 앞쪽 = 기본기, 뒤쪽 = 상위 스킬

### SkillData Resource (✅ 구현)

```
data/skills/skill_data.gd (class_name: SkillData)
├── Identity: id, display_name, description
├── Classification: path (light/shadow/hybrid), skill_type (active/passive), tier (1~3)
├── Effect: effect_type (melee/aoe/projectile/buff), hitbox_size, hitbox_offset, aoe_radius
└── Parameters: damage, cooldown, time_cost, active_duration
```

- `effect_type`이 히트박스 형상 결정 (melee=RectangleShape2D, aoe=CircleShape2D)
- 새 스킬 추가 = .tres 파일 생성 + SKILL_PATHS 배열에 등록

### 테스트 스킬 (✅ 2개 구현)

| 항목 | light_slash | shadow_strike |
|---|---|---|
| id | "light_slash" | "shadow_strike" |
| display_name | "빛 베기" | "그림자 강타" |
| path | "light" | "shadow" |
| effect_type | "melee" | "aoe" |
| damage | 25.0 | 35.0 |
| cooldown | 2.0s | 5.0s |
| time_cost | 5.0 | 10.0 |

### 현재 구현 상태 (2026-04-18)
- ✅ 프레임워크: SkillSystem + SlotManager + AttributeResolver + SkillData Resource (Phase 2-1)
- ✅ 4슬롯 장착 / 쿨타임 / 시간 자원 소모 / 피니시 속성 자동 결정
- ✅ 스킬 HUD (U/I/O/P)
- ⏳ 스킬 콘텐츠: **2/18 구현** (light_slash, shadow_strike — 프레임워크 검증용 테스트 스킬)
- ⏳ 나머지 16개 스킬: **Phase 4-E 전체 연결**에서 .tres 일괄 제작 예정
- ⏳ 기본 공격 세부 동작(빛 쏘기/베기 구체 연출): Phase 3-7 아트 제작과 병행

### 미결 사항
- [ ] 기본 공격 상세 (빛 쏘기/베기의 구체적 동작) — Phase 3-7
- [ ] 빛 계열 스킬 목록 (6개) — Phase 4-E
- [ ] 그림자 계열 스킬 목록 (6개) — Phase 4-E
- [ ] 혼합 계열 스킬 목록 (융합 액티브 + 연쇄 패시브, 6개) — Phase 4-E

---

## 3. 잠금 해제 능력

### 스킬 트리와 별도 (확정)
- 잠금 해제 능력은 스킬 포인트와 **무관**하게 별도 획득
- 스킬 포인트는 순수 전투 성장에만 사용
- 잠금 해제 능력은 보스 처치, 탐색 보상 등으로 획득

### 스테이지 잠금과의 연동
확정된 잠금 유형 (STAGES.md):
- 빛 잠금 — 등불 수준 필요
- 정화 잠금 — 정화 능력 필요
- 환경 잠금 — 환경 도구 활용
- 능력 잠금 — 이동/전투 능력 필요

### 현재 구현 상태 (2026-04-18)
- ✅ 잠금 프레임워크: StageSystem LockValidator (Phase 2-4c)
- ✅ LIGHT 잠금 (등불 수준 기반 검증)
- ✅ PURIFY 잠금 (정화 능력 기반, Phase 2-4d PurificationDetector)
- ⏳ ENVIRONMENT 잠금: **Phase 3-1**에서 조건 정의 + 구현 (환경 오브젝트 상태 연동)
- ⏳ ABILITY 잠금 실제 능력: **0개** — 실제 강화 이동/능력은 **Phase 3-3 1구역 보스 보상부터** 순차 추가, Phase 4-A~4-D 각 구역 보스로 분배

### 미결 사항
- [ ] 각 잠금을 여는 구체적 능력 (구역별 Phase 진입 시 확정)
- [ ] 능력 획득 위치별 분배 — 기본 방향: 구역 보스 처치 + 추가조작 보상
- [ ] 해금 순서와 구역 진행의 관계 (Phase 3-3부터 누적 정의)

---

## 4. SkillSystem 구조 (✅ Phase 2-1 구현)

### Autoload 구조

```
SkillSystem (Autoload, src/systems/skill/skill_system.gd)
├── SlotManager (skill_slot_manager.gd) — 4슬롯 장착/쿨다운 타이머
└── AttributeResolver (skill_attribute_resolver.gd) — 피니시 속성 결정
```

### Public API

| 카테고리 | 메서드 | 용도 |
|---|---|---|
| 슬롯 | `equip_skill(slot, id)` | 스킬 장착 |
| | `unequip_skill(slot)` | 스킬 해제 |
| | `get_equipped_skill(slot)` | 장착된 SkillData 반환 |
| 쿨다운 | `can_use_skill(slot)` | 사용 가능 여부 |
| | `start_cooldown(slot)` | 쿨다운 시작 |
| | `get_cooldown_ratio(slot)` | 0.0=준비, 1.0=쿨다운중 |
| 속성 | `get_finish_attribute()` | "light"/"shadow"/"hybrid"/"neutral" |
| 레지스트리 | `get_skill_data(id)` | SkillData 조회 |
| | `unlock_skill(id)` / `is_skill_unlocked(id)` | 해금 관리 |

### 피니시 속성 결정 (AttributeResolver)

장착된 4슬롯의 `path` 집계:
- light > shadow → "light"
- shadow > light → "shadow"
- light == shadow && 둘 다 > 0 → "hybrid"
- hybrid만 장착 → "hybrid"
- 모두 빈 슬롯 → "neutral"

### 스킬 HUD (✅ 구현)

- 화면 우하단 4슬롯 (20x20 ColorRect)
- 장착 시 색상: 빛=노랑, 그림자=보라, 혼합=청록, 빈=회색
- 쿨다운: 상단→하단 어두운 오버레이 sweep
- 사용 시: 밝은 플래시 (0.15s)
- 키 라벨: U/I/O/P

### 파일 구조

```
src/systems/skill/
├── skill_system.gd            # Autoload 오케스트레이터
├── skill_slot_manager.gd      # 4슬롯 장착/쿨다운 관리
└── skill_attribute_resolver.gd # 피니시 속성 결정

src/entities/player/
└── player_skill.gd            # 플레이어 스킬 입력/실행 컴포넌트

src/ui/hud/
├── SkillHud.tscn              # 스킬 HUD 씬
└── skill_hud.gd               # 스킬 HUD 스크립트

data/skills/
├── skill_data.gd              # SkillData Resource 클래스
├── light_slash.tres           # 테스트 스킬: 빛 베기
└── shadow_strike.tres         # 테스트 스킬: 그림자 강타
```

---

## 5. 성장 연동

### 미결 사항
- [ ] 빛/그림자 투자에 따른 플레이 스타일 분화
- [ ] 능력치 강화 항목 (HP, 공격력, 시간 자원 등)
