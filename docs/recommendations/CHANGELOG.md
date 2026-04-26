# Recommendations Changelog

> Append-only 변경 로그. 추천 항목 추가/수정/상태변경/기각 시 한 줄씩 추가.
> 형식: `YYYY-MM-DD [tag] REC-XXX-NNN — 설명` (또는 `[meta]` 메타 변경)

---

## 2026-04-25

- `[meta]` 폴더 신설 + README 인덱스 + CHANGELOG 골격 작성
- `[add]` REC-MECH-001~010 초기화 (메카닉 카테고리 10건)
- `[add]` REC-FX-001~007 초기화 (연출/이펙트 7건)
- `[add]` REC-CONT-001~007 초기화 (콘텐츠/수집/NPC 7건)
- `[add]` REC-META-001~013 초기화 (메타/구조/끝판 13건)
- `[add]` REC-UX-001~006 초기화 (UI/UX/접근성 6건)
- `[add]` REC-SND-001~005 초기화 (사운드 5건)
- `[add]` REC-NARR-001~005 초기화 (스토리/내러티브 5건)
- `[add]` REC-RISK-001~005 초기화 (위험 신호 5건)
- `[add]` REC-MKT-001~007 초기화 (한국 인디 시장 7건)
- `[add]` INVENTORY_GAP.md — 시스템/콘텐츠 갭 분석 스냅샷 작성
- `[add]` 00_TOP10.md — Top 10 must-haves 진입점 문서 작성

총 65 추천 항목 + 5 위험 신호 + 7 시장 노트 = **77 entries** PROPOSED 상태로 초기화.

## 2026-04-26

- `[status]` REC-RISK-003 OPEN → **RESOLVED** — 사용자 결정: 50 스테이지 풀 양산 유지 (볼륨 우선)
- `[status]` REC-RISK-004 OPEN → **RESOLVED** — 코드 검증 결과 follow 시스템 이미 구현됨 (`stage_camera.gd`). 메모리 stale 확인.
- `[edit]` REC-META-007 명분 재정의 — "자산 재활용" → "NG+ 모드 흐르는 시간 변형 제공"으로 가치 재구성. PROPOSED 유지.
- `[edit]` REC-FX-002 의존 해제 — 카메라 정책 의존 → 해소. 큰 `room_size` 룸으로 follow 시스템 활용 가능.
- `[status]` REC-MECH-007 PROPOSED → **REVIEWING** — 카메라 follow + 가변 룸 크기 환경에서 원 컨셉("다음 방 발견형 즐거움") 약화. 옵션 A (같은 룸 내 거울 연쇄, 노력 S) / 옵션 B (인접 룸 텔레그래프, 노력 M) 중 선택 대기.
- `[meta]` 메모리 MEMORY.md 인덱스 한 줄 정정 — `project_camera_scroll.md` 본문은 2026-04-23에 이미 "옵션 C 하이브리드 가변 룸 확정"으로 갱신되어 있었으나 인덱스 한 줄만 stale 상태였음. 인덱스 정정 완료.
- `[status]` REC-MECH-007 REVIEWING → **ACCEPTED** — 옵션 A (같은 룸 내 거울 연쇄) 확정. 노력 M → S 다운그레이드. 옵션 B 기각 (발견형 즐거움 매체 중복 + 큰 룸 효과 없음).
- `[status]` REC-UX-005 PROPOSED → **IMPLEMENTED** — 코드 검증 결과 `data/themes/main_theme.tres`(Galmuri11/14 + Mulmaru) + `project.godot:58`(theme/custom 등록) 적용 완료 확인. 본 폴더 초기 작성 시 코드 검증 누락으로 PROPOSED로 잘못 표기됐던 사례.
- `[meta]` README §0.5 신설 — **코드 검증 의무화 운영 원칙** 추가. 추천 상태 변경 시 코드/리소스 직접 검증 + 검증 명령 기록 의무화.
- `[meta]` INVENTORY_GAP.md 신뢰도 경고 추가 — 코드 검증 누락 사례 명시 + 전체 재검증 진행 중 표기.
- `[meta]` 백그라운드 에이전트 spawn — 65 추천 항목 + 13 시스템 인벤토리 코드 기반 재검증 진행 중.
- `[verification]` 백그라운드 에이전트 재검증 완료 — 65 추천 + 13 시스템 인벤토리 모두 코드 기반 검증. PROPOSED 외 격상 5건 발견 + INVENTORY_GAP 정정 2건.
- `[status]` REC-FX-003 PROPOSED → **PARTIAL** — `data/effects/timelines/finish_light.tres` 5큐 존재. 잔류 빛줄기 cue 1개 추가만 필요.
- `[status]` REC-FX-006 PROPOSED → **PARTIAL** — `OverlaySystem.play_cinematic_bars()` + `DialogueBox` 인프라 존재. 일러스트 패널 시스템만 추가하면 완성.
- `[status]` REC-FX-007 PROPOSED → **PARTIAL** — `vignette_radial.gdshader` + `OverlaySystem.set_vignette_color()` 인프라 존재. ShadowSystem 강도 → 비네트 라우팅 추가.
- `[status]` REC-UX-001 PROPOSED → **STALE 후보** — 시간 코어 일식링/궤도/배지 디자인이 본 추천 무효화 조건 사실상 충족(메모리 B-6 일식링 결정 2026-04-23). 사용자 의사 결정 대기.
- `[status]` REC-UX-003 PROPOSED → **PARTIAL** — 인벤토리 UI 풀 구현(`inventory_menu.gd`/`equipment_tab.gd`). `item_data.gd`에 `icon` 필드 존재, `flavor_text`/일러스트만 추가.
- `[edit]` INVENTORY_GAP §B 스테이지 카운트 정정 — 1구역 `10/10` → `8/8` (실제 코드 stage_1_1~6 + b + h). 합계 17/(55+히든) ≈ 30%로 정정.
- `[edit]` INVENTORY_GAP §D 사운드 정정 — `main_theme.tres`는 UI Theme이지 BGM 아님. `audio/` 폴더 비어있음, `AudioSystem` Autoload 미등록. 사운드 0% 명시.
- `[verification]` 잔여 추천 60건 PROPOSED 유지 정확 (NOT_FOUND 또는 N/A 콘텐츠/스토리 의존 항목).
- `[status]` REC-UX-001 STALE 후보 → **STALE 확정** — 사용자 결정(옵션 A): 현 일식링/궤도/배지 디자인 만족, 모래시계 메타포 폐기.

## 2026-04-26 (Tier A 그룹 1 구현)

- `[impl]` REC-FX-007 PARTIAL → **IMPLEMENTED** — `effects_shadow_vignette.gd` 신설(우선순위 합산 라우터). DuskWarning 비활성 시 그림자 강도 → 비네트 알파 매핑. `effects_config_data.gd`에 `shadow_vignette_*` 4 파라미터 추가.
- `[impl]` REC-FX-003 PARTIAL → **IMPLEMENTED** — `effects_residual_light.gd` 신설(빛 피니시 후속 거동). `EffectsSystem.spawn_residual_light()` 공개 API + `damage_resolver.gd` hook. EffectTimeline 우회로 1.2초 지속 발광 잔류(halo+core 2레이어). `effects_config_data.gd`에 `residual_light_*` 6 파라미터 추가.
- `[meta]` `effects_system.gd`에 `# gdlint:ignore = max-public-methods` disable comment 추가 — facade 패턴 의도 반영.
- `[verify]` gdlint 통과 + Godot 헤드리스 로드 테스트 통과 (parse error 0, 시스템 정상 init).
- `[meta]` Phase 4-B zone3 Step 0 진입 — `docs/ZONE3_CONTENT_PLAN.md` 신설 + STAGE_INDEX zone3 § 11행 확장. 본 Step 안전 추천값 결정 영향: ① REC-MECH-010(정지 면역 엘리트) **본 zone 미채택, PROPOSED 유지** — 시간 정지 코어 보호(RISK-002 충돌). zone4/Phase 5 재검토. ② REC-NARR-004(5권 일기) zone3 1권 배치 검토 §8 미결로 보존, 별도 NARR 세션에서 결정. ③ REC-MKT 카테고리 출시 임박 시점까지 보류.

## 2026-04-26 (Tier A 그룹 2 구현)

- `[impl]` REC-FX-001 PROPOSED → **IMPLEMENTED** — `effects_time_stop_shutter.gd` 신설(시간 정지 발동 0.15초 색수차 + 화면 플래시). `time_stop_sepia.gdshader`에 `chromatic_strength` uniform 추가(RGB 채널 좌우 분리). `effects_config_data.gd`에 `shutter_*` 4 파라미터 추가. EffectsSystem에 인스턴스 추가.
- `[impl]` REC-FX-004 PROPOSED → **IMPLEMENTED** — `shadow_jitter.gdshader` 신설(vertex sin/cos 기반 동일 offset). `shadow_caster.gd`에 떨림 통합(`enable_jitter` 노출 + 시간 정지 시그널 구독 + 그림자 강도 → 진폭 0.6~1.4px 매핑). 인스턴스별 seed로 위상 분산. fallback ColorRect도 지원.
- `[verify]` gdlint 통과 + Godot 헤드리스 로드 테스트 통과 (parse error 0, 시스템 정상 init).

## 2026-04-26 (Tier A 그룹 3 구현)

- `[impl]` REC-MECH-005 PROPOSED → **IMPLEMENTED** — `dusk_spider_hud.gd` 확장(5단계 발자국 풀 동적 생성, `EventBus.dusk_spider_approached` 시그널 → 단계별 fade in/out + position.x 안쪽 이동). `effects_config_data.gd`에 `footprint_*` 6 파라미터 추가.
- `[add]` `docs/art_specs/dusk_footprint.md` 신설 — 16×16 발자국 sprite 명세. placeholder ColorRect로 즉시 작동, sprite 도착 시 자동 교체 fallback chain (메모리 [feedback_art_ready_code] 정책 부합).
- `[verify]` gdlint 통과 + Godot 헤드리스 로드 테스트 통과 (parse error 0, 시스템 정상 init).

## 2026-04-26 (Tier A 그룹 4 구현 — 마지막)

- `[impl]` REC-MECH-007 ACCEPTED → **IMPLEMENTED** — 빛 굴절 콤보 (같은 룸 내 거울 연쇄). `mirror.gd`에 `add_to_group("mirror")` 등록. `finish_light.gd`에 `_trigger_mirror_reflections(ctx)` 추가 — 같은 stage 내 모든 거울 검색 → 각 거울 `rotation_pivot.global_position/global_rotation`으로 빛 빔 발사. hitbox attacker = pivot으로 회전 자동 추적, AttackSpec.piercing=true로 다중 적 관통, damage=피니시×0.5.
- `[add]` `effects_light_beam.gd` 신설 — Polygon2D 회전된 직사각형 + Tween fade(alpha→0 + scale.y→0.5).
- `[add]` `EffectsSystem.spawn_light_beam(start_pos, angle, duration)` 공개 API 추가.
- `[edit]` `effects_config_data.gd`에 `light_beam_*` 7 파라미터 추가 (length=320 / width=18 / active_duration=0.15 / fade_duration=0.22 / damage_ratio=0.5 / color/alpha).
- `[verify]` gdlint 통과 + Godot 헤드리스 로드 테스트 통과.

**Tier A 5건 모두 IMPLEMENTED**: UX-005(한글 폰트 사전적용 발견) + FX-001/003/004/007 + MECH-005/007. STALE 1건(UX-001). 5 카테고리 IMPLEMENTED + STALE 1 + ACCEPTED 0.
