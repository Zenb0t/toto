// Water and lava on the floor: overlapping slow waves, with highlights where the waves peak.
shader_type canvas_item;

uniform vec4 deep_color : source_color = vec4(0.12, 0.26, 0.5, 1.0);
uniform vec4 shine_color : source_color = vec4(0.45, 0.7, 0.95, 1.0);
// How fast the waves drift.
uniform float speed = 1.0;
// How tight the waves are, per pixel of the 2D plane.
uniform float wave_scale = 0.06;

varying vec2 plane_position;

void vertex() {
	plane_position = VERTEX;
}

void fragment() {
	vec2 p = plane_position * wave_scale;
	float t = TIME * speed;
	float waves = sin(p.x + t) + sin(p.y * 1.3 - t * 0.8) + sin((p.x + p.y) * 0.7 + t * 1.3);
	float glint = smoothstep(1.4, 2.6, waves);
	float swell = 0.5 + 0.5 * sin(p.x * 0.35 - p.y * 0.25 + t * 0.5);
	COLOR = mix(deep_color, shine_color, glint * 0.75 + swell * 0.15);
}
