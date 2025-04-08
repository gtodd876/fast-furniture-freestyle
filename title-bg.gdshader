shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

uniform vec4 top_color : source_color = vec4(0.639, 0.655, 0.761, 1.0); // #A3A7C2
uniform vec4 bottom_color : source_color = vec4(0.863, 0.464, 0.730, 1.0);// #D77BBA

void fragment() {
    // Create gradient from top to bottom
    vec4 gradient = mix(top_color, bottom_color, UV.y);
    COLOR = gradient;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
