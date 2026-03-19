#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    
    // Top-Bottom Alpha Layout:
    // Top half (uv.y 0.0 to 0.5) is the color component
    // Bottom half (uv.y 0.5 to 1.0) is the alpha component
    
    // Sample color from top half
    vec2 colorUv = vec2(uv.x, uv.y * 0.5);
    vec3 color = texture(uTexture, colorUv).rgb;
    
    // Sample alpha from bottom half (offset by 0.5)
    vec2 alphaUv = vec2(uv.x, (uv.y * 0.5) + 0.5);
    float alpha = texture(uTexture, alphaUv).r; // Assuming mask is grayscale, red channel works
    
    fragColor = vec4(color * alpha, alpha); // Premultiplied alpha
}
