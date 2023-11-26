shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

varying vec4 modulate;

void vertex() {
	modulate = COLOR;
}
void fragment() {
	COLOR.rgb = modulate.rgb;	vec2 uv = SCREEN_UV;
	float a = 0.0;
	a += texture(screen_texture, uv).r * 2.0;
	for (float i = 0.0; i < 1.0; i += 1.0 / 3.0) {
		a += texture(screen_texture, uv + vec2(sin(i * TAU + 0.8), cos(i * TAU + 0.8)) * 1.5 * SCREEN_PIXEL_SIZE).r;
		a += texture(screen_texture, uv + vec2(sin(i * TAU), cos(i * TAU)) * 1.0 * SCREEN_PIXEL_SIZE).r;
	}
	a = smoothstep(0.2, 0.6, a / 8.0);

	
	COLOR.a = a * modulate.a;

}