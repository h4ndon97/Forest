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
| **Phase 3-5 월드맵 구현** | **✅ 완료 (2026-04-18) — D10/D11/D12 확정 + 3-5-a/b/c/d. §7 구현 결과 참조** |
| **Phase 3-6 UI Pass 2 §2.2/§2.3** | **✅ 완료 (2026-04-18) — §2.2는 ba721ad에서 선행, §2.3 호흡/저체력 펄스 구현. §8 구현 결과 참조** |
| **Phase 3-6 타이틀 화면** | **✅ 완료 (2026-04-19) — 4-메뉴 + 세이브 감지 + 덮어쓰기 확인 + fade in/out + `game_start_requested` 시그널 구동. §8 구현 결과 참조** |
| **Phase 3-6 일시정지 메뉴** | **✅ 완료 (2026-04-19) — 3-메뉴(이어하기/설정/타이틀로) + ESC 토글 + 다른 UI·대화·전환 차단 + `tree.paused` + BGM -12dB 덕킹 + 어두운 베일. §8 구현 결과 참조** |
| **Phase 3-6 메뉴 마감 (3-6-a/b/c)** | **✅ 완료 (2026-04-19) — 월드맵 상세 패널 + 인벤토리 5-파일 분리(EquipmentTab+SkillTab+Navigator+TabController, Q/E 탭·F·Enter 장착·J 탭별 분기·attack 액션 이중 발화 차단) + MenuFrame/MenuSelectionRect 공통 컴포넌트 + KEYMAP v0.3. 미니맵은 Phase 4 이월. §8 구현 결과 참조** |

**→ Phase 3-6 종결 (2026-04-19). 다음=Phase 3-7 1구역 아트 + 이펙트 착수.** 미니맵은 Phase 4 이월. §2.1 arc_mask shader는 placeholder 충분으로 보류, §2.4 반딧불 파티클은 Phase 3-7 이월

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

## 7. 3-5 — 월드맵 (기본, ✅ 구현 완료 2026-04-18)

현재 (Phase 2-8b) 상태 기반 확장:

| 항목 | 상태 |
|---|---|
| 월드맵 UI (노드그래프, 거점 발견 추적, 패스트트래블) | ✅ 2-8b 완료 |
| 1구역 영역 탑뷰 픽셀아트 | ⏳ Phase 3-7 아트와 병행 |
| 시간 오버레이 (정지=채도0, 낮=따뜻한 톤, 밤=차가운 톤) | ✅ 3-5-a 완료 |
| 클리어 상태 시각화 (미클리어/절반/완전) | ✅ 2-8b + 3-5 폴리싱 |
| 땅거미 위치 아이콘 (⚠ placeholder) | ✅ 3-5-b 완료 |
| 영역(zone) 그룹핑 + 라벨 + 구분선 | ✅ 3-5-c 완료 |

### D10/D11/D12 확정 (2026-04-18)

| 번호 | 항목 | 결정 |
|---|---|---|
| **D10** | 영역 구분 방식 | `StageData.zone_id: String` 필드 신설 (vs prefix 파싱) — CLAUDE.md §2.4 원칙 + checkpoint 스테이지의 비규칙적 ID 수용 |
| **D11** | 시간 정지 오버레이 톤 | **채도만 0** (vs 회색 덮기) — 클리어 상태 색의 명도 유지 |
| **D12** | 땅거미 아이콘 | **단일 "⚠" 스타일 placeholder** (Phase 3-7에서 거미 실루엣으로 교체) |

### 3-5 구현 결과

| sub-phase | 신설/수정 | 검증 |
|---|---|---|
| **3-5-a 시간 오버레이** | `world_map_graph_builder.gd` +3 함수(compute_hour_tint, desaturate, compute_node_bg_color) + DAY_TINT/NIGHT_TINT/CHECKPOINT_TINT 상수. UI가 `time_flow_started/stopped` + `current_hour_changed` 구독해 `_refresh_bg_colors()`로 증분 갱신 | gdlint 0 / gdformat clean / 헤드리스 로드 |
| **3-5-b 땅거미 아이콘** | `DuskSpiderSystem.get_active_stages() -> Array` 공개 API. `world_map_graph_builder.create_spider_icon()` 추가. UI가 `dusk_spider_spawned/arrived/defeated` 구독해 `_refresh_spider_icons()` 갱신 | — |
| **3-5-c 영역 그룹핑** | `StageData.zone_id: String` 신규 필드 + 10개 .tres 마이그레이션(zone_1: start_village~border_checkpoint, zone_2: stage_2_1). `world_map_zone_layout.gd` 신설 — BFS 정렬 순서에서 zone_id 연속 구간 그룹핑, 라벨/세로 구분선 배치 | gdlint 0 |
| **3-5-d QA** | 300줄 제한 준수를 위해 zone 레이아웃 로직 분리(world_map_zone_layout.gd=69줄, world_map_ui.gd=295줄, world_map_graph_builder.gd=230줄) | gdlint 0 / gdformat clean / 헤드리스 로드 성공 |

### 미검증 (인게임 플레이테스트 필요)
- 월드맵 열림 중 시간 흐름 시 hour 변화가 배경색에 실시간 반영되는지
- 시간 정지 진입/해제 시 채도 0 필터 on/off 전환
- 땅거미 스폰/이동/처치 시 ⚠ 아이콘 실시간 추가/이동/제거
- 영역 라벨 위치(노드 하단 y=222)가 힌트 라벨과 겹치지 않는지
- 거점 스테이지(start_village 등)에 시간 오버레이가 적절히 적용되는지 (현재 `CHECKPOINT_TINT` 고정)

### 제한/향후 개선
- 월드맵 노드 레이아웃이 1D 선형(BFS). Phase 3-7 아트 적용 시 2D 레이아웃 or 탑뷰 픽셀아트 기반 재설계 가능
- test_* 스테이지들은 zone_id=""로 "기타" 처리 (라벨 없음)
- 땅거미 TRACKING 중간 transition 시그널이 없어 `current_hour_changed` 폴링으로 간접 갱신

---

## 8. 3-6 — UI 완성

### 필수 추가 UI

| 항목 | 현재 상태 | 3-6 목표 |
|---|---|---|
| 인게임 HUD (A/B 카테고리 Pass 1) | ✅ 33ac495 — 4분면 배치 + HP pip + 콤보 + 스킬 슬롯 + 포션 + 시간 코어 placeholder | 완료 |
| 인게임 HUD (A-7 스킬 슬롯 Pass 2 §2.2) | ✅ ba721ad — 원형 링 + 쿨다운 스윕 + 이끼 배경 + ready 펄스 + icon_path fallback | 완료 |
| 인게임 HUD (A-10 호흡/저체력 Pass 2 §2.3) | ✅ 2026-04-18 — HP pip 호흡(STOPPED 1.0s) + 저체력 맥동(0.8s 붉은) + 자원 링 호흡(FLOWING) + 저자원 맥동 | 완료 |
| 인게임 HUD (B-6 일식 링 shader §2.1) | ❌ **영구 보류 확정** (2026-04-18) — 체감 검증 통과, `draw_arc` placeholder 충분 | 영구 보류 |
| 인게임 HUD (회복 반딧불 파티클 §2.4) | ⏸ Phase 3-7 이월 — 에셋 의존 | Phase 3-7 |
| 인게임 HUD 미니맵 | ⏸ Phase 4 이월 (2026-04-19) | Phase 4 |
| 타이틀 화면 | ✅ 2026-04-19 — 새 게임/이어하기/설정/종료 + 세이브 감지 + 덮어쓰기 확인 + fade + F12 스킵 | 완료 |
| 일시정지 메뉴 | ✅ 2026-04-19 — 이어하기/설정/타이틀로 3-메뉴 + ESC 토글 + 다른 UI·대화·전환 차단 + `tree.paused` + BGM -12dB + 어두운 베일 | 완료 |
| 장비 관리 메뉴 | ✅ 2026-04-19 — Q/E 탭 + EquipmentTab 분리 + 거점 제한 유지 + 공통 컴포넌트 정리 | 완료 |
| 스킬 관리 메뉴 | ✅ 2026-04-19 — 4슬롯/해금 목록 2-컬럼 + ←→ 컬럼 / ↑↓ 항목 / F 장착 / J 해제 + 거점 제한 + 속성·티어·쿨다운 상세 | 완료 |
| 맵 상세 패널 | ✅ 2026-04-19 — `world_map_detail_panel` 우측 패널, 이름/구역/시각/클리어/잠금/⚠/인접 실시간 갱신 + Enter 단일 이동 | 완료 |

### 구현 결과 (2026-04-18 Pass 2 §2.3)

- **`src/ui/hud/combat_hud.gd`**
  - `EventBus.time_state_changed` 구독 (`_time_state` 추적)
  - `_process(delta)` 매 프레임 `_apply_pip_pulse()` 호출 — 채워진 pip에만 적용
  - 우선순위: 저체력(<20%, 0.8s 붉은 맥동) > STOPPED 호흡(1.0s alpha ±5%) > 무처리
  - 상수: `BREATH_PERIOD=1.0`, `BREATH_AMPLITUDE=0.05`, `LOW_HP_PERIOD=0.8`, `LOW_HP_THRESHOLD=0.2`, `LOW_HP_TINT=#E64646`
- **`src/ui/hud/time_core_renderer.gd`**
  - `_process(delta)` `_needs_animated_redraw()` 조건부 `queue_redraw()` — 상시 갱신 방지
  - `_eclipse_fill_color()` 우선순위: 저자원 > STOPPED dim > FLOWING 호흡 > 기본
  - 저자원: `COLOR_ECLIPSE_FULL.lerp(COLOR_LOW_RESOURCE_PULSE, k)` (0.8s sin)
  - FLOWING: alpha ±5%, 1.0s 주기 — A-7/A-10/B-5 리듬 동조

### 알려진 제한 대응
- **세이브 로드 시 초기 씬 1~2프레임 노출** (Phase 2-8a known issue) → **타이틀 화면 추가로 해결됨** (2026-04-19 — `main_scene`을 `TitleScreen.tscn`로 변경하여 StageSystem 자동 로드 경로 제거, `game_start_requested` 시그널 기반 명시적 진입)

### 구현 결과 (2026-04-19 타이틀 화면)

**신규 파일 (5개, 모두 300줄 이하)**
- `src/ui/menus/title/TitleScreen.tscn` / `title_screen.gd` — 루트 오케스트레이터 (CanvasLayer 5단: bg/fg/menu/overlay/settings). `StageSystem.has_save_file()` 확인 후 이어하기 버튼 활성화. 로고 호흡(1.0s ±5%) + fade in/out + `debug_auto_start` @export + F12 debug_skip_title
- `title_menu_controller.gd` — 4 메뉴(새 게임/이어하기/설정/종료) + 키/마우스 네비 + 선택 rect 호흡(1.0s)
- `title_confirm_dialog.gd` — 세이브 덮어쓰기 확인 모달(기본=아니오)
- `title_settings_panel.gd` — BGM/SFX/창모드 placeholder (Phase 5 실구현)
- `title_background.gd` — `title_bg.png` 존재 시 Sprite2D, 없으면 ColorRect + 반딧불 12개 fallback

**시스템 수정**
- `EventBus.game_start_requested(is_new_game: bool)` 시그널 추가
- `StageSystem`: `_ready` 자동 세이브 로드 제거, `game_start_requested` 시그널 기반으로 전환. `has_save_file()` 공개 API 추가. 새 게임 시 세이브 삭제 + 상태 클리어 + `stage_transition_requested("start_village", "checkpoint")`
- `CheckpointBase._ensure_player_spawned()` — 거점 씬이 로드될 때 Player 노드가 없으면 자체 인스턴스화 (타이틀→거점 부팅 경로용)
- `project.godot`: `main_scene = TitleScreen.tscn` + `debug_skip_title`(F12) InputMap 추가

**HUD 가시성 제어 (`game_hud` 그룹)**
- TimeSystem/CombatSystem/SkillSystem/InventorySystem/DuskSpiderSystem `_load_hud()` — instantiate → `add_child` → `add_to_group("game_hud")` 순서
- KeybindHud `_ready()` — `add_to_group("game_hud")` 추가
- TitleScreen — `_ready`에서 `_hide_game_hud.call_deferred()` (autoload의 `_load_hud.call_deferred()`보다 FIFO 뒤에 실행되도록). `_start_game` fade-out 완료 후 `set_visible(true)` 호출로 복원
- **중요**: `call_group` 기본은 immediate(`GROUP_CALL_DEFAULT=0`). HUD 인스턴스화가 deferred 큐에 들어가 있으므로 hide 호출도 deferred로 미뤄야 함. 또한 HUD는 CanvasLayer라 `hide()/show()` 불가 → `set_visible(bool)` 사용 필수

**CanvasLayer 자식 Control 앵커 이슈**
- `control.anchors_preset = Control.PRESET_FULL_RECT` 프로퍼티 세터는 CanvasLayer 자식 Control에서 size를 viewport에 맞게 설정하지 못함 → 메뉴가 좌상단에 size 0으로 쏠림
- 해결: `control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)` 메서드 사용
- 적용: `title_screen.gd`/`title_menu_controller.gd`/`title_confirm_dialog.gd`/`title_settings_panel.gd`의 `_root`/`_fade_rect`/`_dim_rect` 전부 메서드 방식으로 전환

### 구현 결과 (2026-04-19 일시정지 메뉴)

**레퍼런스 리서치 기반 결정 (HK / Blasphemous / Salt and Sanctuary / AAA 공통)**
- 3-메뉴 확정 (이어하기 / 설정 / 타이틀로) — HK 4-메뉴 중 Achievements 제거, Blasphemous·Salt 표준
- "타이틀로" 경고 팝업 **없음** — 마지막 거점 자동 저장 상태이므로 진행 손실 위험 낮음. "※ 마지막 거점에서 이어집니다" 보조 라벨로 명시
- 설정 패널은 **타이틀과 공유** — `title_settings_panel.gd` preload 재사용 (일관성 + 중복 방지)
- BGM 덕킹 -12dB (AAA 표준), 어두운 베일 알파 60%

**신규 파일 (2개, 모두 300줄 이하)**
- `src/ui/menus/pause/pause_menu.gd` — Autoload CanvasLayer(layer=95, PROCESS_MODE_ALWAYS). 진입 시 `get_tree().paused = true` + BGM Master 버스 -12dB + 알파 60% 어두운 베일 + 240×320 플레이스홀더 프레임
- `pause_menu_controller.gd` — 3 메뉴 네비(↑/↓·↑/↓, J/Enter) + "※ 마지막 거점에서 이어집니다" 힌트 + 선택 rect 호흡 펄스(1.0s, 알파 ±0.10)

**시스템 수정**
- `EventBus` 3건 신설 — `game_paused` / `game_resumed` / `return_to_title_requested`
- `InventoryMenu` / `WorldMapUI` / `ShopMenu` — 공개 `is_open()` 게터 추가 (뮤텍스 게이팅용)
- `StageSystem._on_return_to_title_requested()` — `_current_stage_id = ""` + `change_scene_to_file.call_deferred(TitleScreen.tscn)`
- `project.godot` — `pause` InputMap 액션(ESC) + `PauseMenu` Autoload 등록 (ShopMenu 뒤, KeybindHud 앞)

**차단 조건 (뮤텍스)**
- `_in_game == false` (타이틀 화면)
- `_in_transition == true` (스테이지 전환 중, `stage_transition_started/completed`로 추적)
- `_dialog_active_count > 0` (대화 중, `dialogue_started/finished`로 카운트)
- `InventoryMenu.is_open()` or `WorldMapUI.is_open()` or `ShopMenu.is_open()` (다른 메뉴 열림)

**설정 패널 ESC 이중 트리거 방지**
- `pause`·`ui_cancel` 둘 다 ESC 바인딩 → 충돌 우려
- 해결: `_in_settings` 플래그로 pause `_process` 조기 return. `title_settings_panel`가 자체 `ui_cancel` 소비

**`_is_blocked()` max-returns 린트 대응**
- gdlint `max-returns=6` 위반 → 7개 `if/return true`를 2개 boolean 표현식으로 통합

### 구현 결과 (2026-04-19 메뉴 마감 — 3-6-a/b/c)

**3-6-c 공통 컴포넌트**
- `src/ui/common/menu_selection_rect.gd` (`class_name MenuSelectionRect`) — 호흡 펄스(1.0s ±0.10) 선택 사각. `set_target(Control)`/`clear_target()` API. `_process`에서 타깃 위치/크기 동기
- `src/ui/common/menu_frame.gd` (`class_name MenuFrame`) — 어두운 베일(α=0.6) + 중앙 테두리/배경 패널 + 상단 제목 + 하단 힌트 + `get_content_root()` Control. `setup(parent: CanvasLayer, frame_size, title_text)`
- `pause_menu` 마이그레이션: 자체 프레임/베일 코드 제거, MenuFrame/MenuSelectionRect 재사용 (224 → 155줄)
- `pause_menu_controller`: 호흡 로직을 MenuSelectionRect로 이관 (180 → 145줄)
- `title_menu_controller`: SelectionRect만 공통화 (전체 MenuFrame 마이그레이션은 4-CanvasLayer 구조상 위험으로 보류)

**3-6-a 월드맵 상세 패널**
- `src/ui/menus/world_map/world_map_detail_panel.gd` — `PanelContainer` 단독, 위치 (480, 60), 크기 (140, 240). `refresh(stage_id)`/`clear_display()` API
- 표시 항목: `display_name` + `zone_id` + 시각(`get_stage_hour` / STOPPED 시 "정지") + 클리어 상태(미/절반/완전/거점) + 잠금(빛/정화/환경/능력 — `AbilitySystem.has` 미충족 시 능력 ID 노출) + 땅거미 ⚠ + 인접 거점 수
- `world_map_ui._update_selection_highlight()`에서 `_detail_panel.refresh(selected_id)` 호출, 빈 상태에선 `clear_display()`. 단일 Enter 이동 (B안)

**3-6-b 인벤토리 5-파일 분리 (orchestrator + tab strip + 2 tabs + navigator)**
- `inventory_menu.gd` (orchestrator, 약 200줄) — Tab 토글, ESC 닫기, Q/E 탭 전환(`_input` 물리 키), 활성 탭으로 ↑↓/←→/Enter/F/J 라우팅. **이중 발화 방지**: `attack` 액션 라우팅 제거, J는 KEY_J 물리 키 단일 경로. F·Enter=양 탭 공통 장착, J=장비탭 장착 / 스킬탭 해제. 거점 진입/이탈 시 양 탭에 `set_at_checkpoint` 전파
- `inventory_tab_controller.gd` (`class_name InventoryTabController`, ~80줄) — 상단 [장비] / [스킬] 탭 헤더 표시 + `cycle(±1)` + `tab_changed(int)` 시그널
- `equipment_tab.gd` (`class_name EquipmentTab`, ~190줄) — 기존 장비 슬롯/소지품/정보 로직을 그대로 이관. 거점에서만 J 장착
- `skill_tab.gd` (`class_name SkillTab`, ~265줄) — 4-슬롯 좌 컬럼 + 해금 스킬 목록 우 컬럼 + 정보. F·Enter=빈 슬롯 자동 장착(없으면 현재 슬롯 인덱스), J=현재 슬롯 해제. 속성(빛/그림자/하이브리드) 색상, T1~3 티어 + 쿨다운/시간/데미지 상세
- `skill_tab_navigator.gd` (`class_name SkillTabNavigator`, RefCounted, ~55줄) — 컬럼/슬롯 인덱스/리스트 인덱스 상태. `navigate_vertical/horizontal`
- 거점 제한: `EquipmentTab`/`SkillTab` 둘 다 `_is_at_checkpoint == false`면 변경 액션 무시, 힌트 라벨에 "(장착은 거점에서만)" 표기
- `SkillSystem._auto_equip_debug` → `DEBUG_SKILL_AUTO_EQUIP: bool = true` 상수 게이팅 (수동 장착 시연 시 false 권장)
- 모든 신규 파일 < 300줄, 다섯 파일 모두 `gdlint`/`gdformat` 통과

### 체감 검증 완료 (Pass 2 §2.3, 2026-04-18 사용자 확인 — 전부 OK)

- [x] STOPPED HP pip 1.0s 호흡 (±5% 적정)
- [x] HP <20% 0.8s 붉은 맥동 위급감 적절
- [x] FLOWING 자원 링 호흡 시선 피로 없음
- [x] 자원 <20% 금↔붉은 보간 대비 충분

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
| ~~D10~~ | ~~영역 구분 방식(zone_id vs prefix)~~ | ✅ 확정 (2026-04-18) — **zone_id 필드**, §7 참조 |
| ~~D11~~ | ~~시간 정지 오버레이 톤(채도 0 vs 회색 덮기)~~ | ✅ 확정 (2026-04-18) — **채도 0**, §7 참조 |
| ~~D12~~ | ~~땅거미 아이콘 스타일~~ | ✅ 확정 (2026-04-18) — **⚠ placeholder**, §7 참조 |

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
