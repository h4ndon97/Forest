shader_type canvas_item;

// Phase 3-7 Pass 4 — 땅거미 공포 비네트.
// 원형 그라데이션: 화면 중앙은 투명, 가장자리로 갈수록 vignette_color에 수렴.
// OverlaySystem Vignette ColorRect에 assign. 알파는 vignette_color.a로 제어.

uniform vec4 vignette_color : source_color = vec4(0.55, 0.18, 0.78, 0.0);
// 비네트 시작 반경(0=화면 중심부터, 1=가장자리). 이 안쪽은 완전 투명.
uniform float inner_radius : hint_range(0.0, 1.0) = 0.35;
// 비네트 완전 도달 반경. inner~outer 구간에서 smoothstep.
uniform float outer_radius : hint_range(0.0, 1.5) = 0.95;

void fragment() {
	// 화면 중심 기준 거리(0=중앙, ~0.71=모서리). aspect 무시 — 픽셀아트 기준 충분.
	vec2 centered = UV - vec2(0.5);
	float dist = length(centered) * 1.4142;
	float t = smoothstep(inner_radius, outer_radius, dist);
	COLOR = vec4(vignette_color.rgb, vignette_color.a * t);
}
