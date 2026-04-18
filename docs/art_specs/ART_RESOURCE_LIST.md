# 시간이 멈춘 숲 — 아트 리소스 목록

> 구현 진행에 따라 필요한 아트 리소스를 누적 기록한다.
> 각 Phase/마일스톤 완료 시 해당 작업에 필요한 리소스가 추가된다.
> **파일을 해당 폴더에 넣으면 코드 수정 없이 바로 반영됨.** 없으면 fallback(플레이스홀더)으로 동작.
>
> **UI 관련 상위 문서**: [ui_design_master.md](ui_design_master.md) 참조.
> 본 문서는 Phase별 필요 에셋의 규격/파일명을, 상위 문서는 UI 카테고리별 컨셉·연출을 담당한다.
> UI 관련 에셋 선정은 상위 문서의 카테고리 결정을 따른다.

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

---

## Phase 2-8a. 거점 씬 (회복, 세이브)

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 29 | 거점 배경 | 640x360 | `assets/backgrounds/` | `bg_test_checkpoint.png` | 따뜻하고 안전한 느낌. 앰버/갈색 톤. 현재 어두운 갈색 ColorRect placeholder |
| 30 | 거점 바닥 타일 | 64x64, 반복 사용 | `assets/tiles/` | `tile_ground_test.png` | 기존 #1과 동일 에셋 공유 |
| 31 | 휴식 마커 (거점 표식) | 64x64 | `assets/sprites/objects/` | `obj_rest_marker.png` | 모닥불/이정표/빛 기둥 등. 거점임을 시각적으로 표시. 현재 황금색 ColorRect placeholder |

### 거점 배경 제작 가이드

**컨셉**: 안전 구역 — 적이 없고, 시간이 멈춘 평화로운 공간
- 색감: 따뜻한 앰버/갈색 (어두운 숲 스테이지와 대비)
- 느낌: 나무 사이로 따뜻한 빛이 비치는 공터, 또는 오래된 석조 쉼터
- placeholder 색상: `#261F14` (어두운 따뜻한 갈색)

### 휴식 마커 제작 가이드

**컨셉**: 거점의 중앙에 위치하는 상호작용 오브젝트
- 후보: 작은 모닥불, 빛이 새어나오는 이정표, 또는 빛의 기둥
- 크기: 48x40 실효 크기 (64x64 캔버스 내)
- 현재 위치: (296, 288) ~ (344, 328) — 맵 중앙 하단
- 애니메이션: 선택 사항 (모닥불이면 4프레임 루프 권장)
- placeholder 색상: `#CCB266` (황금/탄색)

**적용 방법**:
- `test_checkpoint.gd`에 fallback 로직 이미 포함 (배경/바닥 타일)
- 휴식 마커는 현재 ColorRect — 아트 적용 시 `TestCheckpoint.tscn`의 RestMarker를 Sprite2D로 교체

**기존 에셋 재사용**:
- 바닥 타일 (`tile_ground_test.png`)은 기존 에셋 공유
- 포탈 이펙트 (`portal_stage.png`)도 기존 에셋 동일 사용
- 새로 필요한 것은 **배경 1장 + 휴식 마커 1장**

**우선순위**: 낮음 (placeholder로 기능 테스트 가능. 거점 아트 방향성 확정 후 적용)

---

## Phase 2-1. 전투 확장 (스킬 시스템)

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 36 | 스킬 슬롯 UI 프레임 | 20x20, 1프레임 | `assets/ui/` | `ui_skill_slot.png` | 4슬롯 배경 프레임. 현재 ColorRect fallback 동작 중 |
| 37 | 빛 베기 이펙트 | 64x64, 4프레임, 가로 256x64 | `assets/sprites/effects/` | `fx_light_slash.png` | melee 스킬 이펙트. **코드 연결 미완** (Phase 3 아트 적용 시) |
| 38 | 그림자 강타 이펙트 | 96x96, 4프레임, 가로 384x96 | `assets/sprites/effects/` | `fx_shadow_strike.png` | aoe 스킬 이펙트. **코드 연결 미완** (Phase 3 아트 적용 시) |

---

## Phase 2-3a. 땅거미 시스템

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 32 | 땅거미 스프라이트 시트 | 192x192 캔버스, 가로 스트립 (37프레임) | `assets/sprites/enemies/` | `dusk_spider.png` | 특수 적. 일반 적(64~128)보다 큰 캔버스. 6개 애니메이션 태그 통합 시트 |
| 33 | 접근 경고 이펙트 | 64x64, 가로 스트립 (4프레임) | `assets/sprites/effects/` | `fx_spider_warning.png` | 땅거미 접근 시 HUD에 표시. 어두운 보라/검정 파동. 256x64 PNG. **코드 연결 완료** (dusk_spider_hud.gd — fallback ColorRect 동작 중) |
| 34 | 등장 웅덩이 이펙트 | 128x64, 가로 스트립 (4프레임) | `assets/sprites/effects/` | `fx_spider_pool.png` | emerge 애니메이션과 동기화. 바닥 그림자 웅덩이. 512x64 PNG |
| 35 | 사망 잔류 이펙트 | 64x64, 단일 프레임 | `assets/sprites/effects/` | `fx_spider_residue.png` | 처치 후 남는 큰 그림자 얼룩. 일반 잔류 마커(32x8)보다 큼 |

### 땅거미 스프라이트 시트 제작 가이드

**컨셉**: 그림자 자체가 형태를 이룬 거대한 거미. 특정 오브젝트에서 유래하지 않은 순수한 어둠의 존재.

**캔버스 192x192 선택 이유**:
- 일반 적 중 가장 큰 나무 적(128x128)보다 한 단계 큰 특수 적
- 6~8개 다리의 모션에 충분한 여백 필요
- 실효 크기는 약 128x128, 나머지는 다리/안개 모션 영역

**색상 팔레트** (극도로 어두운 색감):
- 본체: `#0A0A12` ~ `#1E1E35` (거의 검정에 가까운 남색)
- 다리: `#0D0D1A` → 끝부분 `#1A0028` (보라빛으로 소멸)
- 눈: `#8B2FC6` (보라 발광) / 공격 시 `#CC3333` (붉은 빛)
- 안개: `#0D0015`, 투명도 40~60%

**애니메이션 태그**:

| 태그명 | 프레임 수 | FPS | 루프 | 설명 |
|---|---|---|---|---|
| `idle` | 6 | 8 | O | 대기. 본체 맥동 + 다리 미세 움직임 |
| `crawl` | 6 | 8 | O | 이동. 다리 교차 보행 |
| `emerge` | 8 | 10 | X | **스폰 등장**. 바닥 그림자에서 솟아오름. 가장 인상적이어야 함 |
| `attack` | 6 | 10 | X | 앞다리 내려찍기. 눈 붉게 전환 |
| `hurt` | 3 | 10 | X | 피격. 본체 흩어짐 + 보라빛 플래시 |
| `dead` | 8 | 8 | X | 사망. 다리부터 분해 → 본체 폭발 소멸 |

**Aseprite 내보내기**:
```
파일 → Export Sprite Sheet
  → Layout: Horizontal Strip
  → 모든 태그 통합 (또는 태그별 별도 내보내기)
  → Canvas: 192x192
  → Output: assets/sprites/enemies/dusk_spider.png
```

**현재 상태**: 땅거미는 논리적 데이터 객체(DuskSpiderEntity)로만 존재. 스테이지 내 비주얼/전투 엔티티 구현 시 fallback(ColorRect)으로 동작 예정.

> 상세 명세: `docs/art_specs/dusk_spider_art_spec.md` 참조

**우선순위**: 32번(메인 시트) > 33번(접근 경고) > 34번(등장 웅덩이) > 35번(사망 잔류)

---

## Phase 2-5a. 환경 오브젝트 — 거울

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 57 | 거울 본체 | 64x64 캔버스 (실효 24x40) | `assets/sprites/objects/mirror/` | `mirror_body.png` | 마름모 형태. 기본 자세 1장(우향 0°), Godot rotation으로 4방향 처리. 현재 Polygon2D fallback (마름모, 색 #BFD0E0) |
| 58 | 거울 빔 (정적) | 160x160 캔버스 (60° 부채꼴, 반경 128) | `assets/sprites/objects/mirror/` | `mirror_beam_static.png` | STOPPED 상태 부채꼴 영향권 시각화. 노란 반투명. 현재 Polygon2D fallback (#FFF266, alpha 0.2) |
| 59 | 거울 빔 (흐름 중) | 160x160 캔버스, 4프레임 루프 | `assets/sprites/objects/mirror/` | `mirror_beam_flowing.png` | FLOWING 중 약한 펄스 애니메이션. 비활성/활성 차별화 |
| 60 | 분열 발동 플래시 | 96x96 캔버스, 6프레임 비루프 | `assets/sprites/effects/` | `fx_mirror_flash.png` | FLOWING 진입 순간 거울에서 발생 |
| 61 | 분열 버스트 | 128x128 캔버스, 6프레임 비루프 | `assets/sprites/effects/` | `fx_shatter_burst.png` | 분열되는 적 위치에서 발생. 그림자 파편 흩뿌림 |
| 62 | 환경 오브젝트 하이라이트 | 48x64 캔버스 | `assets/ui/` | `env_highlight.png` | 선택된 환경 오브젝트 테두리. 노란색 1~2px 외곽선. 현재 Line2D fallback |
| 63 | E키 프롬프트 아이콘 | 24x24 캔버스 | `assets/ui/` | `prompt_key_e.png` | 상호작용 프롬프트의 E키 아이콘. 현재 Label "[E]" fallback |

### 거울 아트 제작 가이드

**컨셉**: "시간이 멈춘 숲에 남겨진 오래된 손거울/수정" — 고대 유물 느낌, 세로 마름모 형태, 매끈한 은빛/하늘색 반사면 (#BFD0E0)

**방향성**: 기본 자세(0°) = 부채꼴이 **오른쪽**을 향할 때 기준으로 제작. 상/하/좌 방향은 Godot rotation 프로퍼티로 처리.

**Aseprite 내보내기**:
```
파일 → Export Sprite Sheet
  → Layout: Horizontal Strip (애니메이션의 경우)
  → Output: assets/sprites/objects/mirror/mirror_body.png (등)
```

**Fallback 현황** (Phase 2-5a 완료):
- 본체: `MirrorBody` Polygon2D 마름모 (-12,0)~(+12,0)~(0,±20)
- 빔: `BeamVisual` Polygon2D 60° 부채꼴 (반경 128)
- 하이라이트: `environment_highlight.gd` Line2D 40×56 노란 테두리
- 프롬프트: `environment_prompt.gd` Label "[E] 거울 회전"

**우선순위**: 60(분열 플래시 — 가장 임팩트 큼) > 61(분열 버스트) > 57(본체) > 58(빔 정지) > 59(빔 흐름) > 62~63(UI 폴리시)

> 상세 명세: `docs/art_specs/environment_mirror_art_spec.md`

---

## Phase 2-2. 적 확장 (행동 차별화)

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 36 | 돌기둥 투사체 | 16x12 (또는 가로 스트립 4프레임 회전) | `assets/sprites/effects/` | `enemy_projectile_stone.png` | 돌 파편. 비행 방향 우향 기준. 좌향은 코드로 flip_h |
| 37 | 꽃 분열체 스프라이트 | 64x64 캔버스, 원본 꽃의 70% 크기 | `assets/sprites/enemies/` | `flower_spore.png` | 작은 꽃 포자. Idle/Move/Attack 태그 |
| 38 | 나무 범위 공격 이펙트 | 96x48 가로 스트립 4프레임 | `assets/sprites/effects/` | `fx_tree_sweep.png` | 호형 슬래시 이펙트. 반투명 녹/갈색 |
| 39 | 바위 데미지 감산 피드백 | 32x32 가로 스트립 3프레임 | `assets/sprites/effects/` | `fx_block_spark.png` | 반짝 이펙트. 회색/흰색 |
| 40 | 분열 연출 파티클 | 32x32 가로 스트립 4프레임 | `assets/sprites/effects/` | `fx_flower_burst.png` | 포자 흩뿌림. 핑크/흰색 |
| 41 | 투사체 소멸 파티클 | 16x16 가로 스트립 3프레임 | `assets/sprites/effects/` | `fx_stone_puff.png` | 먼지. 회색 반투명 |

### Phase 2-2 아트 우선순위

1. **36, 37** (투사체, 분열체) — 실제 전투 체감에 직결
2. **38** (나무 범위) — 히트박스 가시화 (플레이어 회피 학습 보조)
3. **40, 41** (연출 파티클) — 폴리싱
4. **39** (바위 방어 피드백) — "BLOCK" 텍스트 대체

### Fallback 현황

- 투사체: `EnemyProjectile.tscn`의 `FallbackVisual` ColorRect 8x6 회색갈(#9988 ish)
- 꽃 분열체: `BaseEnemy.tscn` 기본 fallback 재사용 (collision 14x14)
- 나머지: 이펙트 없이 동작, 데미지 넘버로만 피드백

---

## Phase 2-5b. 환경 오브젝트 — 차폐물 (빛 차단, ✅ 구현 완료)

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 64 | 차폐물 본체 | 64x64 캔버스 (실효 24x64) | `assets/sprites/objects/cover/` | `cover_body.png` | 세로 긴 석판. 좌우 대칭, 단일 프레임. 현재 ColorRect fallback (24×64, #5A4D48) |
| 65 | 차폐물 투영 영역 (정적) | 96x32 캔버스 | `assets/sprites/objects/cover/` | `cover_projection_static.png` | 본체 뒤쪽 그림자 투영 영역 시각화. 어두운 반투명 영역. 현재 ColorRect fallback (#0C0C19 alpha 0.35) |
| 66 | 차폐물 투영 영역 (흐름 중) | 96x32, 4프레임 루프 | `assets/sprites/objects/cover/` | `cover_projection_flowing.png` | FLOWING 중 영역 내 적이 override 받는 동안 미세 파동 애니메이션 |

### 제작 가이드

**컨셉**: 빛/그림자 빔을 물리적으로 막는 고대 석판. 거울과 동일 세계관이지만 "차단" 역할 — 표면이 단단하고 불투명. 플레이어가 직접 위치를 밀어 배치하는 "수동 도구" 느낌.
- 본체 색상: 어두운 회색/짙은 갈색 톤 (#5A4D48 계열, 이끼 #4A5A30 액센트)
- 본체 형태: 세로 직사각 석판(24×64). 거울과 대비되도록 회전 모션 없음 (정적, 좌우 이동만)
- 방향성: 좌우 대칭 → flip 불필요
- 투영 영역: 본체 기준 앞쪽(빛 반대 방향) 96×32 직사각형. 회전은 Godot에서 `shadow_direction` 기반으로 적용되므로 스프라이트는 0° 기준 1장

**Fallback 현황 (Phase 2-5b 완료)**:
- 본체: `BodyVisual` ColorRect `body_size(24×64)`, `body_color(#5A4D48)` — `cover_data.tres`에서 조정
- 투영 영역: `ProjectionVisual` ColorRect 96×32, 색 #0C0C19 alpha 0.35. 회전은 `ShadowProjectionZone.rotation` 으로 통합 처리
- 하이라이트: `environment_highlight.gd` Line2D 40×56 노란 테두리 (거울과 공용)
- 프롬프트: `environment_prompt.gd` Label "[E] 차폐물 밀기"

**우선순위**: 64(본체) > 65(정적 투영) > 66(흐름 중 투영)

---

## Phase 2-5c. 환경 오브젝트 — 렌즈 (빛 집중)

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 67 | 렌즈 본체 | 64x64 캔버스 (실효 40x40) | `assets/sprites/objects/lens/` | `lens_body.png` | 원형 유리 렌즈. 투명한 중앙 + 금속 테두리 |
| 68 | 집중 빔 (정적) | 256x96 (원뿔 수렴) | `assets/sprites/objects/lens/` | `lens_beam_static.png` | 넓은 입구 → 좁은 출구. 노란 반투명 |
| 69 | 집중 빔 (흐름 중) | 256x96, 4프레임 루프 | `assets/sprites/objects/lens/` | `lens_beam_flowing.png` | FLOWING 중 강한 집광 펄스 |
| 70 | 집광점 고열 이펙트 | 32x32, 6프레임 루프 | `assets/sprites/effects/` | `fx_lens_focus.png` | 빔이 수렴하는 지점의 번쩍임. 흰색 코어 + 노란 할로 |

### 제작 가이드

**컨셉**: 빛을 한 점으로 모으는 고대 광학 장치. 거울(분산) 대비 렌즈(집중)의 역할 차이를 시각적으로 명확히.
- 본체 색상: 금속 테두리 #8B7A4A + 유리 #D0E8F0 (거의 투명)
- 빔: 거울보다 더 진한 노랑 → 수렴점에서 흰색으로 (열감 표현)
- 방향성: 입구는 좌, 출구는 우 기준. 상/하/좌는 Godot rotation

**우선순위**: 70(수렴점 — 가장 임팩트 큼) > 67(본체) > 68~69(빔)

---

## Phase 2-5d. 환경 오브젝트 — 반사 바닥

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 71 | 반사 바닥 타일 | 64x32 (가로 긴 타일) | `assets/tiles/` | `tile_reflective_floor.png` | 매끄러운 수면/얼음 느낌. 반복 타일링 |
| 72 | 반사 영역 오버레이 | 640x64, 가로 반복 | `assets/sprites/effects/` | `fx_reflection_overlay.png` | 반사 효과를 부각하는 반투명 하이라이트 |
| 73 | 수면 파동 이펙트 | 64x32, 6프레임 루프 | `assets/sprites/effects/` | `fx_water_ripple.png` | 플레이어가 지나갈 때 발생. 동심원 퍼짐 |
| 74 | 수면 반사 왜곡 노이즈 | 256x256 타일링 | `assets/sprites/effects/` | `noise_water_distort.png` | shader로 UV 왜곡. 그레이스케일 |

### 제작 가이드

**컨셉**: 연못/석재 타일/얼음 등 반사 재질. 플레이어/적의 그림자·실루엣을 반사해 분위기 강화.
- 타일 색상: 짙은 청록 #2A4A5A (수면) 또는 라이트 블루 #7AA8C0 (얼음) — 스테이지 분위기 따라
- 반사 대상(플레이어/적) 스프라이트는 코드에서 flip_v + alpha 0.4 자식 Sprite2D로 처리
- shader UV 왜곡: 노이즈 텍스처 × time으로 미세한 물결

**구현 방식** (참고): 반사된 Sprite2D 자식 + shader로 UV를 `noise_water_distort.png` 샘플링해 미묘하게 흔듦. 코드는 다른 세션에서 구현 중.

**우선순위**: 71(타일 — 반드시) > 73(파동 — 인터랙션 피드백) > 72, 74(폴리싱)

---

## Phase 2-7. 아이템 시스템 아트

### 아이템 인벤토리 아이콘

> 현재 6개 아이템 정의가 `data/items/`에 있으나 아이콘 없음. Label "[아이템명]" fallback으로 동작.

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 75 | 무기 아이콘 — 기본 검 | 32x32 | `assets/ui/items/` | `icon_sword_basic.png` | 단순 철검 실루엣 |
| 76 | 무기 아이콘 — 단검 | 32x32 | `assets/ui/items/` | `icon_dagger.png` | 짧은 날 |
| 77 | 방어구 아이콘 — 가죽 갑옷 | 32x32 | `assets/ui/items/` | `icon_armor_leather.png` | 흉갑 형태 |
| 78 | 장신구 아이콘 — 반지 | 32x32 | `assets/ui/items/` | `icon_ring_basic.png` | 원형 반지 |
| 79 | 소모품 아이콘 — HP 포션 | 32x32 | `assets/ui/items/` | `icon_potion_hp.png` | 빨간 액체 플라스크 |
| 80 | 소모품 아이콘 — 시간자원 포션 | 32x32 | `assets/ui/items/` | `icon_potion_time.png` | 청백색 액체 플라스크 |

### 제작 가이드

**공통 규칙**:
- 32x32 캔버스, 실효 크기 24x24 (여백 4px)
- 정면 뷰, 투명 배경
- 등급별 테두리는 **코드에서 동적 적용** (일반=흰 #FFFFFF / 희귀=파랑 #4A9FD8 / 유니크=보라 #B066E0) — 아이콘 자체에는 테두리 불필요
- 스타일: 중세 판타지 — 과하게 사실적이지 않고 픽셀아트 실루엣 중심

**우선순위**: 79~80(소모품 — 자주 사용) > 75~76(무기) > 77~78(방어구/장신구)

### 드롭 월드 스프라이트

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 81 | 아이템 드롭 (일반) | 16x16, 2프레임 루프 | `assets/sprites/objects/` | `drop_item_common.png` | 바닥에 떨어진 빛 포장. 미세 bob 애니메이션 |
| 82 | 아이템 드롭 글로우 (희귀) | 32x32, 4프레임 루프 | `assets/sprites/effects/` | `fx_drop_glow_rare.png` | 드롭 주위 파란 발광. 아이템 뒤 레이어 |
| 83 | 아이템 드롭 글로우 (유니크) | 48x48, 4프레임 루프 | `assets/sprites/effects/` | `fx_drop_glow_unique.png` | 드롭 주위 보라 발광. 더 강함 |

### 제작 가이드

**컨셉**: 적 처치 시 바닥에 떨어지는 시각적 표현. 아이콘과 다른 "월드 표현" — 자연스럽게 숲에 녹아드는 느낌.
- 일반 드롭: 갈색 가죽 주머니 또는 단순 포장. 색은 #8B6F3A
- 희귀/유니크: 본체는 동일, 주위 글로우로만 차별화 → 아이콘 등급과 시각 언어 일치

**우선순위**: 81(기본) > 83(유니크 희소성 강조) > 82(희귀)

### 상점 NPC

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 84 | 상점 NPC 스프라이트 시트 | 128x128 캔버스, 3~4 태그 | `assets/sprites/npcs/` | `npc_shopkeeper.png` | idle/talk/wave 태그. 로브 착용 상인 |
| 85 | 상점 UI 프레임 | 480x270 (화면 중앙 패널) | `assets/ui/` | `ui_shop_frame.png` | 양피지/나무 텍스처 배경 프레임 |
| 86 | 화폐 아이콘 | 16x16 | `assets/ui/` | `icon_currency.png` | 코인/수정 파편 등 (화폐 종류는 Phase 5 결정) |

### 제작 가이드

**NPC 컨셉**: 거점에 상주하는 "시간이 멈춘 숲에 남은 마지막 상인". 후드 로브, 짐꾸러미, 차분한 분위기.
- 애니메이션 태그: `idle`(4프레임 루프), `talk`(4프레임, 대화 중), `wave`(4프레임, 인사 비루프)
- 색상: 낡은 갈색 로브 #5A4A30 + 후드 그림자 #2A2015

**우선순위**: 84(NPC) > 85(UI 프레임) > 86(화폐 — Phase 5까지 보류 가능)

---

## Phase 2-1 / 2-6. 스킬 아이콘 (18종)

> 스킬 슬롯 UI는 Phase 2-1 #36으로 이미 명시됨. 여기는 **각 스킬 데이터의 아이콘** 명세.
> 현재 스킬 트리는 프레임워크만 존재. 구체 18종 리스트는 `docs/SKILLS.md` 참조.

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 87 | 빛 계열 스킬 아이콘 (6종) | 32x32 x 6 | `assets/ui/skills/` | `skill_light_01.png` ~ `_06.png` | 흰색/금색 톤. 개별 파일 6개 |
| 88 | 그림자 계열 스킬 아이콘 (6종) | 32x32 x 6 | `assets/ui/skills/` | `skill_shadow_01.png` ~ `_06.png` | 보라/검정 톤. 개별 파일 6개 |
| 89 | 혼합 계열 스킬 아이콘 (6종) | 32x32 x 6 | `assets/ui/skills/` | `skill_hybrid_01.png` ~ `_06.png` | 빛+그림자 이분할 톤. 개별 파일 6개 |
| 90 | 스킬 미잠금 상태 오버레이 | 32x32, 반투명 | `assets/ui/skills/` | `skill_locked.png` | 자물쇠 또는 회색 오버레이. 모든 아이콘 위에 덮임 |

### 제작 가이드

**공통 규칙**:
- 32x32 캔버스, 실효 24x24
- 계열별 색상 팔레트 강제 (플레이어 학습성)
  - 빛: 중심 흰색 #FFFFFF, 외곽 금색 #F2CC66
  - 그림자: 중심 보라 #8B2FC6, 외곽 검정 #1A0028
  - 혼합: 좌우 또는 상하 이분할 (빛+그림자 팔레트 혼용)
- 스킬명은 아이콘에 쓰지 않음 — 툴팁으로 처리

**18종 구체화는 보류**: Phase 3 콘텐츠 단계에서 스킬 효과가 확정된 후 아이콘 디자인. 현재는 수량과 규격만 명세.

**우선순위**: 90(미잠금 오버레이 — 구조적 필수) > 87~89(계열별, 콘텐츠 확정 후)

---

## Phase 2-8b. 월드맵 UI

> 월드맵은 거점에서 열리는 풀스크린 UI. 현재 ColorRect placeholder로 동작.

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 91 | 월드맵 배경 | 1280x720 (2x 해상도) | `assets/ui/world_map/` | `world_map_bg.png` | 오래된 양피지 또는 숲 조감도. 전체 1구역 지도 |
| 92 | 노드 — 스테이지 | 24x24, 3 상태 | `assets/ui/world_map/` | `node_stage.png` | 가로 스트립: 미클리어 / 클리어 / 현재. 72x24 |
| 93 | 노드 — 거점 | 24x24, 3 상태 | `assets/ui/world_map/` | `node_checkpoint.png` | 거점 전용 — 불/쉼터 아이콘 |
| 94 | 노드 — 보스 | 32x32, 3 상태 | `assets/ui/world_map/` | `node_boss.png` | 보스방은 더 큰 아이콘. 미처치/처치/현재 |
| 95 | 노드 — 잠금 | 24x24, 단일 프레임 | `assets/ui/world_map/` | `node_locked.png` | 자물쇠 아이콘. 잠긴 노드 위 오버레이 |
| 96 | 현재 위치 마커 | 32x32, 4프레임 루프 | `assets/ui/world_map/` | `marker_current.png` | 펄스/회전하는 표시. 현재 위치 강조 |
| 97 | 연결선 — 해금 | 8x8, 점선 타일 | `assets/ui/world_map/` | `line_unlocked.png` | 노드 간 연결선. 밝은 색 |
| 98 | 연결선 — 잠금 | 8x8, 점선 타일 | `assets/ui/world_map/` | `line_locked.png` | 흐린 회색. 잠긴 경로 |
| 99 | 분기 안내 아이콘 | 16x16 | `assets/ui/world_map/` | `icon_branch.png` | 분기점 표시. 선택 가능한 경로 안내 |

### 제작 가이드

**컨셉**: "숲 지도를 펼쳐본다" — 양피지 위에 손글씨로 그려진 느낌. 추상적 노드 배치 (실제 스테이지 좌표와 1:1 아님).

**노드 3상태 시각 언어**:
- 미클리어: 회색 테두리, 반투명 내부
- 클리어: 금색 테두리, 밝은 내부
- 현재: 테두리 위에 #96 마커 중첩 (펄스)

**연결선**: 8x8 점선 타일을 노드 간 경로에 따라 타일링. 해금된 경로만 밝게 표시.

**우선순위**: 96(현재 위치 — 필수) > 92~95(노드) > 91(배경) > 97~99(폴리싱)

---

## Phase 1 리메이크 — 플레이어 보강

> 기존 `player_spritesheet.png`은 64x64 캔버스(구 규격). 확장된 액션에 대응하려면 128x128로 리메이크 필요.

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 100 | 플레이어 idle (128x128) | 128x128, 4프레임 루프 | `assets/sprites/player/` | `player_idle.png` | 기존 64x64 → 128x128. 대기 모션 강화 (숨쉬기, 등불 흔들림) |
| 101 | 플레이어 run (128x128) | 128x128, 6프레임 루프 | `assets/sprites/player/` | `player_run.png` | 기존 64x64 → 128x128. 등불 손에 든 자세 |
| 102 | 플레이어 hurt | 128x128, 3프레임 비루프 | `assets/sprites/player/` | `player_hurt.png` | 피격 리액션. 뒤로 밀림 + 한 손 방어 자세 |
| 103 | 플레이어 death | 128x128, 6프레임 비루프 | `assets/sprites/player/` | `player_death.png` | 쓰러짐. 등불 바닥에 떨어져 흔들림 |
| 104 | 플레이어 interact | 128x128, 4프레임 비루프 | `assets/sprites/player/` | `player_interact.png` | 환경 오브젝트 조작 / 아이템 줍기 공통 |

### 제작 가이드

**128x128 재설계 이유**:
- 기존 64x64는 세부 표현 제약 (등불, 머리카락, 의상)
- 128x128로 확장해 여백 활용 (베기 궤적, 대시 애프터이미지 등이 스프라이트 내에서 가능)
- 실효 캐릭터 크기는 64x64 유지 (충돌 박스 변경 없음) — 나머지는 모션 여백

**등불 통합**: 플레이어가 항상 왼손에 등불을 든 자세. 별도 Sprite2D 자식으로 분리하는 대신 플레이어 스프라이트에 포함 → 애니메이션마다 등불 위치 자연스러움 보장. 단, 등불 라이트 자체는 별도 PointLight2D 자식.

**기존 에셋 처리**: 기존 `player_spritesheet.png`는 유지 (fallback). 신규 128x128 파일이 있으면 `player_character.gd`에서 우선 사용 (코드 수정 필요).

**Aseprite 내보내기**:
```
파일 → Export Sprite Sheet
  → Layout: Horizontal Strip
  → Tag별 별도 내보내기: idle / run / hurt / death / interact
  → Canvas: 128x128
  → Output: assets/sprites/player/player_idle.png (등)
```

**우선순위**: 102~103(hurt/death — 피격 피드백 필수) > 100~101(idle/run 리메이크) > 104(interact)

---

## Phase 1-5 / 2-2. 적 상태 완성

> 현재 4종 적(나무/바위/꽃/돌기둥)은 idle/walk/run/attack만 구현된 fallback 동작 중.
> ART_RESOURCE_LIST.md Phase 1-5 #13~16 명세에는 hurt/dead 태그가 있으나 아직 미제작.

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 105 | 나무 적 — hurt | 128x128, 2프레임 비루프 | `assets/sprites/enemies/` | `enemy_tree_hurt.png` | 피격 플래시 + 가지 떨림. 기존 `enemy_tree.png`에 태그 통합 가능 |
| 106 | 나무 적 — dead | 128x128, 4프레임 비루프 | `assets/sprites/enemies/` | `enemy_tree_dead.png` | 그림자 분해 소멸 |
| 107 | 바위 적 — hurt/dead | 96x96, 2+4프레임 | `assets/sprites/enemies/` | `enemy_rock_hurt.png`, `_dead.png` | 균열 → 부서짐 |
| 108 | 꽃 적 — hurt/dead | 64x64, 2+4프레임 | `assets/sprites/enemies/` | `enemy_flower_hurt.png`, `_dead.png` | 꽃잎 흩어짐 |
| 109 | 돌기둥 적 — hurt/dead | 64x128, 2+4프레임 | `assets/sprites/enemies/` | `enemy_pillar_hurt.png`, `_dead.png` | 기울어짐 → 붕괴 |
| 110 | 꽃 분열체 전용 시트 | 64x64, 원본 70% | `assets/sprites/enemies/` | `flower_spore.png` | Phase 2-2 #37 명세. idle/move/attack 태그 (현재 BaseEnemy fallback) |

### 제작 가이드

**통합 또는 분리 선택**:
- **방안 A (권장)**: 기존 `enemy_tree.png` 등 메인 시트에 hurt/dead 태그 추가 재내보내기 → 파일 수 최소화
- **방안 B**: 위 표처럼 별도 파일 → 파일은 많지만 수정 영향 범위 좁음

**공통 규칙**:
- hurt: 흰색 플래시 오버레이는 **shader로 처리** (아트는 순수 실루엣). 아트에는 미세한 "밀림" 모션만
- dead: 공통 언어 — "그림자 분해 소멸"
  - 나무/꽃/돌기둥: 잎/꽃잎/파편이 흩어지며 투명화
  - 바위: 균열 → 조각화
- 마지막 프레임 후 잔류 마커(#17)로 전환 (코드 처리)

**Aseprite 내보내기** (방안 A):
```
기존 enemy_tree.aseprite 열기
  → 새 태그 추가: hurt, dead
  → 프레임 작업
  → Export Sprite Sheet (기존 파일 덮어쓰기)
```

**우선순위**: 108 (꽃 — 가장 자주 등장) > 105~107 (나머지 4종) > 110 (꽃 분열체 — 기능 동작 중이라 후순위)

---

## Phase 3-7. HUD 시간 코어 (B 카테고리 — UI 설계 마스터 확정)

> 설계 문서: `docs/art_specs/ui_design_master.md` 섹션 B (B-5/B-6/B-7, v0.14~0.17 확정)
> 우상단 "시간 코어" 한 덩어리: 해·달 궤도 시계 + 일식 링 + 전파 배지
> **#48 `hud_clock.png`를 대체**. 기존 placeholder 폐기.

### B-5. 해·달 궤도 시계 (32×32)

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 111 | 궤도 시계 외곽 링 | 32x32 | `assets/ui/hud/` | `hud_time_clock_ring.png` | 금속질 다크브라운 `#1A1410` 2px 링. 상태별 modulate 색(금/시안/금↔시안 보간)으로 재사용. STOPPED 시 1초 주기 미세 펄스 |
| 112 | 해 (태양) 발광 루프 | 8x8, 4프레임 루프 | `assets/ui/hud/` | `hud_time_sun.png` | 궤도 내부에서 회전 위치 이동. 금색 `#F2CC66` 발광 원. 회전 위치는 코드(각도 계산) |
| 113 | 달 (초승달) 발광 루프 | 8x8, 4프레임 루프 | `assets/ui/hud/` | `hud_time_moon.png` | 해와 180° 대립 위치. 시안 `#A8D8D0` 초승달 형태. 발광 루프 동일 |

### B-6. 일식 링 시간 자원 게이지 (40×40)

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 114 | 자원 링 베이스 | 40x40 | `assets/ui/hud/` | `hud_time_gauge_ring.png` | 외곽 3px 링(금 `#F2CC66`). shader로 시계방향 아크 마스킹. 외곽 1px 여백 포함 |
| 115 | 자원 링 그림자 잠식 레이어 | 40x40 | `assets/ui/hud/` | `hud_time_gauge_shadow.png` | 동일 40×40. 그림자 `#1A1410`. shader로 잠식 영역 마스킹. 0%=완전 일식 |
| 116 | 자원 링 경고 오버레이 | 40x40 | `assets/ui/hud/` | `hud_time_gauge_warning.png` | 붉은 `#B83A3A` 오버레이. 20% 이하 시 1초 주기 맥동(modulate로 재사용). STOPPED 시 50% dim |

### B-7. 전파 배지 (10×10)

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 117 | 전파 상태 홉 도트 배지 | 10x10, 5프레임 | `assets/ui/hud/` | `hud_propagation_badge.png` | 프레임 1=원점 금 도트 1개 `#F2CC66` / 2=전파 1홉 보라 도트 2개 `#8B2FC6` / 3=2홉 3개 / 4=3홉 4개 / 5=3홉+ dim. flow 없음 시 전체 숨김 |

### 제작 가이드

**공통 원칙**:
- 플레이어 HUD → **이중 축 원칙 (빛/그림자 우선)** 준수. 숲 모티프 0.
- 우상단 배치 좌표 (640×360 기준):
  - 시간 코어 외곽(일식 링 포함): (588, 12) ~ (628, 52)
  - 전파 배지: (603, 57) ~ (613, 67)
  - 땅거미 경고 HUD(기존 #33): **C 카테고리 진입 시 좌표 재확정 예정** — 시간 코어 좌측

**B-5 궤도 시계**:
- 궤도 회전은 **코드 처리** (각도 계산, 프레임 불필요)
- 링(#111)은 modulate로 상태 색 전환: FLOWING=`#F2CC66` / STOPPED=`#A8D8D0` / MANIPULATING=보간
- 해(#112)·달(#113)은 각자 발광 호흡만 담당, 위치는 코드
- 낮↔밤 전환 시 링 modulate 0.3초 보라/금 플래시

**B-6 일식 링**:
- 아크 마스크 **셰이더 1종** 필요 (자원 퍼센트 → 아크 각도)
- `ring`(빛) + `shadow`(잠식) 2레이어 합성: 자원 N% = shadow가 (100-N)% 시계방향 덮음
- warning(#116)은 modulate 알파 펄스로 저점 경고
- STOPPED 시 링 전체 50% 불투명 dim (내부 B-5 시안 펄스와 시각 간섭 방지)
- FLOWING 중 회복 시 반딧불 파티클은 **기존 `FX_firefly_orb.png` 재사용** (2-12 언어)

**B-7 전파 배지**:
- 5프레임 스프라이트 시트 — 상태별 프레임 전환은 코드
- 원점(프레임 1) ↔ 전파(프레임 2~5) 전환 시 교차 페이드 연출 (0.2초)
- flow 세션 종료 시 배지 전체 페이드 아웃

**Aseprite 내보내기**:
```
aseprite --batch hud_time_clock_ring.ase --sheet hud_time_clock_ring.png --data *.json
aseprite --batch hud_time_sun.ase --sheet hud_time_sun.png --split-tags
(나머지 동일 패턴)
```

**우선순위**: B-5 시계(#111~113) > B-6 일식 링(#114~116) > B-7 배지(#117)
- 시계는 B-6/B-7의 위치 기준이 됨 → 먼저 제작
- B-6은 자원 표시 핵심 기능 → 2순위
- B-7은 전파 상태 보조 → 3순위 (flow 원점이 아니면 숨겨지므로 체감 빈도 낮음)

**Fallback**: 파일 없을 시 코드 fallback(`ColorRect` + 도형 그리기)로 동작 가능. 시각적 완성도만 낮음.

---

## Phase 3-7 이펙트 아트 (1구역 아트 적용과 함께)

> **정책 결정 (2026-04-17)**: 이펙트 관련 아트 에셋은 Phase 3-7 "1구역 아트 적용" 단계에서 1구역 캐릭터/타일/UI 아트와 함께 일괄 제작한다.
> 설계 문서: `docs/EFFECTS.md` (특히 섹션 6 구현 로드맵).
> 아트 디렉션 6가지 선택지는 Phase 3-7 착수 전 확정 필요.
>
> 아래 에셋들은 Phase 3-7에서 Pass 단위로 제작됨. 번호/이름/규격은 그대로 유지.

### Pass 1. 기반 프레임워크 — 아트 불필요 (코드/shader만)

### Pass 4. 땅거미 공포 연출 (비네트/경계 경고)

> `docs/EFFECTS.md` 섹션 3.C, 4 (Tier S).

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 42 | 전역 비네트 (검정) | 640x360, 원형 그라데이션 | `assets/ui/` | `vignette_black.png` | 화면 외곽이 어두워지는 기본 오버레이. blend=Multiply 추천. fallback: 코드 생성 가능 |
| 43 | 땅거미 경고 비네트 | 640x360, 원형 그라데이션 | `assets/ui/` | `vignette_dusk_warning.png` | 붉은/보라 계열. 땅거미 거리에 따라 modulate.a 보간. **색상은 아트 디렉션 선택지 #3에 따라 결정** |
| 44 | 화면 경계 경고 프레임 | 640x360, 4변 그라데이션 | `assets/ui/` | `danger_frame.png` | 가장자리만 진한 색 → 중앙 투명. 근접 시 펄스/떨림 적용 |

### 제작 가이드

**공통**: 픽셀아트가 아니어도 무방 — 화면 오버레이는 부드러운 그라데이션이 자연스러움. Aseprite로 제작 시 안티엘리어싱 허용.

**비네트 원형**: 중심 알파 0 → 외곽 알파 255. 외곽 1/4 영역만 색상 강함.
**4변 그라데이션**: 각 변에서 안쪽 32~64px 폭의 페이드. 중앙 상자 영역은 완전 투명.

**Fallback 동작**: 파일 없을 시 비네트는 코드로 생성 가능(Image.create + 원형 그라데이션 그리기). 아트 추가 시 즉시 반영.

**우선순위**: 42(기반) > 43(땅거미 시각화) > 44(근접 경고)

---

### Pass 2. 전투 타격감

> 설계 문서: `docs/EFFECTS.md` 섹션 3.A, 4 (Tier S #2, #4, A #5).
> 힛 플래시/힛스톱/카메라 쉐이크는 코드·셰이더만 필요(아트 없음).

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 45 | 혈흔 파티클 | 8x8, 3종 변형 | `assets/sprites/effects/` | `particle_blood_01.png` ~ `particle_blood_03.png` | GPUParticles2D 텍스처. 적 타입별 색상은 코드 modulate |
| 46 | 파편/흙 파티클 | 8x8, 3종 변형 | `assets/sprites/effects/` | `particle_debris_01.png` ~ `03.png` | 바위/나무 적 피격 시 |
| 47 | 데미지 비트맵 폰트 (선택) | BitmapFont (.fnt + .png) | `assets/ui/` | `font_damage.fnt` | **아트 디렉션 선택지 #4에서 (A) 선택 시만 필요**. (B) Label+아웃라인 셰이더 선택 시 생략 |

### 제작 가이드

**파티클 텍스처**: 작은 점/얼룩 픽셀아트. 흰색 단색 기본, 코드에서 modulate로 색 변경(피=붉음, 나무=갈색, 바위=회색). 3~5종 랜덤이면 자연스러움.

**비트맵 폰트**: 데미지 숫자 0~9 + 크리티컬용 "!". 8~12px 높이 권장. 선택지 #4 결정 후 제작.

**우선순위**: 45 > 46 > 47 (선택)

---

### Pass 3. 시간 정지 연출

> 설계 문서: `docs/EFFECTS.md` 섹션 3.C, 4 (Tier S #1).
> 전역 포스트프로세스 필터는 셰이더만 필요(아트 없음).

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| ~~48~~ | ~~시계 아이콘 HUD~~ | ~~32x32~~ | ~~`assets/ui/`~~ | ~~`hud_clock.png`~~ | **Superseded by #111~#113 (B-5 해·달 궤도 시계)** — UI 설계 마스터 B 카테고리 확정으로 교체. 단순 시계 placeholder 폐기 (2026-04-18) |
| 49 | 시간 입자 파티클 | 4x4, 3종 | `assets/sprites/effects/` | `particle_timedust_01.png` ~ `03.png` | 정지 중 플레이어 주변만 살아있는 파티클. 청백색 빛 입자. **아트 디렉션 선택지 #1 결정 후 색상 확정** |

### 제작 가이드

**시계 아이콘**: 둥근 시계 실루엣. 시간 정지 중에는 정적. 선택 사항으로 4프레임 회전(해제 직전 빠르게 돌아감) 애니메이션.

**시간 입자**: 매우 작은 점 또는 마름모. 반투명. 선택지 #1의 시간 정지 톤에 맞춤:
- (A) 블루 틴트 선택 시: 파란색 점
- (B) 청백색 하이라이트 선택 시: 흰색+하늘색 점 ← 추천
- (C) 세피아 선택 시: 크림색 점

**우선순위**: 49(메카닉 연출) > 48(HUD 장식)

---

### Pass 5a. UI 감성

> 설계 문서: `docs/EFFECTS.md` 섹션 3.D, 4 (Tier A #6, B #12).

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 50 | 체력 크랙 오버레이 | 640x360 | `assets/ui/` | `hud_hp_crack.png` | HP 20% 이하에서 화면 전체에 실금 오버레이. 알파 채널로 실금만 보이게 |
| 51 | 디졸브 노이즈 텍스처 | 256x256, 타일링 | `assets/ui/` | `overlay_dissolve_noise.png` | 메뉴 전환용. 그레이스케일. shader threshold로 디졸브 효과 |

### 제작 가이드

**크랙 오버레이**: 검은색 얇은 실금. 화면 가장자리에서 중앙으로 퍼지는 방사형 패턴. 투명도는 HP 비율에 따라 코드에서 조절.

**디졸브 노이즈**: 부드러운 펄린 노이즈 또는 셀룰러 노이즈. 타일링 가능해야 함 (상하좌우 이음새 없음). Aseprite 기본 기능 또는 외부 툴로 생성.

**Fallback**: 두 파일 모두 없어도 기능 자체는 코드 fallback으로 동작 가능하지만 시각적 효과 없음.

**우선순위**: 50(체감 큼) > 51(메뉴 전환)

---

### Pass 5b. 환경 분위기

> 설계 문서: `docs/EFFECTS.md` 섹션 3.B, 4 (Tier A #8).

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 52 | 앰비언트 파티클 | 4x4, 4종 | `assets/sprites/effects/` | `particle_ambient_01.png` ~ `04.png` | 반딧불/꽃가루/먼지/낙엽. **아트 디렉션 선택지 #5에서 구체 종류 결정** |
| 53 | 앰비언트 파티클 (밤 전용) | 4x4, 2종 | `assets/sprites/effects/` | `particle_ambient_night_01.png` ~ `02.png` | 선택지 #5에서 밤 전용 유무 결정. 푸른 반딧불 등 |

### 제작 가이드

**선택지 #5 결정 후 구체화**:
- 녹색 반딧불: 작은 녹/황색 원형 발광. 낮/밤 모두 적합
- 흰 꽃가루: 불규칙 작은 얼룩. 낮 시간대
- 갈색 낙엽: 4~8px 잎 실루엣. 바람 방향 고려
- 푸른 반딧불(밤): 차갑고 선명한 파란 발광

**배치**: 카메라 자식 GPUParticles2D로 뒤/앞 레이어 분리. lifetime 길게(6~10s), 낮은 velocity, 약한 중력.

**우선순위**: 52 > 53 (밤 전용은 선택)

---

### Pass 5c. 보스/피니시 컷인 + 검광 스프라이트

> 설계 문서: `docs/EFFECTS.md` 섹션 3.A, 4 (Tier B #7, #10).
> 컷인 블랙바/카메라 연출은 코드만 필요(아트 없음).

| # | 사용처 | 규격 | 폴더 | 파일명 | 비고 |
|---|---|---|---|---|---|
| 54 | 기본 슬래시 트레일 | 64x32, 5프레임 | `assets/sprites/effects/` | `slash_basic.png` | 콤보 1~3타에 얹는 검광. Line2D 대안 또는 보완 |
| 55 | 피니시 슬래시 | 128x64, 8프레임 | `assets/sprites/effects/` | `slash_finish.png` | 콤보 4타(피니시) 전용. **아트 디렉션 선택지 #2에 따라 속성별 파생 제작** |
| 56 | 피니시 슬래시 (속성별) | 128x64, 8프레임 x N | `assets/sprites/effects/` | `slash_finish_light.png`, `_shadow.png`, `_neutral.png` | 선택지 #2에서 (B) 선택 시. 빛=흰, 그림자=보라, 무속성=기본 |

### 제작 가이드

**슬래시 기본 규칙**:
- 오른쪽 방향 기준 제작 (왼쪽은 코드 flip_h)
- 가장자리는 부드러운 페이드 (반투명)
- 비루프 (1회 재생)
- 프레임 간 부드럽게 연결 — 모션 블러 느낌

**속성별 색상** (선택지 #2 → B 선택 시):
- 빛(light): 흰색 + 금빛 글로우
- 그림자(shadow): 보라/검정 + 자주색 테두리
- 혼합(hybrid): 이분할 또는 그라데이션
- 무속성(neutral): 회색/청록색 기본

**Fallback**: 파일 없을 시 기존 Line2D 트레일만으로 동작. 피니시도 기본 공격 모션으로 대체.

**우선순위**: 55(피니시 임팩트) > 54(기본 보강) > 56(속성별 다양화, 여유 있을 때)

---

## Phase 3-7 이펙트 아트 전체 요약

| Pass | 에셋 # | 개수 | 핵심 목적 |
|---|---|---|---|
| Pass 1 | — | 0 | 기반 프레임워크 (코드/shader만) |
| Pass 2 | 45~47 | 3 | 전투 타격감 (파티클, 선택적 폰트) |
| Pass 3 | ~~48~~·49 | 1 | 시간 정지 시각화 (#48 폐기 — B-5 #111~113으로 대체) |
| Pass 4 | 42~44 | 3 | 땅거미 공포 연출 + 비네트 |
| Pass 5a | 50~51 | 2 | UI 감성 (크랙, 디졸브) |
| Pass 5b | 52~53 | 2 | 환경 분위기 (앰비언트 파티클) |
| Pass 5c | 54~56 | 3 | 슬래시 트레일 (기본/피니시/속성별) |
| **합계 (이펙트)** | **42~56** | **14** (#48 폐기) | |
| **B 카테고리 HUD (별도)** | **111~117** | **7** | 우상단 시간 코어 (시계/일식 링/전파 배지) |

**구현 의존성**: 대부분 아트 없이 fallback으로 동작 가능. 아트 추가 시 즉시 반영되도록 코드 측에서 fallback 로직 유지.

**선제 결정 필요** (`docs/EFFECTS.md` 섹션 5 참조):
- 선택지 #1 (시간 정지 톤) → #49 색상 확정
- 선택지 #2 (힛 플래시 색) → #55, #56 속성별 제작 여부
- 선택지 #3 (땅거미 경고 색) → #43 색상 확정
- 선택지 #4 (데미지 넘버 스타일) → #47 폰트 제작 여부
- 선택지 #5 (앰비언트 파티클 종류) → #52, #53 구체 형태
