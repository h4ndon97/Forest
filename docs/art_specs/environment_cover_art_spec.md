# 시간이 멈춘 숲 — 차폐물(Cover) 환경 오브젝트 아트 명세서

> 차폐물은 STOPPED(시간 정지) 중 플레이어가 [E]로 플레이어 반대 방향으로 16px씩 밀어 위치를 조정하는 정적 환경 오브젝트다.
> 본체 뒤쪽에 짙은 그림자 투영 영역(96×32)을 드리우고, 해당 영역 안에 들어온 적의 `shadow_intensity`를 0.9로 강제 override한다.
> "빛과 그림자를 물리적으로 막는 고대 석판" — 거울(회전/반사)과 대비되는 "차단/정적 도구" 컨셉.

---

## 1. 구현 상태 요약

| 항목 | 값 |
|---|---|
| **구현 Phase** | 2-5b (완료) |
| **데이터 스크립트** | `data/environment/cover_data.gd` (`CoverData extends EnvironmentObjectData`) |
| **기본 리소스** | `data/environment/cover_basic.tres` |
| **씬 파일** | `src/entities/objects/environment/cover/Cover.tscn` |
| **루트 스크립트** | `src/entities/objects/environment/cover/cover.gd` |
| **투영 영역 스크립트** | `src/entities/objects/environment/cover/shadow_projection_zone.gd` |
| **공용 컴포넌트** | `environment_highlight.gd`, `environment_prompt.gd` (거울과 공유) |
| **Fallback** | Body/BodyVisual = ColorRect 24×64 `#5A4D48`, ProjectionVisual = ColorRect 96×32 `#0C0C19 α0.35` |

### 기본 데이터 값 (`CoverData`)

| 프로퍼티 | 값 | 설명 |
|---|---|---|
| `move_step_pixels` | 16.0 | [E] 1회당 이동 거리 |
| `min_x_offset / max_x_offset` | -64.0 / +64.0 | 이동 가능 범위 (총 128px = 8스텝) |
| `block_mode` | CREATE | enum BlockMode { CREATE, REMOVE, BOTH } — 현재 CREATE만 구현 |
| `block_intensity` | 0.9 | 영역 내 적 `shadow_intensity` override 값 |
| `shadow_projection_length / width` | 96.0 / 32.0 | 투영 영역 크기 |
| `projection_mode` | LIGHT_OPPOSITE | enum ProjectionMode { LIGHT_OPPOSITE, LOCAL_FIXED } |
| `body_size` | Vector2(24, 64) | Body 충돌 + ColorRect 실효 크기 |
| `body_color` | `Color(0.35, 0.30, 0.28, 1)` = `#5A4D48` | Body fallback 색상 |

### 시그널 (EventBus)
- `environment_interacted(object_id, step_index)` — [E] 입력 성공 시 1회
- `environment_blocked_shadow(cover_id, enemy_id, blocked)` — 영역 내 적 차단 상태 변화 시

---

## 2. 디자인 컨셉

### 전체 느낌
- **"빛과 그림자를 물리적으로 막는 고대 석판"**
- 거울과 동일 세계관의 유물이지만, 용도가 **차단(block)** — 회전 불가, 매끈하지 않음
- 표면은 단단하고 불투명. 거울의 "매끈한 반사"와 정반대 질감
- 숲에 오래 묻혀 있던 석재 — 표면 크랙, 이끼 액센트 허용

### 형태 가이드
- **본체**: 세로로 긴 직사각 석판 (24×64 실효, 캔버스 64×64). 상단이 약간 깨지거나 비스듬하게 처리 가능
- **표면 질감**: 1~2px 단위의 노이즈/크랙. 완벽한 평면이 아니라 "조각난 단단한 돌"
- **이끼/풍화**: 하단 또는 측면에 이끼 액센트 (#4A5A3A 계열) 1~2픽셀씩 산발 배치
- **좌우 대칭**: 방향성 없음 → flip 불필요, 0° 1장만 필요
- **회전 금지**: 본체 스프라이트는 회전하지 않음. 오직 X축 위치만 변경됨

### 투영 영역(Projection Zone) 느낌
- "그림자가 드리워진 어두운 공기" — 완전히 검지 않고 반투명한 안개처럼
- 경계가 너무 선명하지 않게 **에지 소프트닝** (좌우 끝 4~8px 그라데이션)
- 본체 뒤쪽에서 뻗어나가는 느낌 — 본체에 가까운 쪽이 약간 진하고 끝으로 갈수록 옅어지는 선택 권장

### 거울과의 대비 (컨셉 가이드)

| 항목 | 거울 | 차폐물 |
|---|---|---|
| 표면 | 매끈한 반사 | 거친 석재 |
| 동작 | 90° 회전 4프리셋 | 좌우 16px 이동 |
| 역할 | 빛 반사/집중 → 분열 | 빛/그림자 차단 → 강도 override |
| 팔레트 | 하늘색/은빛 (차가움) | 회갈색/이끼 (어둡고 둔탁) |
| 이펙트 색감 | 따뜻한 노란 빛줄기 | 짙은 남색 어둠 영역 |

---

## 3. 색상 팔레트

### 본체 팔레트

| 용도 | 색상 코드 | 설명 |
|---|---|---|
| 본체 기본 | `#5A4D48` | 현재 ColorRect와 동일. 어두운 회갈색 석재 |
| 본체 하이라이트 | `#7A6A62` | 상단/측면 빛 받는 부분. 1~2px |
| 본체 음영 | `#3A2F2B` | 하단/크랙 내부 어두운 영역 |
| 크랙 라인 | `#2A2220` | 표면 갈라짐. 1px 라인 |
| 이끼 액센트 | `#4A5A3A` | 하단/측면 풍화. 1~2px 점 |
| 이끼 밝은 톤 | `#6A7A4A` | 이끼 하이라이트 (선택) |

### 투영 영역 팔레트

| 용도 | 색상 코드 | 설명 |
|---|---|---|
| 투영 기본 | `#0C0C19` | 현재 ColorRect와 동일. 짙은 남빛 어둠 |
| 투영 알파 | 0.35 | 현재 값 유지. 반투명 영역 |
| 에지 그라데이션 | `#0C0C19 α0.15` | 좌우 끝 4~8px 페이드 아웃 |
| FLOWING 펄스 강조 | `#1A1A2E` | 흐름 중 미세 파동 강조 톤 (약간 밝게) |

### 하이라이트 팔레트 (거울 공용)

| 용도 | 색상 코드 | 설명 |
|---|---|---|
| 선택 테두리 | `#FFE066` | 본체 주변 노란 테두리 (거울과 동일) |
| 테두리 알파 | 0.8 | 현재 Line2D fallback 기준 |

### 색상 원칙
- **본체**: 차갑고 어두운 회갈색 — 숲의 녹색과 대비되어 "이질적인 석재 유물"로 인식
- **투영 영역**: 짙은 남색 반투명 — "그림자 속 공간"을 시각적으로 표현, 적이 들어가면 override 중임을 암시
- **이펙트 없음**: 거울과 달리 발동 이펙트(flash/burst)가 없다. 조용한 "상시 차단 장치"

---

## 4. 자산 목록 테이블

| # | 태그/파일 | 캔버스 | 프레임 | FPS | 루프 | 폴더 | 파일명 | 우선순위 |
|---|---|---|---|---|---|---|---|---|
| 64 | 차폐물 본체 | 64×64 | 1 | — | — | `assets/sprites/objects/cover/` | `cover_body.png` | 1 |
| 65 | 투영 영역 (정적) | 96×32 | 1 | — | — | `assets/sprites/objects/cover/` | `cover_projection_static.png` | 2 |
| 66 | 투영 영역 (흐름 중) | 96×32 | 4 | 8 | O | `assets/sprites/objects/cover/` | `cover_projection_flowing.png` | 3 |

> 전부 없어도 현재 ColorRect fallback으로 동작한다. 폴더에 PNG를 넣으면 차후 Sprite2D 교체 예정 코드에서 자동 반영될 수 있도록 네이밍을 고정한다.

---

## 5. 자산별 상세 명세

### 5.1 #64 `cover_body.png` — 차폐물 본체

| 항목 | 값 |
|---|---|
| **캔버스** | 64×64 (여백 포함) |
| **실효 본체** | 24×64 (세로 석판) |
| **프레임 수** | 1 (정적) |
| **태그** | `idle` (단일 프레임이면 생략 가능) |
| **폴더** | `assets/sprites/objects/cover/` |
| **파일명** | `cover_body.png` |
| **피벗/앵커** | 중앙 (Node2D 원점). 본체 중심이 씬 원점과 일치 |
| **좌우 대칭** | 예 (flip 불필요) |
| **회전** | 없음 (코드에서 rotation 변경 안 함) |

**팔레트 적용**
- 바디: `#5A4D48` 기준, `#7A6A62` 상단 하이라이트, `#3A2F2B` 하단 음영
- 표면 크랙 1~2개 (`#2A2220`, 1px 대각선 라인)
- 하단/측면에 이끼 액센트 `#4A5A3A` 2~4픽셀 산발

**Godot 연결 경로**
- 현재: `Cover/Body/BodyVisual` (ColorRect, 색 `body_color`)
- 교체 시: `BodyVisual`을 `Sprite2D`로 변경하고 `texture`에 `cover_body.png` 바인딩
- 혹은 `BodyVisual` 위에 별도 `Sprite2D`를 얹고 ColorRect는 fallback으로 유지 가능
- 크기: 24×64 실효 영역이 `Body/CollisionShape2D`의 `RectangleShape2D(24×64)`와 정렬되어야 함

**제작 팁**
- 외곽 1px은 `#3A2F2B` 어두운 윤곽선으로 실루엣 강조
- 상단 모서리 1~2픽셀을 깨뜨리거나 비스듬하게 처리 → "오래된 유물" 느낌
- 완전 좌우 대칭 유지 (플레이어가 밀어서 방향 구분이 필요 없도록)

---

### 5.2 #65 `cover_projection_static.png` — 투영 영역 (정적)

| 항목 | 값 |
|---|---|
| **캔버스** | 96×32 |
| **실효 영역** | 96×32 (전면 사용) |
| **프레임 수** | 1 (정적) |
| **태그** | `static` (단일 프레임이면 생략 가능) |
| **폴더** | `assets/sprites/objects/cover/` |
| **파일명** | `cover_projection_static.png` |
| **피벗/앵커** | **왼쪽 중앙** — 본체 기준 (48, 0) 오프셋에 왼쪽 끝이 닿도록 |
| **회전 기준** | 0° (오른쪽 방향). 실제 회전은 `ShadowProjectionZone.rotation`으로 런타임 적용 |

**팔레트 적용**
- 기본 색: `#0C0C19` α0.35 (현재 fallback과 동일)
- 에지 페이드: 좌우 끝 4~8px에서 α0.35 → α0.15로 그라데이션
- 상하 끝 2~4px도 동일하게 에지 페이드 (경계 소프트닝)
- 내부 미세 노이즈 1~2% (정적 감 유지 위해 과하지 않게)

**Godot 연결 경로**
- 현재: `Cover/ShadowProjectionZone/ProjectionVisual` (ColorRect 96×32, offset_left=0, offset_top=-16)
- 교체 시: `ProjectionVisual`을 `Sprite2D`로 변경하고 `texture`에 `cover_projection_static.png` 바인딩
- `Sprite2D.centered = false`, `offset = Vector2(0, -16)`로 설정 → 왼쪽 중앙이 `ShadowProjectionZone/CollisionShape2D.position = (48, 0)`에 정렬됨
- 회전은 상위 `ShadowProjectionZone`이 담당 (낮=태양 반대 / 밤=등불 반대)

**제작 팁**
- 완전한 사각형보다 "드리워진 그림자" 느낌 — 왼쪽(본체 가까운 쪽)이 약간 진하고 오른쪽 끝으로 갈수록 옅어지는 수평 그라데이션 권장
- 경계가 선명하지 않아야 함 (안개처럼 퍼지는 느낌)
- 반투명이 중첩될 수 있으므로 알파 총합이 0.5를 넘지 않도록 주의

---

### 5.3 #66 `cover_projection_flowing.png` — 투영 영역 (흐름 중)

| 항목 | 값 |
|---|---|
| **캔버스** | 96×32 |
| **실효 영역** | 96×32 |
| **프레임 수** | 4 |
| **FPS** | 8 (0.5초 1사이클) |
| **루프** | O |
| **태그** | `flowing` |
| **폴더** | `assets/sprites/objects/cover/` |
| **파일명** | `cover_projection_flowing.png` |
| **피벗/앵커** | 왼쪽 중앙 (정적 버전과 동일) |

**애니메이션 프레임 가이드**
- 프레임 1: 정적 버전과 동일 (α0.35, 기본 톤)
- 프레임 2: 중앙 부분에 약한 밝기 파동 (`#1A1A2E` α0.40), 좌→우로 이동하는 흐름 암시
- 프레임 3: 파동이 오른쪽 2/3 지점에 도달, 약간 옅어짐 (α0.32)
- 프레임 4: 파동이 사라지고 기본 상태로 복귀 직전 (α0.35)
- **미세 파동** — 과하지 않게, "영역이 살아있는 느낌"만 암시

**Godot 연결 경로**
- 현재 코드: FLOWING 동안 override가 매 프레임 재적용됨 (`shadow_projection_zone.gd`)
- 교체 시: `ProjectionVisual`을 `AnimatedSprite2D`로 변경하거나, 정적 Sprite2D 위에 별도 AnimatedSprite2D 레이어 추가
- SpriteFrames 리소스에 `static` 태그(1프레임)와 `flowing` 태그(4프레임 loop)를 함께 등록하고, TimeSystem 상태 전환 시 `play("static")` / `play("flowing")`으로 전환 권장
- 현재 구현에는 상태별 비주얼 전환 로직이 없음 — 자산 반영 시 `cover.gd`에 `TimeSystem.state_changed` 시그널 구독 추가 필요

**제작 팁**
- 파동은 **한 방향(좌→우)** 으로만 흐르게 → 본체 뒤쪽에서 어둠이 번지는 방향성 암시
- 프레임 간 차이가 크면 눈에 거슬림 — 전체 알파 차이 0.05 이내 권장
- 색감은 `#0C0C19` 계열 유지, `#1A1A2E` 파동 강조만 살짝

---

## 6. Fallback 현황

현재 아트 자산이 없는 상태에서 씬은 다음 fallback으로 동작한다.

| 요소 | Fallback 방식 | 값 |
|---|---|---|
| 본체 | `Cover/Body/BodyVisual` ColorRect | 24×64, `#5A4D48` (α1.0) |
| 투영 영역 | `Cover/ShadowProjectionZone/ProjectionVisual` ColorRect | 96×32, `#0C0C19` α0.35 |
| 선택 하이라이트 | `Cover/Highlight` Line2D (`environment_highlight.gd`) | 40×56 노란 테두리 (`#FFE066` α0.8) |
| 상호작용 프롬프트 | `Cover/Prompt` Label (`environment_prompt.gd`) | "[E] 차폐물 밀기" |
| 투영 회전 | `ShadowProjectionZone.rotation` (코드에서 매 프레임 갱신) | 낮=태양 반대 / 밤=등불 반대 / 밤+등불 OFF = 0° |

**아트 교체 방침**
- PNG를 해당 경로에 넣은 후, 렌더 노드 타입만 `ColorRect → Sprite2D` / `AnimatedSprite2D`로 교체
- `body_color`, `ProjectionVisual.color` 등 데이터 값은 그대로 두면 fallback 유지 가능 (스프라이트 우선 표시 로직만 추가)
- 선택 하이라이트와 프롬프트는 거울과 공용이므로 이 문서에서는 다루지 않음 (거울 아트 명세서 참고)

---

## 7. Aseprite 작업 가이드 (사용자 후속 작업용)

### 파일 구성 권장

**본체**: 단일 `.aseprite`

```
cover_body.aseprite
[Layers]
├── cracks       (표면 크랙/노이즈 — 최상단)
├── moss         (이끼 액센트)
├── highlight    (상단/측면 빛 받는 영역)
├── shadow       (하단/측면 음영)
└── base         (본체 기본 색 #5A4D48)

캔버스 64×64, 1프레임
```

**투영 영역**: 단일 `.aseprite`에 태그 2개

```
cover_projection.aseprite
[Tags]
├── static   (프레임 1, 단일)
└── flowing  (프레임 2~5, 4프레임 loop)

[Layers]
├── pulse    (FLOWING 파동 강조 레이어)
├── edge     (좌우 상하 에지 페이드)
└── base     (기본 #0C0C19 α0.35)

캔버스 96×32, 총 5프레임
```

### 내보내기 설정

```
cover_body.aseprite
  → Save As PNG
  → assets/sprites/objects/cover/cover_body.png  (64x64)

cover_projection.aseprite
  → Export Sprite Sheet (Horizontal Strip)
  → Tag: static
  → assets/sprites/objects/cover/cover_projection_static.png  (96x32)

  → Export Sprite Sheet (Horizontal Strip)
  → Tag: flowing
  → assets/sprites/objects/cover/cover_projection_flowing.png  (384x32, 4프레임)
```

> Aseprite CLI 호출은 사용자가 `.ase` 파일을 생성한 후 별도 작업으로 진행한다.

---

## 8. 게임 내 동작 참고 (아트 근거)

| 항목 | 값 | 비고 |
|---|---|---|
| 상호작용 키 | E (STOPPED 중만 유효) | FLOWING 중에는 밀기 불가 |
| 이동 1스텝 | 16px | 플레이어 반대 방향으로 이동 |
| 이동 범위 | -64 ~ +64 (총 8스텝) | 양 끝에서 클램프 |
| 상호작용 반경 | 32px 원 (InteractionArea) | collision_layer 32 |
| 본체 충돌 | 24×64 (Body, layer 1) | 플레이어/적 통행 차단 |
| 투영 영역 | 96×32 (mask 4 = 적 감지) | 본체 기준 오프셋 (48, 0) |
| 회전 기준 | 낮 = 태양 반대 / 밤 = 등불 반대 | 밤+등불 OFF = 각도 0 (비활성 표시) |
| 영역 내 적 | `shadow_intensity = 0.9` override (max 병합) | 매 프레임 재적용 |
| 발동 이펙트 | **없음** | 거울과 달리 조용한 상시 차단 |

---

## 9. 제작 우선순위

1. **#64 `cover_body.png`** — 본체 (24×64) — 플레이어가 밀어서 배치하는 주체. 시각적 명확성이 가장 중요
2. **#65 `cover_projection_static.png`** — 정적 투영 영역 (96×32) — "어디가 차단되는지" 영역 표시의 핵심 단서
3. **#66 `cover_projection_flowing.png`** — FLOWING 중 파동 (96×32, 4프레임) — 폴리싱. 없어도 메카닉 동작에는 지장 없음

> 현재는 모든 비주얼이 ColorRect fallback으로 동작한다.
> **#64 + #65** 2장만 있어도 "고대 석판이 그림자를 드리운다"는 컨셉이 살아난다.
> #66은 "흐름 중 영역이 살아있다"는 미묘한 피드백 — 시간 여유 있을 때 제작 권장.

---

## 10. 연결 참고 문서

- 시스템 설계: `docs/CORE_SYSTEMS.md` (환경 오브젝트 섹션)
- 자산 총괄: `docs/art_specs/ART_RESOURCE_LIST.md` Phase 2-5b
- 유사 문서: `docs/art_specs/environment_mirror_art_spec.md` (거울 — 회전/반사 오브젝트)
- 파이프라인: `docs/ART_PIPELINE.md` (캔버스/네이밍/내보내기 규격)
