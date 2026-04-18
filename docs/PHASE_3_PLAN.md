# 시간이 멈춘 숲 — Phase 3 (1구역 버티컬 슬라이스) 진입 노트

> 이 문서는 Phase 3 진입 시점의 **결정 사항**, **스테이지/적/보스 초안**, **마일스톤별 진입 체크리스트**를 정리한다.
> 상위 문서: `DEVELOPMENT_PLAN.md` §Phase 3 / `GDD.md` / `WORLD_DESIGN.md` / `STAGES.md`
> 작성일: 2026-04-18

---

## 1. 진입 조건 점검

| 항목 | 상태 |
|---|---|
| Phase 0 기반 세팅 | ✅ |
| Phase 1 코어 프로토타입 (1-1 ~ 1-7) | ✅ |
| Phase 2 시스템 확장 (2-1 ~ 2-8) | ✅ |
| Phase 2 완료 후 전반 점검 | ✅ (실버그 2건 수정, `43dd449` / `822327c`) |
| 설계 문서 갱신 6건 | ✅ |
| **Phase 3-1 레벨 디자인 구현** | **✅ 완료 (2026-04-18) — 7 스테이지(.tres/.tscn/.gd) + HiddenRevealer + ENVIRONMENT α/β/γ 프레임워크** |
| **Phase 3-2 1구역 적 구현** | **✅ 완료 (2026-04-18) — 서브 타입 4종(`data/enemies/zone1/`) + 빛가루 포자 + airborne_homing 이동 프로파일** |
| **Phase 3-3 1구역 보스 구현** | **✅ 완료 (2026-04-18) — D4/D5 확정 + 3-3-a/b/c/d 구현 + 3-3-e 통합 QA. §5 참조** |
| **Phase 3-4 거점 구현** | **✅ 완료 (2026-04-18) — D6 확정 + 3-4-a/b/c/d/e. §6 구현 결과 참조** |

**→ Phase 3-5 월드맵 착수 가능 상태**

---

## 2. Phase 3 전체 흐름

```
3-1 레벨 디자인
  ├── 3-2 1구역 적 (서브타입 + 고유 적)
  │     └── 3-3 1구역 보스
  ├── 3-4 거점 (시작 마을 + 1-2 경계)
  └── 3-5 월드맵 (기본)
3-6 UI 완성
3-7 1구역 아트 + 이펙트 (EFFECTS.md Pass 1~5c 일괄 적용)
3-8 사운드 (기본)
```

- **3-7 병행 원칙**: 구현 완료 후 Art Spec Writer가 명세 생성 → 사용자가 Aseprite 제작 → 반영. EFFECTS.md의 Pass 1~5c 이펙트도 3-7에서 일괄 적용 (**안 A 확정**).

---

## 3. 3-1 — 1구역 레벨 디자인 (✅ 구현 완료 2026-04-18)

### 스테이지 구성 (6 일반 + 추가조작 1 + 보스 1)

| No. | 이름(가안) | 시간대 주제 | 잠금 | 환경 오브젝트 | 비고 |
|---|---|---|---|---|---|
| 1-1 | 숲의 입구 | 낮, 낮은 그림자 | NONE | 거울 1 | 시간/공격/그림자 튜토리얼 |
| 1-2 | 나무 사이길 | 낮 | NONE | 차폐물 1 | 차폐물 도입 |
| 1-3 | 이끼 계곡 | 밤 도입 | LIGHT(등불 1) | 반사 바닥 | 등불 + 밤 전투 |
| 1-4 | 고목의 뜰 | 낮↔밤 자유 | NONE | 거울 2 + 렌즈 1 | 다중 오브젝트 조합 |
| 1-5 | 부서진 사당 | 밤 중심 | PURIFY(1-2 잔류) | 차폐물 2 | 정화 도입 |
| 1-6 | 빛의 공터 | 낮 특화 | ENVIRONMENT(거울) | 렌즈 2 | 보스 전 긴장 고조 |
| 1-H | **숨겨진 등불대** (추가조작) | 밤 | — | 거울 + 렌즈 | 숨겨진 경로, 발견 시 "이후 구역 빛 경로 생성" |
| 1-B | **1구역 보스** | — | 1-1~1-6 완전 클리어 | — | §5에서 상세 |

> 잠금 유형은 `STAGES.md` LockType enum에 맞춰 배치. ENVIRONMENT 잠금은 Phase 3-1에서 α/β/γ 3종 프레임워크 구현 완료.

**구현 결과 (2026-04-18)**
- 모든 스테이지: `data/stages/stage_1_*.tres` + `src/world/stages/Stage1_*.tscn` + `stage_1_*.gd`
- 1-1: 튜토리얼 — 거울 1 + TreeEnemy 2
- 1-2: 차폐물 1 + `HiddenRevealer(SHADOW_COVER)` — 플레이어가 1.2초간 그림자 안에 머물면 숨김 보상 노출
- 1-3: 반사 바닥 + `LightSensor(sensor_1_3_reflection)` + `HiddenRevealer(REFLECTION)`
- 1-4: 거울 2 + 렌즈 1 + **숨겨진 포탈** (초기 `visible=false` + `process_mode=DISABLED`) + `HiddenRevealer(LIGHT_SENSOR)` — 1-H 진입
- 1-5: 차폐물 2 + 반사 바닥 + `HiddenRevealer(PURIFICATION)` — 잔류 정화 위치 기반
- 1-6: ENVIRONMENT 잠금 α (진입 포탈이 `sensor_1_6_entry` 점등에 연결) + 렌즈 2
- 1-H: 숨겨진 등불대 — 거울 1 + 렌즈 1, 귀환 포탈만 존재

**Cover 확장**
- `PlayerShadowDetectZone` (Area2D, layer=0/mask=2)을 `ShadowProjectionZone` 자식으로 추가 — 부모 회전 상속, 플레이어 전용 감지

**HiddenRevealer 확장**
- `SET_VISIBLE` 액션이 `visible=true` 외에 `process_mode=INHERIT`도 복원 — 숨김 포탈의 Area2D 신호 재활성화

### 자연 경계
- 북쪽 강/개울 → 2구역 경계 (`WORLD_DESIGN.md` §2)

### D1 확정 (2026-04-18) — 1-H 입구 + 숨김 보상 분산 배치

**1-H 입구**: 1-4 "고목의 뜰"에서 렌즈 빛 집중으로 숨겨진 포탈 노출 (LightSensor 기반).
기타 스테이지에는 각 기믹별 숨김 보상을 분산 배치 — 탐색 밀도 ↑, 스테이지 고유 기믹 재활용.

| 스테이지 | 기믹 | 트리거 | 보상 |
|---|---|---|---|
| 1-2 (차폐물) | SHADOW_COVER | 차폐물 그림자로 숨겨진 틈새 노출 | 강화 포인트 / 시간자원 아이템 |
| 1-3 (반사 바닥, 밤) | REFLECTION | 등불 ON + 반사광이 센서 점등 | 장신구 |
| **1-4 (렌즈)** | **LIGHT_SENSOR** | **렌즈 빛 집중으로 포탈 활성화** | **🔑 1-H 입구** |
| 1-5 (PURIFY) | PURIFICATION | 잔류 정화 시 벽이었던 잔류 제거 | 스토리 단서 (비문/벽화) |

**공통 프레임워크 — `HiddenRevealer` 컴포넌트**
- `reveal_condition: enum { LIGHT_SENSOR, REFLECTION, PURIFICATION, SHADOW_COVER }`
- `target_node_path: NodePath` — 드러낼/제거할 대상
- 조건 충족 시 `target.queue_free()` 또는 `visible = true`
- 4가지 센서/디텍터 로직만 개별 구현, 드러내기 동작은 공통

### D2 확정 (2026-04-18) — ENVIRONMENT 잠금 프레임워크 3종 선구현

Phase 3-1에서 **α/β/γ 3종 모두 구현**. 1구역은 α만 사용, β/γ는 앵커만 기록하고 2~5구역에서 점진 사용.

| 유형 | 컴포넌트 | 1구역 사용 | 2~5구역 앵커 (잠정) |
|---|---|---|---|
| **α** | `LightSensor` | **1-6 진입 잠금** (외부 포탈 앞 센서, 렌즈/반사광으로 점등). 1-4 HiddenRevealer와 동일 컴포넌트 재사용 | 3구역+ 어두운 구역 반복 등장 |
| **β** | `EnvironmentStateRegistry` | — | **2구역 예**: 안개 속 거울 3개 회전 조합으로 빛 경로 형성 |
| **γ** | `StateFlagPersistence` | — | **3구역+ 예**: 2구역 특정 스테이지에서 봉인 해제 → 4구역 지름길 해금 |

- β/γ 앵커는 **잠정**. 2구역 설계 시 교체 가능 (`feedback_ui_decisions_mutable` 준용)
- 앵커 기록 이유: API가 "일반 Dictionary" 식으로 뭉툭해지는 것 방지 — 구체 trigger/저장 방식 기준으로 설계

---

## 4. 3-2 — 1구역 적 (✅ 구현 완료 2026-04-18)

### 베이스 4종의 1구역 서브 타입 (확정·구현 완료)

| 베이스 | 1구역 서브 타입 | 리소스 | 주요 델타 |
|---|---|---|---|
| 나무 | **어린 참나무** | `data/enemies/zone1/oak_sapling.tres` | HP 120→90, 공격력 12→9, 히트박스 50×28→40×24 (melee 범위 축소) |
| 바위 | **이끼 바위** | `data/enemies/zone1/moss_rock.tres` | HP 160→130, `hurt_resistance_chance` 0.3→0.6 (경직 완화), `damage_reduction_flat=3` 유지 |
| 꽃 | **빛 꽃** | `data/enemies/zone1/light_flower.tres` | HP 60→45, `spore_count` 2→3, `spore_stats_path` → pollen_spore (고유 적과 병합) |
| 돌기둥 | **이정표 돌** | `data/enemies/zone1/signpost_stone.tres` | HP 80→70, `projectile_speed` 200→140, `projectile_telegraph` 0.4→0.6 |

### 1구역 고유 적 — **C 빛가루 포자 확정 (2026-04-18)**

`data/enemies/zone1/pollen_spore.tres`

- 빛 꽃 사망 시 분열체 슬롯으로 스폰 (별도 스폰 경로 없음, 기존 `death_behavior_split` 인프라 재사용)
- **공중 호밍 적**: `movement_profile="airborne_homing"`, `gravity_scale=0`, `homing_turn_rate=3.5`, `homing_max_speed=55`
- HP 18 / ATK 3 / 접촉 멜리 히트박스 18×14
- 재분열 차단: `is_spore=true` + `death_behavior="none"` 이중 가드
- **보류된 타 안**: A 빛나비 / B 이끼 정령 — 추후 2~5구역 고유 적 후보로 재활용 가능

### 구현된 airborne 프레임워크

| 파일 | 변경 |
|---|---|
| `data/enemies/enemy_stats_data.gd` | +3 필드: `movement_profile` (ground/airborne_homing), `homing_turn_rate`, `homing_max_speed` |
| `src/entities/enemies/base/enemy_movement.gd` | `_calculate_airborne()` 분기 — CHASE에서 `vel.lerp(desired, turn_rate * delta)` 조향, IDLE/PATROL/HURT/DEAD은 hover 감쇠 |
| `src/entities/enemies/base/base_enemy.gd` | `gravity_scale==0` 시 중력/floor snap 스킵 (airborne) |
| `src/world/stages/Stage1_*.tscn` (7) | `ext_resource` 경로를 `zone1/*.tres`로 치환 |

---

## 5. 3-3 — 1구역 보스

### 방향성 (GDD / BOSSES.md 기반)
- **정체성**: 숲의 거대 오브젝트가 괴물화 — 표면적 저주
- **페이즈 수**: 2 (1구역 확정)
- **보상 3종**: 잠금 해제 능력 + 스토리 단서 + 강화 포인트/장비
- **해금 능력 후보**: **빛 대시** — 1구역 "빛" 테마와 정합

### 보스 컨셉 안 (3안 중 택 1)

| 안 | 이름 | 페이즈 1 | 페이즈 2 |
|---|---|---|---|
| A | **거대 고목 (Ancient Oakheart)** | 근접 가지 휘두르기 (광역) | 그림자 뿌리 소환 + 원거리 포자 투사체 |
| B | **빛의 왕관 꽃 (Crown Blossom)** | 꽃잎 투사체 (원거리) | 분열 포자 + 근접 회전 공격 |
| C | **돌기둥 거상 (Standing Stone Guardian)** | 원거리 빔 (관통) | 돌팔매 + 근접 강타 |

### 전투 구조 기대
- 매크로(시간 조작 타이밍) + 마이크로(환경 오브젝트) + 액션(콤보/스킬) 세 레이어 모두 요구
- 페이즈 전환 = HP 50% 경계
- 환경 오브젝트 1~2종 배치 (보스 컨셉에 맞춰 거울/렌즈/차폐물 선택)

### D4 확정 (2026-04-18) — **A 거대 고목 (Ancient Oakheart)**
- P1: 근접 가지 휘두르기 (광역)
- P2: 그림자 뿌리 소환 + 원거리 포자 투사체
- 서사 연결: 3-2 어린 참나무의 "어른", 1-4 "고목의 뜰"의 고목이 괴물화
- 재사용: 1페이즈는 TreeEnemy 히트박스 확장, 2페이즈는 3-2 포자 호밍 인프라 재사용

### D5 확정 (2026-04-18) — **빛 대시 (LightDash) 확정**
- 1구역 보스 보상 = 게임 최초의 ABILITY 해금
- 용도: 2구역 진입 게이트 전용 (1구역 내 소급 숨김 구간은 배치하지 않음)
- `AbilitySystem.unlock("light_dash", ...)` 연동 (SkillSystem과 분리된 별도 Autoload, §5.1)

### 3-3 구현 결과 (2026-04-18)

**3-3-a/b/c**: 보스 엔티티 프레임워크 (거대 고목 2페이즈, 약점 노출 기믹)
- `data/bosses/boss_stats_data.gd` (BossStatsData) + `phase_1_branch_sweep` / `phase_2_branch_storm`
- `data/bosses/zone1/ancient_oakheart.tres` — HP 600 / ATK 15 / 약점 오프셋 (0,-56) / lens_focus 트리거

**3-3-d: 보상 → 영구 능력 → ABILITY 잠금 루프**
- `AbilitySystem` Autoload 신설 (`src/systems/ability/ability_system.gd`) — 능력 보유 + 보스 보상 분배 단일 책임
- `AbilityData` (`data/abilities/ability_data.gd`) + `light_dash.tres`
- `EventBus.ability_unlocked(ability_id)` 시그널
- `stage_lock_validator._validate_ability` — `lock_requirement`를 ability_id로 직접 비교
- `HiddenRevealerData.RevealCondition.FLAG` + `trigger_flag_id` (5번째 조건) — `state_flag_changed` 구독
- `PlayerStateMachine.State.LIGHT_DASH` + `PlayerLightDash` 컴포넌트 — i-frame 부여
- `player_health.set_invulnerable(duration)` API
- `PlayerStatsData`: light_dash_speed=320 / duration=0.18 / cooldown=0.9 / iframe=0.22
- InputMap `light_dash` = O키 (K는 skill_3 점유로 회피)
- `stage_2_1.tres` (ABILITY=light_dash) + `Stage2_1.tscn` 스텁
- `Stage1_B.tscn` PortalRight (visible=false, process_mode=DISABLED) + `hidden_revealer_zone2_portal.tres` (FLAG=`story.zone1.oakheart_defeated`)
- `GrowthSystem.earn_growth_points(amount, source)` 공개 API

**보스 처치 루프 전체**
```
Boss HP 0 → base_boss.EventBus.boss_defeated.emit(boss_id)
          → AbilitySystem._dispatch_reward(BossStatsData)
            ├─ unlock(reward_ability_id)                    → EventBus.ability_unlocked
            ├─ GrowthSystem.earn_growth_points(reward_gp)
            ├─ StateFlags.set_flag(reward_story_flag)       → EventBus.state_flag_changed
            │                                                 → HiddenRevealer(FLAG).reveal → PortalRight 노출
            ├─ StateFlags.set_flag(reward_next_zone_flag)
            └─ EventBus.item_acquired(reward_item_ids)      → InventorySystem 수신
```

**3-3-e: 통합 QA (2026-04-18)**
- 구조적 QA: 시그널 배선/참조 정합성/잠금 엔드투엔드 체크 통과
- 발견 버그 1건 수정: `player_health.set_invulnerable`이 `_invincible_timer.wait_time`을 덮어쓴 뒤 복원하지 않아 일반 피격 무적 시간이 단축되던 이슈 → `_start_invincibility`가 매번 `_config.invincible_duration`으로 리셋
- gdlint: 신규 파일 0 problems, 사전 `class-definitions-order` 1건은 3-3-d 이전부터 존재
- Godot 헤드리스 로드 정상 종료
- **미검증 (인게임 플레이테스트 필요)**: 빛 대시 i-frame 체감, 보스 처치 시 포탈 노출 연출, stage_2_1 실제 진입, 저장/복원 시 PortalRight 상태 지속

---

## 6. 3-4 — 거점 (✅ 구현 완료 2026-04-18)

### 시작 마을 (1구역 입구, 마을형)
- NPC 2명 — **상인 (ShopKeeper)** + **스토리 NPC (촌장)**
- 세이브, 완전 회복, 월드맵 포탈, 상점, 스킬/장비 관리 UI 접근 지점
- 스토리: 주인공의 출발점. 숲 진입 전 마지막 안전 구역

### 1-2 경계 간이형 거점
- 오브젝트만 (NPC 없음)
- 세이브, 완전 회복, 월드맵 포탈
- 보스 처치(stage_1_b) 이후 2구역 진입 직전 보급 지점

### D6 확정 (2026-04-18) — NPC 대화 흐름
- **대화 시스템**: Autoload 아님. `DialogueBox` 씬(CanvasLayer) + `DialogueData` 리소스. 분기/변수/다국어 미지원(후속 리팩터)
- **진행 키**: `interact`(F) 재사용. 시작 프레임 `call_deferred("_arm")`으로 input 겹침 방지
- **입력 잠금 책임**: DialogueBox가 `player.set_physics_process(false)` 토글
- **EventBus 시그널**: `dialogue_started(npc_id)` / `dialogue_finished(npc_id)`
- **스토리 NPC 1명 (촌장)** — 4줄 도입 (`village_story_intro.tres`): 저주 현상 → 출발 동기 → 튜토리얼 힌트 → 선조 단서. 선조 진실 미언급(중반 반전 보존)
- **상인 첫 방문** — 1회 인사 대화 후 상점 UI 오픈. 플래그 `shop_keeper.{shop_id}.greeted`를 StateFlags에 영속화. 재방문 시 바로 UI

### 3-4 구현 결과

| sub-phase | 신설/수정 | 검증 |
|---|---|---|
| **3-4-a 거점 베이스 리팩터** | `src/world/checkpoints/checkpoint_base.gd` (67줄) — stage_entered/spawn_point_set/카메라 제한/BG/Ground. 기존 `test_checkpoint.gd`/`test_checkpoint_2.gd` 제거. 두 .tscn은 스크립트 경로만 교체 + @export 값 주입 | gdlint 0 / gdformat unchanged / 헤드리스 로드 |
| **3-4-b 대화 시스템 + BaseNpc** | `data/dialogues/dialogue_data.gd` (DialogueData 리소스) / `src/ui/common/dialogue/dialogue_box.gd` (120줄) / `src/entities/npcs/base/base_npc.gd` (110줄, ShopKeeper/StoryNpc 공통 접근 감지+HintLabel+interact) / EventBus 2개 시그널 추가 | — |
| **3-4-c 시작 마을** | `StartVillage.tscn` + `start_village.tres` + `StoryNpc.tscn/story_npc.gd` + `village_story_intro.tres` + `shop_keeper_first_greeting.tres`. ShopKeeper BaseNpc로 이관 + 첫 방문 분기 로직 + StateFlags 연동. Stage1_1.tscn에 PortalLeft(→start_village) 추가 + stage_1_1.tres adjacent 갱신 | — |
| **3-4-d 경계 거점** | `BorderCheckpoint.tscn`(베이스 직결) + `border_checkpoint.tres`. Stage1_B.tscn PortalRight(숨겨진) target 재배선(stage_2_1→border_checkpoint). Stage2_1.tscn PortalLeft target 재배선(stage_1_b→border_checkpoint). stage_1_b/stage_2_1 adjacent 갱신 | — |
| **3-4-e 월드맵 등록 + QA** | 신규 `.tres` 2건은 StageSystem BFS로 자동 등록(별도 API 불필요). 본 §6 구현 결과 subsection + CORE_SYSTEMS §대화 시스템 추가 | gdlint 0 / gdformat 6 unchanged / 헤드리스 로드 |

### 시나리오 루프 (신규)
```
[new game] start_village (회복+세이브+상인 첫 인사+촌장 대화)
  ├─ PortalRight → stage_1_1 → ... → stage_1_6 → stage_1_b (보스)
  │                                                   │
  │                                                   └─ 보스 처치 시 PortalRight 공개
  │                                                        │
  │                                                        ▼
  │                                                  border_checkpoint (회복+세이브)
  │                                                        │
  │                                                        ├─ PortalRight → stage_2_1 (ABILITY=light_dash 필요)
  │                                                        └─ PortalLeft  → stage_1_b (복귀)
  └─ 월드맵 포탈 → 패스트트래블 (발견된 거점)
```

### 미검증 (인게임 플레이테스트 필요)
- 상인 첫 방문 대화→상점 UI 오픈 체감 흐름
- StateFlags 저장/로드 후 재방문 시 대화 스킵 지속
- 대화 중 이동/공격 입력이 완전 차단되는지
- border_checkpoint에서 stage_2_1 진입 시 ABILITY 잠금 메시지 노출

### 결정 보류 → Phase 5
- 화폐 시스템 — 1구역 상점은 당분간 "무조건 구매" 유지

---

## 7. 3-5 — 월드맵 (기본)

현재 (Phase 2-8b) 상태 기반 확장:

| 항목 | 상태 |
|---|---|
| 월드맵 UI (노드그래프, 거점 발견 추적, 패스트트래블) | ✅ |
| 1구역 영역 탑뷰 픽셀아트 | ⏳ Phase 3-7 아트와 병행 |
| 시간 오버레이 (정지=회색, 낮=밝음, 밤=어둠 — 영역별 필터) | ⏳ Phase 3-5 |
| 클리어 상태 시각화 (미클리어/절반/완전) | ⏳ Phase 3-5 |
| 땅거미 위치 아이콘 | ⏳ Phase 3-5 |

---

## 8. 3-6 — UI 완성

### 필수 추가 UI

| 항목 | 현재 상태 | 3-6 목표 |
|---|---|---|
| 인게임 HUD | ✅ 시계/HP/시간자원/스킬/소모품/땅거미 | 미니맵 추가 |
| 타이틀 화면 | ❌ | 새 게임 / 이어하기 / 설정 |
| 일시정지 메뉴 | ❌ | 재개 / 설정 / 타이틀로 |
| 장비 관리 메뉴 | ✅ Tab 인벤토리 | 디자인 폴리싱 |
| 스킬 관리 메뉴 | ❌ (장착은 되지만 UI 없음) | 4슬롯 장착/해제 + 스킬 상세 |
| 맵 상세 패널 | ❌ | 월드맵 클릭 시 해당 맵 정보/입장 |

### 알려진 제한 대응
- **세이브 로드 시 초기 씬 1~2프레임 노출** (Phase 2-8a known issue) → **타이틀/로딩 화면 추가 시 자연 해결**

---

## 9. 3-7 — 1구역 아트 + 이펙트 (동시 진행)

### 아트 스펙 상태
- Tier 1 명세 완료, 메타 UI 명세 완료, 한글 폰트 리서치 완료
- `docs/art_specs/` 하위 기존 명세서 활용 + 3-7 착수 전 결정 대기 사항 정리 필요

### 이펙트 로드맵 (EFFECTS.md Pass 1~5c 일괄 적용, **안 A 확정**)
- **Pass 1**: 카메라 쉐이크 (공격/피격/폭발)
- **Pass 2**: 힛 플래시 + 힛스톱 + 데미지 넘버 재설계 + 파티클
- **Pass 5c**: 슬래시 트레일 + 검광 + 피니시 컷인

### 결정 대기
- **D7** EFFECTS.md 디렉션 6가지 — 아트 착수 전 확정 필요
- **D8** UI 아트 팔레트/톤/모티프 — 잠정 기록, 아트 작업 중 변경 가능

### 제작 순서 (권장)
1. 플레이어 스프라이트 + 애니메이션
2. 1구역 타일셋
3. 1구역 적/보스 스프라이트
4. 1구역 배경
5. UI 아트 + 이펙트 Pass 1
6. 이펙트 Pass 2 + 데미지 넘버 재설계
7. 이펙트 Pass 5c (슬래시/피니시 컷인)

---

## 10. 3-8 — 사운드 (기본)

- 효과음 (공격, 피격, 시간 조작, 적 처치, 환경 오브젝트 상호작용)
- 1구역 BGM (몽환, 빛이 쏟아지는 느낌)

### 결정 대기
- **D9** 사운드/음악 제작 방식 (직접 / 외주 / 에셋 구매) — DEVELOPMENT_PLAN 미결 항목

---

## 11. Phase 3 완료 기준

```
타이틀 → 게임 시작
  → 시작 마을에서 출발
  → 1구역 6스테이지 + 추가조작 발견
  → 모든 스테이지 완전 클리어
  → 1구역 보스 전투 + 처치
  → 보상 획득 (능력 + 스토리 단서 + 강화)
  → "1구역 클리어" — 2구역 해금
  → 첫 플레이 체험 완결
```

**이 시점에서 외부 피드백 수집 가능 (데모 빌드)**

---

## 12. 진입 직전 결정 대기 항목 요약

| 번호 | 항목 | 결정 시점 |
|---|---|---|
| ~~D1~~ | ~~추가조작 1-H 숨김 조건~~ | ✅ 확정 (2026-04-18) — §3 참조 |
| ~~D2~~ | ~~ENVIRONMENT 잠금 조건 정의~~ | ✅ 확정 (2026-04-18) — §3 참조 |
| ~~D3~~ | ~~1구역 고유 적 (3안 중 1)~~ | ✅ 확정 (2026-04-18) — **C 빛가루 포자**, §4 참조 |
| ~~D4~~ | ~~1구역 보스 컨셉 (3안 중 1)~~ | ✅ 확정 (2026-04-18) — **A 거대 고목**, §5 참조 |
| ~~D5~~ | ~~1구역 보스 보상 강화 이동 (빛 대시 확정 여부)~~ | ✅ 확정 (2026-04-18) — **빛 대시**, §5 참조 |
| D6 | 시작 마을 NPC 대화 흐름 | ✅ 확정 (2026-04-18) — §6 참조 |
| D7 | EFFECTS.md 디렉션 6가지 | 3-7 착수 전 |
| D8 | UI 아트 팔레트/톤/모티프 | 3-7 착수 전 |
| D9 | 사운드 제작 방식 | 3-8 착수 전 |

---

## 13. 참조

- `DEVELOPMENT_PLAN.md` — §Phase 3 원본 로드맵
- `GDD.md` — 핵심 메카닉 및 구역 구조
- `WORLD_DESIGN.md` — 구역 테마 및 거점 배치 초안
- `STAGES.md` — 맵 등급, 잠금 구조, 클리어 단계
- `BOSSES.md` — 보스 정체성 및 페이즈 수
- `COMBAT.md` — 전투 시스템 + 환경 오브젝트 메커니즘
- `SKILLS.md` — 스킬 프레임워크 및 잠금 해제 능력
- `ENEMIES.md` — 베이스 4종 + 서브타입 방향
- `EFFECTS.md` — 이펙트/연출 설계 (Phase 3-7 참조)
- `art_specs/` — 아트 명세서 (Tier 1 완료)
