#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;     // Base texture (usually the screen or main image)
uniform sampler2D texture1;     // Blend texture (can be another image or effect layer)
uniform vec4 colDiffuse;

// Output fragment color
out vec4 finalColor;

void main()
{
    // Fetch texel colors from both textures
    vec4 baseColor = texture(texture0, fragTexCoord) * colDiffuse * fragColor;
    vec4 blendColor = texture(texture1, fragTexCoord);

    // Apply screen blend mode: result = 1 - (1 - A) * (1 - B)
    vec3 screenRGB = 1.0 - (1.0 - baseColor.rgb) * (1.0 - blendColor.rgb);
    float alpha = baseColor.a; // You can tweak alpha blending logic here

    finalColor = vec4(screenRGB, alpha);
}
