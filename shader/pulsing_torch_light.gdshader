shader_type canvas_item;

// Center of the light in screen UV (0–1)
uniform vec2 center = vec2(0.5, 0.5);  // no : hint_screen_uv

uniform float radius    = 0.30;
uniform float softness  = 0.18;
uniform float intensity = 0.95;

void fragment() {
    float dist = distance(UV, center);

    float edge_start = radius;
    float edge_end   = radius + softness;

    float mask = smoothstep(edge_start, edge_end, dist);
    float a = mask * intensity;

    COLOR = vec4(0.0, 0.0, 0.0, a);
}
