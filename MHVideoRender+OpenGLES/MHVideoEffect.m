//
//  MHVideoEffect.m
//  MHVideoExport+OpenGLES
//
//  Created by FUZE on 2017/8/29.
//  Copyright © 2017年 FUZE. All rights reserved.
//

#import "MHVideoEffect.h"
#import "GLSLProgram.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface MHVideoEffect ()

@end

@implementation MHVideoEffect

- (instancetype)initWithEAGLContext:(EAGLContext *)context;
{
    self.context = context;
    
    return [self init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}


- (void)renderPixelBuffer:(CVPixelBufferRef)aPixbuffer andDestination:(CVPixelBufferRef)destinationPixelBuffer andFrameBuffer:(GLint)frameBufferHandle
{
    [videoShader use];
    
    CVOpenGLESTextureRef destLumaTexture = NULL;
    if (destinationPixelBuffer) {
        destLumaTexture = [self textureForPixelBuffer:destinationPixelBuffer];
        glBindFramebuffer(GL_FRAMEBUFFER, frameBufferHandle);
        glViewport(0, 0, (int)CVPixelBufferGetWidthOfPlane(destinationPixelBuffer, 0), (int)CVPixelBufferGetHeightOfPlane(destinationPixelBuffer, 0));
        // Attach the destination texture as a color attachment to the off screen frame buffer
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, CVOpenGLESTextureGetTarget(destLumaTexture), CVOpenGLESTextureGetName(destLumaTexture), 0);
        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
            NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
            CFRelease(destLumaTexture);
            return;
        }
        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        glClear(GL_COLOR_BUFFER_BIT);
//        glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
//        glClearColor(0.0, 0.0, 0.0, 1);
    }
    
    _videoTextureRef = [self textureForPixelBuffer:aPixbuffer];
    
    glBindTexture(CVOpenGLESTextureGetTarget(_videoTextureRef), CVOpenGLESTextureGetName(_videoTextureRef));
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(_videoTextureRef));
    glBindBuffer(GL_ARRAY_BUFFER, vertexsId);
    
    glEnableVertexAttribArray(inPositionAttrib);
    glEnableVertexAttribArray(inTexCoordAttrib);
    
    glVertexAttribPointer(inPositionAttrib, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, 0);
    glVertexAttribPointer(inTexCoordAttrib, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDrawArrays(GL_TRIANGLES,
                 0,
                 6);
    glDisable(GL_BLEND);
//    [self setupArray];
//
//    glBindBuffer(GL_ARRAY_BUFFER, vertexsId);
//
//    glEnableVertexAttribArray(inPositionAttrib);
//    glEnableVertexAttribArray(inTexCoordAttrib);
//
//    glVertexAttribPointer(inPositionAttrib, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, 0);
//    glVertexAttribPointer(inTexCoordAttrib, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
//    glEnable(GL_DEPTH_TEST);
//    glEnable(GL_BLEND);
////    glBlendEquationSeparate(GL_DST_ALPHA, GL_BLEND_EQUATION_ALPHA);
//    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
//    glDrawArrays(GL_TRIANGLES,
//                 0,
//                 6);
    
    
    if (destLumaTexture) {
        CVBufferRelease(destLumaTexture);
        destLumaTexture = NULL;
    }
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

- (void)cleanUpTextures
{
    
    @synchronized (self) {
        if (_videoTextureRef) {
            CFRelease(_videoTextureRef);
            _videoTextureRef = NULL;
        }
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}

- (CVOpenGLESTextureRef)textureForPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CVOpenGLESTextureRef texture = NULL;
    CVReturn err;
    
    [self cleanUpTextures];
    
    if (!_videoTextureCache) {
        NSLog(@"No video texture cache");
        goto bail;
    }
    
    // Periodic texture cache flush every frame
    //    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
    
    // CVOpenGLTextureCacheCreateTextureFromImage will create GL texture optimally from CVPixelBufferRef.
    // Y
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _videoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RGBA,
                                                       (int)CVPixelBufferGetWidth(pixelBuffer),
                                                       (int)CVPixelBufferGetHeight(pixelBuffer),
                                                       GL_BGRA,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &texture);
    
    if (!texture || err) {
        NSLog(@"Error at creating luma texture using CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
bail:
    return texture;
}


- (void)setup
{
    CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_videoTextureCache);
    [self setupArray];
    [self setupShaders];
    CGRect bounds = [UIScreen mainScreen].bounds;
    
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, bounds.size.width, 0, bounds.size.height, 0, 1);
    glUniformMatrix4fv(MPMtxUniform, 1, GL_FALSE, projectionMatrix.m);
    
}

//- (void)setupArray
//{
//    CGRect bounds = [UIScreen mainScreen].bounds;
//
//    //前三个是顶点坐标， 后面两个是纹理坐标
//    GLfloat attrArr[] =
//    {
//        bounds.size.width, 0, 0.0f,     1.0f, 1.0f, //右下
//        0, bounds.size.height, 0.0f,     0.5f, 0.0f, //左上
//        0, 0, 0.0f,    0.5f, 1.0f, //左下
//        bounds.size.width, bounds.size.height, 0.0f,      1.0f, 0.0f, //
//        0, bounds.size.height, 0.0f,     0.5f, 0.0f, //
//        bounds.size.width, 0, 0.0f,     1.0f, 1.0f,
//    };
//
//    glGenBuffers(1, &vertexsId);
//    glBindBuffer(GL_ARRAY_BUFFER, vertexsId);
//    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
//    glBindBuffer(GL_ARRAY_BUFFER, 0);
//}

- (void)setupArray
{
    CGRect bounds = [UIScreen mainScreen].bounds;
    
    //前三个是顶点坐标， 后面两个是纹理坐标
    GLfloat attrArr[] =
    {
        bounds.size.width, 0, 0.0f,     0.5f, 0.0f, //右下
        0, bounds.size.height, 0.0f,     0.0f, 1.0f, //左上
        0, 0, 0.0f,    0.0f, 0.0f, //左下
        bounds.size.width, bounds.size.height, 0.0f,      0.5f, 1.0f, //
        0, bounds.size.height, 0.0f,     0.0f, 1.0f, //
        bounds.size.width, 0, 0.0f,     0.5f, 0.0f,
    };
    
    glGenBuffers(1, &vertexsId);
    glBindBuffer(GL_ARRAY_BUFFER, vertexsId);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}



- (void)setupShaders
{
    videoShader = [[GLSLProgram alloc]initWithVertexShaderFilename:@"VideoShader" fragmentShaderFilename:@"VideoShader"];
    
    [videoShader addAttribute:@"inPosition"];
    [videoShader addAttribute:@"inTexCoord"];
    
    
    if (![videoShader link]) {
        NSLog(@"Linking failed");
        NSLog(@"Program log: %@", [videoShader programLog]);
        NSLog(@"Vertex log: %@", [videoShader vertexShaderLog]);
        NSLog(@"Fragment log: %@", [videoShader fragmentShaderLog]);
        videoShader = nil;
        exit(1);
    }
    
    inPositionAttrib = [videoShader attributeIndex:@"inPosition"];
    inTexCoordAttrib = [videoShader attributeIndex:@"inTexCoord"];
    
    [videoShader use];
    
    textureUniform = [videoShader uniformIndex:@"texture"];
    MPMtxUniform = [videoShader uniformIndex:@"MPMatrix"];
}

@end
