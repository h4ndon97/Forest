# 피격 파티클 아트 명세 (Phase 3-7 Pass 2 ⑤)

> 참고: Pass 2 구현은 텍스처 부재 시 4×4 흰색 fallback으로 동작 중. 본 명세 제작물이 배치되면 `data/effects/particle_presets.tres` 의 `{카테고리}_texture_path` 필드만 채우면 자동 교체됨.

## 개요

피격 시 적 타입에 따라 서로 다른 파티클이 터진다. 3개 카테고리 × 8×8 단판 스프라이트 1장씩 = **총 3장**.

| 카테고리 | 적용 적 타입 | 느낌 |
|---|---|---|
| organic | tree / flower / flower_spore | 수액·잎사귀 조각 |
| mineral | rock / pillar / shard / shard_spore | 돌·결정 파편 |
| shadow | dusk_spider / 보스 | 그림자 잔재·미립자 |

파티클 엔진이 런타임에 회전·스케일·색 램프를 자동 적용하므로, 스프라이트는 **방향성 없는 단일 모양**이어야 한다.

---

## 공통 규격

| 항목 | 값 |
|---|---|
| 캔버스 | 8×8 |
| 포맷 | PNG 32bit (알파 포함) |
| 텍스처 필터 | Nearest (프로젝트 전역) |
| 배경 | 투명 |
| 정렬 | 중심 정렬 (4,4) |
| 단색 | **YES** — 색은 코드의 color ramp가 부여. 스프라이트는 **흰색 또는 밝은 회색 단계 음영만** 써야 함 |

아웃라인이나 컬러 디테일을 넣으면 런타임 색 오버라이드와 충돌해 탁해지므로 금지.

---

## 1. organic_leaf.png

- 경로: `assets/sprites/effects/hit_particles/organic_leaf.png`
- 컨셉: 찢어진 작은 나뭇잎 조각 (또는 수액 방울)
- 형태: 타원·눈물방울 형태, 6×4 이내
- 내부 음영: 중심 흰색, 가장자리 밝은 회색(#CFCFCF 상당) 1px 링

## 2. mineral_chip.png

- 경로: `assets/sprites/effects/hit_particles/mineral_chip.png`
- 컨셉: 각진 돌 파편
- 형태: 비정형 5각형·삼각형. 예리한 각도 포함. 5×5 이내
- 내부 음영: 단계 음영 2단 (중심 흰색, 한쪽 45° 면만 중간 회색 #A0A0A0)

## 3. shadow_mote.png

- 경로: `assets/sprites/effects/hit_particles/shadow_mote.png`
- 컨셉: 흐릿한 입자·포자 점
- 형태: 원형 또는 별 4각. 4×4 이내
- 내부 음영: 중심 흰색 1~2px + 외곽 50% 회색(#808080) dithering 1px

---

## 프리셋 교체 절차

1. 위 3장을 Aseprite에서 제작해 PNG 내보내기
2. `assets/sprites/effects/hit_particles/` 에 배치
3. `data/effects/particle_presets.tres` 편집:
   ```
   organic_texture_path = "res://assets/sprites/effects/hit_particles/organic_leaf.png"
   mineral_texture_path = "res://assets/sprites/effects/hit_particles/mineral_chip.png"
   shadow_texture_path  = "res://assets/sprites/effects/hit_particles/shadow_mote.png"
   ```
4. 재실행 — 풀 재초기화 시점에 자동 반영

---

## 변경 이력

| 날짜 | 내용 |
|---|---|
| 2026-04-19 | 초안 — Phase 3-7 Pass 2 Step 3 착수와 함께 작성. 3 카테고리, 8×8 단색 권장 규격 |
