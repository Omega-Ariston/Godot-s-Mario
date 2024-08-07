shader_type canvas_item;

const vec4[] origin_colors = {vec4(0.12, 0.52, 0.0, 1.0) , vec4(0.84, 0.55, 0.13, 1.0), vec4(1.0, 1.0, 1.0, 1.0)};

uniform bool shader_enabled = false;
uniform vec4 new_colors[3];

bool colorMatch(vec4 c1, vec4 c2) {
	float maxDiff = 0.01;
    return (
        abs(c1.r - c2.r) < maxDiff
        && abs(c1.g - c2.g) < maxDiff
        && abs(c1.b - c2.b) < maxDiff
		&& abs(c1.a - c2.a) < maxDiff
    );
}

void fragment() {
	// Called for every pixel the material is visible on.
	
	vec4 input_color = texture(TEXTURE, UV);
	
	if (shader_enabled) {
		bool matched = false;
		for (int i = 0; i < 3; i++) {
			if (colorMatch(input_color, origin_colors[i])) {
				COLOR = new_colors[i];
				matched = true;
				break;
			}
		}
		if (!matched) {
			COLOR = input_color;
		}
	} else {
		COLOR = input_color;
	}
	
}
