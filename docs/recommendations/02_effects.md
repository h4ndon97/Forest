# 연출 / 이펙트 추천

> **STATUS**: 본 문서 모든 항목 PROPOSED. 결정 아님.
> **카테고리 코드**: FX
> **연결 문서**: docs/EFFECTS.md (Pass 5 Step 1~7과 통합 가능)

---

## REC-FX-001 — 시간 정지 셔터 (발동 freeze frame)

- **상태**: **IMPLEMENTED** (2026-04-26)
- **우선순위**: ★★★
- **노력**: S
- **레퍼런스**: Ori — 충격 후 잔상
- **관련 시스템**: EffectsSystem, OverlaySystem, time_stop_sepia 셰이더
- **검증**:
  - `assets/shaders/effects/time_stop_sepia.gdshader` — 새 uniform `chromatic_strength` (RGB 채널 좌우 분리 sampling)
  - `src/systems/effects/effects_time_stop_shutter.gd` 신설 — `EventBus.time_flow_stopped` 구독 → 색수차 0→max→0 보간 + 화면 플래시
  - `src/systems/effects/effects_system.gd` — `_time_stop_shutter` 인스턴스 추가 (TimeStop 옆)
  - `data/effects/effects_config_data.gd` — `shutter_*` 4 파라미터 추가 (duration/chromatic_max/flash_color/flash_alpha)
  - gdlint 통과 + Godot 헤드리스 로드 통과
- **결정 이력**: 별도 EffectTimeline `.tres` 신설 대신 **기존 sepia 셰이더에 chromatic uniform 추가** + 별도 헬퍼가 짧은 시퀀스 관리. 둘 다 같은 PostProcess ColorRect의 다른 uniform이라 충돌 없음.

### 구현 컨셉
시간 정지 발동 순간 (EventBus.time_flow_stopped):
- 0.00~0.075s: 색수차 0 → 0.020 (UV 단위, ≈ ±13px @640)
- 0.075~0.15s: 색수차 0.020 → 0
- 동시에 화면 플래시 (흰색, alpha 0.35, 0.15초)
- 이후: 기존 EffectsTimeStop 세피아/잔상/블루펄스가 계속 진행 (인계 자연스러움)

### 시너지
- REC-FX-004 (그림자 떨림 셰이더): 셔터 0.15초 동안 그림자 sprite도 떨림 시작 — "정지 발동 = 빛은 멈췄지만 그림자는 살아있다" 코어 표현 자연 통합

---

## REC-FX-002 — 추격 시퀀스 (땅거미 깨어남)

- **상태**: PROPOSED
- **우선순위**: ★★★
- **노력**: L
- **레퍼런스**: Ori WotW — Shriek/Sandworm 추격 시퀀스
- **관련 시스템**: DuskSpiderSystem, StageSystem, 카메라
- **의존**: ~~카메라 정책 결정 (REC-RISK-004)~~ — **2026-04-26 해소**: follow 시스템 이미 구현됨
- **무효화 조건**: —
- **결정 이력**: 2026-04-26 — REC-RISK-004 RESOLVED. `StageData.room_size`를 큰 값(예: 1920×360 또는 2560×360)으로 설정한 추격 전용 룸을 만들어 follow + 강제 스크롤 시퀀스 구현 가능. 작업 자체의 노력은 유지(L) — 추격 룸 디자인 + 음악 + 체크포인트 시스템.

### 컨셉
1구역당 1회, 또는 핵심 스토리 비트마다. **시간 정지가 "원인"이고 추격이 "결과"**. 좌→우 강제 스크롤 + 시간 정지 봉인 + 음악 인텐스. 카메라 정책(현재 한 화면) 변주 명분도 됨.

### 레퍼런스 분석
Ori WotW Shriek 시퀀스:
- 강제 스크롤 + 즉사 가능
- 체크포인트 빈번 (3~5초마다)
- 음악 + 사운드 + 시각 통합 정점

### 이 프로젝트 적용
- 트리거: 보스 처치 직후 또는 핵심 환경 오브젝트 활성화 직후
- 시간 정지 봉인 (REC-MECH-008과 같은 메커니즘)
- 땅거미 본체가 화면 좌측에서 추적
- 즉사 패널티 대신 hp 5 데미지 + 짧은 노크백
- 추격 룸: `room_size = Vector2(1920~2560, 360)` 정도의 긴 룸 (follow 카메라가 자동 작동)

### 구현 메모
- StageSystem에 새 stage_type `CHASE_SEQUENCE` 추가
- 추격 전용 .tres에 큰 `room_size` 설정 → 기존 follow 시스템이 자동 처리
- 시퀀스 길이 30~45초 (룸 길이로 결정)
- 음악 동적 전환 (REC-SND-001)
- 체크포인트 빈번 (Ori 패턴): 룸 안에 5초마다 1개 (4~5개)

---

## REC-FX-003 — 발광 잔류 (빛 피니시 빛줄기)

- **상태**: **IMPLEMENTED** (2026-04-26)
- **우선순위**: ★★
- **노력**: S
- **레퍼런스**: Ori — 빛 잎사귀 잔류, Light Fairytale
- **관련 시스템**: EffectsSystem, DamageResolver, EffectTimeline
- **검증**:
  - `src/systems/effects/effects_residual_light.gd` 신설 — `EffectsResidualLight.spawn(world_pos, attribute, duration)` 헬퍼
  - `src/systems/effects/effects_system.gd` 신 공개 API: `spawn_residual_light(world_pos, attribute, duration)`
  - `src/systems/combat/damage_resolver.gd:_apply_effects` — `spec.is_finish && spec.attribute=="light"` 시 후속 호출 hook
  - `data/effects/effects_config_data.gd` — `residual_light_*` 6개 파라미터 추가 (duration/halo/core 반경·알파/end_scale)
  - gdlint 통과 + Godot 헤드리스 로드 테스트 통과
- **결정 이력**: EffectTimeline의 단발 cue(0~0.12s) 모델에 1~2초 지속 효과가 안 맞아 **후속 거동으로 분리**. EffectsSystem에 별도 함수 + DamageResolver에서 빛 피니시 시 직접 호출.

### 구현 컨셉
빛 피니시 후 적 위치에 1.2초 발광 잔류:
- **halo**: 22px 반경, finish_color, alpha 0.45 시작 → 0
- **core**: 10px 반경, finish_color에 흰색 50% 가산, alpha 0.85 시작 → 0
- 동시에 scale 1.0 → 1.30 살짝 퍼짐
- 끝나면 자동 queue_free

### 시각 구조 (발광 3레이어 규약)
- **base 생략** — 적 sprite 자체가 base 역할
- **core**: 내부 밝기 (Polygon2D 24-segment)
- **halo**: 외곽 페이드 (Polygon2D 24-segment)

### 미래 확장 후보
- 연쇄 처치 시 잔류끼리 시각적 연결선
- shadow 피니시는 다른 잔류(어둠 점적) 등 — 현재는 light만 hook

---

## REC-FX-004 — 정적인 화면, 살아있는 그림자 셰이더

- **상태**: **IMPLEMENTED** (2026-04-26)
- **우선순위**: ★★★
- **노력**: S
- **레퍼런스**: Don't Starve — 광기 시각 효과
- **관련 시스템**: ShadowCaster, ShadowSystem, EventBus(time_flow_*)
- **검증**:
  - `assets/shaders/effects/shadow_jitter.gdshader` 신설 — vertex 셰이더 sin/cos 기반 동일 offset (sprite 전체 ±1~2px 이동, vertex 별 왜곡 없음)
  - `src/systems/shadow/shadow_caster.gd` — JITTER_SHADER preload + `enable_jitter` 노출 + ShaderMaterial 부착 + 시간 정지 시그널 구독 + 그림자 강도 → 진폭 매핑
  - `seed = (instance_id % 1000) * 0.01` — 인스턴스별 위상 차이로 일제 떨림 방지
  - 기존 그림자 sprite와 fallback ColorRect 둘 다 지원
  - gdlint 통과 + Godot 헤드리스 로드 통과
- **결정 이력**: 별도 헬퍼 클래스 대신 **ShadowCaster 자체가 자기 책임**. 각 그림자 인스턴스가 자기 sprite/ColorRect에 직접 셰이더 부착 + 시간 정지 시그널 구독. 환경 오브젝트 등 떨림 부적절한 곳은 `enable_jitter=false`로 OFF.

### 구현 컨셉
- 시간 정지 진입 시 (`time_flow_stopped`) → ShaderMaterial uniform `active=1.0`
- 시간 흐름 재개 시 (`time_flow_started`) → `active=0.0`
- 진폭 = 그림자 강도(ShadowSystem.get_intensity_multiplier)에 따라 0.6~1.4 픽셀 선형 매핑
- vertex 셰이더 sin/cos 기반 (TIME 의존) → 자연스러운 떨림, 인스턴스별 seed로 위상 분산

### 시너지
- REC-FX-001 (시간 정지 셔터) — 발동 순간 동시 발동, 0.15초 셔터 + 그림자 떨림 시작
- REC-MECH-002 (광기) — 향후 광기 단계 높을수록 진폭 증폭 가능 (intensity uniform 확장)
- REC-FX-007 (가장자리 비네트) — 화면 전체 톤 통합 (어두운 비네트 + 떨리는 그림자)

---

## REC-FX-005 — 보스룸 슬로우 패닝 도입부

- **상태**: PROPOSED
- **우선순위**: ★★
- **노력**: S
- **레퍼런스**: Death's Door — 보스룸 진입, Hollow Knight — Mantis Lords 입장
- **관련 시스템**: BossSystem, 카메라
- **의존**: —
- **무효화 조건**: 보스마다 컷신(REC-FX-006)이 들어가면 중복

### 컨셉
보스룸 진입 시 0.8초 카메라 후진 + 보스 등장 픽셀아트 컷. **한 화면 카메라 정책에서도 가능**. EFFECTS.md Pass 5와 호환.

### 구현 메모
- BossSystem의 진입 hook에 카메라 patrol 시퀀스 추가
- 음악은 보스룸 진입 직전부터 페이드인 (REC-SND-003)
- 보스 외형 그림자가 먼저 나타나고 본체가 그 후 등장 (테마 일치)

---

## REC-FX-006 — 컷신 (정지 일러스트 + 텍스트박스)

- **상태**: **IMPLEMENTED (인프라)** (2026-04-26)
- **우선순위**: ★★★
- **노력**: S 인프라 / M 협업 (일러스트 5~10장 아트)
- **레퍼런스**: Blasphemous — 정적 일러스트 컷, Skul — 픽셀아트 인서트
- **관련 시스템**: OverlaySystem, EventBus, UI cutscene
- **의존**: 아트 작업 (정지 일러스트 5~10장 — placeholder fallback으로 코드는 즉시 작동)
- **무효화 조건**: 풀 애니 컷신 도입 결정 시
- **검증**:
  - `data/cutscenes/cutscene_data.gd` + `cutscene_panel_data.gd` 신설 — 시퀀스 + 1장 패널 Resource 분리
  - `src/ui/cutscene/cutscene_panel.gd` 신설 (~270줄) — CanvasLayer(layer=99), 일러스트 페이드 + RichTextLabel typewriter(32 cps) + 화자 라벨 + 패널 간 fade out→in 자연 전환 + ESC 스킵 + 플레이어 입력 잠금
  - `src/systems/overlay/overlay_system.gd` 공개 API `play_cutscene(data)` 추가 — 1회용 인스턴스 생성/추가/start, 활성 중 재호출 무시
  - `src/systems/event_bus/event_bus.gd` `cutscene_started/finished(cutscene_id)` 시그널 신설 (dialogue 신호와 분리)
  - `data/cutscenes/throne_echo_intro.tres` placeholder 시연 컷신 — 3패널 시조 풍 텍스트 + 보라/검정 톤 ColorRect fallback
  - `src/world/stages/stage_3_b.gd` 트리거 hook 정비 — BossArenaTrigger 진입 시 컷신 재생 → `cutscene_finished` 수신 후 `_activate_boss()` 호출 (보스가 컷신 중 움직이지 않도록)
  - `docs/art_specs/cutscene_panel.md` 신설 — 320×180 캔버스 + 수묵화 톤 + 3레이어 규약 적용 가이드 (광원 등장 시) + 1차 우선순위 5장 명세
  - gdlint 통과 + Godot 헤드리스 로드 통과 (parse error 0, OverlaySystem/CutscenePanel/CutsceneData 정상 등록)
- **결정 이력**:
  - 책임 분배: 별도 StorySystem Autoload 신설 대신 **OverlaySystem 산하**. cinematic bars/dissolve가 이미 OverlaySystem에 있고, 컷신은 1회용 패널이라 Autoload 부담 불필요
  - 렌더 순서: CutscenePanel layer=99 < OverlaySystem layer=100 → 시네마틱 바가 자연스럽게 위에 그려짐
  - 신호 분리: dialogue_started/finished와 cutscene_started/finished 분리 — 음악/카메라/플레이어 hook 시점이 다르고, NPC 대화창과 컷신은 무게/사용처가 명확히 구분됨
  - placeholder fallback: 일러스트 미존재 시 `placeholder_tint` 색의 ColorRect 표시 → 메모리 [feedback_art_ready_code] 정책 부합. 작가가 PNG 넣으면 코드 수정 없이 즉시 반영
  - 첫 시연 위치: zone3 보스 ThroneEcho 등장 — 보스 활성을 컷신 종료 hook으로 분리 (`cutscene_finished` 수신 시 `_activate_boss()`). 이 패턴이 향후 다른 보스/스토리 비트 hook의 표준이 됨

### 컨셉
풀 애니 컷신은 1인 개발 부담. **정지 일러스트 + 텍스트박스 + 음악 변화**로 충분. 빛/그림자 왕가 봉인 회상에 적합. 한국 인디 어필 포인트.

### 레퍼런스 분석
Blasphemous: 정적 일러스트 + 풀보이스 X + 분위기 음악 → 비용 대비 임팩트 매우 좋음

### 이 프로젝트 적용
- 핵심 스토리 비트 5개에 한 컷씩
  - 게임 시작: 봉인 의식 회상
  - 1보스 처치: 첫 봉인 균열
  - 3보스 처치: 그림자 왕가 정체 드러남
  - 4보스 처치: 선조 거래 진실
  - 최종 보스 직전: 두 왕가 결합 직전
- 일러스트는 게임 픽셀아트와 다른 톤(수묵화 풍, REC-MKT-002)으로 차별화

### 구현 메모 (실제 구현 반영, 2026-04-26)
- ~~StorySystem에 새 cutscene_player 노드~~ → OverlaySystem 산하로 결정 (별도 Autoload 회피)
- 일러스트 TextureRect + RichTextLabel typewriter(visible_ratio Tween, 32 cps)
- 패널 간 fade out → 일러스트 교체 → fade in 자연 연결
- ESC 스킵, F 진행, 자동 진행은 `auto_advance_hold > 0` 시
- 음악 변화 hook: `EventBus.cutscene_started(cutscene_id)` 구독자가 처리 (현 단계 미구독, AudioSystem 신설 시 연결)

### 후속 작업
- 일러스트 5장 작가 협업 (REC-FX-006 본문 1차 우선순위 표 참조)
- AudioSystem 신설 시 `cutscene_started` 수신 → BGM duck/페이드 hook
- `pause_time_during=true` 컷신 시 TimeSystem 일시정지 hook (현 단계 placeholder, 첫 시연은 false)
- 3레이어 규약 적용 일러스트 도입 시 `CutscenePanelData`에 `core_path/halo_path` 필드 + cutscene_panel.gd에 컴포지트 노드 추가

---

## REC-FX-007 — 화면 가장자리 비네트 (그림자 강도)

- **상태**: **IMPLEMENTED** (2026-04-26)
- **우선순위**: ★★
- **노력**: S
- **레퍼런스**: Don't Starve — 광기 비네트
- **관련 시스템**: ShadowSystem, OverlaySystem, EventBus
- **검증**:
  - `src/systems/effects/effects_shadow_vignette.gd` 신설 — `EventBus.shadow_params_changed` + `EventBus.dusk_spider_approached` 이중 구독
  - `src/systems/effects/effects_system.gd` — `_shadow_vignette` 인스턴스 추가 (DuskWarning 옆)
  - `data/effects/effects_config_data.gd` — `shadow_vignette_*` 4개 파라미터 추가 (color/threshold/alpha_max/transition_duration)
  - gdlint 통과 + Godot 헤드리스 로드 테스트 통과
- **결정 이력**: 비네트 슬롯이 `EffectsDuskWarning`(보라/빨강) 점유 중인 충돌 발견 → **우선순위 합산 라우터** 채택. DuskWarning 활성(거리 0~2) 시 ShadowVignette는 손 떼고, 비활성으로 전환 시 자기 색 재발화.

### 구현 컨셉
- 그림자 강도 < threshold(0.5) → 비네트 OFF
- threshold ≤ 강도 ≤ 1.5 → 선형 매핑으로 알파 0~0.35
- 색은 어두운 보라/검정 (`Color(0.05, 0.0, 0.10, 1.0)`) — 그림자 왕가 팔레트 톤
- 변화는 0.30s Tween (자연스러운 전이)

### 우선순위 정책
| DuskWarning 거리 | ShadowVignette 동작 |
|---|---|
| -1 (비활성) | 자기 색 set (그림자 강도 기반) |
| 0~2 (활성) | 손 뗌 — DuskWarning이 비네트 점유 |
| 활성 → 비활성 전환 | 즉시 자기 색 재발화 |

### 시너지
- REC-MECH-002 (그림자 광기 페널티)와 자연 통합 가능 — 광기 단계 높을수록 비네트 강조
- REC-FX-004 (그림자 떨림 셰이더)와 톤 통합 — 화면 전체 어둠 + 그림자 떨림

### 컨셉
작은 HUD 숫자 대신 **화면 가장자리 어둠**으로 그림자 강도 직관 표시. UI 이중 축 정책(플레이어 HUD = 빛/그림자 우선)과 부합.

### 구현 메모
- OverlaySystem에 vignette 셰이더 1장
- 강도 = 현 그림자 평균 강도 (또는 최대 강도)
- 광기 단계(REC-MECH-002)와 연동하여 색조 변화
- 정지 중 = 푸르스름, 광기 중 = 보라색

### 시너지
- REC-FX-004 (그림자 떨림) — 가장자리 비네트가 어두울 때 그림자 떨림 강조
- REC-MECH-002 (광기) — 비네트가 광기 단계 시각화 채널 역할

---

## 카테고리 메모

- 7개 중 5개가 노력 S — Pass 5 Step 1~7 작업 시 한 번에 통합 가능
- REC-FX-002 (추격)은 단독 큰 작업, 카메라 정책 결정에 의존
- REC-FX-006 (컷신)은 일러스트 의존 — 아트 일정에 종속
- 셰이더 작업이 많음 → godot-shaders-fx skill 활용 + EffectsSystem template 활용
