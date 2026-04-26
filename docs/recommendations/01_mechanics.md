# 메카닉 / 게임플레이 추천

> **STATUS**: 본 문서 모든 항목 PROPOSED. 결정 아님.
> **카테고리 코드**: MECH

---

## REC-MECH-001 — Echo Nail (정지 잔상 들여다보기)

- **상태**: PROPOSED
- **우선순위**: ★★★
- **노력**: M
- **레퍼런스**: Hollow Knight — Dream Nail
- **관련 시스템**: StorySystem, EffectTimeline, EnemySystem, NPC
- **의존**: —
- **무효화 조건**: 스토리 전달 매체로 다른 방식(컷신/대화) 채택 시

### 컨셉
시간이 정지된 세계관과 1:1 매칭. "정지된 자에게서 흐른 시간의 잔상을 본다"는 컨셉이 제사장 가문 정체성과 부합. 적/NPC/오브젝트를 시간 정지 중 들여다보면 짧은 회상 텍스트 + 자원 획득.

### 레퍼런스 분석
HK의 Dream Nail:
- 일반 적 → 짧은 한 줄 + Essence 1
- 보스/NPC → 긴 한 줄 + Essence 더 많이
- 죽은 NPC 위치에 Dream Boss 부활 (재대결)

### 이 프로젝트 적용
- Essence 대신 **회상 파편(Memory Shard)** 자원
- Memory Shard는 (a) 추가 스킬 슬롯 잠금 해제 또는 (b) 엔딩 분기 게이트로 사용
- 죽은 NPC 잔상 → 5세대 선조 회상에 활용 (REC-NARR-005와 시너지)

### 구현 메모
- Echo Nail은 별도 입력(예: 시간 정지 중 장기 누름)이거나 새 슬롯 1개로 운용
- 잔상 표시는 EffectTimeline 새 .tres 1장 + 짧은 다이얼로그 박스
- 적/NPC/오브젝트 종류별로 잔상 텍스트 사전 작성 필요 → 스토리 작가 협업 시점 결정

---

## REC-MECH-002 — 그림자 광기 (장기 노출 페널티)

- **상태**: **IMPLEMENTED (인프라)** (2026-04-26)
- **우선순위**: ★★★
- **노력**: M (인프라) / L (환영 적 entity 후속)
- **레퍼런스**: Don't Starve — Sanity / Shadow Creature
- **관련 시스템**: ShadowSystem, EventBus, MadnessSystem(신설), MadnessHud(신설)
- **검증 (인프라)**:
  - `data/madness/madness_config_data.gd` + `madness_config.tres` 신설 — 임계/누적/회복/단계/시너지 파라미터
  - `src/systems/madness/madness_system.gd` Autoload 신설 — 강도≥threshold일 때 `delta×강도×accumulation_rate` 누적, 시간 정지 중 회복, 4단계 분류 + EventBus emit
  - `event_bus.gd` 시그널 추가: `madness_changed(value, max)` + `madness_stage_changed(old, new)`
  - `src/ui/hud/madness_hud.gd` 신설 — Autoload, ProgressBar placeholder + 단계별 색조 (SAFE→CRITICAL 보라→빨강 그라데이션)
  - `src/systems/effects/effects_shadow_vignette.gd` — 광기 단계 시너지 추가 (`madness_stage_changed` 구독 → 비네트 알파 추가 보정)
  - `project.godot` MadnessSystem + MadnessHud autoload 등록
  - gdlint 통과 + Godot 헤드리스 로드 통과
- **남은 작업 (후속)**: 환영 적 entity 디자인 + spawn 코드 (밸런싱 + Phase 4-C 이후 작업으로 분리)

### 4단계 정책
| 단계 | 비율 | 비네트 추가 보정 | 환영 적 |
|---|---|---|---|
| SAFE (0) | 0~30% | +0.00 | 없음 |
| WARNING (1) | 30~60% | +0.05 | 신호만 |
| ALERT (2) | 60~85% | +0.12 | 향후 1체 |
| CRITICAL (3) | 85~100% | +0.20 | 향후 다수 + 처치 시 Memory Shard |

### 누적/회복 정책 (config 기본값)
- 누적: 강도 ≥ 0.5일 때 `강도 × 5.0 × delta` (강도 1.0 = 20초 만에 풀)
- 회복: 시간 정지 중 `10.0 × delta` (10초 만에 풀 회복)
- 코어 메카닉 통합: 위험을 감수해 큰 그림자에서 머물면 광기 누적, 시간 정지로 회복 = 코어 자원이 카운터로 자연 통합

### 시너지 (REC-FX-007)
광기 단계 → `effects_shadow_vignette` 가 비네트 알파에 추가 보정 적용. 광기 단계가 높을수록 화면 가장자리 어둠 강조.

### 미래 확장 (후속 작업)
- **환영 적 entity** (Don't Starve Shadow Creature 패턴): 단계 ALERT 이상부터 spawn. 일반 적과 구별되는 외형 + 처치 시 보상.
- 거점 진입 시 광기 즉시 회복 (HP 회복과 같은 패턴).
- NG+ 균열 깊이(REC-META-004)와 결합 — 깊이 높을수록 누적 속도 증가.
- 셰이더 화면 왜곡 (Don't Starve 풀 광기 효과) — Pass 5 후속.

---

## REC-MECH-003 — 양방향 패리 (빛/그림자 패리 구분)

- **상태**: PROPOSED
- **우선순위**: ★★
- **노력**: M
- **레퍼런스**: Blasphemous 2 — 정밀 패리 + 후속 응징
- **관련 시스템**: CombatSystem
- **의존**: —
- **무효화 조건**: 4타 콤보가 충분히 깊다고 판단되면 추가 시스템 부담

### 컨셉
4타 콤보 + 4 스킬 슬롯이 이미 있는 상황에서, 패리를 추가해 속성 정체성을 액션으로 직접 표현. 빛 패리 = 정화 데미지 ×2, 그림자 패리 = 카운터 후 시간 자원 회복.

### 레퍼런스 분석
Blasphemous 2:
- 마지막 순간 패리 → 적 스턴 → riposte 가능
- 패리 윈도우는 무기마다 다름

### 이 프로젝트 적용
- 패리 윈도우 0.15s
- 직전 사용한 속성 피니시에 따라 패리 효과 변경
  - 빛 피니시 후 패리: 적 정화 데미지 ×2 (잔류 즉시 제거)
  - 그림자 피니시 후 패리: 시간 자원 +5 회복
  - 혼합 피니시 후 패리: 콤보 카운터 유지
- 코어 룰의 보상 사이클을 닫는 효과

### 구현 메모
- 4타 콤보의 hit reaction 시스템 활용 가능
- 적의 공격 모션에 "패리 가능 윈도우" 마커 추가 (BaseEnemy hook)
- 시각 큐: 적 공격 직전 0.2초 빛/그림자 색 플래시

---

## REC-MECH-004 — 시간 잔향 종 (환경 오브젝트 #5)

- **상태**: PROPOSED
- **우선순위**: ★★
- **노력**: M
- **레퍼런스**: Outer Wilds — 22분 루프의 "지식만 남는" 진행
- **관련 시스템**: TimeSystem, 환경 오브젝트
- **의존**: —
- **무효화 조건**: 기존 4 환경 오브젝트로 퍼즐 깊이 충분하다고 판단 시

### 컨셉
종을 치면 그 방의 **60초 전 상태(적 위치/오브젝트 위치)**를 5초간 환영으로 표시. 환영의 적은 데미지 안 줌. 퍼즐 룸/보스 패턴 학습용. 거점 외에서도 짧은 "메타 학습" 가능.

### 이 프로젝트 적용
- 환경 오브젝트 #5로 등재 (현재 4종: 거울/렌즈/차폐물/반사 바닥)
- 시간 정지 중 종을 치면 발동, 시간 흐름 중에는 차폐
- 보스룸에 1개씩 배치하면 패턴 학습 보조 도구로 작동
- 한 화면 카메라 정책에 부합

### 구현 메모
- BaseEnvironmentObject 확장
- 60초 상태 기록은 모든 적/오브젝트 위치 스냅샷 (1초 간격)
- 환영 표시는 EffectTimeline + 반투명 sprite
- 메모리 부하 우려 → 종 활성 룸에서만 기록

---

## REC-MECH-005 — 그림자 발자국 (땅거미 추적 전조 UI)

- **상태**: **IMPLEMENTED** (2026-04-26)
- **우선순위**: ★★★
- **노력**: S
- **레퍼런스**: Hollow Knight — Hunter, Dead Cells — Concierge 알람
- **관련 시스템**: DuskSpiderSystem, dusk_spider_hud, EventBus
- **검증**:
  - `src/ui/hud/dusk_spider_hud.gd` 확장 — 발자국 풀 5개 동적 생성, `EventBus.dusk_spider_approached` 시그널 → 단계별 fade in/out + position.x 안쪽 이동
  - `data/effects/effects_config_data.gd` — `footprint_*` 6 파라미터 추가 (pool_size/color/size/edge_margin/inward_drift/fade_duration)
  - `docs/art_specs/dusk_footprint.md` 신설 — 16×16 발자국 sprite 명세 + sprite 자동 교체 fallback chain
  - placeholder ColorRect로 즉시 작동, sprite 도착 시 자동 교체 (`assets/sprites/ui/dusk_footprint.png`)
  - gdlint 통과 + Godot 헤드리스 로드 테스트 통과
- **결정 이력**: 별도 OverlaySystem 셰이더 슬롯 신설 대신 **dusk_spider_hud 자체 확장**. CanvasLayer 안에 동적 노드 풀로 단순 구현. 기존 보라색 맥동 작은 아이콘은 유지 (환경 가시화 + 명시 카운터 둘 다).

### 구현 단계 매핑
| 거리 | 표시 발자국 | 안쪽 이동 | 알파 |
|---|---|---|---|
| -1 (비활성) | 0개 | — | 0.0 |
| 2 (먼 보라) | 2개 | 0px | 0.4 |
| 1 (근접) | 4개 | 18px | 0.7 |
| 0 (도착) | 5개 | 36px | 1.0 |

### 시너지
- REC-FX-007 (그림자 비네트): 비네트(사방 어둠) + 발자국(좌측 침투) 두 시각 단서 동시 작동 — DuskWarning이 비네트 점유, 발자국은 별도 슬롯이라 충돌 없음
- REC-SND-002 (정지 음향): 향후 SOUND.md 신설 시 거리 1 단계부터 발걸음 SFX 추가 가능
- REC-FX-004 (그림자 떨림): 향후 거리 0 단계 발자국에 떨림 셰이더 적용 가능

### 미결 (확장 후보)
- 음향 큐 — REC-SND-002 채택 시
- 화면 우측 동시 침투 (양방향 위협)
- sprite 변형 옵션 B/C (좌우 교차 또는 5장 다른 형태)

---

## REC-MECH-006 — 그림자 흡수 (흡혈 메카닉)

- **상태**: PROPOSED
- **우선순위**: ★★
- **노력**: S
- **레퍼런스**: Castlevania SOTN — 흡혈 효과, Hades — Stygian
- **관련 시스템**: CombatSystem, TimeSystem
- **의존**: —
- **무효화 조건**: 시간 자원 회복이 이미 충분히 빠르다고 판단되면

### 컨셉
적 처치 시 그림자 크기에 비례한 흡수. 큰 그림자 적을 처치할수록 시간 자원/HP 회복 더 큼. **코어 룰을 보상 사이클로 닫음** — 위험을 감수한 만큼 보상.

### 이 프로젝트 적용
- 적 처치 시 시간 자원 회복량 = 그림자 크기에 비례 (현 단조 회복에서 변경)
- 큰 그림자(150%) 처치 = 시간 자원 +10
- 작은 그림자(20%) 처치 = 시간 자원 +2
- 빛/그림자 빌드별 차등 가능

### 구현 메모
- CombatSystem의 적 처치 hook에서 그림자 강도 읽어 회복량 계산
- 장신구 특수효과로 흡수 강화 가능 (ITEMS.md 미결 사항과 연결)

---

## REC-MECH-007 — 빛 굴절 콤보 (거울 연쇄 공격)

- **상태**: **IMPLEMENTED** (2026-04-26)
- **우선순위**: ★★
- **노력**: S
- **레퍼런스**: Animal Well — 환경 상호작용 퍼즐
- **관련 시스템**: Mirror, FinishStrategy(finish_light), CombatSystem, EffectsSystem
- **검증**:
  - `src/entities/objects/environment/mirror/mirror.gd` — `add_to_group("mirror")` 등록 (1줄)
  - `src/entities/player/finish/finish_light.gd` — `_trigger_mirror_reflections(ctx)` 추가. 같은 stage scene 내 모든 거울 검색 → 각 거울의 `rotation_pivot.global_position` + `global_rotation` 으로 빛 빔 발사
  - `src/systems/effects/effects_light_beam.gd` 신설 — Polygon2D 회전된 직사각형 + Tween fade
  - `src/systems/effects/effects_system.gd` — `_light_beam` 인스턴스 + 공개 API `spawn_light_beam(start_pos, angle, duration)`
  - `data/effects/effects_config_data.gd` — `light_beam_*` 7 파라미터 추가 (length/width/active_duration/fade_duration/damage_ratio/color/alpha)
  - hitbox attacker = `mirror.rotation_pivot` → 거울 회전 자동 추적, AttackSpec.piercing=true로 룸 내 다중 적 관통
  - gdlint 통과 + Godot 헤드리스 로드 통과

### 구현 컨셉
빛 피니시 발동(`finish_light.execute`) 시:
1. 기존 LIGHT_DASH 돌진 + 60×24 히트박스 (변경 없음)
2. **추가**: `tree.get_nodes_in_group("mirror")` 로 같은 stage 내 모든 거울 검색
3. 각 거울:
   - 시각: `EffectsSystem.spawn_light_beam(pivot.global_position, pivot.global_rotation)` — Polygon2D 320×18 빔, 0.22초 페이드
   - Hitbox: `AttackSpec(rect 320×18, attacker=rotation_pivot, attribute="light", piercing=true, damage=피니시 50%)` → CombatSystem.request_attack
4. hitbox는 `rotation_pivot` 자식이라 거울 회전(4프리셋 90°)에 따라 자동 추적

### 데미지 정책
- 빔 데미지 = 피니시 데미지 × `light_beam_damage_ratio` (기본 0.5 = 50%)
- 다중 거울 시너지: 거울이 N개면 동시 N개 빔 발사 (의도된 빌드 보상)
- 1차 출시 후 밸런싱 별도

### GIF 친화도
빛 빔이 거울에 튕겨 적 여러 마리 한 번에 잡는 그림 = SNS 공유에 강함 (REC-MKT-005 시너지).

### 결정 이력
- 2026-04-26 REC-RISK-004 RESOLVED 후 옵션 A/B 재검토 → **옵션 A 확정** (사용자 결정).
- 2026-04-26 IMPLEMENTED — 구현 시 `attacker = mirror.rotation_pivot` 패턴으로 회전 자동 추적, AttackSpec.piercing=true로 다중 적 관통.

### 기각된 옵션 (참고)
- **옵션 B 인접 룸 텔레그래프**: 빛 빔이 룸 경계를 넘어 인접 룸의 적에 데미지 누적. 발견형 즐거움 강하지만 (1) 다른 매체와 중복, (2) 큰 룸에서는 효과 없음, (3) 구현 복잡도 높음 → 기각.

### 미결 / 확장 후보
- 거울 + 렌즈 콤보 (빔이 렌즈 통과 시 데미지 증폭)
- 빔 발광 셰이더 (현재 단색 Polygon2D — 향후 hud_eclipse_ring 같은 발광 셰이더 적용)
- shadow 피니시도 거울 반사 적용 검토 (그림자 흡수 빔)

---

## REC-MECH-008 — 시간 봉인 룸 (시간 정지 금지 챔버)

- **상태**: PROPOSED
- **우선순위**: ★★
- **노력**: S
- **레퍼런스**: Hollow Knight — Trial of the Conqueror
- **관련 시스템**: StageSystem, TimeSystem
- **의존**: —
- **무효화 조건**: REC-MECH-009의 보스 패턴 P3에서 같은 효과를 페이즈로 구현 시

### 컨셉
일부 도전 룸에서 **시간 정지 봉인**. 코어 자원 없이 정공법으로 클리어해야 함. 플레이어의 무브/콤보 실력만 시험. 보상은 챔버당 차터/스킬 코어.

### 이 프로젝트 적용
- 일부 챌린지 룸 또는 1구역당 1개 숨겨진 룸
- 진입 시 TimeSystem이 STOPPED 상태 잠금
- 클리어 보상: 영구 스탯 1포인트 또는 비밀 스킬

### 구현 메모
- StageSystem에 새 lock_type `TIME_LOCK_FORBIDDEN` 추가
- 진입 시 TimeSystem.lock_stop() 호출, 퇴장 시 unlock
- HUD에 시간 정지 슬롯이 잠겼다는 시각 큐

---

## REC-MECH-009 — 보스 패턴 4페이즈 골격

- **상태**: PROPOSED
- **우선순위**: ★★★
- **노력**: L
- **레퍼런스**: Death's Door 보스, Blasphemous 2 — Esdras
- **관련 시스템**: BossSystem
- **의존**: —
- **무효화 조건**: 후반 보스가 다른 컨셉으로 확정되면

### 컨셉
5 보스 중 후반 보스(3~5구역) 표준 골격으로 권장. 코어 메카닉을 페이즈마다 다른 각도로 시험.

### 표준 골격
| 페이즈 | 컨셉 | 시험 대상 |
|---|---|---|
| P1 | 일반 (작은 그림자) | 4타 콤보, 기본 스킬 학습 |
| P2 | 그림자 확장 (영역 자체가 어두워짐) | 큰 그림자 = 강한 적의 가시화 |
| P3 | 시간 가속 (보스가 시간 자원 소모) | 코어 룰 역전 — 정지가 불리 |
| P4 | 봉인 해제 — 패리 윈도우만 열림 | REC-MECH-003 + 정밀 액션 |

### 이 프로젝트 적용
- 3~5구역 보스 설계 시 본 골격을 출발점으로
- 페이즈 수: 3구역 3페이즈, 4구역 3페이즈, 5구역 4페이즈 (GDD §7.2 일치)
- P3 "시간 가속"이 가장 차별화 포인트 — 코어 룰 역전 보스는 다른 게임에 없음

### 구현 메모
- BossSystem의 페이즈컨트롤러 이미 존재 → 패턴 추가
- P3에서 보스가 TimeSystem에 영향을 주는 새 hook 필요
- 5구역 P4 보스는 두 왕가 결합체이므로 P4 = 빛/그림자 동시 패리 윈도우

---

## REC-MECH-010 — 정지 면역 엘리트 적

- **상태**: PROPOSED
- **우선순위**: ★★
- **노력**: S
- **레퍼런스**: Don't Starve — Nightmare Light 옆 Shadow Creature
- **관련 시스템**: EnemySystem, TimeSystem
- **의존**: —
- **무효화 조건**: REC-MECH-009 P3가 같은 역할을 보스 단위로 흡수 시 일반 적은 불필요

### 컨셉
일부 엘리트는 시간 정지 무시. 정지로 도주해도 따라옴. **코어 룰 의존 플레이 스타일을 깨뜨려 주의를 강제**. 1구역당 1~2종으로 제한.

### 이 프로젝트 적용
- 3구역부터 등장하는 정지 면역 엘리트 1종 추가
- 외형: 일반 적과 구별되는 색조 (그림자 왕가 잔재 모티프)
- 행동: 시간 정지 중에도 천천히 추적
- 처치 시 Memory Shard 드롭 (REC-MECH-001 시너지)

### 구현 메모
- BaseEnemy에 `time_stop_immune: bool` 플래그 추가
- TimeSystem이 STOPPED일 때도 해당 적은 _process 계속
- 1·2구역에는 등장 안 함 (난이도 곡선 고려)

---

## 카테고리 메모

- 본 10개는 모두 **기존 시스템 위에 얇은 레이어로 추가** 가능 (큰 시스템 신설 없음)
- REC-MECH-001/002/005는 코어 정체성 강화로 우선순위 ★★★
- REC-MECH-003/006은 액션감 향상이지만 4타 콤보로 충분할 수도
- REC-MECH-009는 후반 보스 설계 출발점으로 매우 가치 큼
