# UI 구현 작업 계획 — A·B 카테고리

> **문서 성격**: 구현 매핑 가이드. 설계 명세가 아님.
> **설계 근거**: [`docs/art_specs/ui_design_master.md`](art_specs/ui_design_master.md) (v0.18+)
> **에셋 번호**: [`docs/art_specs/ART_RESOURCE_LIST.md`](art_specs/ART_RESOURCE_LIST.md) #111~117 (B 카테고리)
> **작업 시작**: Phase 3-3 병렬 진행 (세션 단위 트랙 분리)
> **마지막 갱신**: 2026-04-18

---

## 0. 이 문서의 목적

기존 설계 문서는 **무엇을 만들지**를 규정한다. 이 문서는 **어느 파일을 어떤 순서로 바꿀지**를 규정한다.

- 설계 변경이 생기면 이 문서 아님 — `ui_design_master.md`에 선행 반영 후 여기 동기화
- 각 작업 단위는 **독립 커밋 가능**한 크기로 쪼갬
- Pass 단위 실행 → 중간 중간 인게임 검증 → 체감 문제 있으면 `ui_design_master.md` 개정으로 환류

---

## 1. 현재 HUD 코드 맵

`src/ui/hud/`에 5개 HUD CanvasLayer 존재. 각각 독립 `.tscn`/`.gd` 페어.

| 파일 | 역할 | 현재 배치 | 현재 형태 | A/B 설계 매핑 |
|---|---|---|---|---|
| [combat_hud.gd](../src/ui/hud/combat_hud.gd) + [CombatHud.tscn](../src/ui/hud/CombatHud.tscn) | HP 바 + 콤보 + 사망 오버레이 | 좌하단(preset 2) | ProgressBar + ColorRect×4 | **A-5 좌상단 이동** / HP pip 5개 / 콤보 오브+도트 / A-6 |
| [time_hud.gd](../src/ui/hud/time_hud.gd) + [TimeHud.tscn](../src/ui/hud/TimeHud.tscn) | 시계/상태/자원 | 좌상단(preset 0, offset 4,4) | VBoxContainer > ClockLabel + StateLabel + ResourceGauge + ResourceLabel (4 children) | **B-5 궤도 시계 + B-6 일식 링 + B-7 배지**로 전면 재작성 (우상단 이동) |
| [skill_hud.gd](../src/ui/hud/skill_hud.gd) + [SkillHud.tscn](../src/ui/hud/SkillHud.tscn) | 스킬 슬롯 4개 | 우하단(preset 3) | ColorRect 20×20 HBox | **A-7 원형 32×32 + 완만한 오름 호** / 쿨다운 원형 sweep |
| [consumable_hud.gd](../src/ui/hud/consumable_hud.gd) + [ConsumableHud.tscn](../src/ui/hud/ConsumableHud.tscn) | 포션 슬롯 2개 | 좌하단(preset 2) | ColorRect 20×20 HBox | **A-8 각진 병 24×32** 좌표 (16,312)/(48,312) |
| [dusk_spider_hud.gd](../src/ui/hud/dusk_spider_hud.gd) + [DuskSpiderHud.tscn](../src/ui/hud/DuskSpiderHud.tscn) | 땅거미 경고 | 우상단 | HBox + 아이콘 + 거리 Label | **B-5/B-6 추가로 좌측 밀림 필요 — C 카테고리 진입 시 재확정** |

**기준 해상도**: 640×360 (project.godot). 모든 좌표는 이 기준.

---

## 2. Pass 구조

3 Pass로 분할. 각 Pass 내부는 독립 커밋 가능 단위로 쪼갬.

| Pass | 목표 | 의존 | 예상 세션 |
|---|---|---|---|
| **Pass 1 — 기반 프레임워크** | 좌표 이동 + 구조 치환. 시각은 placeholder 도형/색 | 없음 | 2~3 |
| **Pass 2 — 시각 디테일** | Shader / 애니메이션 / 세부 상태 | Pass 1 완료 | 2~3 |
| **Pass 3 — 아트 드롭-인** | 실제 픽셀 에셋(#111~117) 교체 | Phase 3-7 아트 제작 후 | 1 |

---

## 3. Pass 1 — 기반 프레임워크 (placeholder 유지)

**원칙**: **아트 의존성 0**. `Polygon2D`, `ColorRect`, `Control._draw()`, shader 없이 GDScript 도형만으로 구성. 시각 품질은 조잡해도 OK — 구조와 좌표 검증이 목적.

### 1.1. A-5 HUD 레이아웃 — combat_hud 좌상단 이동

**파일**: [CombatHud.tscn](../src/ui/hud/CombatHud.tscn), [combat_hud.gd](../src/ui/hud/combat_hud.gd)
**설계 근거**: `ui_design_master.md` §A-5 (4분면 배치 + 좌상단 클러스터)

**변경 내용**:
- `MarginContainer` anchors_preset: 2 (bottom-left) → **0 (top-left)**
- offset 조정: 시작점 (16, 16)
- VBoxContainer 제거 → HBoxContainer로 재구성 (좌상단 클러스터 순서: 오브 → 도트 4개 → HP pip 5개 → 상태이상 배지 자리 placeholder)
- 기존 `HpBar` ProgressBar → **5개 pip으로 분리** (HP 20당 1 pip, 각 16×16)
  - placeholder: `ColorRect` 16×16 × 5 (금색 `#F2CC66`, 빈 상태는 dim)
  - HP 구간별 채움 로직: pip 0~4번 각 20HP 단위
- 기존 콤보 ColorRect 4개 유지 → 색만 `#4A4A50`(빈) / 속성 색(채움)으로 조정
  - **Combo4 크기 통일**: 현재 12×8 (기존 4타 피니시 강조용) → **8×8로 통일** (A-6 설계: 도트 4개 동일 크기, 피니시 강조는 별도 속성 오브가 담당)
- **속성 오브 24×24 placeholder**: `ColorRect` 24×24, `_combo_finished(attribute)` 시 색 변경

**완료 기준**:
- [ ] 인게임에서 HP/콤보가 좌상단 (16,16) 기준 클러스터로 표시됨
- [ ] HP 감소 시 pip이 오른쪽부터 dim (혹은 왼쪽부터 — 설계 명시 없음, 기본은 **오른쪽부터 비우기**로 가정)
- [ ] 콤보 4타 피니시 시 속성 오브 색이 속성에 따라 변경 (`light`/`shadow`/`hybrid`/`neutral`)

**주의**: 상태이상 배지(A-9)는 이 Pass에서 **자리 확보만** (빈 공간 16×16×4개분, 내용 없음).

---

### 1.2. A-7 스킬 슬롯 — 완만한 오름 호 좌표 적용

**파일**: [skill_hud.gd](../src/ui/hud/skill_hud.gd) (프로그래매틱 `_build_ui()`)
**설계 근거**: `ui_design_master.md` §A-5 (스킬 슬롯 배치 — 완만한 오름 호)

**변경 내용**:
- `SLOT_SIZE`: 20 → **32**
- `MarginContainer` → 개별 Control 절대 배치로 전환 (HBox 해제)
- 4개 슬롯 좌표 명시:
  ```
  Q: (442, 330), W: (480, 325), E: (518, 319), R: (556, 312)
  ```
- 각 슬롯 placeholder: `ColorRect` 32×32 (임시 사각형 — Pass 2에서 원형 shader로 전환)
- 쿨다운 오버레이 기존 로직 유지 (높이 비례 sweep)

**완료 기준**:
- [ ] 4개 슬롯이 **우하단 완만한 오름 호**로 배치됨
- [ ] 기존 쿨다운/장착/플래시 로직 그대로 동작
- [ ] 키 레이블(U/I/O/P 또는 Q/W/E/R — 현재 InputMap 확인) 각 슬롯 하단

**주의**: 현재 `KEY_LABELS := ["U", "I", "O", "P"]` — 설계는 Q/W/E/R 기준. InputMap 확인 후 일치시킬 것. 불일치 시 설계 문서 또는 InputMap 중 하나 조정 필요 (feedback_keymap_remap_later 참조 — Phase 2 이후 일괄 조정 예정이므로 **현 시점 레이블은 건드리지 않음**, 주석으로 TODO만 남김).

---

### 1.3. A-8 포션 슬롯 — 각진 병 좌표 적용

**파일**: [consumable_hud.gd](../src/ui/hud/consumable_hud.gd)
**설계 근거**: `ui_design_master.md` §A-5 (소모품 병 배치)

**변경 내용**:
- `SLOT_SIZE` → 24×32 (비대칭 크기, Vector2로 교체)
- 배치 좌표:
  ```
  HP 병: (16, 312)
  Time 병: (48, 312)
  ```
- `MarginContainer` → 개별 Control 절대 배치
- placeholder 형태: `ColorRect` 24×32 (색은 HP=금 `#F2CC66` / Time=보라 `#8B2FC6`)
- 수량 숫자: 우측 상단 (x+16, y-4), 기존 Label 유지

**완료 기준**:
- [ ] 2개 병이 좌하단 지정 좌표에 표시됨
- [ ] 스킬 슬롯 R(y=312)과 하단 기준선 일치 확인

---

### 1.4. B-5/B-6/B-7 — 시간 코어 전면 재작성

**파일**: [time_hud.gd](../src/ui/hud/time_hud.gd), [TimeHud.tscn](../src/ui/hud/TimeHud.tscn)
**설계 근거**: `ui_design_master.md` §B-5, §B-6, §B-7

**현재 구조 (검증 완료)**:
- `TimeHud (CanvasLayer, layer=10)` > `MarginContainer (preset 0, offset 4,4)` > `VBoxContainer` > 4 children:
  - `ClockLabel` (Label, font_size=10, text="12:00")
  - `StateLabel` (Label, font_size=6, text="STOP")
  - `ResourceGauge` (ProgressBar, 80×8, max=100)
  - `ResourceLabel` (Label, font_size=6, text="100 / 100")

**변경 내용**:
- 기존 Label×2 + ProgressBar + ResourceLabel (4개 자식) **전면 제거**
- 신규 Control 구조:
  ```
  TimeHud (CanvasLayer)
    └ TimeCore (Node2D, position=(608, 32))
       ├ EclipseRing (Control, B-6)
       ├ ClockRing (Control, B-5) — 안쪽 32×32
       │  ├ Sun (Sprite2D or Polygon2D)
       │  └ Moon (Sprite2D or Polygon2D)
       └ PropagationBadge (Control, B-7) — position=(0, 30) 상대
  ```
- **Pass 1에서는 도형만**:
  - EclipseRing: `Control._draw()` 오버라이드로 `draw_arc()` 사용 (3px, 자원 비례 각도)
  - ClockRing: `draw_arc()` (2px, 상태별 색 modulate)
  - Sun/Moon: `Polygon2D` 또는 `ColorRect` 8×8 (위치는 코드에서 각도 계산)
  - Badge: `Polygon2D`로 도트 5상태 그리기
- EventBus 연결 유지:
  - `current_hour_changed` → 해·달 위치 각도 계산
  - `time_state_changed` → 궤도 회전 속도 변경
  - `time_resource_changed` → EclipseRing arc 각도 업데이트
- **전파 시그널 (해결 완료 — 2026-04-18, 안 (a) 채택)**:
  - ✓ `flow_rate_changed(rate: float)` — 현재 스테이지 rate 전달 (배지 도트 개수 결정)
  - ✓ `propagation_origin_changed(is_origin: bool)` **신규 추가** — 원점 여부 변경 시 발행
  - 발행 지점: `_emit_player_rate()` / `_on_flow_stopped()` / `notify_stage_entered()` 전파 비대상 분기
  - 중복 발행 방지: `_is_current_origin` 플래그로 상태 변경 시에만 emit

**완료 기준**:
- [ ] 해와 달이 궤도를 돌면서 현재 시각 반영
- [ ] 시간 상태 변경 시 궤도 회전 속도/색 변화 (FLOWING 정상 / STOPPED 정지 / MANIPULATING 역회전)
- [ ] 자원 감소 시 외곽 링이 시계방향으로 그림자 잠식
- [ ] 자원 20% 이하 시 붉은 맥동 (modulate tween)
- [ ] 배지: 원점 금 도트 1개 / 전파 보라 도트 2~4개 / flow 없음 시 숨김

**주의**:
- TimeHud.tscn 구조 검증 완료 (위 "현재 구조" 참조) — **덮어쓰기 방향 확정**
- **전파 시그널 3안 사용자 결정 선행** 필요 (위 전파 시그널 갭 섹션)

---

### 1.5. Pass 1 커밋 단위 (권장 분리)

1. `ui(A-5): combat_hud 좌상단 이동 + HP pip 5개 분리 + 콤보 오브 placeholder`
2. `ui(A-7): skill_hud 완만한 오름 호 좌표 적용 (32×32)`
3. `ui(A-8): consumable_hud 각진 병 좌표 적용 (24×32)`
4. `ui(B): time_hud 시간 코어 전면 재작성 (draw_arc placeholder)`

각 커밋은 인게임 검증 후 독립 커밋. 체감 문제 발생 시 **커밋 전에 사용자에게 보고 → 설계 개정 후 재시도**.

---

## 4. Pass 2 — 시각 디테일

**원칙**: Pass 1 placeholder를 아트 퀄리티에 근접하게 개선. 여전히 아트 에셋 없이 **셰이더 + 도형 + 애니메이션**으로.

### 2.1. B-6 일식 링 shader

- 아크 마스크 shader 1종 신규 작성 (`res://assets/shaders/arc_mask.gdshader`)
- 입력: `fill_percent (0~1)`, `direction (cw/ccw)`, `thickness (px)`
- 출력: 40×40 링에서 해당 각도만 남기고 마스킹
- STOPPED 시 50% dim: `modulate.a = 0.5` 간단 적용

### 2.2. A-7 스킬 슬롯 원형

- `draw_circle()` + `draw_arc()`로 원형 2px 링
- 쿨다운 원형 시계 sweep: `draw_arc()`로 완성 각도 → 현재 각도 방향 전환

### 2.3. A-10 호흡 애니메이션

- HP pip modulate ±5% 0.8초 주기 sine 펄스 (STOPPED 시)
- 자원 링 동일 리듬 (FLOWING 시)
- 저체력/저자원 20% 이하 시 붉은 펄스 덮어쓰기

### 2.4. 반딧불 파티클 (회복 시)

- `GPUParticles2D` 또는 `CPUParticles2D` 노드로 HP/자원 회복 시 반딧불 스폰
- 기존 에셋 없으면 Pass 3에 이월 가능 — `FX_firefly_orb.png` 여부 확인

### 2.5. Pass 2 커밋 단위

1. `ui(B-6): 일식 링 arc_mask shader 적용`
2. `ui(A-7): 스킬 슬롯 원형 렌더링 + 쿨다운 원형 sweep`
3. `ui(A-10): 호흡/저체력 펄스 애니메이션`
4. `ui(A-10): 회복 시 반딧불 파티클` (에셋 있을 때만)

---

## 5. Pass 3 — 아트 드롭-인

Phase 3-7에서 사용자가 실제 픽셀 에셋 제작 후 진행. 현재 단계에서는 준비만.

- 각 HUD 스크립트에 `_try_load_texture(path)` 헬퍼 추가 → 파일 있으면 Sprite2D로 대체, 없으면 Pass 1/2 fallback 유지
- 에셋 경로는 `ART_RESOURCE_LIST.md` #111~117 그대로

---

## 6. Placeholder 전략 요약

| 요소 | Pass 1 (도형) | Pass 2 (shader/애니) | Pass 3 (아트) |
|---|---|---|---|
| HP pip | ColorRect 16×16 | + 호흡 펄스 | Sprite2D `hud_hp_pip.png` (신규) |
| 콤보 오브 | ColorRect 24×24 | + 속성 색 전이 | Sprite2D `hud_combo_orb.png` (신규 필요) |
| 콤보 도트 | ColorRect 8×8 | 유지 | 유지 |
| 스킬 슬롯 | ColorRect 32×32 | draw_circle + 쿨다운 arc | Sprite2D 스킬 아이콘 #87~90 |
| 포션 병 | ColorRect 24×32 | + 액체 출렁임 | Sprite2D `hud_potion_hp/time.png` (신규 필요) |
| 궤도 링 (B-5) | draw_arc 2px | + 상태 색 modulate | Sprite2D #111 |
| 해·달 (B-5) | ColorRect 8×8 | + 발광 modulate | Sprite2D #112/#113 |
| 일식 링 (B-6) | draw_arc 3px | + arc_mask shader | Sprite2D #114~116 |
| 전파 배지 (B-7) | Polygon2D 도트 | + 교차 페이드 | Sprite2D #117 |

**신규 필요 에셋** (ART_RESOURCE_LIST 미등록 — 추후 추가 필요):
- `hud_combo_orb.png` (A-6 속성 오브 4종)
- `hud_hp_pip.png` (A-5 횃불 불씨 5단계)
- `hud_potion_hp.png` / `hud_potion_time.png` (A-8 각진 병 2종)

→ **Pass 1 종료 시 ART_RESOURCE_LIST에 일괄 추가 작업** 필요 (현재 TODO로 기록).

---

## 7. 위험 / 의존 / 유의사항

### 7.1. Phase 3-3 보스와의 접점

- **파일 충돌 없음** (`src/ui/hud/` vs `src/entities/bosses/`)
- **보스 HP bar 설계 공백**: 3-3 구현 시 placeholder 유지 → C 카테고리에서 보스 HP 설계 추가
- **세션 단위 트랙 분리** 필수 (맥락 혼선 방지)

### 7.2. 땅거미 HUD 좌표

- B-5/B-6 시간 코어(40×40)가 우상단 (588~628) 점유
- 땅거미 HUD는 현재 위치 유지, **C 카테고리 진입 시 실제 크기 측정 후 좌측 재배치**
- Pass 1에서 땅거미 HUD는 **건드리지 않음**

### 7.3. B-6 shader 난이도

- Godot 4 shader 경험 없을 경우 `_draw()` + `draw_arc()` 방식으로 대체 가능
- 성능 문제 거의 없음 (UI는 고정 렌더 영역 작음)

### 7.4. TimePropagation 시그널 (해결 완료)

- ✓ `EventBus.flow_rate_changed(rate: float)` — 배지 도트 개수 결정
- ✓ `EventBus.propagation_origin_changed(is_origin: bool)` — 2026-04-18 신규 추가 (안 (a) 채택)
- 구현 파일: `src/systems/event_bus/event_bus.gd`, `src/systems/stage/time_propagation.gd`

### 7.5. 설계 개정 회귀

- 인게임 검증 중 체감 문제 발견 시 코드 수정 전 **`ui_design_master.md` 개정**
- 하위 문서(이 문서) 동기화 후 재시도
- feedback_ui_decisions_mutable 원칙 준수

---

## 8. 체크리스트 (진행 추적)

### Pass 1
- [x] §1.1 combat_hud 좌상단 이동 + HP pip 분리 + 콤보 placeholder (2026-04-18)
- [x] §1.2 skill_hud 완만한 오름 호 좌표 (2026-04-18)
- [x] §1.3 consumable_hud 각진 병 좌표 (2026-04-18)
- [x] §1.4 time_hud 시간 코어 재작성 (2026-04-18)
- [ ] Pass 1 종료 시 ART_RESOURCE_LIST 신규 에셋 항목 추가 (불씨 pip / 콤보 오브 / 포션 병)

### Pass 2
- [~] §2.1 B-6 arc_mask shader — **영구 보류 확정** (2026-04-18, 체감 검증 통과)
- [x] §2.2 A-7 원형 렌더 + 쿨다운 원형 sweep (ba721ad 스킬 교보재로 선행 완료)
- [x] §2.3 A-10 호흡/저체력 펄스 (2026-04-18 — HP pip + 자원 링, 파티클은 §2.4 이월)
- [ ] §2.4 회복 반딧불 파티클 → Phase 3-7 이월 (에셋 의존)

### Pass 3
- [ ] 아트 드롭-인 (Phase 3-7에서 진행)

---

## 9. 인수인계 메모 (2026-04-18 UI 트랙 세션 종료)

### 완료 상태
- **Pass 1 §1.1~§1.4 전부 완료** + 커밋 (본 세션 종료 시점 기준)
- 사용자 인게임 검증 완료 항목: **스킬 슬롯 위치 조정** (+44 shift / -14 shift 두 차례 개정 반영)
- 미검증 항목 (다음 세션에서 확인 필요):
  - HP pip 우→좌 비우기 체감
  - 콤보 4타 피니시 속성 오브 색 전환 (light/shadow/hybrid/neutral)
  - 시간 코어 해·달 궤도 회전 (FLOWING/STOPPED/MANIPULATING 차이)
  - B-6 일식 링 자원 비례 축소 + STOPPED 시 50% dim
  - B-7 전파 배지 3상태 (hidden / 금 도트 1 / 보라 도트 2~4)

### 병렬 세션 주의사항
- 본 세션은 **Phase 3-3~3-5 개발 병렬 진행**으로 인한 머지 충돌 방지 위해 Pass 1 완료 시점에서 종료
- **event_bus.gd 변경점**: `propagation_origin_changed(is_origin: bool)` 시그널 1건 추가. 다른 세션에서 event_bus 수정 시 conflict 예상 (merge 재해결 필요)
- **skill_hud.gd KEY_LABELS**: 본 세션 종료 직전 외부(다른 세션) 수정으로 `["U", "I", "K", "L"]`로 변경됨 — InputMap 재매핑이 별도 세션에서 진행 중. Pass 2 이전 최종 확정 필요

### Pass 2 진입 전 결정 필요
1. **Pass 2 착수 시점** — Phase 3-5까지 병렬 세션 작업 완료 후 단일 세션으로 재개 권장
2. **땅거미 HUD 좌표** — C 카테고리 진입 시 우상단 시간 코어(40×40, 588~628)와의 충돌 재확인
3. **ART_RESOURCE_LIST 신규 에셋 등록** — Pass 1 placeholder가 확정되었으므로 아래 항목 언제든 추가 가능:
   - `hud_combo_orb.png` (A-6 속성 오브 4종)
   - `hud_hp_pip.png` (A-5 횃불 불씨 5단계)
   - `hud_potion_hp.png` / `hud_potion_time.png` (A-8 각진 병 2종)

### Pass 2 작업 단위 (재개 시 참조)
- §2.1 B-6 일식 링 `arc_mask.gdshader` 작성 (신규 파일)
- §2.2 A-7 스킬 슬롯 원형 렌더링 (`draw_circle` + `draw_arc` 쿨다운 sweep)
- §2.3 A-10 호흡/저체력 펄스 애니메이션 (modulate tween)
- §2.4 회복 시 반딧불 파티클 (에셋 의존, 보류 가능)

### 미해결 설계 의사결정
- HP pip 비우기 방향 — 현재 코드는 우→좌 (오른쪽부터 dim). ui_design_master.md에 명시적 기록 없음. 인게임 검증 후 설계 문서 확정 필요
- 속성 오브 hybrid 색 — Pass 1 placeholder `(0.8, 0.5, 0.6)` 사용 중. Pass 2에서 금↔보라 pulse로 전환 예정 (A-6 설계 참조)

---

## 10. 버전 이력

| 일자 | 내용 |
|---|---|
| 2026-04-18 | 초안 작성 — A/B 카테고리 Pass 1~3 구조, 기존 HUD 코드 맵, placeholder 전략 |
| 2026-04-18 | v1.1: 검토 반영 4건 — §1 TimeHud.tscn 구조 검증 / §1.1 Combo4 8×8 통일 / §1.4 현재 구조 기록 + 전파 시그널 갭 3안 / §6 HP pip 에셋 표기 정정(#14 오류→신규) / §7.4 시그널 갭 구체화 |
| 2026-04-18 | v1.2: `propagation_origin_changed(is_origin)` 시그널 신설 (안 (a) 채택) — EventBus + TimePropagation 발행 로직 구현. §1.4/§7.4 "해결 완료"로 갱신 |
| 2026-04-18 | v1.3: Pass 2 스코프 A 진행 — §2.2는 ba721ad로 선행 완료 확인 / §2.3 HP pip·자원 링 호흡 + 저체력·저자원(<20%) 0.8s 붉은 맥동 구현(combat_hud·time_core_renderer). §2.1은 placeholder 충분으로 보류, §2.4는 Phase 3-7 이월 |
| 2026-04-18 | v1.4: Pass 2 §2.3 체감 검증 4건 전부 통과 (사용자 확인). §2.1 arc_mask shader **영구 보류 확정** — draw_arc placeholder 유지. Pass 2 스코프 A 종료, Phase 3-6 잔여(타이틀/일시정지/메뉴/미니맵)로 이관 |
| 2026-04-19 | v1.5: **타이틀 화면 구현 완료**. 4-메뉴(새 게임/이어하기/설정/종료) + 세이브 감지 + 덮어쓰기 확인 모달 + fade in/out + F12 디버그 스킵. `EventBus.game_start_requested` 시그널 신설, StageSystem 자동 로드 경로 제거 → 타이틀 주도 진입. HUD 가시성 제어 위해 `game_hud` 그룹 도입 (CanvasLayer는 `hide()` 불가, `set_visible(bool)` 사용). CanvasLayer 자식 Control은 `anchors_preset` 프로퍼티 아닌 `set_anchors_and_offsets_preset()` 메서드 사용 필수. 상세=`PHASE_3_PLAN.md` §8 구현 결과 |
