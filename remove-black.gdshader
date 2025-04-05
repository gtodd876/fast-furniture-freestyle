shader_type canvas_item;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    // Remove fully black areas that shouldn't be there
    if (col.rgb == vec3(0.0, 0.0, 0.0) && col.a > 0.0) {
        col.a = 0.0;
    }
    COLOR = col;
}