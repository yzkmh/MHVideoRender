//
//  ViewController.m
//  MHVideoExport+OpenGLES
//
//  Created by FUZE on 2017/8/29.
//  Copyright © 2017年 FUZE. All rights reserved.
//

#import "ViewController.h"
#import "MHVideoPlayerManager.h"
#import "MHVideoView.h"

@interface ViewController ()
{

}
@property (nonatomic, strong) MHVideoView *videoView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSURL *urlbase = [[NSBundle mainBundle]URLForResource:@"12" withExtension:@"mp4"];
    AVPlayer *player = [[AVPlayer alloc]initWithURL:urlbase];
    
    AVPlayerLayer *layer = [[AVPlayerLayer alloc]init];
    layer.frame = self.view.bounds;
    [self.view.layer addSublayer:layer];
    [layer setPlayer:player];
    [player play];
    
    NSURL *url = [[NSBundle mainBundle]URLForResource:@"1_720" withExtension:@"mp4"];
    NSLog(@"%@",NSStringFromCGRect(self.view.bounds));
    _videoView = [[MHVideoView alloc]initWithFrame:self.view.bounds];
    _videoView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_videoView];
    [[MHVideoPlayerManager shareManager]loadVideoWithURL:url showOnView:_videoView];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)addEffect:(UIButton *)sender
{
    [MHVideoPlayerManager shareManager].type = MHVideoPrepareToEdit;
    sender.hidden = YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




@end
