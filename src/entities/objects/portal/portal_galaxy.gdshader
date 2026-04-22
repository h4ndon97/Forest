shader_type canvas_item;
render_mode blend_add;

uniform vec4 tint : source_color = vec4(0.55, 0.92, 1.0, 1.0);
uniform float rotation_speed : hint_range(0.0, 2.0) = 0.25;
uniform float arm_count : hint_range(1.0, 6.0) = 3.0;
uniform float swirl_tightness : hint_range(0.0, 8.0) = 3.5;
uniform float intensity : hint_range(0.0, 2.0) = 0.55;
uniform float near_boost : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float r = length(uv) * 2.0;
	if (r > 1.0) {
		COLOR = vec4(0.0);
	} else {
		float angle = atan(uv.y, uv.x);
		float swirl = angle + r * swirl_tightness + TIME * rotation_speed;
		float arms = 0.5 + 0.5 * sin(swirl * arm_count);
		float radial = 1.0 - smoothstep(0.0, 1.0, r);
		float arm_mask = smoothstep(0.12, 0.38, r);
		float a = arms * radial * intensity * near_boost * arm_mask;
		COLOR = vec4(tint.rgb, a);
	}
}
