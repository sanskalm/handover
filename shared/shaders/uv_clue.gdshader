shader_type spatial;
uniform sampler2D tex;
void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	ALPHA = 0.0;
}

void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
	vec4 pixel = textureLod(tex, UV, 1.0);
	SPECULAR_LIGHT = vec3(0);
	ALPHA = ATTENUATION * pixel.a;
	if (ATTENUATION == 1.0){
		ALPHA=0.0;
	}
}
