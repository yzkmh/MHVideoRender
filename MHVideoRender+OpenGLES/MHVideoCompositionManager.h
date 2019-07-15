//
//  MHVideoCompositionManager.h
//  MHVideoExport
//
//  Created by FUZE on 2017/8/18.
//  Copyright © 2017年 FUZE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>

@interface MHVideoCompositionManager : NSObject

+ (instancetype)shareManager;

- (void)prepareToDraw:(CVPixelBufferRef)videoPixelBuffer andDestination:(CVPixelBufferRef)destinationPixelBuffer andCompositionTime:(CMTime)time;

@end
