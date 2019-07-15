//
//  MHVideoEffect.h
//  MHVideoExport+OpenGLES
//
//  Created by FUZE on 2017/8/29.
//  Copyright © 2017年 FUZE. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLSLProgram;

@interface MHVideoEffect : NSObject
{
    GLSLProgram *videoShader;
    GLuint  inPositionAttrib,
    inTexCoordAttrib,
    textureUniform,
    MPMtxUniform;
    
    GLuint vertexsId;
    
}
@property (nonatomic, strong) EAGLContext *context;
@property CVOpenGLESTextureRef videoTextureRef;
@property CVOpenGLESTextureCacheRef videoTextureCache;

- (instancetype)initWithEAGLContext:(EAGLContext *)context;

- (void)renderPixelBuffer:(CVPixelBufferRef)aPixbuffer andDestination:(CVPixelBufferRef)destinationPixelBuffer andFrameBuffer:(GLint)frameBufferHandle;

@end
