# 캐릭터/적/보스/광원 아트 명세서 — 템플릿

> **사용법**: 이 파일을 복사해 `<name>_art_spec.md`로 이름 붙이고, 플레이스홀더 `<...>`와 TODO 항목을 채운다.
> **준거 문서**: [../ART_PIPELINE.md](../ART_PIPELINE.md) §6.7 (발광 3레이어 규약) / §5 (명세서 포함 항목)
> **발광 대상인가?** 발광 대상(플레이어/적/보스/광원 오브젝트)이면 §6 발광 레이어 구성 섹션 필수. 환경 타일/UI면 §6 생략 가능.

---

## 1. 캔버스 / 크기 규격

| 항목 | 값 | 비고 |
|---|---|---|
| **캔버스 크기** | **<가로>×<세로>** (예: 128×128) | 프레임당. 모든 애니메이션 공통 |
| **실효 크기** | 약 <가로>×<세로> | 캔버스 중앙 정렬. 나머지는 모션/이펙트 여백 |
| **콜리전 박스** | <W>×<H> | `<scene>.tscn` 값과 일치해야 함 |
| **스프라이트 offset** | `Vector2(<x>, <y>)` | 발끝/기준점이 콜리전 하단에 맞도록 |
| **타일 대비** | 약 <N>타일(64×64) | 세계의 타일 기준과 대비 |
| **앵커** | 하단 중앙 / 중앙 / 상단 중앙 | 대상에 따라 |
| **픽셀 필터** | Nearest (프로젝트 전역) | 보간/안티에일리어싱 금지 |

### 캔버스 크기 선택 근거
<이 캔버스 크기를 택한 이유 — 모션 범위, 이펙트 여백, 타일 대비 등>

---

## 2. 디자인 컨셉

### 전체 느낌
- <한 줄 요약 — "등불을 든 제사장 가문의 후예" 같은>
- <핵심 시각 특징 2~3개>
- <서사적 역할 / 톤>

### 형태 가이드
- <고정된 형태 요소 — 무기, 장신구, 특정 자세 등>
- <대비 요소 — 어디가 밝고 어디가 어두워야 하는지>
- <세계관 모티프 — 숲/빛/그림자 등 어느 축에 속하는가>

### 연출 의도
- <idle에서 보여야 할 미세 모션>
- <피격/공격/특수 상태별 자세 의도>
- <스토리상 중요한 순간의 시각 변화>

---

## 3. 애니메이션 목록

> 모든 프레임은 **<캔버스>×<캔버스>, 가로 스트립(Horizontal Strip)** 으로 내보낸다.
> 태그별로 별도 PNG 파일 권장 (Aseprite `--split-tags` 사용).

### 3.1 필수 애니메이션

| 파일명 | 프레임 수 | 루프 | FPS | 설명 |
|---|---|---|---|---|
| `<name>_idle.png` | 4 | ✅ | 10 | <idle 설명> |
| `<name>_run.png` 또는 `<name>_move.png` | 6 | ✅ | 12 | <이동 설명> |
| `<name>_hurt.png` | 3 | ❌ | 12 | <피격 리액션> |
| `<name>_death.png` | 6 | ❌ | 10 | <쓰러짐> |

### 3.2 공격/특수 (해당 시)

| 파일명 | 프레임 수 | 루프 | FPS | 설명 |
|---|---|---|---|---|
| `<name>_attack_1.png` | <n> | ❌ | 20~24 | <1타 공격> |
| `<name>_telegraph.png` (적/보스) | <n> | ❌ | 10 | <공격 예비 동작> |

**우선순위**: hurt / death (피격 피드백) > idle / move (기본 존재감) > attack > special

---

## 4. 색상 팔레트

### 기본 팔레트
<Aseprite 팔레트 파일 경로 또는 HEX 리스트 — 보통 8~16색>

- 주요 색 1: `#______` (설명)
- 주요 색 2: `#______` (설명)
- 하이라이트: `#______`
- 그림자: `#______`

### 프로젝트 팔레트와의 일관성
- <기존 타일/배경 팔레트와 어떻게 어울리는지>
- <인물 vs 환경 vs 적의 색 구분 원칙>

---

## 5. 파일 구조

### 출력 경로
```
assets/sprites/<category>/<name>/
  <name>_base.png       # 필수
  <name>_core.png       # 발광 대상이면 필수
  <name>_halo.png       # 발광 대상이면 필수
  <name>_idle.png       # 태그별 분리 시
  <name>_run.png
  ...
  <name>_spritesheet.json    # Aseprite --data 출력 (base 기준, 1회)
```

### Aseprite Export 명령
```bash
# base 레이어만
aseprite --batch input.ase --layer "base" --sheet <name>_base.png --data <name>_spritesheet.json

# core/halo 레이어 (발광 대상)
aseprite --batch input.ase --layer "core" --sheet <name>_core.png
aseprite --batch input.ase --layer "halo" --sheet <name>_halo.png

# 태그별 분리가 필요하면 --split-tags 추가
```

---

## 6. 발광 레이어 구성 (§6.7 규약)

> **발광 대상인가?** 예 / 아니오

발광 대상이 **아닌** 경우(환경 타일, UI 등): 이 섹션 삭제.
발광 대상인 경우 아래 항목 채움.

### 6.1 적용 여부
- [x] `base` 레이어 — 필수
- [x] `core` 레이어 — 필수 (피니시/크리티컬 시 발광)
- [x] `halo` 레이어 — 필수 (외곽 발광, 블룸 확산 주체)

### 6.2 레이어별 제작 가이드

| 레이어 | 위치 | 두께 | 색상 | 비고 |
|---|---|---|---|---|
| `base` | 기본 스프라이트 자체 | 원본 | 기본 팔레트 | 평상시 보이는 모습 |
| `core` | `base`의 내부 | **1~2px** | 순백 `#FFFFFF` | 발광의 심장. 기본 비표시 |
| `halo` | `base`의 외곽 바깥 | **1~2px** | **속성색** (아래 §6.3) | 반투명/블러 느낌 가능. 기본 비표시 |

**중요**: `core`/`halo`는 단색 순백 또는 속성색만 사용. **세부 음영 금지** — 음영은 셰이더가 처리.

### 6.3 속성 매핑

이 대상이 발동시키는 피니시/강조 속성:
- [ ] `light` = `#FFFFFF` (흰색) — 빛 속성
- [ ] `shadow` = `#8B2FC6` (보라) — 그림자 속성
- [ ] `hybrid` = `#F2CC66` (금) — 혼합 속성
- [ ] 해당 없음 (기본 흰색 플래시만)

> **체크한 속성색을 `halo` 기본색으로** 사용. `core`는 기본 순백 유지.

### 6.4 Godot 구조 (자동 생성 가이드)

```
<NodeRoot> (CharacterBody2D 또는 Node2D)
└── Visual (Node2D)
    ├── Base (AnimatedSprite2D, z=0, visible=true)
    ├── Core (AnimatedSprite2D, z=1, visible=false, blend=normal)
    └── Halo (AnimatedSprite2D, z=2, visible=false, blend=add)
```

세 `AnimatedSprite2D`는 동일한 `SpriteFrames` 애니메이션 이름을 공유. Core/Halo의 프레임은 Base 프레임 변경 시 동기화.

### 6.5 검증 체크리스트

Aseprite 파일 저장 전:
- [ ] `base` / `core` / `halo` 세 레이어 존재
- [ ] 모든 애니메이션 태그(`idle`, `run` 등)에서 세 레이어가 동일 프레임 레이아웃
- [ ] `core`는 `base`의 내부 윤곽 안쪽 1~2px
- [ ] `halo`는 `base` 외곽 1~2px 바깥, 반투명 가능
- [ ] `core`/`halo`에 속성색 외 색 없음 (세부 음영 금지)

Export 후:
- [ ] `<name>_base.png`, `<name>_core.png`, `<name>_halo.png` 세 파일 존재
- [ ] 세 PNG의 프레임 수/크기/간격 완전 일치
- [ ] 게임 내 Godot 씬에 Base/Core/Halo 3개 AnimatedSprite2D 배치

---

## 7. 구현 메모

### 기존 에셋 / 관련 씬
- 관련 씬: `<scene_path>.tscn`
- 기존 에셋 대체: <기존 에셋이 있는 경우 교체 계획>

### Phase 도입
- [ ] Phase <X>: <제작 시점>
- [ ] Phase <Y>: 3레이어 합류 시점 (§6.7.5)

### 관련 문서
- [../ART_PIPELINE.md](../ART_PIPELINE.md) §6.7 — 3레이어 규약
- [ART_RESOURCE_LIST.md](ART_RESOURCE_LIST.md) — 원본 리스트에서 이 대상의 번호
- [../EFFECTS.md](../EFFECTS.md) — 피니시/크리티컬 연출이 이 명세와 맞물리는 지점
- <기타 관련 설계 문서>

---

## 8. 변경 이력

| 날짜 | 내용 |
|---|---|
| YYYY-MM-DD | 초안 작성 |
