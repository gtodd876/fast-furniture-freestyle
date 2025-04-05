shader_type canvas_item;

uniform float speed : hint_range(0.1, 2.0) = 0.3;
uniform float distortion : hint_range(1.0, 10.0) = 3.0;
uniform float saturation : hint_range(0.0, 1.0) = 0.8;
uniform float brightness : hint_range(0.0, 1.0) = 0.9;

void fragment() {
    // Get screen position
    vec2 uv = SCREEN_UV;
    float time = TIME * speed;

    // Create flowing waves
    float wave1 = sin(uv.x * distortion + time) * cos(uv.y * distortion + time * 0.5);
    float wave2 = sin(uv.y * distortion - time * 1.3) * cos(uv.x * distortion * 0.8 - time);

    // Create hue from the waves
    float hue = fract(0.5 + (wave1 + wave2) * 0.25);

    // Convert HSV to RGB
    vec3 hsv = vec3(hue, saturation, brightness);

    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(hsv.xxx + K.xyz) * 6.0 - K.www);
    vec3 rgb = hsv.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), hsv.y);

    COLOR = vec4(rgb, 1.0);
}