shader_type canvas_item;
render_mode blend_premul_alpha;

// 呼吸脉冲发光 Shader — 给 UI 元素加呼吸光效
// 使用 luminance 驱动发光强度，越亮的区域发光越强，配合 TIME 正弦脉冲。

uniform float pulse_speed : hint_range(0.0, 5.0) = 2.0;
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.6;
uniform vec4 glow_color : source_color = vec4(0.44, 0.84, 1.0, 1.0);

void fragment() {
	vec4 base = texture(TEXTURE, UV);

	// 正弦脉冲 [0.0, 1.0]
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;

	// 亮度驱动发光：越亮的区域发光越强
	float lum = dot(base.rgb, vec3(0.299, 0.587, 0.114));
	float glow = lum * pulse * glow_intensity;

	// 叠加发光到原色，保持 alpha
	COLOR = base + glow_color * glow * base.a;
}
