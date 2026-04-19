shader_type canvas_item;

// Phase 3-7 Pass 1 — Damageable 공통 힛플래시.
// flash_amount(0~1)이 1에 가까울수록 flash_color로 덮인다. alpha 보존.

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR = vec4(mix(tex.rgb, flash_color.rgb, flash_amount), tex.a);
}
