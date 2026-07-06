shader_type canvas_item;
render_mode blend_mix;

uniform float inset : hint_range(0.0, 0.25) = 0.105;
uniform float radius : hint_range(0.0, 0.30) = 0.075;
uniform float feather : hint_range(0.001, 0.08) = 0.030;

float rounded_box_alpha(vec2 uv, vec2 half_size, float corner_radius, float edge_feather) {
	vec2 centered = abs(uv - vec2(0.5));
	vec2 q = centered - half_size + vec2(corner_radius);
	float outside = length(max(q, vec2(0.0))) - corner_radius;
	return 1.0 - smoothstep(0.0, edge_feather, outside);
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec2 half_size = vec2(0.5 - inset);
	float mask = rounded_box_alpha(UV, half_size, radius, feather);
	base.a *= mask;
	COLOR = base;
}
