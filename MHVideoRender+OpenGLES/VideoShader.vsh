attribute vec3 inPosition;
attribute vec2 inTexCoord;

varying lowp vec2 textureCoordinateRGB;
varying lowp vec2 textureCoordinateAlpha;

uniform             mat4        MPMatrix;


void main(){
    textureCoordinateAlpha = inTexCoord;
    textureCoordinateRGB = vec2(inTexCoord.x + 0.5, inTexCoord.y);
    
    gl_Position = MPMatrix * vec4(inPosition.x, inPosition.y, inPosition.z, 1.0);
    
}
