shader_type canvas_item;

// Phase 3-7 Pass 3 — 시간 정지 전역 포스트프로세스.
// D7-1 재조정 (2026-04-19): 화면 전체 균일 세피아. 주변부 원색 유지 미적용.
// OverlaySystem PostProcess ColorRect에 assign.

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform float weight : hint_range(0.0, 1.0) = 0.0;
uniform vec4 sepia_tone : source_color = vec4(0.74, 0.55, 0.33, 1.0);
uniform vec4 tint_color : source_color = vec4(0.90, 0.75, 0.55, 1.0);
uniform float saturation_lerp : hint_range(0.0, 1.0) = 0.15;

void fragment() {
	vec4 original = texture(screen_tex, SCREEN_UV);
	float lum = dot(original.rgb, vec3(0.299, 0.587, 0.114));
	vec3 sepia = vec3(lum) * sepia_tone.rgb * 2.0;
	sepia = mix(sepia, original.rgb * tint_color.rgb, saturation_lerp);

	vec3 result = mix(original.rgb, sepia, weight);
	COLOR = vec4(result, 1.0);
}
