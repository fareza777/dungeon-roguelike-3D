shader_type spatial;
render_mode diffuse_toon, specular_disabled;

// Toon unifier + flash untuk hit effect.
// ALBEDO > 1 saat flash supaya ikut terangkat bloom.

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(1.0);
uniform float bands : hint_range(2.0, 5.0) = 3.0;
uniform float shadow_softness : hint_range(0.0, 0.4) = 0.12;
uniform vec3 rim_color : source_color = vec3(0.9, 0.85, 0.7);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.25;
uniform float rim_size : hint_range(0.0, 1.0) = 0.45;
uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(albedo_texture, UV);
	ALBEDO = mix(tex.rgb * tint.rgb, vec3(1.6), flash);
}

void light() {
	float ndotl = dot(NORMAL, LIGHT);
	float band = floor(clamp(ndotl * 0.5 + 0.5, 0.0, 0.999) * bands) / (bands - 1.0);
	float soft = smoothstep(0.0, shadow_softness, clamp(ndotl, 0.0, 1.0));
	float lit = clamp(band * 0.7 + soft * 0.3, 0.0, 1.0);
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * lit * ATTENUATION;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	rim = step(1.0 - rim_size, rim) * rim_strength;
	DIFFUSE_LIGHT += rim_color * rim * ATTENUATION;
}
