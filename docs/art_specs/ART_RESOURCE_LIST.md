# 시간이 멈춘 숲 — 아트 리소스 목록

> 구현 진행에 따라 필요한 아트 리소스를 누적 기록한다.
> 각 Phase/마일스톤 완료 시 해당 작업에 필요한 리소스가 추가된다.
> **파일을 해당 폴더에 넣으면 코드 수정 없이 바로 반영됨.** 없으면 fallback(플레이스홀더)으로 동작.

---

## Phase 1-1. 플레이어 기본 이동 + Phase 1-2. 테스트 스테이지

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 1 | 바닥 타일 | 64x64, 반복 사용 | `assets/tiles/` | `tile_ground_test.png` | 풀/흙 느낌. TextureRect 타일 반복으로 적용됨 |
| 2 | 플랫폼 타일 | 192x64 (64x64 x 3 = 좌/중/우) | `assets/tiles/` | `tile_platform_test.png` | Sprite2D로 플랫폼에 적용됨 |
| 3 | 배경 | 640x360 | `assets/backgrounds/` | `bg_test_stage.png` | 단색 or 간단한 그라데이션 |
| 4 | 플레이어 점프 | 128x128 캔버스, 가로 스트립 (2~4프레임) | `assets/sprites/player/` | `player_jump.png` | 예: 2프레임 → 256x128 PNG |
| 5 | 플레이어 낙하 | 128x128 캔버스, 가로 스트립 (2~4프레임) | `assets/sprites/player/` | `player_fall.png` | 예: 2프레임 → 256x128 PNG |
| 6 | 플레이어 대시 | 128x128 캔버스, 가로 스트립 (2~3프레임) | `assets/sprites/player/` | `player_dash.png` | 예: 2프레임 → 256x128 PNG. 비루프 |

### 플레이어 애니메이션 내보내기 방법

Aseprite에서 태그별로 내보내기:
```
파일 → Export Sprite Sheet
  → Layout: Horizontal Strip
  → Tag 선택: Jump / Fall / Dash (각각 별도 내보내기)
  → Output: assets/sprites/player/player_jump.png (등)
```

> **주의**: 기존 `player_spritesheet.png`은 64x64 캔버스(구 규격)로 제작됨.
> 128x128 캔버스로 새로 제작 필요. 새 스프라이트시트 적용 시 Player.tscn의 AtlasTexture region도 갱신 필요.

**우선순위**: 4~6번(플레이어 모션) > 1~3번(환경)

---

## Phase 1-3. 시간 시스템

> **아트 리소스 없음** — HUD는 Godot UI 노드(Label, ProgressBar), 분위기 전환은 CanvasModulate로 처리.
> Phase 3에서 UI 아트 본격 적용 시 HUD 스킨 리소스가 추가될 예정.

---

## Phase 1-4. 그림자 시스템

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 7 | 테스트 오브젝트 (나무) | 64x128 | `assets/sprites/objects/` | `obj_tree_test.png` | 그림자 생성 대상. 간단한 나무 실루엣 |
| 8 | 나무 그림자 | 128x64 (가로 긴 형태) | `assets/sprites/objects/` | `shadow_tree.png` | 반투명 검정. 코드로 scale/offset 조절 |
| 9 | 바위 그림자 | 64x32 | `assets/sprites/objects/` | `shadow_rock.png` | 반투명 검정. 바위 실루엣 |
| 10 | 꽃 그림자 | 32x16 | `assets/sprites/objects/` | `shadow_flower.png` | 반투명 검정. 작고 가벼운 형태 |
| 11 | 돌기둥 그림자 | 32x64 | `assets/sprites/objects/` | `shadow_pillar.png` | 반투명 검정. 길고 가느다란 형태 |
| 12 | 범용 그림자 | 64x32 | `assets/sprites/effects/` | `shadow_generic.png` | 단색 반투명 검정. 타원형. 모든 오브젝트 fallback 용 |

### 그림자 스프라이트 제작 가이드

**공통 규칙**:
- 색상: 순수 검정 (`#000000`), 투명도 60~70%
- 형태: 원본 오브젝트의 납작한 실루엣 (위에서 내려다본 느낌)
- 앵커: 좌측 중앙 (코드에서 direction에 따라 offset 조절)
- 태양 방향 변화, 길이 변화는 **코드로 처리** — 스프라이트 자체는 한 방향(오른쪽)으로만 제작

**Aseprite 내보내기**:
```
파일 → Export Sprite Sheet (또는 그냥 Save As PNG)
  → 단일 프레임 (애니메이션 없음)
  → Output: assets/sprites/objects/shadow_tree.png (등)
```

### 참고
- 그림자는 **스프라이트 기반** (Light2D/Shadow2D 미사용)
- 시간(태양 각도)에 따라 코드로 direction/scale 조절
- **아트 없이도 동작**: 파일이 없으면 검정 ColorRect fallback으로 그림자 표시
- 파일을 해당 폴더에 넣으면 코드 수정 없이 즉시 반영

**우선순위**: 12번(범용) > 7번(테스트 나무) > 8~11번(개별 그림자)

---

## Phase 1-5. 적 시스템 (기본)

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 13 | 나무 적 스프라이트 시트 | 128x128 캔버스 | `assets/sprites/enemies/` | `enemy_tree.png` | 크고 느린 느낌. 스프라이트 시트 |
| 14 | 바위 적 스프라이트 시트 | 96x96 캔버스 | `assets/sprites/enemies/` | `enemy_rock.png` | 작고 단단한 느낌 |
| 15 | 꽃 적 스프라이트 시트 | 64x64 캔버스 | `assets/sprites/enemies/` | `enemy_flower.png` | 빠르고 가벼운 느낌 |
| 16 | 돌기둥 적 스프라이트 시트 | 64x128 캔버스 | `assets/sprites/enemies/` | `enemy_pillar.png` | 길고 가느다란 느낌 |
| 17 | 그림자 잔류 마커 | 32x8 | `assets/sprites/effects/` | `shadow_residue.png` | 반투명 보라/검정 얼룩. 바닥에 남는 흔적 |

### 적 스프라이트 시트 제작 가이드

**공통 규칙**:
- 적은 "그림자에서 생성된 존재" — 반투명하거나 어두운 톤, 원본 오브젝트의 형태가 왜곡된 느낌
- 모든 적은 동일한 애니메이션 태그 세트를 가짐

**애니메이션 태그 목록**:

| 태그명 | 프레임 수 | 루프 | 설명 |
|---|---|---|---|
| `idle` | 4 | O | 대기 상태. 미세하게 흔들림/맥동 |
| `walk` | 4 | O | 순찰 이동. 느리게 떠다니는 느낌 |
| `run` | 4 | O | 추적 이동. walk보다 빠르고 공격적 |
| `attack` | 4 | X | 공격 모션. 그림자 팔/촉수를 뻗는 느낌 |
| `hurt` | 2 | X | 피격. 잠시 밝아지거나 흩어지는 느낌 |
| `dead` | 4 | X | 사망. 그림자가 흩어져 사라짐 |

**Aseprite 내보내기**:
```
파일 → Export Sprite Sheet
  → Layout: Horizontal Strip
  → Tag별 별도 내보내기 또는 하나의 시트로 통합
  → Output: assets/sprites/enemies/enemy_tree.png (등)
```

### 유형별 캐릭터 가이드

| 유형 | 크기 | 실루엣 | 특징 |
|---|---|---|---|
| 나무 | 크고 넓음 | 나뭇가지가 뻗은 형태 | 둔탁하고 묵직한 움직임 |
| 바위 | 작고 둥글음 | 바위 덩어리 형태 | 단단하고 안정적인 느낌 |
| 꽃 | 작고 날렵 | 꽃잎/덩굴 형태 | 가볍고 빠른 움직임 |
| 돌기둥 | 길고 가늘음 | 기둥/창 형태 | 원거리 찌르기 느낌 |

### 잔류 마커 가이드
- 적 처치 후 바닥에 남는 그림자 얼룩
- 색상: 어두운 보라/검정 (`#1A0028` ~ `#0D0015`), 투명도 50~70%
- 형태: 불규칙한 얼룩/웅덩이
- 코드에서 투명도가 미세하게 맥동함

**우선순위**: 17번(잔류) > 13번(나무 적, 기본 타입) > 14~16번(나머지 적)

---

## Phase 1-6. 콤보 전투 시스템

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 18 | 콤보 1타 | 128x128 캔버스, 가로 스트립 (3~4프레임) | `assets/sprites/player/` | `player_slash_1.png` | 가벼운 횡베기. 비루프 |
| 19 | 콤보 2타 | 128x128 캔버스, 가로 스트립 (3~4프레임) | `assets/sprites/player/` | `player_slash_2.png` | 반대 방향 횡베기. 비루프 |
| 20 | 콤보 3타 | 128x128 캔버스, 가로 스트립 (3~4프레임) | `assets/sprites/player/` | `player_slash_3.png` | 더 강한 횡베기. 비루프 |
| 21 | 콤보 4타 (피니시) | 128x128 캔버스, 가로 스트립 (4~6프레임) | `assets/sprites/player/` | `player_slash_4.png` | 가장 강한 마무리 공격. 이펙트 포함 가능. 비루프 |

### 콤보 애니메이션 제작 가이드

**콤보 흐름**: 1타 → 2타 → 3타 → 4타(피니시)
- 1~3타: 무속성 횡베기 (좌우 교차). 점점 빨라지거나 강해지는 느낌
- 4타(피니시): 가장 강력한 타격. 이후 스킬 속성(빛/그림자/혼합)에 따라 이펙트 차별화 예정
- 모든 공격은 **비루프** — 한 사이클 재생 후 이동 애니메이션으로 복귀
- 히트 활성 시간: 0.3초 (10fps 기준 3프레임)

**Aseprite 내보내기**:
```
파일 → Export Sprite Sheet
  → Layout: Horizontal Strip
  → Tag 선택: Slash1 / Slash2 / Slash3 / Slash4 (각각 별도 내보내기)
  → 캔버스: 128x128 (모션/이펙트 여백 포함)
  → Output: assets/sprites/player/player_slash_1.png (등)
```

**현재 상태**: 기존 slash 스프라이트(64x64, 4프레임)를 4타 모두 공유하는 fallback으로 동작.
파일을 해당 폴더에 넣으면 코드 수정 없이 개별 애니메이션 반영.

### HUD 아트

> **아트 리소스 없음** — HP 바는 Godot ProgressBar, 콤보 인디케이터는 ColorRect.
> Phase 3에서 UI 아트 본격 적용 시 스킨 리소스가 추가될 예정.

**우선순위**: 21번(피니시) > 18~20번(일반 타) — 피니시의 차별화가 가장 중요

---

## Phase 1-7. 등불 시스템 (기본)

> **아트 리소스 없음** — PointLight2D는 코드에서 Image로 생성한 원형 그라데이션 텍스처를 사용.
> 등불 자체의 시각적 표현(손에 든 랜턴 오브젝트)은 Phase 3에서 플레이어 스프라이트 아트와 함께 적용 예정.
> 그림자는 기존 ShadowCaster의 fallback(ColorRect)으로 동작.

### 향후 필요 아트 (Phase 3)

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 22 | 등불 조명 텍스처 | 128x128, 원형 그라데이션 | `assets/sprites/effects/` | `lantern_light.png` | 부드러운 감쇠 원형. 현재 코드 생성 fallback |
| 23 | 등불 오브젝트 | 플레이어 스프라이트에 통합 | `assets/sprites/player/` | — | 플레이어 idle/run 등에 손에 든 랜턴 포함 |

**우선순위**: 낮음 (현재 fallback으로 동작. Phase 3 아트 일괄 적용 시 포함)

---

## Phase 2-4b. 스테이지 전환 (인접 포탈)

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 24 | 포탈 이펙트 | 32x360 (세로 전체) | `assets/sprites/objects/` | `portal_stage.png` | 맵 경계의 빛 기둥/안개 느낌. 반투명. 현재 파란색 ColorRect placeholder |
| 25 | TestStage2 배경 | 640x360 | `assets/backgrounds/` | `bg_test_stage_2.png` | TestStage와 다른 분위기. 현재 보라색 ColorRect placeholder |

### 포탈 제작 가이드

**포탈 시각적 컨셉**:
- 맵 좌/우 끝에 배치되는 세로형 이펙트
- "다른 공간으로의 통로" 느낌 — 빛이 새어 나오거나 안개가 피어오르는 형태
- 색상: 옅은 파란/흰색 계열, 투명도 30~50%
- 애니메이션 없이 단일 이미지로 충분 (코드에서 추가 연출 가능)

**적용 방법**:
- `StagePortal.tscn`의 `PortalVisual` (ColorRect)을 Sprite2D로 교체
- 또는 `stage_portal.gd`에 fallback 로직 추가 후 파일 존재 시 자동 반영

**우선순위**: 낮음 (placeholder로 기능 테스트 가능. 아트 방향성 확정 후 적용)

---

## Phase 2-4e. 테스트 스테이지 3~5 추가

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 26 | TestStage3 배경 | 640x360 | `assets/backgrounds/` | `bg_test_stage_3.png` | 새벽 분위기. 어두운 갈색 → 연한 주황 그라데이션. 현재 갈색 ColorRect placeholder |
| 27 | TestStage4 배경 | 640x360 | `assets/backgrounds/` | `bg_test_stage_4.png` | 황혼 분위기. 어두운 붉은/주황색. 현재 붉은 갈색 ColorRect placeholder |
| 28 | TestStage5 배경 | 640x360 | `assets/backgrounds/` | `bg_test_stage_5.png` | 심야 분위기. 매우 어두운 남색/보라. 현재 짙은 보라색 ColorRect placeholder |

### 배경 제작 가이드

**공통 규칙**:
- 640x360, 단일 이미지 (애니메이션 없음)
- 각 스테이지의 시간대를 반영한 색감
- 파일을 `assets/backgrounds/`에 넣으면 코드 수정 없이 자동 반영

**스테이지별 컨셉**:

| 스테이지 | 시간대 | 색감 방향 | placeholder 색상 |
|---|---|---|---|
| TestStage3 | 새벽 06시 | 어두운 갈색 → 새벽 주황빛 | `#2E261F` |
| TestStage4 | 황혼 18시 | 석양 붉은빛 + 어둠 | `#331F1A` |
| TestStage5 | 심야 03시 | 깊은 남색/보라 | `#140F1F` |

**기존 에셋 재사용**:
- 바닥 타일 (`tile_ground_test.png`), 플랫폼 타일 (`tile_platform_test.png`)은 TestStage/TestStage2와 공유
- 적 스프라이트, 포탈 이펙트도 기존 에셋 동일 사용
- 새로 필요한 것은 **배경 3장**뿐

**우선순위**: 낮음 (placeholder로 기능 테스트 가능. 구역별 아트 방향성 확정 후 일괄 적용)
