//
//  MHVideoCompositionManager.m
//  MHVideoExport
//
//  Created by FUZE on 2017/8/18.
//  Copyright © 2017年 FUZE. All rights reserved.
//

#import "MHVideoCompositionManager.h"
#import "MHVideoEffect.h"


@interface MHVideoCompositionManager ()

@property GLuint offscreenBufferHandle;
@property (nonatomic, strong) MHVideoEffect *videoEffect;
@property EAGLContext *context;
@end


@implementation MHVideoCompositionManager

+ (instancetype)shareManager
{
    static MHVideoCompositionManager * _instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[MHVideoCompositionManager alloc]init];
    });
    return _instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
        [EAGLContext setCurrentContext:self.context];
        [self setupOffscreenRenderContext];
        self.videoEffect = [[MHVideoEffect alloc]initWithEAGLContext:self.context];
    }
    return self;
}

- (void)setupOffscreenRenderContext
{
    glGenFramebuffers(1, &_offscreenBufferHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenBufferHandle);
}

- (void)prepareToDraw:(CVPixelBufferRef)videoPixelBuffer andDestination:(CVPixelBufferRef)destinationPixelBuffer andCompositionTime:(CMTime)time
{
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenBufferHandle);
    [EAGLContext setCurrentContext:self.context];
    [self.videoEffect renderPixelBuffer:videoPixelBuffer andDestination:destinationPixelBuffer andFrameBuffer:_offscreenBufferHandle];
    
    glFinish();
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

@end
