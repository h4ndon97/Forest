shader_type canvas_item;

// Phase 3-7 Pass 4 — 땅거미 공포 비네트.
// 원형 그라데이션: 화면 중앙은 투명, 가장자리로 갈수록 vignette_color에 수렴.
// OverlaySystem Vignette ColorRect에 assign. 알파는 vignette_color.a로 제어.

uniform vec4 vignette_color : source_color = vec4(0.55, 0.18, 0.78, 0.0);
// 비네트 시작 반경(짧은 변 절반=0.5 기준). 이 안쪽은 완전 투명.
uniform float inner_radius : hint_range(0.0, 1.5) = 0.30;
// 비네트 완전 도달 반경. inner~outer 구간에서 smoothstep.
// 1.05+ 권장 — 코너 너머에서 풀 도달해야 가장자리 라인이 안 보임.
uniform float outer_radius : hint_range(0.0, 2.0) = 1.10;
// 화면 가로/세로 비율 (16:9=1.7778). aspect 보정으로 진짜 원 형태.
uniform float aspect_ratio : hint_range(0.5, 3.0) = 1.7778;

void fragment() {
	// aspect 보정: 짧은 변(세로) 절반=0.5, 긴 변(가로)=0.5*aspect 기준 정원.
	vec2 centered = (UV - vec2(0.5)) * vec2(aspect_ratio, 1.0);
	float dist = length(centered);
	float t = smoothstep(inner_radius, outer_radius, dist);
	// 8비트 알파 밴딩 방지 — 픽셀별 의사 난수 ±0.5/255.
	// 옅은 그라디언트에서 계단이 보이는 현상을 깬다.
	float noise = fract(sin(dot(FRAGCOORD.xy, vec2(12.9898, 78.233))) * 43758.5453);
	float dither = (noise - 0.5) / 255.0;
	COLOR = vec4(vignette_color.rgb, vignette_color.a * t + dither);
}
