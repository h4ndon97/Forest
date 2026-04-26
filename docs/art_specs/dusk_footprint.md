# 아트 명세 — 땅거미 발자국 (REC-MECH-005)

> **작성일**: 2026-04-26
> **연관 추천**: docs/recommendations/01_mechanics.md REC-MECH-005
> **연관 시스템**: src/ui/hud/dusk_spider_hud.gd
> **상태**: placeholder ColorRect로 즉시 작동. sprite 도착 시 자동 교체 (코드 수정 불필요).

---

## 1. 사용처

화면 좌측 가장자리에서 안쪽으로 침투하는 **5개의 발자국**. 땅거미가 가까워질수록 발자국이 늘어나고 안쪽으로 이동.

5단계 매핑:
| 거리 | 표시 발자국 | 위치 | 알파 |
|---|---|---|---|
| -1 (비활성) | 0개 | — | 0.0 |
| 2 (먼 보라) | 2개 | 가장자리 (margin 24px) | 0.4 |
| 1 (근접) | 4개 | 가장자리 + 18px 안쪽 | 0.7 |
| 0 (도착) | 5개 | 가장자리 + 36px 안쪽 | 1.0 |

---

## 2. 규격

| 항목 | 값 |
|---|---|
| 캔버스 | **16×16 픽셀** |
| 실제 크기 | 12×12 (캔버스 안에서 여백 2px) |
| 색조 | 어두운 보라/검정 (#4D0D80 ~ #1A0029) — 그림자 왕가 팔레트 |
| 배경 | 투명 (PNG, alpha 채널) |
| 형태 | **거미 발자국 모티프** (4~6개 작은 점이 거미 다리 모양) 또는 단순 발자국 모양 |

### 색조 가이드 (수묵화 톤 + REC-MKT-002 시너지)
- 외곽: `#4D0D80` (보라, 진함)
- 내부: `#1A0029` (어두운 점)
- alpha: 모든 픽셀 100% (코드에서 modulate 알파로 단계 조정)

---

## 3. 변형 (선택)

5개 풀이라 동일 sprite 반복도 OK. 다만 자연스러움을 위해 변형 권장:

### 옵션 A — 단일 sprite (간단)
- `dusk_footprint.png` 1장
- 모두 같은 모양으로 표시

### 옵션 B — 좌/우 발자국 교차 (자연스러움)
- `dusk_footprint_left.png`, `dusk_footprint_right.png` 2장
- 코드에서 짝수 인덱스/홀수 인덱스로 교차 적용 (옵션 B 채택 시 코드 추가 필요)

### 옵션 C — 5장 다른 형태 (몰입감)
- `dusk_footprint_0.png` ~ `dusk_footprint_4.png`
- 각자 약간 다른 회전/크기 — 자연스러운 군집

**1차 권장**: 옵션 A로 시작. 옵션 B/C는 향후 패치.

---

## 4. 출력 경로

```
assets/sprites/ui/dusk_footprint.png
```

이 파일이 존재하면 dusk_spider_hud.gd가 자동 로드해 placeholder ColorRect를 TextureRect로 교체.

존재하지 않으면 placeholder ColorRect(`footprint_color = Color(0.3, 0.05, 0.5, 1.0)`)로 작동 — 코드 수정 없이 검증 가능.

---

## 5. 애니메이션

**없음** (정적 sprite). 떨림/페이드는 코드 Tween으로 처리 (modulate.a, position.x).

미래 확장 가능: 거리 0 단계에서 발자국이 살짝 떨림 — REC-FX-004 그림자 떨림 셰이더 적용 검토.

---

## 6. 검증 방법

1. placeholder 단계: `dusk_spider_hud.gd` _ready 시 ColorRect 5개가 좌측 가장자리에 생성 (기본 알파 0)
2. 디버그 키 또는 시간 흐름으로 땅거미 거리 변화 → 5단계 fade in/out + position.x 이동 확인
3. sprite 도착 후: ColorRect 대신 TextureRect로 자동 교체

---

## 7. 발광 3레이어 규약 (REC-NARR-001 시너지)

본 발자국은 **non-glowing UI 요소**라 발광 3레이어 규약 적용 안 함. 다만 향후 "땅거미 본체 출현 시 발자국이 발광하며 경고" 같은 확장 시 규약 적용 검토.

---

## 8. 미결 / 확장 후보

- [ ] 음향 큐 (SOUND.md 신설 시) — 거리 1 단계부터 발걸음 SFX
- [ ] REC-FX-004 그림자 떨림 적용 — 거리 0에서 발자국 떨림
- [ ] 옵션 B/C 변형 sprite 추가
- [ ] 화면 우측에서도 침투 (좌우 동시) — 위협감 증폭 옵션
