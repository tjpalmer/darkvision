shader_type canvas_item;

uniform float width : hint_range(0.0, 10.0) = 2.0; // Thickness in pixels
uniform float threshold : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec4 central_color = texture(TEXTURE, UV);
    bool is_white = central_color.r > threshold;
    
    if (is_white) {
        COLOR = central_color;
    } else {
        bool neighbor_white = false;
        vec2 size = TEXTURE_PIXEL_SIZE;
        
        // Check a box around the pixel based on 'width'
        for (float x = -width; x <= width; x++) {
            for (float y = -width; y <= width; y++) {
                // Skip checking the center itself
                if (x == 0.0 && y == 0.0) continue;
                
                vec2 offset = vec2(x, y) * size;
                if (texture(TEXTURE, UV + offset).r > threshold) {
                    neighbor_white = true;
                    break;
                }
            }
            if (neighbor_white) break;
        }
        
        if (neighbor_white) {
            COLOR = vec4(0.0, 0.0, 0.0, 1.0); // Border color
        } else {
            COLOR = vec4(0.0, 0.0, 0.0, 0.0); // Transparent background
        }
    }
}
