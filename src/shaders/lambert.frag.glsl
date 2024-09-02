#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.

uniform float u_Frequency;
// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec3 fs_world;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.
#define MOD3 vec3(443.8975,397.2973, 491.1871)

float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float hash13(vec3 p)
{
    vec3 p3 = fract(p * MOD3);
    p3 += dot(p3, p3.zyx+19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 GetGradient(vec2 intPos, float t) {
    
    // Uncomment for calculated rand
    //float rand = fract(sin(dot(intPos, vec2(12.9898, 78.233))) * 43758.5453);;
    
    // Texture-based rand (a bit faster on my GPU)
    float rand = hash12(intPos / 64.f);
    
    // Rotate gradient: random starting rotation, random rotation rate
    float angle = 6.283185 * rand + 4.0 * t * rand;
    return vec2(cos(angle), sin(angle));
}


float perlin3D(vec3 pos) {
    vec2 i = floor(pos.xy);
    vec2 f = pos.xy - i;
    vec2 blend = f * f * (3.0 - 2.0 * f);
    float noiseVal = 
        mix(
            mix(
                dot(GetGradient(i + vec2(0, 0), pos.z), f - vec2(0, 0)),
                dot(GetGradient(i + vec2(1, 0), pos.z), f - vec2(1, 0)),
                blend.x),
            mix(
                dot(GetGradient(i + vec2(0, 1), pos.z), f - vec2(0, 1)),
                dot(GetGradient(i + vec2(1, 1), pos.z), f - vec2(1, 1)),
                blend.x),
        blend.y
    );
    return noiseVal / 0.7; // normalize to about [-1..1]
}

// 3d fbm function
float cubic(float a) {
    return a * a * (3.0 - 2.0 * a);
}

float interphash13(vec3 pos) {
    float x = pos.x;
    float y = pos.y;
    float z = pos.z;

    int intX = int(floor(x));
    float fractX = fract(x);
    int intY = int(floor(y));
    float fractY = fract(y);
    int intZ = int(floor(z));
    float fractZ = fract(z);

    float v1 = hash13(vec3(intX, intY, intZ));
    float v2 = hash13(vec3(intX + 1, intY, intZ));
    float v3 = hash13(vec3(intX, intY + 1, intZ));
    float v4 = hash13(vec3(intX + 1, intY + 1, intZ));
    float v5 = hash13(vec3(intX, intY, intZ + 1));
    float v6 = hash13(vec3(intX + 1, intY, intZ + 1));
    float v7 = hash13(vec3(intX, intY + 1, intZ + 1));
    float v8 = hash13(vec3(intX + 1, intY + 1, intZ + 1));

    float i1 = mix(v1, v2, cubic(fractX));
    float i2 = mix(v3, v4, cubic(fractX));
    float i3 = mix(v5, v6, cubic(fractX));
    float i4 = mix(v7, v8, cubic(fractX));

    float j1 = mix(i1, i2, cubic(fractY));
    float j2 = mix(i3, i4, cubic(fractY));

    return mix(j1, j2, fractZ);
}

float fbm3D(vec3 pos) {
    float total = 0.f;
    float persistence = 0.5f;
    int octaves = 8;
    float freq = 2.f;
    float amp = 0.5f;
    for(int i = 1; i <= octaves; i++) {
        total += interphash13(pos * freq) * amp;

        freq *= 2.f;
        amp *= persistence;
    }
    return total;
}

// Worley 3d
float worley3D(vec3 pos) {
    vec3 p = floor(pos);
    vec3 f = fract(pos);

    float min_dist = 1.0;
    for(int x = -1; x <= 1; x++) {
        for(int y = -1; y <= 1; y++) {
            for(int z = -1; z <= 1; z++) {
                vec3 neighbor = vec3(x, y, z);
                vec3 point = vec3(hash13(p + neighbor));
                vec3 diff = neighbor + point - f;
                float dist = dot(diff, diff);
                min_dist = min(min_dist, dist);
            }
        }
    }
    return 1.0 - min_dist;
}

void main()
{
        vec3 world = fs_world;
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        // Calculate the diffuse term for half-Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        diffuseTerm = diffuseTerm * 0.5 + 0.5;

        // Avoid negative lighting values
        // diffuseTerm = clamp(diffuseTerm, 0, 1);

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.
        // Compute final shaded color
        // out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
        float perlin = perlin3D(fs_world * u_Frequency);
        float fbm = fbm3D(fs_world * u_Frequency);
        float worley = worley3D(fs_world * u_Frequency);
        out_Col = vec4(vec3(worley), 1.0);
}
