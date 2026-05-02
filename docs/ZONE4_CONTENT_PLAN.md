# 시간이 멈춘 숲 — 4구역 콘텐츠 계획

> Phase 4-C 진입 직전 콘텐츠 양산 슬라이스 기준 문서.
> 작성일: 2026-04-26
> 상태: **Step 0 진행 중** (본 문서 + STAGE_INDEX zone4 § 확장).
> 상위: [WORLD_DESIGN.md §1](WORLD_DESIGN.md) / [STAGES.md §5](STAGES.md) / [BOSSES.md](BOSSES.md) / [ENEMIES.md](ENEMIES.md) / [STORY.md](STORY.md) / [ZONE3_CONTENT_PLAN.md](ZONE3_CONTENT_PLAN.md)

---

## 1. 개요

| 항목 | 값 |
|---|---|
| 테마 | 그림자 숲 (빛이 거의 없음, 수정/광물 지형, 압도적 어둠) |
| 분위기 | 검은 결정·흑요석·미세한 빛 결 / 그림자 왕가의 잔재가 환경에 깊게 새겨짐 |
| 스토리 톤 | **진실 드러남** — 선조가 영웅이 아니라 거래자였음 인정. **수장 본인은 zone5 보존 (zone4 보스=수장의 잔재)** |
| 스테이지 수 | 통상 11 (4-1 ~ 4-11) + 숨김 1 (4-H) + 보스 1 (4-B) = **13** |
| 보스 페이즈 | 3 ([BOSSES.md §1](BOSSES.md)) |
| 진입 거점 | **3-4 경계 마을형** `ruined_village` (Phase 4-C 신설, 진실 NPC 위치) + **4구역 내부 간이형** `shadow_camp` (큰 구역 중간 체크포인트) |
| 출구 거점 | **4-5 경계 간이형** (Phase 4-D 진입 시 추가) |
| 자연 경계 (4-5) | 거대 뿌리/절벽 |
| 보스 보상 | `shadow_step` 능력 + 강화 포인트 11 + 액세서리 1 |
| 추가조작 | **그림자 결정** (`ShadowCrystal`) → `world.zone4.shadow_crystal_attuned` flag → **zone5 최종 보스실 진입 조건** ([WORLD_DESIGN §3](WORLD_DESIGN.md)) |

---

## 2. 적 설계

### 2.1 서브타입 4종 — `data/enemies/zone4/`

zone3 대비 **HP·공격력 ×1.4** 계단식 (zone1 대비 약 ×2.8). 시각·이름은 그림자/결정 테마.

| 베이스 | 작명 | 파일 | 핵심 변경 |
|---|---|---|---|
| 나무 | **흑수목 감시자** | `blackwood_watcher.tres` | HP 185→260, ATK 18→25, 외형: 검은 나무 + 결정 박힘 |
| 바위 | **어둠 결정** | `dark_crystal.tres` | HP 250→350, ATK ×1.4, dmg_reduction 4→6 |
| 꽃 | **검은 백합** | `black_lily.tres` | HP 90→125, ATK 10→14, 분열체 `pollen_spore.tres` 재활용 |
| 돌기둥 | **흑요 비석** | `obsidian_stele.tres` | HP 140→195, ATK 20→28, 투사체 속도 180→200 |

### 2.2 구역 고유 적 1종

| 작명 | 파일 | 행동 모듈 | 핵심 |
|---|---|---|---|
| **결정 잔재** | `crystal_wraith.tres` | `melee` (베이스 답습, 신규 코드 0) | 그림자 결정에서 솟은 잔재. zone3 zone1 답습으로 안전 — 행동은 melee 표준 |

### 2.3 정지 면역 엘리트 1종 (REC-MECH-010 채택)

| 작명 | 파일 | 구현 | 핵심 |
|---|---|---|---|
| **잔영 첨병** | `echo_vanguard.tres` | **`EnemyStatsData.time_immune: bool` 필드 +`base_enemy.deactivate()` 가드** (신규 *행동* 모듈 미작성 — 행동이 아닌 *상태* 영향이라 flag 방식이 깔끔. ~5줄) | **시간 정지 중에도 active 유지** — 그림자 왕가 잔재가 시간 흐름에서 분리됐다는 모티프. zone4부터 등장(recommendations §01_mechanics L298 권장 1단계 늦음 해소). attack_behavior=`"melee"` 표준 사용 |

→ **zone4 정지 면역 엘리트 채택 결정 (Phase 4-C, REC-MECH-010 PROPOSED→IMPLEMENTED 예정)**. RISK-002(시간 정지 만능 카드) 대응 — *zone4부터 점진 도입*으로 코어 메카닉 깊이 추가.

---

## 3. 보스 — 수장의 잔재 (Lord Remnant, 잠정명)

| 항목 | 값 |
|---|---|
| 파일 | `data/bosses/zone4/lord_remnant.tres` |
| HP | 1700 (zone3=1190에서 ×1.4) |
| ATK | 43 (zone3=31에서 ×1.4) |
| 페이즈 | **3** |
| 약점 | **`torch_lit`** *(신규 source — 등불 트리거 인프라 본 zone에서 신설)*. lens_focus 4번째 임시 사용 회피 |

**정체성 결정 (사용자 답변, 2026-04-26)**: zone4 보스 = **수장의 잔재** (수장 본인이 아님). zone5 최종 보스 = 수장 본인 + 두 왕가 결합 (GDD §7.2 보존).

### 3.1 페이즈 설계

| 페이즈 | 패턴 | 빌딩블록 |
|---|---|---|
| Phase 1 | 근접 광역 (`shadow_sweep`, 240×100, telegraph 0.45s, cd 1.4s) | `boss_melee_aoe` 재활용 (신규 코드 0) |
| Phase 2 | **수장의 잔재** (`remnant_echo`) — 보라 잔영 톤 텔포 + 4way 22° 원거리(240px/s) | **`boss_remnant_echo.gd`** (~110줄, `boss_shadow_echo.gd` 답습 + SHADOW_TINT 보라 `(0.55,0.40,0.65)` 차별화) + `boss_ranged_spread` 재활용 cycle. 다중 분신 잔상 시각은 Step 6 검토 |
| Phase 3 | 페이즈 1+2 패턴 빠른 순환 (`lord_storm`) — telegraph 0.35s + cd 0.9~1.3s | 기존 3 패턴 재활용 (boss_melee_aoe + boss_remnant_echo + boss_ranged_spread). 신규 코드 0 |

### 3.2 보상

| 필드 | 값 |
|---|---|
| `reward_ability_id` | `shadow_step` |
| `reward_growth_points` | 11 (zone3=9에서 +2) |
| `reward_story_flag` | `story.zone4.lord_remnant_defeated` |
| `reward_next_zone_flag` | `stage_progress.zone5_unlocked` |
| `reward_item_ids` | `["abyss_charm"]` (액세서리 1개) |

### 3.3 신규 아이템

| ID | 슬롯 | 효과 (잠정) | 비고 |
|---|---|---|---|
| `abyss_charm` | 액세서리 | `defense_bonus +5` (잠정) | zone4 시그니처. **"그림자 정지 면역 + N초"는 Phase 5 hook**. 단순 stat 부여 우선 (mire_pendant/ruin_signet 답습) |

### 3.4 등불 트리거 인프라 신설 (본 zone)

`boss_weak_point.gd`의 `weak_point_reveal_source` enum 확장: `"lens_focus"` → **`+"torch_lit"`**. zone4 보스만 사용. zone1/2/3은 `lens_focus` 임시 유지 (회귀 위험 회피).

신규 노드: **`Torch.tscn`** (Lens 답습 + 시각만 다름, 잠정 ColorRect). 보스 아레나(Stage4_B) 안에 배치. `torch_lit` source는 Torch가 활성화 시 약점 reveal.

---

## 4. 스테이지 토폴로지

```
[3-4 경계 ruined_village] → 4-1 → 4-2 → 4-3 ─┬─ 4-4 → 4-5 → 4-7 → 4-9 → 4-11 → 4-B → [4-5 경계, Phase 4-D]
                                              ├─ 4-6 → 4-8 → 4-10 (옵션 경로)
                                              └─ 4-6 → 4-H (숨김, 그림자 결정)
                                              [shadow_camp 4구역 내부 간이형, 4-7 인근]
```

| 스테이지 | 표시명(잠정) | 시간 | 잠금 | 적 수 | 기믹 |
|---|---|---|---|---|---|
| 4-1 | 어둠의 입구 | 22 | ABILITY(`light_leap`) | 3 | 그림자 도입, 인공물 → 검은 결정 첫 등장 |
| 4-2 | 잠긴 협곡 | 19 | NONE | 3 | 호흡 |
| 4-3 | 흑요석 안마당 | 23 | LIGHT | 4 | 빛탑 학습 + Lens + LightSensor(`sensor_4_4_chasm`) |
| 4-4 | 깊은 광맥 | 14 | ENVIRONMENT(`light_sensor:sensor_4_4_chasm`) | 4 | 환경 잠금 본격 (4-3 Lens 회전으로 활성화) |
| 4-5 | 정화의 동굴 | 20 | PURIFY (`stage_4_3`) | 4 | 정화 재학습 |
| 4-6 | 갈림의 결정 | 11 | NONE | 3 | 호흡 + 분기 (4-7/4-8/4-H). **4-H 숨김 힌트** |
| 4-7 | 절벽 위 | 23 | LIGHT | 5 | 검증 1. **shadow_camp 거점 인근** |
| 4-8 | 잠긴 결정 광장 | 13 | NONE | 4 | **zone3 sealing_altar_opened 활용처** — flag set 시 추가 PortalHidden 노출 (4-H 옵션 진입 경로) |
| 4-9 | 어둠의 회랑 | 22 | LIGHT | 5 | 검증 2 + **첫 잔영 첨병(정지 면역 엘리트) 도입** |
| 4-10 | 결정 미로 | 11 | NONE | 4 | 검증 3 (강화 적 배치 + 잔영 첨병) |
| 4-11 | 잔영의 문 | 23 | LIGHT | 6 | 보스 직전 종합 — **zone4 6종 모두** (베이스 4 + 결정 잔재 + 잔영 첨병) |
| 4-H | 그림자 결정의 자리 | 6 | 숨김 (HiddenRevealer 4-6 메인 / 4-8 옵션) | 2 | **추가조작: 그림자 결정** + 잔영 첨병×2 |
| 4-B | 수장의 안식처 | 17 | NONE (4-1~4-11 fully cleared) | 1(보스) | 보스 아레나 + Torch×2 (등불 트리거 인프라) |

> **잠금 분포**: NONE(4) + LIGHT(4) + PURIFY(1) + ENVIRONMENT(1) + ABILITY(1) + 숨김(1) = 5종 모두 한 번씩 (zone2/3 패턴 답습).
> **zone5 진입 = zone4 보스 처치만으로** (`stage_progress.zone5_unlocked`). **그림자 결정은 zone5 *최종 보스실* 진입 조건** (Phase 4-D zone5 작업 시 게이트 적용). zone4 진행 차단 회피.
> **4-9에서 정지 면역 엘리트 첫 도입** (zone3 marsh_tendril 3-3 도입 패턴 답습). 4-10·4-11·4-H에서 강조.

---

## 5. 환경 메커니즘

### 5.1 기존 활용
- **LightSensor / HiddenRevealer**: 4-4 잠금 + 4-H 숨김 + 4-8 (zone3 sealing_altar 구독)
- **PurificationDetector**: 4-5 정화 잠금
- **Lens**: 4-3 (4-4 활성화) / 4-6 (4-H 활성화)

### 5.2 신규 2종

| 컴포넌트 | 파일 | 역할 |
|---|---|---|
| **그림자 결정 (Shadow Crystal)** | `src/entities/objects/environment/shadow_crystal/shadow_crystal.gd` (~50줄) + `ShadowCrystalData` + `ShadowCrystal.tscn` + `shadow_crystal_basic.tres` | SealingPedestal 답습 + **한 번만 활성화 가드**. set 시 `EventBus.environment_interacted` + `StateFlags.set("world.zone4.shadow_crystal_attuned", true)`. 본체 64×48 어둠 결정 톤(잠긴=어두운 보라 / 활성=발광 보라) |
| **횃불 (Torch)** | `src/entities/objects/environment/torch/torch.gd` (~50줄) + `TorchData` + `Torch.tscn` + `torch_basic.tres` | Lens 답습 + interact 시 점화/소화 토글. 점화 시 `EventBus.torch_lit` 시그널 emit (잠정 신규). 보스 약점 `torch_lit` source가 본 시그널 구독해 reveal. 본체 24×56 횃불 톤(소화=어두운 갈색 / 점화=황금 발광) |

### 5.3 그림자 시야 단서

**선택**: 기존 CanvasModulate + 어두운 BG. 별도 셰이더 도입 미진행 (Pass 5 환경 폴리시에서 결정).

---

## 6. 스토리 비트 4개

| 시점 | 비트 | 구현 위치 |
|---|---|---|
| 4-1 진입 | "빛이 닿지 않는다. 발 밑에서 그림자가 흐른다." | StageNameplate / intro_sequence |
| 4-3 또는 ruined_village NPC | **선조 기록 단편 3** — 거래의 *대가* 명시 (zone2/3은 거래 자체, zone4는 시간 조작 능력의 정체). | `data/dialogues/zone4/elder_record_3.tres` (신규, NPC 미배치 시 잠정) |
| 4-B 입구 | "이건 잔재다. 본체는 더 깊은 곳에 있다." (수장 본인은 zone5에서) | StageNameplate |
| 4-B 처치 후 | "잔영을 가른다. 이제 그림자 사이로 걸을 수 있다." | shadow_step 해금 컷인 (ThroneEcho intro 패턴 답습 — `data/cutscenes/lord_remnant_intro.tres` 옵션) |

> **그림자 왕가 정식 이름·수장은 zone4에서도 미공개 유지** — zone5에서 본격 등장. zone4는 "수장의 잔재"라는 *기능적 표현*만 사용. STORY.md §7 미결 [그림자 왕가 이름] [수장 이름] 항목 zone5로 이월.

---

## 7. 신규 빌딩블록 체크리스트

| 항목 | 비용 | 의존성 | 상태 |
|---|---|---|---|
| `EnemyStatsData.time_immune` flag + `base_enemy.deactivate()` 가드 | ~5줄 (flag 방식, 행동 모듈 X) | base_enemy / EnemyRegistry.deactivate_all 호출 자동 가드 | ✅ Step 2 |
| `boss_remnant_echo.gd` (페이즈 2 패턴, 다중 분신) | 100~150줄 | `boss_shadow_echo.gd` 답습 + 다중 위치 | ⏳ Step 3 |
| `shadow_crystal.gd` (환경, 한 번만 활성화) | 50~60줄 | `sealing_pedestal.gd` 답습 | ⏳ Step 4 |
| `torch.gd` (환경, 점화 토글) + `EventBus.torch_lit` | 60~80줄 + 시그널 1 | Lens 답습 + EventBus 시그널 신규 | ⏳ Step 3 또는 4 |
| `boss_weak_point.gd` `weak_point_reveal_source` enum +`"torch_lit"` | 1~2줄 | 기존 boss_weak_point | ⏳ Step 3 |
| 데이터: 적 .tres 6 + 보스 .tres 1 + 페이즈 .tres 3 + 스테이지 .tres 13 + 아이템 .tres 1 + 환경 .tres 2 + sensor 1 + revealer 2 + 다이얼로그 .tres 1+ | — | — | ⏳ Step 1~5 |
| 스테이지 .tscn 13 + LordRemnant.tscn + 거점 2 (`RuinedVillage` + `ShadowCamp`) | 한 스테이지당 1~3일 | — | ⏳ Step 5 |
| (선택) `lord_remnant_intro.tres` 컷신 — ThroneEcho intro 답습 (사용자 인게임 검증 결과 cutscene 인프라 활용) | 잠정 | OverlaySystem.play_cutscene + cutscene_finished | ⏳ Step 5 또는 별도 |

**총 코드 ~400~500줄 + 데이터 ~30 .tres + 씬 16 .tscn** — zone3 대비 신규 인프라 3종(정지 면역 + 등불 트리거 + 그림자 결정) 추가로 **7~8시간** 추정.

---

## 8. 미결정 (착수 중 확정)

- [ ] **그림자 왕가 정식 이름·수장 정식 이름** — zone5 진입 시 (Phase 4-D)
- [ ] 그림자 결정 활용처 zone5 보스실 잠금 구체 (Phase 4-D)
- [ ] 보스 외형·시각 정체성 (수장의 잔재) — 아트 명세서 작업 시점
- [ ] 정지 면역 엘리트 외형 + 그림자 왕가 잔재 모티프 — 아트 명세
- [ ] `shadow_camp` 정확한 토폴로지 위치 (4-7 인근 잠정, Step 5 확정)
- [ ] 등불 트리거 인프라 구체 — `EventBus.torch_lit` 시그널 vs `boss_weak_point.gd`가 직접 그룹 검색? (Step 3 착수 시)
- [ ] `abyss_charm` 시그니처 효과 hook (정지 면역 +N초 등) — Phase 5 밸런싱
- [ ] `lord_remnant_intro.tres` 컷신 작성 여부 — 사용자 cutscene 인프라 작업 결과에 따라
- [ ] **REC-NARR-004 5권 일기 4권 zone4 깊은 곳 배치 검토** — recommendations 07_narrative L156. Step 5 또는 별도 NARR 세션
- [ ] zone3 stage_3_b PortalRight target = `border_checkpoint` → `ruined_village` 갱신 (Step 5에서 거점 신설 시)

---

## 9. 진행 순서

1. ⚙️ Step 0 본 문서 작성 (현재) + STAGE_INDEX zone4 § 13행 확장
2. ✅ Step 1 stage_4_1 양산 (zone3 적 placeholder, 그림자 어두운 보라톤) — 2026-04-26
3. ✅ Step 2 적 .tres 6종 + `EnemyStatsData.time_immune` flag + `base_enemy.deactivate()` 가드 (2026-04-26)
4. ✅ Step 3 보스 + 페이즈 3 + abyss_charm + 등불 트리거 인프라 단순화 (2026-04-26)
5. ✅ Step 4 그림자 결정 + stage_4_h.tres + zone3 sealing_altar 구독 (2026-04-26)
6. ⏳ Step 5 zone4 13 스테이지 .tscn 양산 + LordRemnant.tscn + 거점 2 (`ruined_village` 마을형 + `shadow_camp` 간이형) + zone3 stage_3_b PortalRight 갱신
7. ⏭️ Step 6 러프 밸런싱 (사용자 *수시 진행*)
8. ⏳ Step 7 STORY/BOSSES/ENEMIES/WORLD_DESIGN/STAGE_INDEX/ZONE3 본 문서 마이그레이션

---

## 변경 이력

| 날짜 | 내용 |
|---|---|
| 2026-04-26 | Step 0 — 본 문서 신설. zone3 템플릿 답습 + 사용자 결정 1항(C-3 보스=수장의 잔재) + 안전 추천값 7항(봉인 제단=4-8 옵션 노출 / **REC-MECH-010 정지 면역 엘리트 본 zone 채택** / **등불 트리거 인프라 본 zone 신설** / 4 베이스 + 고유 1 + 정지 면역 1 = 6종 / abyss_charm 액세서리 / Phase 5 hook 별도 / NARR 별도 세션). C-1·C-2(그림자 왕가 정식 이름·수장) zone5 이월. STAGE_INDEX zone4 § 13행 확장. |
| 2026-04-26 | Step 1 — stage_4_1 '어둠의 입구' 양산. stage_3_1 패턴 답습. zone3 적 placeholder 3 (withered_sentinel + toppled_statue + ash_lily — Step 7에서 zone4 교체). 그림자 어두운 보라톤 (BG=0.10,0.08,0.12 / Floor=0.18,0.16,0.20 / Platform=0.22,0.20,0.25 / DustOverlay=0.55,0.50,0.65, α0.10 — zone3 갈색에서 보라 시프트). PortalLeft→`border_checkpoint`(잠정, Step 5에서 ruined_village로 갱신), PortalRight→`stage_4_2`(미존재). ABILITY(`light_leap`) 잠금. ring=4 angle=270°. gdlint clean / Godot 헤드리스 ERROR 0. |
| 2026-04-26 | Step 2 — zone4 적 6종 + 정지 면역 flag 방식. `data/enemies/zone4/` 신규 6: blackwood_watcher(HP 260/ATK 25, tree) / dark_crystal(HP 350/ATK 18, rock, dmg_reduction 6) / black_lily(HP 125/ATK 14, flower split, pollen_spore 재활용) / obsidian_stele(HP 195/ATK 28, pillar ranged) / crystal_wraith(HP 110/ATK 15, wraith melee, **신규 행동 0**) / echo_vanguard(HP 130/ATK 17, vanguard melee, **`time_immune=true`**). zone3 ×1.4 계단식. enemy_stats_data.gd `time_immune: bool` flag 추가 + base_enemy.deactivate() 가드 (~5줄, 신규 attack_behavior 모듈 작성 X — flag가 깔끔). REC-MECH-010 본격 활성화. gdlint clean / Godot 헤드리스 ERROR 0. |
| 2026-04-26 | Step 3 — Lord Remnant 보스 + 페이즈 3 + abyss_charm + 등불 트리거 인프라 단순화. `data/bosses/zone4/` 4 신규: lord_remnant.tres(HP 1700/ATK 43/페이즈 3, hp_thresholds 0.66/0.33, 약점 lens_focus→**torch_lit** 메타, 보상 shadow_step+GP 11+abyss_charm+flag 2) + phase_1_shadow_sweep(boss_melee_aoe 재활용 cd 1.4s) + phase_2_remnant_echo(remnant_echo+ranged_spread cycle 4way 22° 240px/s) + phase_3_lord_storm(3 패턴 cycle, telegraph 0.35s 가속). `data/items/accessories/abyss_charm.tres`(defense_bonus +5, 시그니처 "정지 면역 +N초" Phase 5 hook). `attack_behavior_boss_remnant_echo.gd` ~110줄(boss_shadow_echo 답습 + SHADOW_TINT 보라 0.55,0.40,0.65 차별화). `lord_remnant_visual.gd` ~70줄(throne_echo_visual 답습 + 보라 페이즈 시리즈). **등불 트리거 단순화**: `torch_data.gd` + `torch_basic.tres` + `torch.gd` ~40줄(Floodgate 답습 토글, 점화 시 같은 stage 보스 → `boss_weak_point_exposed.emit`) + `Torch.tscn`. **`boss_weak_point.gd` 변경 0 / EventBus.torch_lit X** — `weak_point_reveal_source`가 메타 분류 필드라 base_boss source-agnostic 구독, Lens emit 패턴 그대로 답습. 신규 11파일. 새 class_name(TorchData) 캐시 갱신 1회 + 헤드리스 ERROR 0 (Loaded 9 items). |
| 2026-04-26 | Step 4 — 그림자 결정 + stage_4_h.tres + zone3 sealing_altar 구독 인프라. 신규 7: `shadow_crystal_data.gd` (sealing_pedestal_data 답습 + 보라 결정 톤) + `shadow_crystal_basic.tres` + `shadow_crystal.gd` (~50줄, sealing_pedestal 답습 + flag/이름 차별화) + `ShadowCrystal.tscn` (64×48 보라 결정, 잠긴=어두운 보라/활성=발광 보라) + `stage_4_h.tres` (그림자 결정의 자리, 6시 새벽, ring=4 angle=225 offset=-50, adjacent=[4-6,4-8]) + `hidden_revealer_zone4_h.tres` (LIGHT_SENSOR 모드, 4-6 메인) + `hidden_revealer_zone4_h_sealing.tres` (FLAG 모드, `world.zone3.sealing_altar_opened` 구독, 4-8 옵션). `lord_remnant_intro.tres` 컷신 미진행 — Step 5 또는 사용자 인게임 검증 시 추가 가능(throne_echo_intro 패턴). 새 class_name(ShadowCrystalData) 캐시 갱신 1회 + 헤드리스 ERROR 0. |
