precision mediump float;
varying vec2 texcoord;
uniform sampler2D tex;

void main() {
    float radius = 20.0; // corner radius in pixels — adjust to taste
    float width  = 1920.0;
    float height = 1080.0;

    vec2 pixelPos = texcoord * vec2(width, height);

    vec2  nearest  = vec2(0.0);
    bool  inCorner = false;

    if (pixelPos.x < radius && pixelPos.y < radius) {
        nearest = vec2(radius, radius);
        inCorner = true;
    } else if (pixelPos.x > width - radius && pixelPos.y < radius) {
        nearest = vec2(width - radius, radius);
        inCorner = true;
    } else if (pixelPos.x < radius && pixelPos.y > height - radius) {
        nearest = vec2(radius, height - radius);
        inCorner = true;
    } else if (pixelPos.x > width - radius && pixelPos.y > height - radius) {
        nearest = vec2(width - radius, height - radius);
        inCorner = true;
    }

    if (inCorner) {
        float dist  = length(pixelPos - nearest);
        float alpha = smoothstep(radius - 1.0, radius + 1.0, dist);
        gl_FragColor = mix(texture2D(tex, texcoord), vec4(0.0, 0.0, 0.0, 1.0), alpha);
        return;
    }

    gl_FragColor = texture2D(tex, texcoord);
}
