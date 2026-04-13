# 시간이 멈춘 숲 — 개발 계획

> 이 문서는 프로토타입부터 Steam 출시까지의 전체 개발 로드맵을 정의한다.
> 1인 개발 체제를 고려하여, 각 단계의 목표와 산출물을 명확히 한다.

---

## 전체 구조

```
Phase 0  기반 세팅                ✅ 완료
Phase 1  코어 프로토타입          ✅ 완료 (1-1~1-7 전체 완료)
Phase 2  시스템 확장
Phase 3  1구역 버티컬 슬라이스
Phase 4  전체 콘텐츠
Phase 5  폴리싱
Phase 6  출시
```

---

## Phase 0 — 기반 세팅 ✅

> 프로젝트 구조, 에이전트, 설계 문서 정비

| 항목 | 상태 |
|---|---|
| 설계 문서 12개 (GDD + 상세) | ✅ |
| CLAUDE.md (아키텍처 원칙) | ✅ |
| 에이전트 7개 | ✅ |
| 프로젝트 폴더 구조 | ✅ |
| project.godot 초기 설정 | ✅ |
| EventBus | ✅ |

---

## Phase 1 — 코어 프로토타입

> **목표**: 핵심 게임 루프 1사이클이 작동하는 최소 플레이 가능 빌드
> **아트**: 전부 플레이스홀더 (단색 사각형, 기본 도형)

### 마일스톤

#### 1-1. 플레이어 기본 이동 ✅
- [x] CharacterBody2D 기반 플레이어 씬
- [x] 달리기 (단일 속도)
- [x] 2단 점프 (코요테 타임, 가변 점프 높이 포함)
- [x] 대시 (쿨다운 기반)
- [x] 카메라 추적
- **의존성**: 없음
- **구현 파일**:
  - `src/entities/player/Player.tscn` — 플레이어 씬 (Composition 패턴, 10개 자식 노드)
  - `src/entities/player/player.gd` — 루트 오케스트레이터
  - `src/entities/player/player_input.gd` — 입력 → 의도 변환
  - `src/entities/player/player_state_machine.gd` — 상태 관리 (IDLE/RUN/JUMP/FALL/DASH)
  - `src/entities/player/player_movement.gd` — 속도 계산
  - `src/entities/player/player_animation.gd` — 상태→애니메이션 매핑
  - `src/entities/player/player_stats_data.gd` — Resource 클래스 (PlayerStatsData)
  - `data/player/player_stats.tres` — 스탯 데이터 인스턴스
- **참고**: 예시 .ase 스프라이트(player_spritesheet.png)로 동작 확인 완료. Jump/Fall/Dash는 임시로 run 애니메이션 사용 중.

#### 1-2. 테스트 스테이지 ✅
- [x] 바닥, 벽, 플랫폼 배치 (StaticBody2D + ColorRect 플레이스홀더)
- [x] 플레이어 스폰 포인트
- [x] 아트 fallback 로직 (PNG 존재 시 자동 적용)
- **의존성**: 1-1
- **구현 파일**:
  - `src/world/stages/TestStage.tscn` — 바닥(640x32), 플랫폼 3개(192x16), 벽 2개, 배경 ColorRect
  - `src/world/stages/test_stage.gd` — 아트 리소스 fallback 로더
- **참고**: TileMap 전환은 Phase 3(1구역 버티컬 슬라이스)에서 타일셋 아트와 함께 진행. 현재 구조는 Phase 1 테스트 목적으로 충분.

#### 1-3. 시간 시스템 ✅
- [x] 시간 상태 머신 (정지 / 조작 / 흐름)
- [x] 시간 조작 (버튼 꾹 → 시각 빠르게 이동)
- [x] 시간 흐름 (1분 = 1시간)
- [x] 시간 자원 소모/회복
- [x] 낮/밤 경계 (06:00, 18:00) 처리
- [x] CanvasModulate 연동 (낮/밤 분위기 전환)
- [x] HUD: 시계 + 시간 자원 게이지
- **의존성**: 1-2
- **구현 파일**:
  - `src/systems/time/time_system.gd` — Autoload 오케스트레이터
  - `src/systems/time/time_state_machine.gd` — 상태 머신 (STOPPED/MANIPULATING/FLOWING)
  - `src/systems/time/time_clock.gd` — 시각 진행, 경계 판정
  - `src/systems/time/time_resource.gd` — 시간 자원 소모/회복
  - `src/systems/time/time_atmosphere.gd` — CanvasModulate 낮/밤 전환
  - `src/systems/time/time_config_data.gd` — Resource 클래스 (TimeConfigData)
  - `data/time/time_config.tres` — 수치 데이터 인스턴스
  - `src/ui/hud/TimeHud.tscn` + `time_hud.gd` — 시간 HUD
- **참고**: 수치(조작 속도, 자원량 등)는 time_config.tres에서 조정. 적 처치 회복은 EventBus 연결 준비 완료.

#### 1-4. 그림자 시스템 ✅
- [x] 오브젝트별 그림자 스프라이트 생성 (ShadowCaster 컴포넌트, fallback ColorRect)
- [x] 시간(태양 각도)에 따른 그림자 방향/길이 변화
- [x] 그림자 scale → 적 강도 배율 매핑 (20%~150%, Curve 슬롯 준비)
- [x] 낮/밤 반전 로직 (밤은 등불 시스템 전까지 fallback 고정값)
- **의존성**: 1-3
- **구현 파일**:
  - `src/systems/shadow/shadow_system.gd` — Autoload 오케스트레이터
  - `src/systems/shadow/shadow_calculator.gd` — 순수 계산 (태양 각도→방향/스케일→강도)
  - `src/systems/shadow/shadow_config_data.gd` — Resource 클래스 (ShadowConfigData)
  - `src/systems/shadow/shadow_caster.gd` — 오브젝트 컴포넌트 (그림자 스프라이트 갱신)
  - `data/shadow/shadow_config.tres` — 수치 데이터 인스턴스
- **참고**: 시스템 간 통신은 EventBus.sun_state_updated 수신 / shadow_params_changed 발신. 매핑 곡선은 선형(기본) + Curve 리소스로 교체 가능. 밤 per-object 계산은 1-7(등불) 구현 시 활성화.

#### 1-5. 적 시스템 (기본) ✅
- [x] 그림자에서 적 생성 (시간 흐름 시) — 현재는 씬 미리 배치 + DORMANT↔활성 전환 방식. 동적 스폰은 Phase 2에서 확장.
- [x] 강도 배율 적용 (HP, 공격력, 속도)
- [x] 기본 AI (순찰, 추적, 공격)
- [x] 베이스 1종 (나무형 — 크고 느림) — 실제로는 4종(나무/바위/꽃/돌기둥) 모두 구현
- [x] 처치 → 그림자 잔류 생성
- **의존성**: 1-4
- **구현 파일**:
  - `src/systems/enemy/enemy_system.gd` — Autoload 오케스트레이터 (활성화/비활성화, 강도 갱신)
  - `src/systems/enemy/enemy_registry.gd` — 적 목록 관리
  - `src/systems/enemy/enemy_intensity.gd` — 전역 강도 → 유형별 배율 변환
  - `src/entities/enemies/base/base_enemy.gd` — 적 루트 스크립트 (Composition 패턴)
  - `src/entities/enemies/base/enemy_state_machine.gd` — AI 상태 머신 (DORMANT/PATROL/CHASE/ATTACK/HURT/DEAD)
  - `src/entities/enemies/base/enemy_stats.gd` — HP/강도 동적 조정
  - `src/entities/enemies/base/enemy_movement.gd` — 이동 계산
  - `src/entities/enemies/base/enemy_animation.gd` — 애니메이션 매핑
  - `src/entities/enemies/shadow_residue/shadow_residue.gd` — 잔류 컴포넌트
  - `data/enemies/enemy_config.tres` — 전역 적 설정
  - `data/enemies/tree_enemy.tres` 등 4종 — 유형별 스탯 데이터

#### 1-6. 기본 전투 ✅
- [x] 4타 횡베기 콤보
- [x] 히트박스/허트박스 시스템
- [x] 데미지 처리 (적 → 플레이어, 플레이어 → 적)
- [x] HP 시스템 (플레이어 + 적)
- [x] 사망 처리 (거점 귀환)
- [x] HUD: HP 게이지
- **의존성**: 1-5
- **구현 파일**:
  - `src/systems/combat/combat_system.gd` — Autoload (리스폰 관리)
  - `src/systems/combat/combat_calculator.gd` — 데미지 계산
  - `src/systems/combat/combat_config_data.gd` — Resource 클래스
  - `data/combat/combat_config.tres` — 전투 수치 데이터
  - `src/entities/player/player_combo.gd` — 4타 콤보 상태 머신 + 동적 히트박스
  - `src/entities/player/player_health.gd` — HP, 넉백, 무적, 사망/리스폰 + 동적 허트박스
  - `src/ui/hud/CombatHud.tscn` + `combat_hud.gd` — HP 바, 콤보 인디케이터, 사망 오버레이

#### 1-7. 등불 (기본) ✅
- [x] PointLight2D 기반 등불
- [x] 밤에 오브젝트에 빛 → 그림자 생성
- [x] 등불 거리 기반 그림자 크기 (밤 반전 로직)
- **의존성**: 1-4
- **구현 파일**:
  - `src/entities/player/player_lantern.gd` — 등불 컴포넌트 (PointLight2D 관리, 토글, ShadowSystem 등록)
  - `data/lantern/lantern_config_data.gd` — Resource 클래스 (LanternConfigData)
  - `data/lantern/lantern_config.tres` — 수치 데이터 인스턴스
- **수정 파일**: shadow_system.gd (등불 관리 API + per-object 계산), shadow_caster.gd (밤 모드 분기 + 폴링), player.gd/player_input.gd/Player.tscn (Lantern 연동), enemy_system.gd/enemy_registry.gd (per-enemy 강도)
- **참고**: 등불 ON/OFF는 L키. 밤+등불 ON 시 ShadowCaster가 per-object로 등불 거리 기반 그림자 계산. 밤+등불 OFF 시 그림자 없음(적 없음). 시간 정지 중에도 토글 가능.

### Phase 1 완료 기준
```
테스트 스테이지 진입
  → 시간 정지 상태에서 시각 확인
  → 시간 조작으로 원하는 시각 설정 (자원 소모)
  → 시간 흐름 → 그림자 변화 → 적 등장
  → 전투 (4타 콤보로 적 처치)
  → 밤 전환 → 등불로 그림자 생성 → 전투
  → 시간 자원 고갈 체험
```

---

## Phase 2 — 시스템 확장

> **목표**: 모든 게임 시스템이 기본 형태로 작동
> **아트**: 플레이스홀더 유지, 플레이어만 기본 애니메이션 적용 가능

### 마일스톤

#### 2-1. 전투 확장
- [ ] 4타 피니시 속성 공격 (빛/그림자/혼합)
- [ ] 스킬 슬롯 시스템 (4슬롯, 쿨타임)
- [ ] 스킬 2~3개 구현 (빛 1, 그림자 1, 혼합 1)
- [ ] 피격 무적 프레임
- [ ] 자동 회복 (시간 정지 상태)
- **의존성**: Phase 1 완료

#### 2-2. 적 확장
- [ ] 베이스 4종 완성 (나무, 바위, 꽃, 돌기둥)
- [ ] 유형별 그림자 반응 (표준/둔감/민감)
- [ ] 잔류 부활 (HP 50%, 공격력 150%)
- **의존성**: Phase 1 완료

#### 2-3. 땅거미 시스템
- [ ] 잔류 부활 메카닉 (2-2 최소 범위) — 2-3a
- [ ] 땅거미 엔티티 + 맵 이동 AI — 2-3b
- [ ] HUD 경고 + 도착 이벤트 — 2-3c
- **의존성**: 2-4a (스테이지 시스템 기반)

#### 2-4. 스테이지 시스템
- [x] 3단계 클리어 (미클리어/절반/완전) — 2-4a
- [x] 스테이지 전환 (인접 포탈, 씬 로딩) — 2-4b
- [x] 잠금 프레임워크 + 빛 잠금 — 2-4c
- [x] 인접 맵 시간 전파 (50%) + 정화 프레임워크 — 2-4d
- [x] 독립 스테이지 시간 흐름 + 자동 재개/정지 — 2-4d+
- [x] 테스트 스테이지 3개 추가 — 2-4e
- **의존성**: Phase 1 완료
- **구현 파일** (2-4a):
  - `src/systems/stage/stage_system.gd` — Autoload 오케스트레이터
  - `src/systems/stage/stage_registry.gd` — 스테이지 데이터 저장/조회
  - `src/systems/stage/stage_clear_tracker.gd` — 클리어 상태 추적
  - `data/stages/stage_data.gd` — StageData Resource 클래스 (ClearState/LockType enum)
  - `data/stages/test_stage.tres` — 테스트 스테이지 데이터
- **구현 파일** (2-4b):
  - `src/entities/objects/portal/stage_portal.gd` — 포탈 엔티티 (Area2D, EventBus 통신)
  - `src/entities/objects/portal/StagePortal.tscn` — 포탈 씬 (재사용)
  - `src/systems/stage/stage_transition.gd` — 전환 연출 (페이드 + Player 보존/재삽입)
  - `src/world/stages/test_stage_2.gd` — 두 번째 테스트 스테이지
  - `src/world/stages/TestStage2.tscn` — 두 번째 테스트 스테이지 씬
  - `data/stages/test_stage_2.tres` — 두 번째 스테이지 데이터
- **구현 파일** (2-4c):
  - `src/systems/stage/stage_lock_validator.gd` — 잠금 유형별 검증 (LIGHT, PURIFY, ENVIRONMENT, ABILITY)
- **구현 파일** (2-4d):
  - `src/systems/stage/time_propagation.gd` — 독립 스테이지 시간 전파 (_process 기반, BFS 감쇠, 자동 재개/정지)
  - `data/stages/propagation_config_data.gd` — PropagationConfigData Resource 클래스
  - `data/stages/propagation_config.tres` — 전파 설정 (rate 0.5, threshold 0.05, max_depth 6)
  - `src/entities/enemies/shadow_residue/purification_detector.gd` — 정화 조건 감지 (등불 + 반대 시간대)
- **수정 파일** (2-4d/2-4d+):
  - `src/systems/event_bus/event_bus.gd` — 시간 전파 시그널 추가 (flow_rate_changed, time_flow_paused/resumed, time_hour_sync_requested, time_flow_resume_requested)
- **구현 파일** (2-4e):
  - `data/stages/test_stage_3.tres` — 새벽 6시, NONE, 적 3
  - `data/stages/test_stage_4.tres` — 황혼 18시, PURIFY(test_stage_2), 적 5
  - `data/stages/test_stage_5.tres` — 심야 3시, LIGHT, 적 1
  - `src/world/stages/test_stage_3.gd` + `TestStage3.tscn` — 수직 플랫폼 레이아웃
  - `src/world/stages/test_stage_4.gd` + `TestStage4.tscn` — 좁은 복도 + 단차 레이아웃
  - `src/world/stages/test_stage_5.gd` + `TestStage5.tscn` — 넓은 아레나 레이아웃
- **수정 파일** (2-4e):
  - `data/stages/test_stage.tres` — adjacent에 test_stage_3 추가
  - `data/stages/test_stage_2.tres` — adjacent에 test_stage_4 추가
  - `src/world/stages/TestStage.tscn` — 좌측 포탈(→test_stage_3) 추가
  - `src/world/stages/TestStage2.tscn` — 우측 포탈(→test_stage_4) 추가
  - `src/systems/time/time_system.gd` — 가변 속도 FLOWING, pause/resume, 자동 재개 핸들러
  - `src/systems/time/time_clock.gd` — advance_flow에 rate 파라미터, compute_full_flow_hours 추가
  - `src/systems/stage/stage_system.gd` — 독립 흐름 자동 재개/정지 분기, 전환 중 flow pause/resume

#### 2-5. 환경 오브젝트
- [ ] 거울/수정 (빛 분산)
- [ ] 렌즈 (빛 집중)
- [ ] 차폐물 (빛 차단)
- [ ] 반사 바닥 (이중 약화)
- [ ] 수동 조작 (시간 정지 중만)
- **의존성**: Phase 1 완료

#### 2-6. 성장 시스템
- [ ] 강화 포인트 획득 (처치/클리어)
- [ ] 빛/그림자 투자 + 능력치 상승
- [ ] 프로퍼티 (시간 자원) 투자
- [ ] 리스펙
- **의존성**: 2-1

#### 2-7. 아이템/장비 시스템
- [ ] 장착 슬롯 (무기 1 + 방어구 1 + 장신구 3)
- [ ] 장비 능력치 적용
- [ ] 장신구 특수 효과 (1~2개)
- [ ] 소모품 (HP 회복, 시간 자원 회복)
- [ ] 인벤토리 UI
- **의존성**: 2-6

#### 2-8. 거점 시스템
- [ ] 거점 씬 (회복, 세이브) — 2-8a
- [ ] 월드맵 포탈 (거점 간 이동) + 월드맵 UI — 2-8b
- **의존성**: 2-4

### Phase 2 완료 기준
```
거점에서 출발
  → 여러 스테이지 탐색 (잠금 경로 존재)
  → 시간 조작 + 전투 + 환경 활용
  → 적 처치 → 포인트 획득 → 성장 투자
  → 장비 획득/교체
  → 잔류 정화 → 완전 클리어
  → 땅거미 접근 → 대응
  → 거점 귀환 → 회복 → 재출발
```

---

## Phase 3 — 1구역 버티컬 슬라이스

> **목표**: 1구역(빛의 숲) 전체를 플레이 가능한 수준으로 완성
> **아트**: 1구역 아트 본격 제작 시작 (플레이어 + 1구역 적 + 1구역 타일 + 1구역 보스)

### 마일스톤

#### 3-1. 1구역 레벨 디자인
- [ ] 6개 스테이지 레벨 설계 (지형, 적 배치, 환경 오브젝트)
- [ ] 추가조작 스테이지 1개
- [ ] 자연 경계 (강/개울 → 2구역 경계)
- **의존성**: Phase 2 완료

#### 3-2. 1구역 적
- [ ] 나무/바위/꽃/돌기둥 서브 타입 (1구역 버전)
- [ ] 1구역 고유 적 1종
- **의존성**: 3-1

#### 3-3. 1구역 보스
- [ ] 보스 설계 (거대 오브젝트 괴물화, 2페이즈)
- [ ] 보스 맵 설계
- [ ] 보스 처치 보상 (잠금 해제 능력 + 스토리 + 강화)
- **의존성**: 3-2

#### 3-4. 거점: 시작 마을
- [ ] 시작점 마을형 거점 (NPC, 상인)
- [ ] 1-2 경계 간이형 거점
- **의존성**: 3-1

#### 3-5. 월드맵 (기본)
- [ ] 1구역 영역 표시
- [ ] 시간 오버레이 (정지/낮/밤 시각화)
- [ ] 거점 간 이동
- [ ] 클리어 상태 표시
- **의존성**: 3-4

#### 3-6. UI 완성
- [ ] 인게임 HUD (시계, HP, 시간 자원, 스킬, 미니맵)
- [ ] 타이틀 화면
- [ ] 일시정지 메뉴
- [ ] 장비/스킬 관리 메뉴
- [ ] 맵 상세 패널
- **의존성**: Phase 2 완료

#### 3-7. 1구역 아트 적용
- [ ] 플레이어 스프라이트 + 애니메이션
- [ ] 1구역 타일셋 (빛의 숲)
- [ ] 1구역 적/보스 스프라이트
- [ ] 1구역 배경
- [ ] UI 아트
- [ ] 이펙트 (공격, 피격, 그림자 등)
- **의존성**: Art Spec Writer 명세서 기반, 3-1~3-6 구현 완료 후

#### 3-8. 사운드 (기본)
- [ ] 효과음 (공격, 피격, 시간 조작, 적 처치)
- [ ] 1구역 BGM
- **의존성**: 3-1

### Phase 3 완료 기준
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

## Phase 4 — 전체 콘텐츠

> **목표**: 2~5구역 전체 + 스토리 완성
> **아트**: 구역별 순차 제작

### 4-A. 2구역 — 안개 습지
- [ ] 8개 스테이지
- [ ] 서브 타입 적 + 고유 적
- [ ] 보스 (2페이즈)
- [ ] 거점 (2-3 경계 마을형 + 간이형)
- [ ] 아트 + 사운드

### 4-B. 3구역 — 폐허의 숲
- [ ] 10개 스테이지
- [ ] 서브 타입 적 + 고유 적
- [ ] 보스 (3페이즈, 전환점)
- [ ] 거점 (3-4 경계 마을형)
- [ ] 스토리 전환점 연출
- [ ] 아트 + 사운드

### 4-C. 4구역 — 그림자 숲
- [ ] 12개 스테이지
- [ ] 서브 타입 적 + 고유 적
- [ ] 보스 (3페이즈)
- [ ] 거점 (4구역 내부 간이형 + 4-5 경계 간이형)
- [ ] 아트 + 사운드

### 4-D. 5구역 — 봉인의 심부
- [ ] 14개 스테이지
- [ ] 서브 타입 적 + 고유 적
- [ ] 최종 보스 (4페이즈, 두 왕가의 결합체)
- [ ] 거점 (5구역 내부 간이형)
- [ ] 엔딩 연출
- [ ] 아트 + 사운드

### 4-E. 전체 연결
- [ ] 월드맵 전체 완성 (5구역 + 거점 8개)
- [ ] 스킬 전체 구현 (18개)
- [ ] 강화 이동 해금 (빛 대시, 그림자 점프 등)
- [ ] 장비/장신구 전체 목록
- [ ] 추가조작 4개 완성
- [ ] 스토리 전체 흐름 (컷신, 기록물)

### Phase 4 완료 기준
```
1구역부터 5구역까지 전체 플레이 가능
  → 50스테이지 + 보스 5개 완전 클리어 가능
  → 스토리 처음부터 엔딩까지 완결
  → 모든 스킬, 장비, 장신구 획득 가능
```

---

## Phase 5 — 폴리싱

> **목표**: 출시 품질 달성

### 5-1. 밸런싱
- [ ] 그림자 배율 곡선 (선형 vs 곡선) 확정
- [ ] 시간 자원 초기치/회복량
- [ ] 땅거미 이동 속도
- [ ] 적/보스 능력치 전체 조정
- [ ] 강화 포인트 분배 비율
- [ ] 소모품 최대 소지량
- [ ] 장비/장신구 수치

### 5-2. 아트 폴리싱
- [ ] 스프라이트 최종 리비전
- [ ] 배경 레이어 (패럴랙스)
- [ ] 파티클 이펙트 추가
- [ ] UI 최종 디자인

### 5-3. 사운드 완성
- [ ] 전 구역 BGM
- [ ] 보스전 BGM
- [ ] 환경음
- [ ] 효과음 보강

### 5-4. QA
- [ ] 전체 플레이스루 테스트 (3회 이상)
- [ ] 엣지 케이스 테스트 (자원 0, 경계 시간, 동시 이벤트)
- [ ] 성능 프로파일링
- [ ] 메모리 누수 점검

### 5-5. 접근성 / 편의
- [ ] 키 리바인드
- [ ] 컨트롤러 지원
- [ ] 해상도/창 모드 설정
- [ ] 세이브 슬롯 관리
- [ ] 튜토리얼/힌트 시스템

---

## Phase 6 — 출시

### 6-1. Steam 준비
- [ ] Steam 개발자 계정
- [ ] 스토어 페이지 (스크린샷, 트레일러, 설명)
- [ ] Steam 실적/업적 연동
- [ ] 클라우드 세이브

### 6-2. 빌드
- [ ] Windows EXE 빌드 + 테스트
- [ ] macOS 빌드 + 테스트
- [ ] Linux 빌드 + 테스트

### 6-3. 출시
- [ ] 얼리 액세스 or 정식 출시 결정
- [ ] 출시일 설정
- [ ] 출시

---

## 의존성 맵

```
Phase 1 (코어 프로토타입)
  │
  ├─ 1-1 플레이어 이동
  │       │
  │       ▼
  │   1-2 테스트 스테이지
  │       │
  │       ▼
  │   1-3 시간 시스템
  │       │
  │       ▼
  │   1-4 그림자 시스템 ──────┐
  │       │                   │
  │       ▼                   ▼
  │   1-5 적 (기본)       1-7 등불
  │       │
  │       ▼
  │   1-6 전투 (기본)
  │
  ▼
Phase 2 (시스템 확장)
  │
  ├─ 2-1 전투 확장 ─────── 2-6 성장 ─── 2-7 아이템
  ├─ 2-2 적 확장 ────────── 2-3 땅거미
  ├─ 2-4 스테이지 ────────── 2-8 거점
  └─ 2-5 환경 오브젝트
  │
  ▼
Phase 3 (1구역 버티컬 슬라이스)
  │
  ├─ 3-1 레벨 디자인 ──┬── 3-2 적 ── 3-3 보스
  │                     ├── 3-4 거점
  │                     └── 3-5 월드맵
  ├─ 3-6 UI
  ├─ 3-7 아트 (구현 완료 후)
  └─ 3-8 사운드
  │
  ▼
Phase 4 (전체 콘텐츠: 2~5구역 순차)
  │
  ▼
Phase 5 (폴리싱)
  │
  ▼
Phase 6 (출시)
```

---

## 아트 제작 타임라인

> 코드와 아트는 병행 진행. Art Spec Writer가 구현 완료 시 명세서를 생성하면, 사용자가 Aseprite에서 제작.

| 시점 | 아트 작업 |
|---|---|
| Phase 1 | 없음 (플레이스홀더) |
| Phase 2 | 플레이어 기본 스프라이트 시작 가능 |
| Phase 3 | 플레이어 완성 + 1구역 적/보스/타일/배경/UI/이펙트 |
| Phase 4-A | 2구역 아트 |
| Phase 4-B | 3구역 아트 |
| Phase 4-C | 4구역 아트 |
| Phase 4-D | 5구역 아트 |
| Phase 5 | 전체 리비전 + 파티클/이펙트 추가 |

---

## 구현 현황 요약 (최종 업데이트: 2026-04-12, Phase 2 진행 중)

| Phase | 마일스톤 | 상태 | 비고 |
|---|---|---|---|
| 0 | 기반 세팅 | ✅ 완료 | 문서 12개, 에이전트 7개, project.godot, EventBus |
| 1-1 | 플레이어 기본 이동 | ✅ 완료 | Composition 패턴 5개 컴포넌트, 예시 스프라이트로 동작 확인 |
| 1-2 | 테스트 스테이지 | ✅ 완료 | ColorRect 플레이스홀더, TileMap은 Phase 3 이관 |
| 1-3 | 시간 시스템 | ✅ 완료 | Composition 6개 컴포넌트, HUD, TimeConfigData |
| 1-4 | 그림자 시스템 | ✅ 완료 | ShadowSystem Autoload + Calculator + Caster, Curve 슬롯 |
| 1-5 | 적 시스템 (기본) | ✅ 완료 | 4종 적 + AI + 그림자 잔류 |
| 1-6 | 기본 전투 | ✅ 완료 | CombatSystem Autoload + 4타 콤보 + HP/사망/리스폰 + 전투 HUD |
| 1-7 | 등불 (기본) | ✅ 완료 | PlayerLantern 컴포넌트 + PointLight2D + 밤 per-object 그림자 + per-enemy 강도 |
| **2-4a** | **스테이지 시스템 기반** | **✅ 완료** | **StageSystem Autoload + StageData + 3단계 클리어 상태** |
| **2-4b** | **스테이지 전환** | **✅ 완료** | **StagePortal(윗방향키) + 페이드 전환 + Player 보존 + 적 유지 + 스테이지별 독립 시간** |

### Phase 2 세부 작업 순서

```
2-4a 스테이지 시스템 기반 ✅
  │
  ├── 2-4b 스테이지 전환 (인접 포탈, 씬 로딩) ✅
  │     │
  │     ├── 2-4c 잠금 프레임워크 + 빛 잠금
  │     ├── 2-4d 시간 전파 + 정화 프레임워크
  │     └── 2-4e 테스트 스테이지 2~3개 추가
  │           │
  │           ├── 2-8a 거점 씬 (회복, 세이브)
  │           │     │
  │           │     └── 2-8b 월드맵 포탈 + 월드맵 UI
  │           │
  │           └── 2-3a 잔류 부활 메카닉 (2-2 최소)
  │                 │
  │                 └── 2-3b 땅거미 엔티티 + 맵 이동 AI
  │                       │
  │                       └── 2-3c 땅거미 HUD 경고
  │
  합의된 결정:
  - 정화: 프레임워크만 (해금은 Phase 3)
  - 잠금: 프레임워크 + 빛 잠금만 (나머지 Phase 3)
  - 적 확장: 땅거미에 필요한 최소 범위(잔류 부활)만
```

### 프로젝트 설정 변경 이력
- **스트레치 모드**: `viewport` → `canvas_items` (Phase 1-3에서 변경. UI 텍스트 선명도 확보, 스프라이트는 snap_2d로 픽셀 유지)
- **밤 색조**: `(0.15, 0.1, 0.25)` → `(0.4, 0.35, 0.55)` (캐릭터 식별 가능한 수준으로 조정)
- **기준 사이즈 변경** (Phase 1-4): 타일 32x32→64x64, 해상도 384x216→640x360, 스케일 5배→3배, 중력 980→1960. 플레이어 스탯 화면비 보정 적용. 기존 스프라이트시트(64x64)는 미교체 — 128x128 아트 제작 시 Player.tscn 갱신 필요.
- **카메라 제한**: TestStage에 Camera2D limit 설정 추가 (스테이지 범위 내로 제한)

---

## 미결 사항 (개발 계획 관련)

- [ ] 각 Phase의 예상 소요 기간은 산정하지 않음 (프로토타입 진행 속도 보고 판단)
- [ ] 얼리 액세스 여부 (Phase 3 완료 후 판단 가능)
- [ ] 외부 피드백 수집 시점 (Phase 3 데모 빌드 유력)
- [ ] 사운드/음악 제작 방식 (직접 제작? 외주? 에셋 구매?)
- [x] Phase 1-1 구현에 대한 Code Reviewer / QA 에이전트 실행 → max_air_jumps 하드코딩 수정 완료
- [x] Phase 1-3 구현에 대한 Code Reviewer / QA 에이전트 실행 → resource_changed 시그널 연결 등 3건 수정 완료
- [x] Phase 2 진입 시 base_enemy.gd set_deferred 버그 수정 (monitoring/monitorable 시그널 중 직접 변경 → set_deferred)
