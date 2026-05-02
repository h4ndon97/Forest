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

## 2026-04-26 (Tier A 후속 — PARTIAL 마무리 1건)

- `[impl]` REC-UX-003 PARTIAL → **IMPLEMENTED (인프라)** — `item_data.gd`에 `flavor_text: String` `@export_multiline` 필드 추가. `equipment_tab.gd`에 `_flavor_label` 추가(보라/회색 톤 `Color(0.55, 0.45, 0.7, 0.85)`), 빈 문자열 아닐 때만 표시. `sword_basic.tres`에 placeholder 시조 풍 텍스트 추가(시각 검증용). 작가 협업 시 30~50개 아이템 텍스트만 채우면 즉시 반영(메모리 [feedback_art_ready_code] 정책 부합).
- `[verify]` gdlint 통과 + Godot 헤드리스 로드 통과 (ItemRegistry 8개 정상 로드).

## 2026-04-26 (Tier A 후속 — REC-MECH-002 인프라)

- `[impl]` REC-MECH-002 PROPOSED → **IMPLEMENTED (인프라)** — `MadnessSystem` Autoload 신설(`src/systems/madness/`). 강도≥0.5 영역에서 누적, 시간 정지 중 회복, 4단계(SAFE/WARNING/ALERT/CRITICAL) 분류. `madness_config.tres` 신설, `event_bus.gd`에 madness_changed + madness_stage_changed 시그널 추가.
- `[add]` `MadnessHud` Autoload 신설 — placeholder ProgressBar + 단계별 색조 (보라→빨강 그라데이션). 좌상단 시간 코어 아래 잠정 위치(Pass 5 재배치 검토).
- `[edit]` `effects_shadow_vignette.gd` REC-FX-007 시너지 — 광기 단계 시그널 → 비네트 알파 추가 보정 (warning +0.05 / alert +0.12 / critical +0.20).
- `[edit]` `project.godot` autoload 2개 등록 (MadnessSystem + MadnessHud).
- `[verify]` gdlint 통과(class-definitions-order 1건 enum 위치 정정) + Godot 헤드리스 로드 통과.
- **남은 작업**: 환영 적 entity 디자인 + spawn 코드 (별도 후속, 밸런싱 결정 필요).

## 2026-04-26 (PARTIAL 마무리 — REC-FX-006 컷신 인프라)

- `[impl]` REC-FX-006 PARTIAL → **IMPLEMENTED (인프라)** — 컷신 시스템 풀 인프라 신설. OverlaySystem 산하 1회용 CutscenePanel 패턴.
- `[add]` `data/cutscenes/cutscene_data.gd` + `cutscene_panel_data.gd` — 시퀀스 + 1장 패널 Resource 분리. typed Array[CutscenePanelData].
- `[add]` `src/ui/cutscene/cutscene_panel.gd` (~270줄, 300줄 안쪽) — CanvasLayer(layer=99 < OverlaySystem 100), 일러스트 페이드 인/아웃 + RichTextLabel typewriter(visible_ratio Tween, 32 cps) + 화자 라벨 + 패널 간 fade out→교체→in 자연 전환 + ESC 스킵 + F 진행/typewriter 즉시완성 + 플레이어 set_physics_process(false) 잠금.
- `[edit]` `src/systems/overlay/overlay_system.gd` 공개 API `play_cutscene(data)` 추가 — 1회용 인스턴스 add_child + start. 활성 중 재호출 무시 (`get_node_or_null("Cutscene")` 가드).
- `[edit]` `src/systems/event_bus/event_bus.gd` `cutscene_started/finished(cutscene_id)` 시그널 신설 — dialogue 신호와 분리 (음악/카메라/플레이어 hook 시점 다름).
- `[add]` `data/cutscenes/throne_echo_intro.tres` placeholder 시연 컷신 — 3패널 시조 풍 텍스트("빛이 멈춘 시간..." / "옛 왕좌의 메아리" / "멈춘 빛을 풀어야 한다") + 보라/검정 톤 ColorRect fallback.
- `[edit]` `src/world/stages/stage_3_b.gd` 트리거 hook 정비 — BossArenaTrigger 진입 → 컷신 재생 → `cutscene_finished` 수신 → `_activate_boss()` 분리. 보스가 컷신 중 움직이지 않음. 향후 다른 보스/스토리 비트의 표준 패턴.
- `[add]` `docs/art_specs/cutscene_panel.md` 신설 — 320×180 캔버스 + 수묵화 톤 차별화 + 6.7 3레이어 규약 적용 가이드(광원 등장 시) + 1차 우선순위 5장 명세 표.
- `[verify]` gdlint 통과 + Godot --import 로 class_name 캐시 등록 (CutsceneData/CutscenePanelData/CutscenePanel) + 헤드리스 로드 통과 (parse error 0).
- **placeholder 정책 부합**: 일러스트 미존재 시 `placeholder_tint` ColorRect로 즉시 작동. 작가가 PNG 5~10장 채우면 코드 수정 없이 즉시 반영(메모리 [feedback_art_ready_code]).
- **다른 ★★★ 추천의 선결 인프라**: REC-MECH-001 Echo Nail / REC-CONT-001 빛령+Light Father / REC-CONT-002 측량사 NPC 모두 컷신/일러스트 패널 호출이 필요하므로, 본 인프라가 다음 작업의 노력을 단축시킴.

## 2026-04-26 (REC-UX-007 신규 등재)

- `[add]` REC-UX-007 신규 — 월드맵 상시 열람 + 일러스트 맵 + 시간 반영. Stage 0~3 단계적 진행 (상시 열람 → 영역 polygon → 시간 셰이더 → 일러스트 swap). 사용자 결정 ACCEPTED. 차후 Architect 설계 단계 진입.
- `[meta]` 본 폴더 카테고리 합계: UX 6→7건. 누계 65→66 추천.

## 2026-04-26 (REC-UX-007 Stage 0 — 상시 열람 인프라)

- `[impl]` REC-UX-007 ACCEPTED → **IN_PROGRESS** (Stage 0 완료) — `world_map_input_router.gd` + `world_map_open_policy.gd` 신설(WorldMapUI 자식 노드, process_mode=ALWAYS). M키 어디서든 토글 + view-only 모드 / 거점 포털 = fast-travel 모드 분기. 기존 `map` InputMap 액션 재활용(신규 0). 신규 EventBus 시그널 0. 차단 정책: PauseMenu/InventoryMenu/ShopMenu / 컷신/전환/대화 / 보스 인트로 / 최근 2초 전투 휴리스틱(damage_received/dealt).
- `[edit]` `world_map_ui.gd` 302→296줄 (입력 라우터 위임 + 시간 갱신 graph_builder 위임 + MODE 상수 + 공개 API 6개). `world_map_graph_builder.gd` 261→278줄 (`is_time_stopped()` + `refresh_all_node_bg_colors()` 추가).
- `[edit]` `world_map_portal.gd` 1줄 추가 — emit 직전 `WorldMapUI.set_open_mode(WorldMapUI.MODE_FAST_TRAVEL)` 호출.
- `[verify]` gdlint 통과 + Godot 헤드리스 로드 통과 (parse error 0, 시스템 정상 init).
- `[fix]` Stage 0 인게임 검증 후속 — view-only 모드에서 detail panel 자동 표시되던 문제 + 노드마다 스테이지 라벨 표시되던 문제 수정. `_detail_show` 멤버 추가(view-only 진입 시 false, navigate ←→ 시 true). `graph_builder.create_stage_node`에서 라벨 생성 17줄 제거(`DOT_LABEL_*` 상수 3개 동반 삭제). 스테이지 명칭은 detail panel에서만 노출. graph_builder 278→257줄, world_map_ui 296→299줄.
- **남은 작업**: Stage 1 영역 polygon, Stage 2 시간 셰이더, Stage 3 일러스트 swap.

## 2026-04-26 (REC-UX-007 Stage 0.5 — 마우스 호버 + fog)

- `[impl]` REC-UX-007 Stage 0.5 (호버 + fog) 완료 — Stage 0 인게임 피드백 후속.
- `[add]` `src/systems/stage/stage_discovery.gd` 신규(60줄) — Stage 단위 발견 추적. EventBus `stage_entered`/`game_start_requested` 직접 구독. 시작 마을 자동 발견. `mark_discovered`/`is_discovered`/`get_save_data`/`load_save_data` API.
- `[edit]` `stage_system.gd` 349→347줄 — Discovery 자식 노드 추가 + `is_stage_discovered` 위임. 한계 압박 회수: `_unhandled_input`의 debug jump 핫키 7줄 → `stage_debug.gd`로 이주. collect_data 호출 형식 단축 2줄 회수. (한계 47줄 초과 상태이나 본 작업이 -2줄 회수, 추가 분할은 별도 작업 대상.)
- `[edit]` `save_manager.gd` `discovered_stages` 인자 + 직렬화 키 추가.
- `[edit]` `world_map_graph_builder.gd` 257→274줄 — `FOG_BG_COLOR`/`FOG_BORDER_COLOR` + `compute_node_bg_color`/`get_border_color` fog 분기 + 노드 mouse_filter PASS + `build_all(node_container, line_container)` 통합 메서드(미발견 사이 연결선 미표시) + dead code `_build_info_text` 33줄 제거.
- `[edit]` `world_map_detail_panel.gd` 192→224줄 — fog 시 `???`/"미발견" 표시 + `show_for(stage_id, position_hint)`/`hide_panel()` 공개 API 추가.
- `[add]` `src/ui/menus/world_map/world_map_node_hover.gd` 신규(36줄) — WorldMapUI 자식. `attach(stage_nodes)` 호출 시 각 노드 Control에 `mouse_entered/exited` 시그널 connect → `ui.set_hover_id(stage_id)` 호출.
- `[edit]` `world_map_ui.gd` 299→293줄 — `_hover_id`/`_node_hover` 멤버 + `get_hover_id`/`set_hover_id` 공개 API + `_update_selection_highlight`에 hover 분기(`_resolve_detail_target`: hover 우선, 비면 selection fallback) + `_rebuild_graph` 단축(graph_builder.build_all 위임).
- 키보드 ←→는 거점 순회용 유지(패드 호환). fast-travel ↑은 keyboard selection만, hover로 이동 X.
- `[verify]` gdlint 통과(pre-existing stage_system 한계 위반 외 신규 위반 0) + Godot 헤드리스 로드 통과 (parse error 0).
- **남은 작업**: Stage 1 영역 polygon, Stage 2 시간 셰이더, Stage 3 일러스트 swap.

## 2026-04-26 (REC-UX-007 Stage 1 — 영역 polygon fallback)

- `[impl]` REC-UX-007 Stage 1 (영역 polygon fallback) 완료.
- `[add]` `data/world_map/zone_polygon_data.gd` Resource 정의(24줄, `class_name ZonePolygonData`) — `zone_id`/`polygon_points`/`base_color`/`z_index`/`illust_texture_path`(Stage 3)/`time_tint_strength`(Stage 2) 필드.
- `[add]` `data/world_map/zones/zone_{1~5}_polygon.tres` 5개 — 색상 zone_1=황색(0.45,0.40,0.10) / zone_2=청록(0.10,0.30,0.32) / zone_3=보라(0.20,0.10,0.28) / zone_4=짙은 그림자(0.08,0.08,0.12) / zone_5=금/검정(0.30,0.22,0.05). polygon_points 빈 상태로 시작 — renderer가 ring 기반 default 도넛/disc 자동 생성. 사용자가 .tres에 직접 정점 입력 시 우선 사용.
- `[add]` `src/ui/menus/world_map/world_map_zone_polygon_renderer.gd` 신규(90줄) — 5 zone .tres 직접 로드 + Polygon2D 생성. `build(container)` 공개 API. ring 기반 default polygon 헬퍼(`_annulus_polygon`/`_disc_polygon`/`_zone_id_to_ring`).
- `[edit]` `world_map_graph_builder.gd` 274→286줄 — `refresh_spider_icons(container, stage_positions)` 메서드 추가(ui에서 이주, 회수 목적).
- `[edit]` `world_map_ui.gd` 293→293줄(불변 — polygon 통합분과 spider 위임 회수 상쇄) — `_polygon_renderer`/`_polygon_container` 멤버 + `_rebuild_graph`에서 polygon build 호출 + spider refresh를 graph_builder 위임. `_refresh_spider_icons` 제거(graph_builder.refresh_spider_icons로 통합).
- `[verify]` gdlint 통과(max-line-length 위반 2건은 줄바꿈으로 즉시 수정) + Godot 헤드리스 로드 통과(parse error 0, 시스템 정상 init).
- **placeholder 정책 부합**: polygon_points 빈 .tres → 자동 도넛 생성. 사용자가 .tres만 손보면 코드 변경 없이 형태 변경 가능(메모리 [feedback_art_ready_code]).
- **남은 작업**: Stage 2 시간 셰이더 톤 변화, Stage 3 일러스트 swap.

## 2026-04-26 (REC-UX-007 컨셉 전환 — 동심 극좌표 → 직사각형 톱뷰)

- `[edit]` 사용자 결정 — 월드맵 컨셉을 동심 극좌표 그래프(WORLD_MAP_REDESIGN.md 2026-04-20)에서 **살짝 기울어진 톱뷰 직사각형 지도**로 전환. 이유: ① 노드 자유 배치 ② 시간 셰이더 톤 변화의 시각 효과 극대화 ③ 메트로배니아 표준 ④ 한국 신화/수묵화 톤(REC-MKT-002)과 강한 부합. 셰이더는 시점과 무관하므로 코드 영향 0, 차이는 아트 작업에만.
- `[edit]` 사용자 결정 사항 5건 채택 — ① normalized (0~1) 좌표계 ② 화면 70% 직사각형 영역(448×252 / 640×360) ③ 자동 변환 fallback(현 극좌표 → 직사각형) + 수동 미세조정 ④ 단순 직선 연결선(호 폐기) ⑤ Stage 1 polygon 재작업으로 즉시 진행.
- `[edit]` `data/stages/stage_data.gd` — `world_map_pos: Vector2 = Vector2(-1.0, -1.0)` 필드 신설(미설정 sentinel). 기존 `radius_ring`/`angle_deg`/`radius_offset`은 `[deprecated]` 마킹 + 자동 변환 fallback용으로 유지. 기존 stage_*.tres 무수정으로 작동.
- `[edit]` `world_map_graph_builder.gd` 286→265줄 — `is_polar()` → `has_world_map_node()` 이름/로직 변경(world_map_pos 우선, 미설정 시 ring fallback). `compute_node_position()` 양면 처리. 호 로직 폐기(`_create_arc_line`/`ARC_SAMPLES` 제거 ~30줄). `create_connection()` 단순 직선만. `build_all` 결과 `ring_populated` → `zone_populated` (zone_id 기준).
- `[edit]` `world_map_zone_polygon_renderer.gd` 90→70줄 — ring 기반 default 도넛 폐기. 직사각형 가로 띠 5개 default(zone_1=상단, zone_5=하단). polygon_points는 normalized 0~1 통일, renderer가 픽셀 변환.
- `[edit]` `world_map_zone_layout.gd` 102→46줄 — RING placeholder 점선/각도 라벨 폐기. zone별 좌측 외부 라벨(normalized 위치). 미발견 zone 라벨 숨김 정책 유지.
- `[edit]` `world_map_ui.gd` 293→288줄 — `_zone_layout.build_overlay` 호출 시그니처 단축(`(container, zone_populated)` 2 인자, RING_CENTER/RADII 인자 폐기).
- `[verify]` gdlint 통과 + Godot 헤드리스 로드 통과 (parse error 0).
- **시각 결과**: 노드 위치는 자동 fallback으로 현 동심원 위치 그대로(마이그레이션 전) + polygon만 직사각형 가로 띠로 표시 → 일시적 부조화. 사용자 인게임 확인 후 stage 좌표 마이그레이션 또는 polygon 미세조정 결정.
- **남은 작업**: ① stage_*.tres `world_map_pos` 마이그레이션 (~30+개, 자동 변환 헬퍼 또는 수동) ② polygon 영역 미세조정 ③ Stage 2 시간 셰이더 ④ Stage 3 일러스트.

## 2026-04-26 (REC-UX-007 Stage 1 micro-adjust — 동심 사각형 + 미니맵 80%)

- `[edit]` 사용자 결정 — 가로 띠 5개 → **동심 사각형 5층(양파 껍질)** 으로 변경. 1구역=가장 외곽, 안쪽으로 진행하는 흐름 유지. 미니맵 영역 70%→**80%**(0.10~0.90).
- `[edit]` `world_map_zone_polygon_renderer.gd` — `RECT_AREA` 0.15~0.85 → 0.10~0.90. `ZONE_DEFAULT_BANDS` → `ZONE_DEFAULT_RECTS` (Rect2 5개 동심 사각형). `_default_polygon`은 4점 사각형 생성. z_index 동일 → tree 순서로 안쪽이 외곽을 덮음.
- `[edit]` `world_map_zone_layout.gd` — `ZONE_LABEL_POS` 좌측 외부 → `ZONE_LABEL_CENTER` 각 띠 상단 중앙. 라벨 색상 (0.92, 0.88, 0.72)로 가독성 ↑. 동심 띠에서 어느 zone인지 즉시 식별.
- `[meta]` 노드 마이그레이션 가이드 — 7×7 N×N grid (사용자 멘탈 모델, 코드 시각 표시 X). 노드 자유 배치 + 동심 zone 띠 가이드.
- `[verify]` gdlint 통과 + Godot 헤드리스 로드 통과.

## 2026-04-26 (REC-UX-007 Stage 1 — 노드 자동 변환 fallback)

- `[edit]` `world_map_graph_builder.gd` — 극좌표 fallback을 동심원 픽셀 변환에서 **동심 사각형 둘레 매핑**으로 변경. `RING_RADII` 폐기, `RING_RECTS`(zone_polygon_renderer.ZONE_DEFAULT_RECTS와 동일) 추가. `_polar_to_rect_perimeter(ring, angle_deg)` 헬퍼 — angle 0°=12시 ray가 ring의 동심 사각형 외곽과 만나는 점을 반환.
- 효과: stage_*.tres `world_map_pos` 미설정 상태에서도 노드가 동심 사각형 외곽 둘레로 자동 배치 → polygon과 시각 정합. `world_map_pos` 직접 입력하면 즉시 우선 적용(미세조정 가능).
- `[verify]` gdlint 통과 + Godot 헤드리스 로드 통과.

## 2026-04-26 (Phase 4-C zone4 진입)

- `[status]` REC-MECH-010 PROPOSED → **ACCEPTED** — Phase 4-C zone4 채택 결정 (zone3에서는 미채택, 1단계 늦은 도입 해소). zone4=그림자 왕가 영역 = 시간 정지 약화 잔재 적 자연. ZONE4_CONTENT_PLAN §2.3 잔영 첨병(`echo_vanguard.tres`)으로 도입. 신규 행동 모듈 `attack_behavior_time_immune.gd` Step 2 작성 예정. RISK-002(시간 정지 만능 카드) 부분 대응 — zone4부터 점진 도입으로 코어 메카닉 깊이 추가.
- `[impl]` REC-MECH-010 ACCEPTED → **IMPLEMENTED** (Phase 4-C Step 2). `data/enemies/enemy_stats_data.gd`에 `time_immune: bool` 필드 + `src/entities/enemies/base/base_enemy.gd` `deactivate()` 가드(~5줄). `data/enemies/zone4/echo_vanguard.tres` `time_immune=true`로 시간 정지 중에도 active 유지. **신규 attack_behavior 모듈 미작성** — 정지 면역은 *행동*이 아닌 *적 상태* 영향이라 flag 방식이 깔끔. RISK-002 부분 대응(zone4부터 점진 도입). gdlint clean + Godot 헤드리스 ERROR 0.
- `[meta]` Phase 4-C zone4 Step 0 진입 — `docs/ZONE4_CONTENT_PLAN.md` 신설 + STAGE_INDEX zone4 § 13행 확장. 사용자 결정 C-3(보스=수장의 잔재) + 안전 추천값 7항. C-1·C-2(그림자 왕가 정식 이름·수장) zone5 이월. 등불 트리거 인프라 본 zone에서 신설(`boss_weak_point.gd` source `+torch_lit`). REC-NARR-004 zone4 1권 배치는 Step 5+에서 검토.
