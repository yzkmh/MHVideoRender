uniform sampler2D uniTexture;
varying highp vec2 textureCoordinateRGB;
varying highp vec2 textureCoordinateAlpha;

void main() {
    highp vec4 rgbColor = texture2D(uniTexture, textureCoordinateRGB);
    highp vec4 alphaColor = texture2D(uniTexture, textureCoordinateAlpha);
    gl_FragColor = vec4(rgbColor.r, rgbColor.g, rgbColor.b, alphaColor.r);
}
