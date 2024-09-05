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

uniform int u_Noise;
uniform float u_Time; // in seconds
uniform vec3 u_Camera;

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

vec3 rand(vec3 p){
 	const vec3 k = vec3( 3.1415926, 2.71828,6.62607015);
 	p = p*k + p.yzx;
 	return -1.0 + 2.0*fract( 2.0 * k * fract( p.x*p.y*(p.x+p.y)) );
}

float perlin3D(vec3 p){
    vec3 i = floor(p);
    vec3 f = fract(p);
    vec3 u = f*f*f*(f*(f*6.0-15.0)+10.0);
    
    //random gradiant
    vec3 g1 = rand(i+vec3(0.0,0.0,0.0));
    vec3 g2 = rand(i+vec3(1.0,0.0,0.0));
    vec3 g3 = rand(i+vec3(0.0,1.0,0.0));
    vec3 g4 = rand(i+vec3(1.0,1.0,0.0));
    vec3 g5 = rand(i+vec3(0.0,0.0,1.0));
    vec3 g6 = rand(i+vec3(1.0,0.0,1.0));
    vec3 g7 = rand(i+vec3(0.0,1.0,1.0));
    vec3 g8 = rand(i+vec3(1.0,1.0,1.0));
    
    //direction vector
    vec3 d1 = f - vec3(0.0,0.0,0.0);
    vec3 d2 = f - vec3(1.0,0.0,0.0);
    vec3 d3 = f - vec3(0.0,1.0,0.0);
    vec3 d4 = f - vec3(1.0,1.0,0.0);
    vec3 d5 = f - vec3(0.0,0.0,1.0);
    vec3 d6 = f - vec3(1.0,0.0,1.0);
    vec3 d7 = f - vec3(0.0,1.0,1.0);
    vec3 d8 = f - vec3(1.0,1.0,1.0);
    
    //weight
    float n1 = dot(g1, d1);
    float n2 = dot(g2, d2);
    float n3 = dot(g3, d3);
    float n4 = dot(g4, d4);
    float n5 = dot(g5, d5);
    float n6 = dot(g6, d6);
    float n7 = dot(g7, d7);
    float n8 = dot(g8, d8);
    
    //trilinear interpolation
    float a = mix(n1,n2,u.x);
    float b = mix(n3,n4,u.x);
    float c1 = mix(a,b,u.y);
    a = mix(n5,n6,u.x);
    b = mix(n7,n8,u.x);
    float c2 = mix(a,b,u.y);
    float c = mix(c1,c2,u.z);
    
    
    return c;
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

float sdOctahedron( vec3 p, float s)
{
  p = abs(p);
  return (p.x+p.y+p.z-s)*0.57735027;
}

vec3 calcNormal( in vec3 p ) 
{
    const float eps = 0.0001;
    const vec2 h = vec2(eps,0);
    return normalize( vec3(sdOctahedron(p+h.xyy, 0.4) - sdOctahedron(p-h.xyy, 0.4),
                           sdOctahedron(p+h.yxy, 0.4) - sdOctahedron(p-h.yxy, 0.4),
                           sdOctahedron(p+h.yyx, 0.4) - sdOctahedron(p-h.yyx, 0.4) ));
}

const mat4 r15x = mat4(1.0000000,  0.0000000,  0.0000000, 0,
                        0.0000000,  0.2588190, -0.9659258, 0, 
                        0.0000000,  0.9659258,  0.2588190, 0,
                        0, 0, 0, 1);
void main()
{
        
        // out_Col = vec4(world, 1.0);
        // return;
        
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
        

        vec3 world = fs_world; 
        vec4 octColor = vec4(0);

        // create a rotating octahedron
        if (u_Noise != 0)
        {
            // raymarch sdf
            float t = 0.0;
            float tmax = 20.0;
            vec3 rd = normalize(world - u_Camera);
            for (int i = 0; i < 64 && t < tmax; i++)
            {
                vec3 p = u_Camera + t * rd;

                // rotate the octahedron with time
                float time = u_Time * 0.5;
                mat3 rtimey = mat3(cos(time * 1.5), 0.0 , -sin(time * 1.5),
                                      0.0, 1.0, 0.0,
                                      sin(time * 1.5), 0 , cos(time * 1.5));
                mat3 rtimez = mat3(cos(time), -sin(time), 0.0,
                                      sin(time), cos(time), 0.0,
                                      0.0, 0.0, 1.0);

                vec3 rp = p * rtimey * rtimez;

                float d = sdOctahedron(rp, 0.56);
                if (d < 0.001)
                {
                    octColor = vec4(u_Color.xyz, fbm3D(p * u_Frequency));
                    float kd = dot(normalize(calcNormal(rp)), normalize(fs_LightVec.xyz)) * 0.5 + 0.5;
                    octColor *= kd + ambientTerm;
                    break;
                }
                t += d;
            }
        }

        float noise = 0.0;
        if (u_Noise == 1) {
            noise = perlin3D(world * u_Frequency);
        } else if (u_Noise == 2) {
            noise = fbm3D(world * u_Frequency * 0.5);
            noise = fbm3D((world + noise) * u_Frequency * 0.5);
            noise = fbm3D((world + noise) * u_Frequency * 0.5);
        } else if (u_Noise == 3) {
            noise = worley3D(world * u_Frequency * 0.6);
        }

        // return output color
        out_Col = u_Noise == 0 ? vec4(diffuseColor.rgb  * lightIntensity, diffuseColor.a) : vec4(u_Color.xyz * lightIntensity, noise);
        out_Col = mix(out_Col, octColor, octColor.a);
}
