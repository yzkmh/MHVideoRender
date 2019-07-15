//
//  MHVideoCompositor.m
//  MHVideoExport
//
//  Created by FUZE on 2017/8/18.
//  Copyright © 2017年 FUZE. All rights reserved.
//

#import "MHVideoCompositor.h"
#import "MHVideoCompositionManager.h"
#import "MHVideoPlayerManager.h"
//#import "MHVideoExportRender.h"


@interface MHVideoCompositor ()
{
    BOOL								_shouldCancelAllRequests;
    BOOL								_renderContextDidChange;
    dispatch_queue_t					_renderingQueue;
    dispatch_queue_t					_renderContextQueue;
    AVVideoCompositionRenderContext*	_renderContext;
    CVPixelBufferRef					_previousBuffer;
}
//@property (nonatomic, strong) MHVideoExportRender *aplRender;

@end



@implementation MHVideoCompositor


- (instancetype)init
{
    self = [super init];
    if (self) {
        _renderingQueue = dispatch_queue_create([@"com.linekong.musicwave.videoexport.render" UTF8String], DISPATCH_QUEUE_SERIAL);
        _renderContextQueue = dispatch_queue_create([@"com.linekong.musicwave.videoexport.conetextrender" UTF8String], DISPATCH_QUEUE_SERIAL);
        _previousBuffer = nil;
        _renderContextDidChange = NO;
    }
    return self;
}


- (NSDictionary *)sourcePixelBufferAttributes {
    return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
              (NSString*)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]};
}

- (NSDictionary *)requiredPixelBufferAttributesForRenderContext {
    return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
              (NSString*)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]};
}

- (void)startVideoCompositionRequest:(AVAsynchronousVideoCompositionRequest *)request {
    @autoreleasepool {
        dispatch_async(_renderingQueue,^() {
            
            // Check if all pending requests have been cancelled
            if (_shouldCancelAllRequests) {
                [request finishCancelledRequest];
            } else {
                NSError *err = nil;
                // Get the next rendererd pixel buffer
                CVPixelBufferRef resultPixels = [self newRenderedPixelBufferForRequest:request error:&err];
                
                if (resultPixels) {
                    // The resulting pixelbuffer from OpenGL renderer is passed along to the request
                    [request finishWithComposedVideoFrame:resultPixels];
                    CFRelease(resultPixels);
                } else {
                    [request finishWithError:err];
                }
            }
        });
    }
}

- (void)renderContextChanged:(AVVideoCompositionRenderContext *)newRenderContext {
    dispatch_sync(_renderContextQueue, ^() {
        _renderContext = newRenderContext;
        _renderContextDidChange = YES;
    });
}

- (void)cancelAllPendingVideoCompositionRequests
{
    // pending requests will call finishCancelledRequest, those already rendering will call finishWithComposedVideoFrame
    _shouldCancelAllRequests = YES;
    
    dispatch_barrier_async(_renderingQueue, ^() {
        // start accepting requests again
        _shouldCancelAllRequests = NO;
    });
}



- (CVPixelBufferRef)newRenderedPixelBufferForRequest:(AVAsynchronousVideoCompositionRequest *)request error:(NSError **)errOut
{
    CVPixelBufferRef dstPixels = nil;
    dstPixels = [_renderContext newPixelBuffer];
    
    if (request.sourceTrackIDs.count > 0)
    {
        CVPixelBufferRef videoBufferRef = [request sourceFrameByTrackID:[[request.sourceTrackIDs objectAtIndex:0] intValue]];
        if (videoBufferRef) {
            [[MHVideoCompositionManager shareManager]prepareToDraw:videoBufferRef andDestination:dstPixels andCompositionTime:request.compositionTime];
        }else {
            return nil;
        }
    }
    return dstPixels;
}

@end
