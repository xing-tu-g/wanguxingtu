shader_type canvas_item;
render_mode blend_mix;

uniform float threshold : hint_range(0.0, 1.0) = 0.88;
uniform float softness : hint_range(0.001, 0.20) = 0.08;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float white_amount = min(min(base.r, base.g), base.b);
	float keyed = smoothstep(threshold - softness, threshold, white_amount);
	base.a *= 1.0 - keyed;
	COLOR = base;
}
