# 시간이 멈춘 숲 — 4. 보스전 설계

> 이 문서는 구역별 보스의 구조, 전투 방식, 보상을 정의한다.
> 전투 시스템(COMBAT.md), 적 시스템(ENEMIES.md), 핵심 로직(CORE_SYSTEMS.md) 위에서 설계된다.

> **현재 구현 상태 (2026-04-18)**: 구현 1/5 (1구역 — **거대 고목**, Phase 3-3 완료).
> - 1구역 보스 → **Phase 3-3 완료** — `ancient_oakheart.tres` / 2페이즈 / 약점 lens_focus / 보상 빛 대시
> - 2~4구역 보스 → Phase 4-A / 4-B / 4-C
> - 5구역 최종 보스 → Phase 4-D

---

## 1. 보스전 기본 원칙

### GDD 확정 사항
- 매크로(시간 조절) + 마이크로(환경 조작) + 액션(직접 공격) 세 가지를 복합적으로 사용
- 구역당 보스 1개, 총 5개
- 보스 해금 조건: 해당 구역 모든 스테이지 완전 클리어

### 보스 정체성 (확정)
- **초반 (1~2구역)**: 숲의 거대 오브젝트가 괴물화. 단순한 저주의 산물로 보임.
- **중반 (3~4구역)**: 괴물화 + 그림자 왕가의 잔재가 결합. 보스에게 의지와 사연이 느껴지기 시작.
- **최종 (5구역)**: 두 왕가의 불완전한 결합체. 분노와 뒤틀림 속에 합쳐진 존재.
- 보스 진행 = 스토리 진행. 초반 "저주 괴물" → 후반 "봉인된 존재" 인식 전환.

### 전투 구조 (확정)
- **멀티 페이즈** — HP 구간마다 패턴 변화
- 구역이 올라갈수록 페이즈 수 증가

### 구역별 페이즈 수 (확정)

| 구역 | 페이즈 | 정체성 |
|---|---|---|
| 1구역 | 2 | 거대 오브젝트 괴물화. 규칙 학습. |
| 2구역 | 2 | 거대 오브젝트 괴물화. 패턴 심화. |
| 3구역 | 3 | 괴물화 + 그림자 왕가 흔적. 중반 전환점. |
| 4구역 | 3 | 괴물화 + 그림자 왕가 결합. 복합 전투. |
| 5구역 | 4 | 두 왕가의 불완전한 결합체. 빛+그림자 모두 활용. |

### 미결 사항
- [ ] 보스 맵 환경 설계
- [ ] 최종 보스 (5구역) 상세
- [ ] 각 보스별 페이즈 전환 조건 및 패턴

---

## 2. 구역별 보스

### 구현 상태
- 구현: **0/5**
- 상세 설계 착수 일정: 각 구역 Phase 진입 시점

### 미결 사항
- [ ] 1구역 보스 — Phase 3-3 확정 (2페이즈, 거대 오브젝트 괴물화)
- [ ] 2구역 보스 — Phase 4-A 확정 (2페이즈, 안개 습지 테마)
- [ ] 3구역 보스 — Phase 4-B 확정 (3페이즈, 중반 전환점 — 그림자 왕가 흔적 결합)
- [ ] 4구역 보스 — Phase 4-C 확정 (3페이즈, 괴물화 + 그림자 왕가 결합)
- [ ] 5구역 보스 — Phase 4-D 확정 (4페이즈, 두 왕가의 불완전한 결합체, 최종)

---

## 3. 보스 처치 보상 (확정)

모든 보스 처치 시 세 가지 보상이 동시에 주어짐:

| 보상 | 역할 | 예시 |
|---|---|---|
| **잠금 해제 능력** | 게임플레이 확장 | 빛 대시, 그림자 점프 등 |
| **스토리 단서** | 내러티브 진행 | 컷신, 기록물 — 진실이 점차 드러남 |
| **강화 보상** | 성장 | 대량 강화 포인트, 고유 장비/장신구 |

- 다음 구역 해금은 기본으로 포함

### 구현 상태 (Phase 3-3-d 완료)

- **`AbilitySystem` Autoload** (`src/systems/ability/ability_system.gd`) — 영구 능력 보유 + 보스 보상 분배를 단일 책임으로 처리
- **`AbilityData` Resource** (`data/abilities/*.tres`) — 능력 ID/표시명/카테고리/해금 스토리 플래그
- **`BossStatsData` 보상 필드** (3-3-d 추가): `reward_ability_id`, `reward_growth_points`, `reward_item_ids`, `reward_story_flag`, `reward_next_zone_flag`
- **분배 루프**: `EventBus.boss_defeated` → `AbilitySystem._dispatch_reward(BossStatsData)` →
  1. `AbilitySystem.unlock(ability_id)` → `EventBus.ability_unlocked`
  2. `GrowthSystem.earn_growth_points(amount, "boss:...")`
  3. `StateFlags.set_flag(story_flag, true)` → `EventBus.state_flag_changed`
  4. `StateFlags.set_flag(next_zone_flag, true)` (다음 구역 해금)
  5. `EventBus.item_acquired.emit(item_id)` per 아이템 → `InventorySystem` 수신
- **ABILITY 잠금과 연동**: `stage_lock_validator._validate_ability`가 `AbilitySystem.has(ability_id)`로 스테이지 접근 검증. `lock_requirement`는 ability_id 문자열을 직접 사용.
- **숨김 포탈 연동**: 스토리 플래그가 set되면 `HiddenRevealer(FLAG)`가 구독하여 다음 구역 진입 포탈을 노출 (1구역 `Stage1_B` → `stage_2_1`).

### 1구역 보스 — 거대 고목 (Ancient Oakheart)

- **데이터**: `data/bosses/zone1/ancient_oakheart.tres` — HP 600 / ATK 15 / 접근 범위 130 / 2페이즈
- **페이즈 1**: 근접 가지 휘두르기 (광역) — `phase_1_branch_sweep.tres`
- **페이즈 2**: 그림자 뿌리 + 원거리 포자 투사체 (3-2 빛가루 포자 인프라 재사용) — `phase_2_branch_storm.tres`
- **약점**: 오프셋 (0, -56), 반경 22, 배율 2.5배, 트리거 소스 `lens_focus`
- **보상**: `reward_ability_id="light_dash"` / `reward_growth_points=5` / `reward_story_flag="story.zone1.oakheart_defeated"` / `reward_next_zone_flag="stage_progress.zone2_unlocked"`
