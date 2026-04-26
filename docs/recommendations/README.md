# 추천/리서치 보존 폴더 — 인덱스

> 이 폴더는 레퍼런스 게임 분석을 통한 **추천**과 **현황 갭 분석**을 보존한다.
> 본 폴더 내용은 **결정 사항이 아니다**. 채택/기각은 메인 세션에서 별도로 이뤄진다.

---

## 0. 폴더 운영 정책

### 0.1 STATUS 라이프사이클

모든 추천 항목은 다음 중 한 상태:

| 상태 | 의미 |
|---|---|
| `PROPOSED` | 리서치 단계 추천. 채택 여부 미정. |
| `REVIEWING` | 사용자가 검토 중. 곧 채택/기각 결정. |
| `ACCEPTED` | 채택 결정. 아직 구현 시작 전. |
| `IN_PROGRESS` | 구현 중. 관련 시스템에 변경 진행. |
| `IMPLEMENTED` | 구현 완료. 본 폴더에서는 더 이상 능동 관리 대상 아님. |
| `REJECTED` | 기각. 사유 함께 기록. |
| `STALE` | 무효화 조건 충족. 재검토 필요. |

### 0.2 ID 체계

`REC-{카테고리코드}-{3자리}` 형식.

| 코드 | 카테고리 |
|---|---|
| MECH | mechanics — 메카닉/게임플레이 |
| FX | effects — 연출/이펙트 |
| CONT | content — 콘텐츠/수집/NPC |
| META | meta — 메타/구조/끝판 |
| UX | ux — UI/UX/접근성 |
| SND | sound — 사운드/음악 |
| NARR | narrative — 스토리/내러티브 |
| RISK | risks — 위험 신호 |
| MKT | market — 한국 인디 시장 어필 |

### 0.3 인덱스 갱신 규칙

- 항목 상태 변경 시 → **이 README의 표 갱신** + `CHANGELOG.md`에 한 줄 추가
- 새 항목 추가 시 → 카테고리 문서에 항목 추가 + 표에 행 추가 + CHANGELOG 한 줄
- 항목 본문 대폭 수정 시 → CHANGELOG에 `[edit] REC-XXX-NNN ...` 한 줄

### 0.4 병렬 세션 충돌 방지

- 카테고리 문서(01~09) 본문은 카테고리별로 분리되어 충돌 적음
- 공유 파일(README.md, CHANGELOG.md)은 **append 또는 한 행 수정** 단위로 짧게 편집
- worktree 머지 직전 인덱스 표 충돌만 한 번 확인

### 0.5 코드 검증 의무화 (2026-04-26 운영 원칙 추가)

**왜**: 본 폴더 초기 작성 시 REC-UX-005 한글 폰트가 PROPOSED로 표기됐으나 실제로는 IMPLEMENTED 상태였음. 코드/리소스 직접 확인 없이 다른 문서(`korean_pixel_font_research.md`) 표기만 의존한 결과.

**규칙**:
1. 추천 항목의 상태를 **PROPOSED 외 상태**(IMPLEMENTED, PARTIAL, REJECTED, STALE)로 변경할 때는 **반드시 코드/리소스 직접 검증** 후 변경
2. INVENTORY_GAP.md의 ✅/⏳ 표기 작성/갱신 시 **반드시 코드 검증** (Grep, Read, Glob 활용)
3. 검증 결과는 본 항목 본문에 **검증 명령 또는 파일 경로 함께 기록** (재현성 보장)
4. 다른 문서(GDD, STORY, EFFECTS 등)의 "구현 완료" 표기를 그대로 신뢰하지 말 것 — 문서가 코드보다 stale일 수 있음

**예시 (좋은 검증)**:
```
- 검증: `data/themes/main_theme.tres`(Galmuri11/14 + Mulmaru) + `project.godot:58`(theme/custom 등록) 확인
```

**예시 (나쁜 검증)**:
```
- 출처: korean_pixel_font_research.md 리서치 완료
```
→ 리서치 완료 ≠ 적용 완료. 코드를 봐야 함.

---

## 1. 문서 구성

| 파일 | 역할 |
|---|---|
| [README.md](README.md) | 본 인덱스 + 운영 정책 |
| [CHANGELOG.md](CHANGELOG.md) | 폴더 변경 로그 (append-only) |
| [INVENTORY_GAP.md](INVENTORY_GAP.md) | 시스템/콘텐츠 갭 분석 (현재 스냅샷) |
| [00_TOP10.md](00_TOP10.md) | Top 10 must-haves (빠른 진입) |
| [01_mechanics.md](01_mechanics.md) | 메카닉/게임플레이 추천 |
| [02_effects.md](02_effects.md) | 연출/이펙트 추천 |
| [03_content.md](03_content.md) | 콘텐츠/수집/NPC 추천 |
| [04_meta_endgame.md](04_meta_endgame.md) | 메타/구조/끝판 추천 |
| [05_ui_ux_accessibility.md](05_ui_ux_accessibility.md) | UI/UX/접근성 추천 |
| [06_sound.md](06_sound.md) | 사운드/음악 추천 |
| [07_narrative.md](07_narrative.md) | 스토리/내러티브 추천 |
| [08_risks.md](08_risks.md) | 위험 신호 |
| [09_market_korea.md](09_market_korea.md) | 한국 인디 시장 어필 |

---

## 2. 추천 항목 마스터 인덱스

> 상태/우선/노력은 변경 시마다 갱신. CHANGELOG에도 한 줄 기록.

### 2.1 메카닉 (REC-MECH)

| ID | 이름 | 상태 | 우선 | 노력 | 관련 시스템 | 의존 |
|---|---|---|---|---|---|---|
| REC-MECH-001 | Echo Nail — 정지 잔상 들여다보기 | PROPOSED | ★★★ | M | StorySystem, EffectTimeline, EnemySystem | — |
| REC-MECH-002 | 그림자 광기 — 장기 노출 페널티 | PROPOSED | ★★★ | M | ShadowSystem, EnemySystem | — |
| REC-MECH-003 | 양방향 패리 — 빛/그림자 패리 구분 | PROPOSED | ★★ | M | CombatSystem | — |
| REC-MECH-004 | 시간 잔향 종 — 환경 오브젝트 #5 | PROPOSED | ★★ | M | TimeSystem, 환경 오브젝트 | — |
| REC-MECH-005 | 그림자 발자국 — 땅거미 추적 전조 UI | **IMPLEMENTED** | ★★★ | S | DuskSpiderSystem, dusk_spider_hud, EventBus | 5단계 풀 + sprite 자동 교체 fallback |
| REC-MECH-006 | 그림자 흡수 — 흡혈 메카닉 | PROPOSED | ★★ | S | CombatSystem, TimeSystem | — |
| REC-MECH-007 | 빛 굴절 콤보 — 거울 연쇄 공격 (같은 룸 내) | **IMPLEMENTED** | ★★ | S | Mirror, finish_light, CombatSystem, EffectsSystem | effects_light_beam.gd + finish_light hook |
| REC-MECH-008 | 시간 봉인 룸 — 시간 정지 금지 챔버 | PROPOSED | ★★ | S | StageSystem, TimeSystem | — |
| REC-MECH-009 | 보스 패턴 4페이즈 골격 (후반 보스) | PROPOSED | ★★★ | L | BossSystem | — |
| REC-MECH-010 | 정지 면역 엘리트 적 | PROPOSED | ★★ | S | EnemySystem, TimeSystem | — |

### 2.2 연출/이펙트 (REC-FX)

| ID | 이름 | 상태 | 우선 | 노력 | 관련 시스템 | 의존 |
|---|---|---|---|---|---|---|
| REC-FX-001 | 시간 정지 셔터 — 발동 freeze frame | **IMPLEMENTED** | ★★★ | S | EffectsSystem, OverlaySystem, sepia 셰이더 | effects_time_stop_shutter.gd + chromatic uniform |
| REC-FX-002 | 추격 시퀀스 — 땅거미 깨어남 | PROPOSED | ★★★ | L | DuskSpiderSystem, StageSystem, 카메라 | — (의존 해소) |
| REC-FX-003 | 발광 잔류 — 빛 피니시 빛줄기 | **IMPLEMENTED** | ★★ | S | EffectsSystem, DamageResolver | effects_residual_light.gd + spawn_residual_light API |
| REC-FX-004 | 정적 화면, 살아있는 그림자 셰이더 | **IMPLEMENTED** | ★★★ | S | ShadowCaster, ShadowSystem, EventBus | shadow_jitter.gdshader + shadow_caster.gd 통합 |
| REC-FX-005 | 보스룸 슬로우 패닝 도입부 | PROPOSED | ★★ | S | BossSystem, 카메라 | — |
| REC-FX-006 | 컷신 — 정지 일러스트 + 텍스트박스 | **PARTIAL** | ★★★ | S~M | StorySystem, UI, OverlaySystem | 일러스트 패널 + 5~10장 아트 |
| REC-FX-007 | 화면 가장자리 비네트 — 그림자 강도 | **IMPLEMENTED** | ★★ | S | ShadowSystem, OverlaySystem, EventBus | effects_shadow_vignette.gd + 우선순위 라우터 |

### 2.3 콘텐츠/수집/NPC (REC-CONT)

| ID | 이름 | 상태 | 우선 | 노력 | 관련 시스템 | 의존 |
|---|---|---|---|---|---|---|
| REC-CONT-001 | 빛령 수집 + Light Father NPC | PROPOSED | ★★★ | M | StageSystem, GrowthSystem, NPC | — |
| REC-CONT-002 | Cornifer형 측량사 NPC | PROPOSED | ★★★ | S | WorldMapUI, NPC | REC-UX-002 |
| REC-CONT-003 | 비밀 레이어 — 흐르는 시간 영역 | PROPOSED | ★★ | L | StageSystem, TimeSystem | NG+ 결정 |
| REC-CONT-004 | 챌린지 룸 — 정지의 시련 | PROPOSED | ★★ | M | StageSystem, EnemySystem | — |
| REC-CONT-005 | Manuscript Pages — 선조의 일지 | PROPOSED | ★★★ | M | StorySystem, AbilitySystem, UI | 룬 디자인 선결 |
| REC-CONT-006 | 비밀 보스 — 잊혀진 제사 | PROPOSED | ★★ | M | BossSystem | REC-CONT-005 |
| REC-CONT-007 | NPC 사이드 라인 — 기억 잃은 자 | PROPOSED | ★★ | M | NPC, StorySystem | REC-MECH-001 |

### 2.4 메타/구조/끝판 (REC-META)

| ID | 이름 | 상태 | 우선 | 노력 | 관련 시스템 | 의존 |
|---|---|---|---|---|---|---|
| REC-META-001 | 맹세 모드 (Penitences 차용) | PROPOSED | ★★★ | M | SaveSystem, GrowthSystem | NG+ 결정 |
| REC-META-002 | Pantheon — 시간의 사슬 보스 러시 | PROPOSED | ★★ | M | BossSystem, StageSystem | 5보스 완성 후 |
| REC-META-003 | 다중 엔딩 3 분기 | PROPOSED | ★★★ | M | StorySystem, SaveSystem | 후반 스토리 확정 |
| REC-META-004 | Heat / Pact — 균열 깊이 | PROPOSED | ★★ | M | NG+, GrowthSystem | NG+ 결정 |
| REC-META-005 | Photo / 정지 모드 | PROPOSED | ★★ | S | UI, EffectsSystem | — |
| REC-META-006 | 도전과제 — 스토리 결합형 | PROPOSED | ★★ | S | SaveSystem, Steam SDK | 도전과제 문서 신설 |
| REC-META-007 | Inverted Forest — 흐르는 숲 (NG+ 모드) | PROPOSED | ★★ | L | StageSystem, TimeSystem, NG+ | NG+ 결정 |
| REC-META-008 | 진실의 시련 — Manuscript 100% 보상 | PROPOSED | ★★ | S | StorySystem | REC-CONT-005 |
| REC-META-009 | 스피드런 모드 — Steel Soul/타이머 | PROPOSED | ★★ | S | SaveSystem, UI | — |
| REC-META-010 | NG+ 빌드 다양성 — 슬롯 추가 | PROPOSED | ★★ | S | GrowthSystem, SaveSystem | NG+ 결정 |
| REC-META-011 | Daily Challenge — 일일 시련 | PROPOSED | ★★ | M | StageSystem, Steam SDK | — |
| REC-META-012 | 보스 갤러리 — 박물관 모드 | PROPOSED | ★★ | S | BossSystem, UI | — |
| REC-META-013 | 도전 룸 셔플 — 무한 모드 | PROPOSED | ★★ | M | StageSystem, EnemySystem | — |

### 2.5 UI/UX/접근성 (REC-UX)

| ID | 이름 | 상태 | 우선 | 노력 | 관련 시스템 | 의존 |
|---|---|---|---|---|---|---|
| REC-UX-001 | 모래시계 그림자 — 시간 자원 시각화 | **STALE** | — | S | HUD, TimeSystem | 일식링 디자인 만족 (2026-04-26 확정) |
| REC-UX-002 | 미니맵 단계 시스템 (Cornifer 의존) | PROPOSED | ★★★ | M | WorldMapUI, MiniMap | REC-CONT-002 |
| REC-UX-003 | 인벤토리 — 픽셀 일러스트 + 짧은 시 | **PARTIAL** | ★★★ | M | InventorySystem, UI | flavor_text 스키마 + 일러스트 144×144 + 작가 |
| REC-UX-004 | 시간 정지 자동 보조 모드 | PROPOSED | ★★ | S | TimeSystem, 옵션 메뉴 | — |
| REC-UX-005 | 한글 픽셀아트 폰트 통합 | **IMPLEMENTED** | ★★★ | S | UI 전체 | main_theme.tres + project.godot 등록 |
| REC-UX-006 | Tunic식 디제틱 가이드 (매뉴얼 발견형) | PROPOSED | ★★★ | S | StorySystem, UI | REC-CONT-005 |

### 2.6 사운드/음악 (REC-SND)

| ID | 이름 | 상태 | 우선 | 노력 | 관련 시스템 | 의존 |
|---|---|---|---|---|---|---|
| REC-SND-001 | 동적 음악 레이어 — 그림자 강도 반응 | PROPOSED | ★★ | M | AudioSystem (신설), ShadowSystem | SOUND.md 신설 |
| REC-SND-002 | 정지 음향 — 시간 정지 무음 | PROPOSED | ★★★ | S | AudioSystem, TimeSystem | SOUND.md 신설 |
| REC-SND-003 | 보스 음악 페이즈 변화 | PROPOSED | ★★ | M | AudioSystem, BossSystem | SOUND.md 신설 |
| REC-SND-004 | 거점 음악 — 30~40초 우디 루프 | PROPOSED | ★★★ | S | AudioSystem | SOUND.md 신설 |
| REC-SND-005 | 환경 음향 — 정지된 자연음 | PROPOSED | ★★ | S | AudioSystem | SOUND.md 신설 |

### 2.7 스토리/내러티브 (REC-NARR)

| ID | 이름 | 상태 | 우선 | 노력 | 관련 시스템 | 의존 |
|---|---|---|---|---|---|---|
| REC-NARR-001 | 환경 스토리텔링 — 정지된 사람들/사물 | PROPOSED | ★★★ | M | StageSystem, 아트 | REC-MECH-001 |
| REC-NARR-002 | NPC 변화 추적 — Quirrel 패턴 | PROPOSED | ★★ | M | NPC, StorySystem, SaveSystem | — |
| REC-NARR-003 | Lore Trinkets — 짧은 시 컬렉션 | PROPOSED | ★★ | M | InventorySystem, 아트 | — |
| REC-NARR-004 | 컬렉터블 — 5권 일기 | PROPOSED | ★★★ | M | StorySystem, SaveSystem | 후반 스토리 확정 |
| REC-NARR-005 | 가족 라인 — 5단계 선조 | PROPOSED | ★★★ | L | StorySystem, NPC | 후반 스토리 확정 |

### 2.8 위험 신호 (REC-RISK)

> 추천이 아니라 **현재 설계의 우려 영역**. 채택/기각이 아니라 **결정** 또는 **완화** 대상.

| ID | 이름 | 상태 | 긴급도 | 영향 영역 |
|---|---|---|---|---|
| REC-RISK-001 | 그림자 회피 가능 → 게임 평면화 | OPEN | 중 | 코어 메카닉 |
| REC-RISK-002 | 시간 정지 만능 카드 → 코어 자원 평면화 | OPEN | 중 | 코어 메카닉, 보스 |
| REC-RISK-003 | 5구역 50스테이지 1인 개발 Scope | **RESOLVED** (2026-04-26: 50 풀 양산 결정) | 중 | 전체 일정 |
| REC-RISK-004 | 한 화면 카메라 — 메트로배니아 표준 위반 | **RESOLVED** (2026-04-26: follow 이미 구현됨) | 해소 | UX, 마케팅 |
| REC-RISK-005 | Manuscript/Echo Nail 추가 시 텍스트량 폭발 | OPEN | 낮음 | 작가 협업 |

### 2.9 한국 인디 시장 (REC-MKT)

| ID | 이름 | 상태 | 영향 |
|---|---|---|---|
| REC-MKT-001 | Skul 사례 분석 — 픽셀아트 퀄리티/1메카닉 깊이/로컬라이제이션 | NOTE | 전략 참고 |
| REC-MKT-002 | 수묵화 톤 픽셀아트 | PROPOSED | 아트 방향 |
| REC-MKT-003 | 한국 신화 모티프 | PROPOSED | 보스/NPC 디자인 |
| REC-MKT-004 | 시간 = 동양 철학 모티프 | PROPOSED | 텍스트/내러티브 |
| REC-MKT-005 | GIF 친화 메카닉 — 트레일러 hook | NOTE | 마케팅 |
| REC-MKT-006 | Steam Next Fest 타이밍 | NOTE | 일정 |
| REC-MKT-007 | 커뮤니티 엔진 — Daily/Inverted/Manuscript | NOTE | 롱테일 |

---

## 3. 사용 가이드 (병렬 세션용)

### 3.1 작업 시작 전
1. 본 README의 인덱스 표에서 본인 작업 영역에 해당하는 추천 확인
2. CHANGELOG.md 마지막 작업 이후 변경사항 훑기
3. 대상 항목 본문 읽기 (해당 카테고리 .md)

### 3.2 작업 중
- 추천을 채택하면: 상태 `PROPOSED → ACCEPTED → IN_PROGRESS` 단계적 갱신
- 추천을 변형/조합하면: 본문에 `구현 메모` 섹션 갱신 + ID 유지
- 새 추천이 떠오르면: 동일 카테고리에 새 ID로 추가

### 3.3 작업 완료
- 구현 완료 시: 상태 `IMPLEMENTED` + 어느 커밋에서 완료됐는지 본문에 기록
- 기각 시: 상태 `REJECTED` + 사유 한 줄
- 무효화 조건 충족: 상태 `STALE` + 재검토 메모

### 3.4 인덱스 갱신
README.md §2의 표에서 상태 셀만 수정. CHANGELOG.md에 한 줄 추가.

---

## 4. 작성 시점 / 출처

- **작성일**: 2026-04-25
- **출처**: 백그라운드 리서치 에이전트 결과
  - 시스템 갭 매핑 (내부 docs + src 분석)
  - 레퍼런스 게임 딥 리서치 (HK / Blasphemous / Ori / Tunic / Animal Well / SOTN / Don't Starve / Death's Door / Hades / Salt and Sanctuary / Skul 등)
- **관련 메모리**: 본 폴더 위치는 auto memory에 등록됨
