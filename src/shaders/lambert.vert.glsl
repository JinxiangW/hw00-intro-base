#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself
uniform float u_Time; // In seconds

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.

out vec3 fs_world;         // The world position of each vertex. This is implicitly passed to the fragment shader.

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.
const mat4 r45x = mat4(1.0000000,  0.0000000,  0.0000000, 0,
                        0.0000000,  0.7071068, -0.7071068, 0, 
                        0.0000000,  0.7071068,  0.7071068, 0,
                        0, 0, 0, 1);

const mat4 r45z = mat4(0.7071068, -0.7071068, 0.0000000, 0,
                        0.7071068,  0.7071068, 0.0000000, 0,
                        0.0000000,  0.0000000, 1.0000000, 0,
                        0, 0, 0, 1);
void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.

    mat4 rtimey = mat4(cos(u_Time * 0.5), 0.0 , -sin(u_Time * 0.5), 0.0,
                      0.0, 1.0, 0.0, 0.0,
                      sin(u_Time * 0.5), 0 , cos(u_Time * 0.5), 0.0,
                      0.0, 0.0, 0.0, 1.0);
    mat4 rtimez = mat4(cos(u_Time * 0.5), sin(u_Time * 0.5), 0.0, 0.0,
                      -sin(u_Time * 0.5), cos(u_Time * 0.5), 0.0, 0.0,
                      0.0, 0.0, 1.0, 0.0,
                      0.0, 0.0, 0.0, 1.0);
    vec4 modelposition =  rtimez * r45x * u_Model * vs_Pos * r45z * rtimey;   // Temporarily store the transformed vertex positions for use below
    float shrink = sin(u_Time * 2.) - 1.0f;
    modelposition.xyz += 0.1 * shrink * (modelposition.xyz); // Add a sine wave to the x, y, and z positions of the model

    fs_world = vec3(modelposition); // Pass the world position of the vertex to the fragment shader
    
    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
