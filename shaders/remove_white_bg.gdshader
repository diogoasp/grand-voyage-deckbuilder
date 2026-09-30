shader_type canvas_item;

uniform float threshold : hint_range(0.5, 1.0) = 0.94;
uniform float softness : hint_range(0.0, 0.2) = 0.04;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	// Calcula a proximidade com o branco puro (1.0, 1.0, 1.0)
	float min_channel = min(col.r, min(col.g, col.b));
	if (min_channel >= threshold) {
		float alpha = 1.0 - smoothstep(threshold, threshold + softness, min_channel);
		col.a *= alpha;
	}
	COLOR = col;
}
