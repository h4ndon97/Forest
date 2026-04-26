shader_type canvas_item;

// Phase 3-7 Pass 3 — 시간 정지 전역 포스트프로세스.
// D7-1 재조정 (2026-04-19): 화면 전체 균일 세피아. 주변부 원색 유지 미적용.
// REC-FX-001 (2026-04-26): chromatic_strength uniform 추가 — 셔터 발동 시 0~0.02 보간.
// OverlaySystem PostProcess ColorRect에 assign.

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform float weight : hint_range(0.0, 1.0) = 0.0;
uniform vec4 sepia_tone : source_color = vec4(0.74, 0.55, 0.33, 1.0);
uniform vec4 tint_color : source_color = vec4(0.90, 0.75, 0.55, 1.0);
uniform float saturation_lerp : hint_range(0.0, 1.0) = 0.15;
// REC-FX-001: 색수차 강도 (UV 단위, 0.02 = 약 ±13px @640). 0이면 비활성.
uniform float chromatic_strength : hint_range(0.0, 0.05) = 0.0;

void fragment() {
	// 색수차 — RGB 채널을 좌우로 분리해 샘플링.
	vec4 original;
	if (chromatic_strength > 0.0) {
		float r_off = chromatic_strength;
		vec2 r_uv = SCREEN_UV + vec2(r_off, 0.0);
		vec2 b_uv = SCREEN_UV - vec2(r_off, 0.0);
		float r = texture(screen_tex, r_uv).r;
		float g = texture(screen_tex, SCREEN_UV).g;
		float b = texture(screen_tex, b_uv).b;
		float a = texture(screen_tex, SCREEN_UV).a;
		original = vec4(r, g, b, a);
	} else {
		original = texture(screen_tex, SCREEN_UV);
	}

	float lum = dot(original.rgb, vec3(0.299, 0.587, 0.114));
	vec3 sepia = vec3(lum) * sepia_tone.rgb * 2.0;
	sepia = mix(sepia, original.rgb * tint_color.rgb, saturation_lerp);

	vec3 result = mix(original.rgb, sepia, weight);
	COLOR = vec4(result, 1.0);
}
