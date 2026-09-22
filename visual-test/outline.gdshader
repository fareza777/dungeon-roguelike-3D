shader_type spatial;
render_mode cull_front, unshaded, depth_draw_always;

// Inverted-hull outline. Dipasang sebagai next_pass dari material toon.
// Di mobile: selektif saja (karakter/boss), jangan seluruh dungeon.

uniform vec4 outline_color : source_color = vec4(0.05, 0.03, 0.08, 1.0);
uniform float thickness : hint_range(0.0, 0.1) = 0.018;

void vertex() {
	VERTEX += NORMAL * thickness;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
