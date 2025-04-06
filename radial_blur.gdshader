shader_type canvas_item;

uniform vec2 center = vec2(0.5, 0.5);
uniform float blur_amount : hint_range(0.0, 1.0) = 0.1;
uniform float brightness_boost : hint_range(0.0, 1.0) = 0.1;

void fragment() {
	vec2 dir = UV - center;
	float distance = length(dir);
	vec4 color = vec4(0.0);

	// Number of samples along the blur direction
	const float samples = 20.0;

	// Normalize the direction
	dir = normalize(dir);

	// Sample multiple times along the ray
	for(float i = 0.0; i < samples; i++) {
		float scale = 1.0 - (blur_amount * (i / samples));
		vec2 offset = center + (dir * distance * scale);
		color += texture(TEXTURE, offset);
	}

	// Average the samples and add a brightness boost
	color /= samples;
	color += brightness_boost * length(dir);

	COLOR = color;
}
