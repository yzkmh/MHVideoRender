//
//  MHVideoPlayerManager.m
//  MHVideoExport
//
//  Created by FUZE on 2017/8/18.
//  Copyright © 2017年 FUZE. All rights reserved.
//

#import "MHVideoPlayerManager.h"
#import "MHVideoCompositor.h"
#import <AssetsLibrary/AssetsLibrary.h>

#define kVideoRadio 540.f/960.f
#define kVideoEidtToolHeight 200.f
#define kVideoEidtViewHeight 150.f
@interface MHVideoPlayerManager ()
{
    id _notificationToken;
    BOOL isSeeking;
}

@property (strong, nonatomic) AVMutableVideoComposition *videoComposition;
@property (strong, nonatomic) AVAssetImageGenerator     *imageGenerator;
@property (strong, nonatomic, nonnull) UIView *contentView;
@property (strong, nonatomic, nonnull) UIView *showView;
@property (strong, nonatomic, nonnull) UIView *showViewSuperView;
@end


@implementation MHVideoPlayerManager

+ (nullable instancetype)shareManager
{
    static MHVideoPlayerManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MHVideoPlayerManager alloc]init];
    });
    return instance;
}
- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.player = [[AVPlayer alloc]init];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.playerLayer.backgroundColor = [UIColor clearColor].CGColor;
}


- (void)loadVideoWithURL:(nullable NSURL *)url showOnView:(nullable UIView *)showView
{
    if ([url isKindOfClass:NSString.class]) {
        url = [NSURL URLWithString:(NSString *)url];
    }
    if (![url isKindOfClass:NSURL.class]) {
        url = nil;
    }
    self.playerLayer = (AVPlayerLayer *)showView.layer;
    [self.playerLayer setPlayer:self.player];
    self.playerLayer.backgroundColor = [UIColor clearColor].CGColor;
    self.showView = showView;
    self.showViewSuperView = showView.superview;
    
    _asset = [[AVURLAsset alloc]initWithURL:url options:nil];
    _videoComposition = [AVMutableVideoComposition videoCompositionWithPropertiesOfAsset:_asset];
    _videoComposition.frameDuration = CMTimeMake(1, 10);
    CGRect frame = [UIScreen mainScreen].bounds;
    _videoComposition.renderSize = CGSizeMake(frame.size.width, frame.size.height); //[[[_asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
    _videoComposition.customVideoCompositorClass = [MHVideoCompositor class];
    self.playerItem = [AVPlayerItem playerItemWithAsset:_asset];
    self.playerItem.videoComposition = _videoComposition;
    [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    [self addDidPlayToEndTimeNotificationForPlayerItem:self.playerItem];
    [self play];
    
//    [self setupEditOperation];
}

- (void)addDidPlayToEndTimeNotificationForPlayerItem:(AVPlayerItem *)item
{
    if (_notificationToken)
        _notificationToken = nil;
    
    /*
     Setting actionAtItemEnd to None prevents the movie from getting paused at item end. A very simplistic, and not gapless, looped playback.
     */
    _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    _notificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:item queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        // Simple item playback rewind.
        [[_player currentItem] seekToTime:kCMTimeZero];
    }];
}

- (CGImageRef _Nullable)currentVideoFrame;
{
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [self.imageGenerator copyCGImageAtTime:self.player.currentItem.currentTime actualTime:&actualTime error:&error];
    return image;
}
- (void)play
{
    [self.player play];
    self.isPlaying = YES;
}

- (void)pause
{
    [self.player pause];
    self.isPlaying = NO;
}
- (void)videoSeekToTime:(CGFloat)time
{
    if (isSeeking) {
        return;
    }else{
        isSeeking = YES;
        [self.player pause];
        self.isPlaying = NO;
    }
    
    CGFloat value = self.playerItem.duration.value * time;
    
    [self.player seekToTime:CMTimeMake(value, self.playerItem.duration.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        isSeeking = NO;
    }];
}


#pragma makr property

- (AVAssetImageGenerator *)imageGenerator
{
    if (!_imageGenerator) {
        _imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:_asset];
        _imageGenerator.appliesPreferredTrackTransform = YES;
        _imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
        _imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    }
    return _imageGenerator;
}


@end
