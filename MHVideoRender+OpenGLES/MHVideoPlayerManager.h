//
//  MHVideoPlayerManager.h
//  MHVideoExport
//
//  Created by FUZE on 2017/8/18.
//  Copyright © 2017年 FUZE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


typedef NS_ENUM(NSUInteger,MHVideoEditType) {
    MHVideoNormal,
    MHVideoPrepareToEdit,
    MHVideoEidting,
    MHVideoEidtFinished,
};

@interface MHVideoPlayerManager : NSObject
@property (strong, nonatomic, nullable) AVPlayer *player;
@property (strong, nonatomic, nullable) AVPlayerLayer *playerLayer;
@property (strong, nonatomic, nullable) AVPlayerItem  *playerItem;
@property (strong, nonatomic, nullable) AVAsset *asset;
//@property (nonatomic) CMTime compositionTime;
@property (assign, nonatomic) MHVideoEditType type;
@property (nonatomic, assign) BOOL isPlaying;


+ (nullable instancetype)shareManager;

- (void)loadVideoWithURL:(nullable NSURL *)url showOnView:(nullable UIView *)showView;

- (CGImageRef _Nullable)currentVideoFrame;

- (void)play;

- (void)pause;

- (void)videoSeekToTime:(CGFloat)time;

@end
