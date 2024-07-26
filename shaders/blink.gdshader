shader_type canvas_item;

uniform bool shader_enabled = false;

// 所有颜色顺序为：衣服、头发、皮肤
const vec4[] colors_classic = {vec4(0.69, 0.20, 0.14, 1.0) , vec4(0.41, 0.41, 0.01, 1.0), vec4(0.89, 0.61, 0.14, 1.0)};
const vec4[] colors_fire = {vec4(0.96, 0.86, 0.64, 1.0) , vec4(0.70, 0.19, 0.12, 1.0), vec4(0.90, 0.61, 0.12, 1.0)};
const vec4[] colors_green = {vec4(0.22, 0.51, 0.0, 1.0) , vec4(0.90, 0.61, 0.12, 1.0), vec4(1.0, 1.0, 1.0, 1.0)};
const vec4[] colors_red = {vec4(0.69, 0.20, 0.14, 1.0) , vec4(0.90, 0.61, 0.12, 1.0), vec4(1.0, 1.0, 1.0, 1.0)};
const vec4[] colors_black = {vec4(0.0, 0.0, 0.0, 1.0) , vec4(0.61, 0.29, 0.0, 1.0), vec4(1.0, 0.80, 0.77, 1.0)};

uniform vec4 origin_colors[3];
uniform vec4 new_colors[3];

bool colorMatch(vec4 c1, vec4 c2) {
	float maxDiff = 0.001;
    return (
        abs(c1.r - c2.r) < maxDiff
        && abs(c1.g - c2.g) < maxDiff
        && abs(c1.b - c2.b) < maxDiff
    );
}

void fragment() {
	// Called for every pixel the material is visible on.
	
	vec4 input_color = texture(TEXTURE, UV);
	
	if (shader_enabled) {
		for (int i = 0; i < 3; i++) {
			if (colorMatch(input_color, origin_colors[i])) {
				COLOR = new_colors[i];
				break;
			}
		}
	} else {
		COLOR = input_color;
	}
	
}

