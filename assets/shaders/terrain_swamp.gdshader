
// terrain_swamp.gdshader
// 沼泽地形：棕绿色半透明叠加 + 缓慢气泡扰动
// 适用 renderer：Forward+ / Mobile / Compatibility（无 SCREEN_TEXTURE）
shader_type canvas_item;

uniform vec4 overlay_color : source_color = vec4(0.40, 0.35, 0.20, 0.45);
uniform float noise_scale : hint_range(1.0, 8.0) = 3.0;
uniform float bubble_speed : hint_range(0.0, 2.0) = 0.4;

// 简单伪随机噪声（无纹理采样，兼容 Compatibility）
float hash(float n) {
	return fract(sin(n) * 43758.5453);
}
float noise_2d(float x, float y) {
	float ix = floor(x);
	float iy = floor(y);
	float fx = fract(x);
	float fy = fract(y);
	fx = fx * fx * (3.0 - 2.0 * fx);
	fy = fy * fy * (3.0 - 2.0 * fy);
	float a = mix(hash(ix + hash(iy)), hash(ix + 1.0 + hash(iy)), fx);
	float b = mix(hash(ix + hash(iy + 1.0)), hash(ix + 1.0 + hash(iy + 1.0)), fx);
	return mix(a, b, fy);
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);

	// 两张噪声叠加，模拟沼泽气泡扰动
	float n1 = noise_2d(UV.x * noise_scale + TIME * bubble_speed * 0.3,
	                     UV.y * noise_scale + TIME * bubble_speed * 0.2);
	float n2 = noise_2d(UV.x * noise_scale * 1.7 - TIME * bubble_speed * 0.15,
	                     UV.y * noise_scale * 1.3 + TIME * bubble_speed * 0.25);
	float blend = 0.3 + 0.25 * (n1 + n2) * 0.5;

	// 在 base 亮部叠加颜色，暗部保持不动
	vec4 terrain = overlay_color;
	terrain.a = blend * overlay_color.a;
	COLOR = mix(base, terrain, terrain.a);
}
