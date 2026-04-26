# 시간이 멈춘 숲 — 3구역 콘텐츠 계획

> Phase 4-B 진입 직전 콘텐츠 양산 슬라이스 기준 문서.
> 작성일: 2026-04-26
> 상태: **Step 0 진행 중** (본 문서 + STAGE_INDEX zone3 § 확장).
> 상위: [WORLD_DESIGN.md §1](WORLD_DESIGN.md) / [STAGES.md §5](STAGES.md) / [BOSSES.md](BOSSES.md) / [ENEMIES.md](ENEMIES.md) / [STORY.md](STORY.md) / [ZONE2_CONTENT_PLAN.md](ZONE2_CONTENT_PLAN.md)

---

## 1. 개요

| 항목 | 값 |
|---|---|
| 테마 | 폐허의 숲 (고목과 옛 왕국 유적이 뒤섞임. 인공물 첫 등장) |
| 분위기 | 고요·먼지 / 부서진 석조물 / 흐릿한 옛 영광 / **그림자 왕가의 흔적이 환경에 새겨짐** |
| 스토리 톤 | **전환점** — 옛 왕가(그림자 왕가)의 표식·기록 첫 발견. 정식 이름·수장은 zone4에서 |
| 스테이지 수 | 통상 9 (3-1 ~ 3-9) + 숨김 1 (3-H) + 보스 1 (3-B) = **11** |
| 보스 페이즈 | 3 (BOSSES.md §1 확정) |
| 진입 거점 | **2-3 경계** (마을형 1 + 간이형 1, 본 Phase 4-B에서 신설) |
| 출구 거점 | **3-4 경계** 마을형 (Phase 4-C 진입 시 추가 — WORLD_DESIGN §2) |
| 자연 경계 (3-4) | 무너진 성벽/유적 |
| 보스 보상 | `light_leap` 능력 + 강화 포인트 9 + 액세서리 1 |
| 추가조작 | **봉인 제단** (3-H) → `world.zone3.sealing_altar_opened` flag (활용처는 Phase 4-C에서 결정) |

---

## 2. 적 설계

### 2.1 서브타입 4종 — `data/enemies/zone3/`

zone2 대비 **HP·공격력 ×1.4** 계단식 (zone1 대비 약 ×2). 시각·이름은 폐허 테마.

| 베이스 | 작명 | 파일 | 핵심 변경 |
|---|---|---|---|
| 나무 | **고사목 보초** | `withered_sentinel.tres` | HP 130→185, 공격력 13→18, 외형: 마른 나무에 옛 갑주 잔해 |
| 바위 | **무너진 석상** | `toppled_statue.tres` | HP 180→250, 공격력 ×1.4, 경직 저항 0.7 유지 |
| 꽃 | **잿빛 백합** | `ash_lily.tres` | HP 65→90, 공격력 7→10, 분열체는 `pollen_spore.tres` 또는 `shard_spore_enemy.tres` 재활용 |
| 돌기둥 | **부서진 비석** | `shattered_stele.tres` | HP 100→140, 공격력 ×1.4, 투사체 속도 160→180 |

### 2.2 구역 고유 적 1종

| 작명 | 파일 | 신규 행동 모듈 | 핵심 |
|---|---|---|---|
| **옛 보초** | `old_sentinel.tres` | `attack_behavior_ruin_charge.gd` (신규) | 부서진 갑주 잔해. 시야 내 광역 충격파 (ground_tether 답습 + 짧고 둥근 광역 형상, 폐허 갈색-주황 톤). 짧은 돌진은 Step 6 인게임 검증 후 확장 검토 |

→ **REC-MECH-010 정지 면역 엘리트는 본 Step 미채택** (시간 정지 코어 보호 — RISK-002 충돌 우려). PROPOSED 유지, zone4 또는 Phase 5에서 재검토.

---

## 3. 보스 — 왕좌의 잔영 (Throne Echo, 잠정명)

| 항목 | 값 |
|---|---|
| 파일 | `data/bosses/zone3/throne_echo.tres` |
| HP | 1190 (zone2=850에서 ×1.4) |
| ATK | 31 (zone2=22에서 ×1.4) |
| 페이즈 | **3** |
| 약점 | `lens_focus` *(임시 재활용 — zone2 답습)*. 등불 트리거 인프라는 zone4에서 결정 |

### 3.1 페이즈 설계

| 페이즈 | 패턴 | 빌딩블록 |
|---|---|---|
| Phase 1 | 근접 광역 휘두르기 (`debris_sweep`, hitbox 220×90, telegraph 0.5s, cd 1.6s) | `boss_melee_aoe` 재활용 (신규 코드 0). 잔해 낙하 시각 효과는 Step 6 검토 |
| Phase 2 | **그림자 왕가 잔재** (`shadow_echo`) — 시안 잔영 톤 텔포 + 3way 22° 원거리(220px/s) | **`boss_shadow_echo.gd`** (~115줄, `boss_reflection_teleport` 답습 + 색조 차별화) + `boss_ranged_spread` 재활용. cycle |
| Phase 3 | 페이즈 1+2 패턴 빠른 순환 (`throne_storm`) — telegraph 0.4s 단축 + cd 1.0~1.5s | 기존 3 패턴 재활용 (boss_melee_aoe + boss_shadow_echo + boss_ranged_spread cycle). 신규 코드 0 |

### 3.2 보상

| 필드 | 값 |
|---|---|
| `reward_ability_id` | `light_leap` |
| `reward_growth_points` | 9 (zone2=7에서 +2) |
| `reward_story_flag` | `story.zone3.throne_echo_defeated` |
| `reward_next_zone_flag` | `stage_progress.zone4_unlocked` |
| `reward_item_ids` | `["ruin_signet"]` (액세서리 1개) |

### 3.3 신규 아이템

| ID | 슬롯 | 효과 (잠정) | 비고 |
|---|---|---|---|
| `ruin_signet` | 액세서리 | `attack_bonus +3` (잠정) | zone3 시그니처. **시그니처 효과 "빛 피니시 데미지 +15%"는 Phase 5 밸런싱** (현재 hook 미구현 — mire_pendant 패턴 답습으로 단순 stat만 부여). 수치는 Step 6 밸런싱 |

---

## 4. 스테이지 토폴로지

```
[2-3 경계] → 3-1 → 3-2 → 3-3 ─┬─ 3-4 → 3-5 → 3-7 → 3-9 → 3-B → [3-4 경계 / zone4 진입]
                              └─ 3-6 → 3-8 → 3-H (숨김, 봉인 제단)
```

| 스테이지 | 표시명(잠정) | 시간 | 잠금 | 적 수 | 기믹 |
|---|---|---|---|---|---|
| 3-1 | 잔해의 길 | 18 | ABILITY(`shadow_phase`) | 3 | 폐허 도입, 인공물 첫 등장 |
| 3-2 | 무너진 회랑 | 16 | NONE | 3 | 옛 회랑 잔해, **선조 기록 단편 2** NPC 위치 후보 |
| 3-3 | 옛 빛탑 | 22 | LIGHT | 4 | 빛탑 학습, 짙은 어둠 |
| 3-4 | 깨어진 광장 | 14 | ENVIRONMENT(`light_sensor:sensor_3_4_arch`) | 4 | 환경 잠금 본격 (3-3 안의 Lens로 활성화) |
| 3-5 | 정화의 안마당 | 19 | PURIFY (`stage_3_3` fully cleared) | 4 | 정화 재학습 |
| 3-6 | 갈림 유적 | 11 | NONE | 3 | 호흡 + 분기 (3-7/3-8). **3-H 숨김 힌트 위치** |
| 3-7 | 부서진 첨탑 | 23 | LIGHT | 5 | 보스 직전 검증 1 |
| 3-8 | 잠긴 수로 | 13 | NONE | 4 | **zone2 floodgate_opened 활용처** — flag set 시 추가 PortalHidden 노출 (3-H 옵션 진입 경로) |
| 3-9 | 왕좌 앞 | 21 | LIGHT | 5 | 보스 직전 종합 |
| 3-H | 봉인의 단 | 6 | 숨김 (HiddenRevealer, 3-6에서 발견) | 2 | **추가조작: 봉인 제단** → `world.zone3.sealing_altar_opened` flag |
| 3-B | 옛 왕좌의 뜰 | 17 | NONE (3-1~3-9 fully cleared) | 1(보스) | 보스 아레나 |

> **잠금 분포**: NONE(3) + LIGHT(3) + PURIFY(1) + ENVIRONMENT(1) + ABILITY(1) + 숨김(1) = 5종 모두 한 번씩 (zone2 패턴 답습).
> **3-B 진입은 보스 처치만으로 zone4 해금** — 봉인 제단(3-H)은 *보너스* (zone2 H 미발견자도 진행 가능. zone1 1-H 등불대 패턴 답습).

---

## 5. 환경 메커니즘

### 5.1 기존 활용
- **LightSensor / HiddenRevealer**: 3-4 잠금 + 3-H 숨김 + 3-8 (zone2 flag 구독)
- **PurificationDetector**: 3-5 정화 잠금
- **Lens / Cover**: 3-3 (3-4 활성화) / 3-6 (3-H 활성화)

### 5.2 신규 1종

| 컴포넌트 | 파일 | 역할 |
|---|---|---|
| **봉인 제단 (Sealing Pedestal)** | `sealing_pedestal.gd` (~50줄) + `SealingPedestalData` + `SealingPedestal.tscn` + `sealing_pedestal_basic.tres` | Floodgate 답습 + **한 번만 활성화 가드** (재토글 불가). 활성화 시 `EventBus.environment_interacted` + `StateFlags.set("world.zone3.sealing_altar_opened", true)`. 본체 56×40 폐허 석조 톤(잠긴=어두운 갈색 / 활성=황금빛). **활용처는 Phase 4-C에서 결정** |

### 5.3 폐허 시야 단서

**선택**: 기존 CanvasModulate + Light2D 영역 마스킹으로 시작. 안개 같은 별도 셰이더 도입 미진행 (zone3는 *시야*보다 *고요한 공허감*이 핵심 — Pass 5 환경 폴리시 단계에서 결정).

---

## 6. 스토리 비트 4개

| 시점 | 비트 | 구현 위치 |
|---|---|---|
| 3-1 진입 | "낯선 돌이 발에 채인다. 누군가의 손이 닿은 흔적." | StageNameplate / intro_sequence |
| 3-2 NPC (또는 거점 NPC) | **선조 기록 단편 2** — 봉인이 *거래*였음을 명시 (zone2 단편 1에서 *암시*만 있었던 것을 확정) | `data/dialogues/zone3/elder_record_2.tres` (신규) |
| 3-B 입구 | "이건 살아있지 않다. 분노만 남은 무엇이다." | StageNameplate |
| 3-B 처치 후 | "도약을 익혔다. 이제 더 높은 곳도 닿는다." | light_leap 해금 컷인 (Pass 5 또는 hardcode) |

> **그림자 왕가 정식 이름·수장은 zone3에서 등장하지 않음** — 일반명("옛 왕가" / "그림자 왕가")만 사용. STORY.md L108 미결은 zone4 진입 시 확정.

---

## 7. 신규 빌딩블록 체크리스트

| 항목 | 비용 | 의존성 | 상태 |
|---|---|---|---|
| `attack_behavior_ruin_charge.gd` (적 행동, 옛 보초) | 60~80줄 | base_enemy 상속 | ✅ Step 2 (~120줄, ground_tether 답습) |
| `boss_shadow_echo.gd` (페이즈 2 패턴, 시안 잔영 텔포) | 100~150줄 | `boss_reflection_teleport` 패턴 답습 | ✅ Step 3 (~115줄, 색조 차별화) |
| `boss_debris_fall.gd` (페이즈 1 신규, *선택*) | 80~120줄 | `boss_melee_aoe` 답습 | ⏭️ 미진행 (안전 추천 — Phase 1은 boss_melee_aoe 단독 재활용) |
| `sealing_pedestal.gd` (환경 오브젝트) | 80~100줄 | Floodgate/Cover 패턴 답습 | ✅ Step 4 (~50줄 + Data + tscn + tres + revealer 2종) |
| 데이터: 적 .tres 5 + 보스 .tres 1 + 페이즈 .tres 3 + 스테이지 .tres 11 + 아이템 .tres 1 (`ruin_signet`) + 다이얼로그 .tres 1+ | — | — | ⏳ Step 1~5 |
| 스테이지 .tscn 11 (Stage3_1 ~ Stage3_9 + Stage3_H + Stage3_B + ThroneEcho.tscn) | 한 스테이지당 1~3일 | — | ⏳ Step 5 |
| 진입/출구 거점 .tscn 2 (2-3 경계 마을형 + 간이형) — Step 5 또는 별도 | — | NPC + StoryDialogue | ⏳ Step 5 |
| (선택) 등불 트리거 인프라 (`BossWeakPoint` 신규 source) | 1일 | — | zone4로 보류 |

**총 코드 ~400~500줄 + 데이터 ~22 .tres + 씬 11~13 .tscn** (zone2 누적 약 6시간 기준 zone3 추정 6~7시간).

---

## 8. 미결정 (착수 중 확정)

- [ ] **그림자 왕가 정식 이름·수장** — STORY.md L108. zone4 진입 시 확정. zone3에서는 일반명 유지
- [ ] 봉인 제단 활용처 정확한 노출 대상 — Phase 4-C zone4 작업 시 결정 (숨김 경로 / 추가 환경)
- [ ] zone2 `floodgate_opened` 구독 노출 컴포넌트 — 3-8 PortalHidden 추가? HiddenRevealer FLAG 모드? Step 5에서 구체화
- [ ] 보스 약점 트리거 — `lens_focus` 임시. 등불 트리거 인프라(`BossWeakPoint` 신규 source)는 zone4 진입 시 결정
- [ ] 보스 외형·시각 정체성 (옛 왕좌+그림자 왕가 잔재) — 아트 명세서 작업 시점
- [ ] 페이즈 3 패턴 구체 (현 안: 페이즈 1+2 cycle 가속) — Step 3 착수 시 구체화
- [ ] 폐허 전용 신규 적 외형 — 아트 명세서
- [ ] **REC-NARR-004 5권 일기 1권 zone3 배치 검토** — recommendations 07_narrative L156 "3권: 3구역 깊은 곳" 권장. Step 5 또는 별도 NARR 세션에서 결정

---

## 9. 진행 순서

1. ✅ Step 0 본 문서 작성 + STAGE_INDEX zone3 § 확장 (2026-04-26)
2. ✅ Step 1 stage_3_1 양산 (zone2 적 placeholder, 폐허 갈색 톤 ColorRect) — 2026-04-26
3. ✅ Step 2 적 .tres 5종 + `attack_behavior_ruin_charge.gd` (2026-04-26)
4. ✅ Step 3 보스 (`throne_echo.tres` + 페이즈 .tres 3 + `boss_shadow_echo.gd` + `ruin_signet.tres`) — 2026-04-26
5. ✅ Step 4 봉인 제단 + stage_3_h.tres + zone2 flag 구독 .tres (2026-04-26)
6. ✅ Step 5 zone3 11 스테이지 .tscn 양산 + ThroneEcho.tscn + 2-3 경계 거점 2개 (2026-04-26)
7. ⏭️ Step 6 러프 밸런싱 (사용자 *수시 진행*)
8. ✅ Step 7 STORY/BOSSES/ENEMIES/WORLD_DESIGN/STAGE_INDEX/ZONE2 본 문서 마이그레이션 (2026-04-26)

---

## 변경 이력

| 날짜 | 내용 |
|---|---|
| 2026-04-26 | Step 0 — 본 문서 신설. zone2 템플릿 답습 + 안전 추천값 6항(봉인 제단=zone4 보너스 / floodgate=옵션 노출 / 정지 면역 미채택 / lens_focus 답습 / 그림자 왕가 일반명 유지 / NARR 별도 세션) 반영. STAGE_INDEX.md zone3 § 11행 확장. |
| 2026-04-26 | Step 1 — stage_3_1 '잔해의 길' 양산. stage_2_1 패턴 답습. zone2 적 placeholder 3 (weeping_willow + mire_stone + miasma_lily — Step 7에서 zone3 교체). 폐허 갈색 톤 (BG=0.18,0.16,0.14 / Floor=0.26,0.22,0.20 / Platform=0.32,0.28,0.26 / DustOverlay=0.72,0.65,0.55, α0.10). PortalLeft→`border_checkpoint`(잠정, Step 5 거점 신설 시 갱신), PortalRight→`stage_3_2`(미존재). gdlint clean / Godot 헤드리스 ERROR 0. |
| 2026-04-26 | Step 2 — zone3 적 5종 + `attack_behavior_ruin_charge.gd` (~120줄, ground_tether 답습). `data/enemies/zone3/` 신규 5: withered_sentinel(HP 185/ATK 18, tree) / toppled_statue(HP 250/ATK 13, rock, dmg_reduction 4) / ash_lily(HP 90/ATK 10, flower split, pollen_spore 재활용) / shattered_stele(HP 140/ATK 20, pillar ranged) / old_sentinel(HP 90/ATK 14, sentinel ruin_charge). zone2 ×1.4 계단식. enemy_stats_data.gd attack_behavior enum +ruin_charge / base_enemy.gd 디스패치 +ruin_charge. ruin_charge 시각: 폐허 갈색-주황 톤 fallback. **§2.2 정정** — "짧은 돌진" → "광역 충격파(짧은 돌진은 Step 6 검토)". gdlint clean (line-length 1건 fix) / Godot 헤드리스 ERROR 0. |
| 2026-04-26 | Step 3 — Throne Echo 보스 + 페이즈 3 + ruin_signet. `data/bosses/zone3/` 신규 4: throne_echo.tres(HP 1190/ATK 31/페이즈 3, 임계 0.66/0.33, 약점 lens_focus, 보상 light_leap+GP 9+ruin_signet) + phase_1_debris_sweep(boss_melee_aoe 재활용, 220×90, cd 1.6s) + phase_2_shadow_echo(shadow_echo+ranged_spread cycle, 3way 22° 220px/s) + phase_3_throne_storm(3 패턴 cycle, telegraph 0.4s 단축). `data/items/accessories/ruin_signet.tres`(attack_bonus +3 잠정, 시그니처 light 피니시 +15%는 Phase 5). `boss_shadow_echo.gd`(~115줄, boss_reflection_teleport 답습 + SHADOW_TINT(0.7,0.75,0.95) 시안 잔영 톤). 신규 코드 1 + 데이터 5. boss_debris_fall 미채택 (안전 추천 — Phase 1 단독 재활용). gdlint clean / Godot 헤드리스 ERROR 0 (Loaded 8 items). |
| 2026-04-26 | Step 4 — 봉인 제단 + stage_3_h.tres + zone2 flag 구독 인프라. 신규 7: `sealing_pedestal_data.gd` (FloodgateData 답습) + `sealing_pedestal_basic.tres` + `sealing_pedestal.gd` (~50줄, **한 번만 활성화 가드** 추가) + `SealingPedestal.tscn` (56×40 폐허 석조 톤, 잠긴=갈색·활성=황금) + `stage_3_h.tres` (봉인의 단, 6시 새벽, ring=3 angle=225 offset=-50, adjacent=[3-6,3-8]) + `hidden_revealer_zone3_h.tres` (LIGHT_SENSOR 모드, 3-6 메인 발견) + `hidden_revealer_zone3_h_floodgate.tres` (FLAG 모드, `world.zone2.floodgate_opened` 구독, 3-8 옵션 노출). 노드 와이어링은 Step 5에서 stage_3_6/3-8.tscn 양산 시. gdlint clean / Godot 헤드리스 ERROR 0. |
| 2026-04-26 | Step 5-A — stage_3_2~3_5 + sensor_3_4_arch.tres 양산 (4 stage + 1 sensor). NONE/LIGHT/ENVIRONMENT/PURIFY 잠금 분포. 폐허 갈색 톤 미세 변주. 신규 13. gdlint clean / Godot 헤드리스 ERROR 0. |
| 2026-04-26 | Step 5-B — stage_3_6~3_9 + sensor_3_6_hidden.tres 양산 (4 stage + 1 sensor). 3-6 HiddenRevealer LIGHT_SENSOR 와이어링(메인 발견 경로) + 3-8 HiddenRevealer FLAG 와이어링(zone2 floodgate 구독, 옵션 경로). 3-7/3-9에서 zone3 5종 모두 종합 검증. 신규 13. gdlint clean / Godot 헤드리스 ERROR 0. |
| 2026-04-26 | Step 5-C — stage_3_h.gd/.tscn(SealingPedestal 배치) + stage_3_b 보스 아레나 + ThroneEcho.tscn(MireMother 답습) + throne_echo_visual.gd(~70줄 잠정 stub, 페이즈별 색상 변화) + mire_village/mire_outpost 거점 2 + zone2 영향 갱신(stage_2_b PortalRight target=mire_village, adjacent_stages 갱신). 신규 11 + Edit 4. **신규 class_name 트리거로 캐시 stale → `--editor --headless --quit` 1회 갱신 후 재검증 ERROR 0**. |
| 2026-04-26 | **Step 7 마이그레이션** — 6 문서 갱신: STAGE_INDEX zone3 § 11행 ⏳→✅ 일괄 + 거점 종합 표 (TBD)→mire_village/outpost / WORLD_DESIGN §2 거점 2건 + §3 추가조작 표 + §3.4 미결 [x] 3구역 마킹 / ZONE2_CONTENT_PLAN §8 미결 [x] 2-3 경계 거점 마킹 / BOSSES.md §1·§2 미결 [x] + 3구역 보스 § 신설 (Mire Mother 답습 형식) + 구현 상태 헤더 2/5→3/5 / ENEMIES.md zone3 § 신설 (서브 4 + 옛 보초) + enum 확장 라인 + [x] 3구역 마킹 / STORY.md §3구역 § 신설 + 비트 4개 + 미결 항목 갱신. 총 ~17 Edit. |
