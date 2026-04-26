# 시간이 멈춘 숲 — 2구역 콘텐츠 계획

> Phase 4-A 진입 직전 콘텐츠 양산 슬라이스 기준 문서.
> 작성일: 2026-04-25
> 상태: **구현 완료** (Step 0~5 + 7 ✅, Step 6 사용자 수시 진행).
> 상위: [WORLD_DESIGN.md §1](WORLD_DESIGN.md) / [STAGES.md §5](STAGES.md) / [BOSSES.md](BOSSES.md) / [ENEMIES.md](ENEMIES.md) / [STORY.md](STORY.md)

---

## 1. 개요

| 항목 | 값 |
|---|---|
| 테마 | 안개 습지 (몽환적 → 어두워짐 그라디언트의 2단계) |
| 분위기 | 안개 자욱, 시야 흐림, 물 반사면 존재, 불안함 |
| 스토리 톤 | "숲이 무언가 숨기고 있다" — 봉인 거래의 1차 단서 발견 |
| 스테이지 수 | 통상 8 (2-1 ~ 2-7 + 숨김 2-H) + 보스 1 (2-B) = **9** |
| 보스 페이즈 | 2 (거대 오브젝트 괴물화 심화) |
| 진입 거점 | `border_checkpoint` (1-2 경계 간이형, 기존) |
| 출구 거점 | 2-3 경계 마을형 + 간이형 (Phase 4-B 진입 시 추가) |
| 자연 경계 | 강/개울(1-2) → 짙은 안개벽(2-3) |
| 보스 보상 | `shadow_phase` 능력 + 강화 포인트 7 + 액세서리 1 |

---

## 2. 적 설계

### 2.1 서브타입 4종 — `data/enemies/zone2/`

zone1 대비 **HP·공격력 ×1.3~1.5** 계단식. 시각·이름은 습지 테마.

| 베이스 | 작명 | 파일 | 핵심 변경 |
|---|---|---|---|
| 나무 | **젖은 버드나무** | `weeping_willow.tres` | HP 90→130, 공격력 9→13 |
| 바위 | **수렁 돌멩이** | `mire_stone.tres` | HP 130→180, 경직 저항 0.6→0.7 |
| 꽃 | **독안개 백합** | `miasma_lily.tres` | HP 45→65, 공격력 5→7, 분열체는 `pollen_spore.tres` 재활용 |
| 돌기둥 | **젖은 비석** | `drowned_pillar.tres` | HP 70→100, 투사체 속도 140→160, 선딜 0.6→0.55 |

### 2.2 구역 고유 적 1종

| 작명 | 파일 | 신규 행동 모듈 | 핵심 |
|---|---|---|---|
| **늪 촉수** | `marsh_tendril.tres` | `attack_behavior_ground_tether.gd` (신규) | 지면 고정, 짧은 사거리에서 잡아당기기 |

→ 신규 행동 카테고리(지면 고정형) 도입. zone1의 공중 호밍(빛가루 포자)과 변주.

---

## 3. 보스 — 늪의 어머니 (Mire Mother)

| 항목 | 값 |
|---|---|
| 파일 | `data/bosses/zone2/mire_mother.tres` |
| HP | 850 (zone1=600에서 ×1.4) |
| ATK | 22 (zone1=15에서 ×1.5) |
| 페이즈 | 2 |
| 약점 | 안개가 걷히는 순간만 노출 — 등불 ON + 보스 머리 위 약점 영역 트리거 |

### 3.1 페이즈 설계

| 페이즈 | 패턴 | 빌딩블록 |
|---|---|---|
| Phase 1 | 근접 휘두르기 + 안개 방출(시야 차단 영역) | `boss_melee_aoe` 재활용 + **`boss_fog_release.gd`** (신규) |
| Phase 2 | 물 반사면 통한 위치 텔레포트 + 원거리 포자 wave | **`boss_reflection_teleport.gd`** (신규) + `boss_ranged_spread` 재활용 |

### 3.2 보상

| 필드 | 값 |
|---|---|
| `reward_ability_id` | `shadow_phase` |
| `reward_growth_points` | 7 |
| `reward_story_flag` | `story.zone2.mire_mother_defeated` |
| `reward_next_zone_flag` | `stage_progress.zone3_unlocked` |
| `reward_item_ids` | `["mire_pendant"]` (액세서리 1개) |

### 3.3 신규 아이템

| ID | 슬롯 | 효과 | 비고 |
|---|---|---|---|
| `mire_pendant` | 액세서리 | 시간 자원 회복속도 +10% | zone2 시그니처 |

---

## 4. 스테이지 토폴로지

```
[border_checkpoint] → 2-1 → 2-2 → 2-3 ─┬─ 2-4 → 2-5 → 2-7 → 2-B → [zone3 진입]
                                       └─ 2-6 → 2-H (숨김, 수문)
```

| 스테이지 | 표시명(잠정) | 시간 | 잠금 | 적 수 | 기믹 |
|---|---|---|---|---|---|
| 2-1 | 안개의 문턱 | 16시 | ABILITY(`light_dash`) ✅ 기존 | 3 | 진입, 안개 도입 |
| 2-2 | 물웅덩이 | 18시 | NONE | 3 | 안개 + 물 반사면 학습 |
| 2-3 | 가라앉은 길 | 22시 | LIGHT | 4 | 등불 ON 강제, 시야 차단 안개 |
| 2-4 | 거울 늪 | 14시 | ENVIRONMENT(`light_sensor:sensor_2_4_pool`) | 4 | 물 반사면 본격 (ReflectiveFloor) |
| 2-5 | 잠긴 둑 | 20시 | PURIFY (2-3 완전클리어) | 4 | 정화 메커닉 재학습 |
| 2-6 | 안개 갈림길 | 11시 | NONE | 3 | 호흡, **수문 추가조작 힌트 위치** |
| 2-7 | 마지막 늪 | 23시 | LIGHT | 5 | 보스 직전, 강화된 적 배치 |
| 2-H | 잠긴 수문 | 8시 | 숨김 (HiddenRevealer, 2-6에서 발견) | 2 | **수문 조작 → state_flag** |
| 2-B | 늪의 어머니의 뜰 | 17시 | 통상 8개 fully cleared | 1(보스) | 보스 아레나 |

> **잠금 분포 의도**: 5종 잠금(NONE/LIGHT/PURIFY/ENVIRONMENT/ABILITY)을 모두 한 번씩 체험. zone1 패턴 답습.

---

## 5. 환경 메커니즘

### 5.1 기존 활용
- **ReflectiveFloor** ([Phase 3-1 구현](STAGES.md)): 2-2/2-4에서 본격 사용
- **LightSensor / HiddenRevealer**: 2-4 잠금 + 2-H 숨김
- **PurificationDetector**: 2-5 정화 잠금

### 5.2 신규 1종

| 컴포넌트 | 파일 | 역할 |
|---|---|---|
| **Floodgate (수문)** | `src/entities/objects/floodgate.gd` (신규, ~80~120줄) | Cover/Lens 패턴. 토글 시 `EventBus.environment_state_changed` + `StateFlags.set("world.zone2.floodgate_opened")`. zone3+에서 활용. |

### 5.3 안개 시야 차단

**선택 (A)**: Light2D 영역 마스킹 + CanvasModulate 어두운 영역 = 셰이더 없이 구현. Pass 5에서 `fog_volume.gdshader` 업그레이드 옵션 보류.

---

## 6. 스토리 비트 4개

| 시점 | 비트 | 구현 위치 |
|---|---|---|
| 2-1 진입 | "숲이 더 깊어진다. 발 밑이 젖어 있다." | StageNameplate + intro_sequence 또는 환경 텍스트 |
| 2-3 경계 마을형 NPC | **선조 기록 단편 1차** — 봉인이 *거래*였음을 암시 | `data/dialogues/zone2/elder_record_1.tres` (신규) |
| 2-B 입구 | "이건 단순한 괴물이 아니다. 통곡 소리가 들린다." | StageNameplate |
| 2-B 처치 후 | "잠수하는 법을 배웠다. 수면 아래도 길이다." | shadow_phase 해금 컷인 (Pass 5 또는 hardcode) |

---

## 7. 신규 빌딩블록 체크리스트

| 항목 | 비용 | 의존성 | 상태 |
|---|---|---|---|
| `attack_behavior_ground_tether.gd` (적 행동) | 80~100줄 | base_enemy 상속 | ✅ Step 2 (60줄) |
| `attack_behavior_boss_fog_release.gd` (페이즈 1 패턴) | 100~150줄 | boss_melee_aoe 패턴 답습 | ✅ Step 3 (130줄, 잔존 안개 페이드 포함) |
| `attack_behavior_boss_reflection_teleport.gd` (페이즈 2 패턴) | 150~200줄 | player group lookup (ReflectiveFloor 쿼리는 추후) | ✅ Step 3 (75줄, 단순화) |
| `floodgate.gd` (환경 오브젝트) | 80~120줄 | Cover/Lens 패턴 답습 | ✅ Step 4 (45줄, 단순 토글) |
| 데이터: 적 .tres 5 (Step 2 ✅) + 보스 .tres 1 ✅ + 페이즈 .tres 2 ✅ + 스테이지 .tres 9 (2-1 ✅) + 아이템 .tres 1 ✅ (mire_pendant) + 다이얼로그 .tres 1+ | — | — | ⚙️ 대부분 |
| 스테이지 .tscn 9 (Stage2_1 ~ Stage2_7 + Stage2_H + Stage2_B + MireMother.tscn) | 한 스테이지당 1~3일 | — | ✅ 9/9 (MireMother.tscn 포함) |
| (선택) `fog_volume.gdshader` | 1일 | — | Pass 5로 보류 |

**총 코드 ~600줄 + 데이터 ~20 .tres + 씬 9 .tscn**

---

## 8. 미결정 (착수 중 확정)

- [ ] 보스 늪의 어머니 외형 컨셉 (아트 명세서 작성 시점)
- [ ] 안개 시야 차단의 적 시야 영향 (적 AI가 안개 안에서 플레이어 못 찾는지 여부)
- [x] 2-3 경계 거점 위치 — `mire_village` (마을형) + `mire_outpost` (간이형) Phase 4-B Step 5-C 신설. zone2 stage_2_b PortalRight=`mire_village`로 갱신
- [ ] 2-H 수문 힌트 전달 방식 (NPC 대사? 환경 오브젝트 시각 단서?)
- [ ] 약점 트리거 — 등불 ON 단순? 또는 환경(반사면) 결합?

---

## 9. 진행 순서

1. ✅ Step 0 본 문서 작성
2. ✅ Step 1 stage_2_1 양산
3. ✅ Step 2 적 .tres 5종 + `ground_tether`
4. ✅ Step 3 보스 .tres + 페이즈 패턴 2종 + mire_pendant
5. ✅ Step 4 Floodgate + stage_2_h.tres
6. ✅ Step 5 스테이지 .tscn 9개 양산 + MireMother.tscn
7. ⏭️ **Step 6 러프 밸런싱** — 사용자 *수시 진행*. zone2 통과 + 보스 처치 + 체감 후 .tres 미세 조정. 통과 마킹.
8. ✅ Step 7 STORY/BOSSES/ENEMIES/WORLD_DESIGN 본 문서 마이그레이션

---

## 변경 이력

| 날짜 | 내용 |
|---|---|
| 2026-04-25 | 초안 작성 (7개 결정 항목 통합) |
| 2026-04-25 | Step 1 완료 — stage_2_1 양산 (zone1 적 placeholder, FogOverlay) |
| 2026-04-25 | Step 2 완료 — 적 .tres 5종 + `attack_behavior_ground_tether.gd` (60줄). enemy_stats_data enum 확장. base_enemy 디스패치 추가. |
| 2026-04-25 | Step 3 완료 — 보스 패턴 2종 + Mire Mother + mire_pendant. `boss_fog_release.gd` (130줄, 잔존 안개 페이드 포함) + `boss_reflection_teleport.gd` (75줄). data: `mire_mother.tres` (HP 850/ATK 22/2페이즈) + phase_1_fog_release / phase_2_reflection_storm + `mire_pendant.tres` (액세서리, 시간회복+10%). 약점 source는 임시로 `lens_focus` 재활용 (등불 트리거 인프라는 zone3 대기). |
| 2026-04-25 | Step 4 완료 — Floodgate 환경 오브젝트 + stage_2_h.tres. `floodgate.gd` (45줄, 단순 토글) + `FloodgateData` + `Floodgate.tscn` + `floodgate_basic.tres`. StateFlags `world.zone2.floodgate_opened` 영속 플래그. zone3+ HiddenRevealer가 구독해 막힌 경로 노출 (zone3 콘텐츠 진입 시 결정). stage_2_h.tres 등록 — .tscn은 Step 5에서. |
| 2026-04-25 | Step 5 완료 — zone2 9 스테이지 모두 양산. 8 sub-step (5-1~5-8): 2-1 적 교체는 미진행, 2-2~2-7 + 2-H + 2-B + MireMother.tscn 신규. 잠금 5종 모두 체험 (ABILITY/NONE/LIGHT/ENVIRONMENT/PURIFY/숨김). 환경 인프라 추가: light_sensor_2_4_pool / light_sensor_2_6_hidden / hidden_revealer_zone2_h. 누적 약 3시간. |
| 2026-04-25 | Step 7 완료 — 본 문서 마이그레이션. ENEMIES.md 2구역 서브타입 4 + 늪 촉수 + ground_tether enum 확장 / BOSSES.md 늪의 어머니 명세 + 보상 맵 / STORY.md 1·2구역 스토리 단서 구체화 + 봉인 거래 1차 단서 위치 명시 / WORLD_DESIGN.md 2구역 수문 추가조작 ✅ 확정. + stage_2_1 적 zone1 placeholder → zone2(weeping_willow/mire_stone/miasma_lily) 교체 마무리. Step 6은 사용자 수시 진행으로 통과. |
