shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

varying vec4 modulate;

uniform sampler2D goolash_boil_noise : repeat_enable;
uniform float goolash_frame;

void vertex() {
	modulate = COLOR;
}

void fragment() {
	COLOR.rgb = modulate.rgb;
	vec2 uv = SCREEN_UV;
	
	// Anti-alias
	float a = 0.0;
	float directions = 8.0;
	float quality = 4.0;
	float size = 4.0;
	for (float angle = 0.0; angle < TAU; angle += TAU / directions) {
		vec2 offset = vec2(cos(angle), sin(angle));
		for (float i = 1.0; i <= quality; i += 1.0) {
			a += texture(screen_texture, uv + offset * i / quality * size * SCREEN_PIXEL_SIZE).r;
		}
	}
	a /= directions * quality;
	a = smoothstep(0.3, 0.6, a);
	
	COLOR.a = a * modulate.a;
	
}
