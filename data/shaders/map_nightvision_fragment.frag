// Greyscale night-vision effect
uniform sampler2D u_Tex0;
varying vec2 v_TexCoord;

float luma(vec3 c) {
  return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

void main() {
  vec4 col = texture2D(u_Tex0, v_TexCoord);

  // Greyscale conversion
  float g = luma(col.rgb);
  vec3 grey = vec3(g);

  // Brighten shadows slightly
  float gamma = 1.3;
  float gain  = 0.5;
  grey = pow(grey, vec3(gamma)) * gain;

  gl_FragColor = vec4(grey, col.a);
}
