//
//  ViewController.m
//  CameraStickerDemo
//
//  Created by Sinkup on 2016/12/4.
//  Copyright © 2016年 Asura. All rights reserved.
//

#import "ViewController.h"

#import <GPUImage/GPUImage.h>
#import <AssetsLibrary/ALAssetsLibrary.h>

#import "SKSticker.h"
#import "SKStickerFilter.h"

@interface ViewController () <GPUImageVideoCameraDelegate>
{
}
@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageView *filterView;

@property (nonatomic, strong) SKStickerFilter *stickerFilter;

@property (nonatomic, copy) NSArray<SKSticker *> *stickers;
@property (nonatomic,strong)     GPUImageMovieWriter *movieWriter;
@property (nonatomic,assign) BOOL isRecording;
@property (nonatomic,strong) UIButton *recordButton;
@property (nonatomic,strong) NSString *recordFilePath;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    [self.videoCamera addAudioInputsAndOutputs];
    self.videoCamera.frameRate = 25;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    self.videoCamera.delegate = self;
    
    self.stickerFilter = [SKStickerFilter new];
    [self.videoCamera addTarget:self.stickerFilter];
    
    self.filterView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    self.filterView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    self.filterView.center = self.view.center;
    
    [self.view addSubview:self.filterView];
    
    [self.stickerFilter addTarget:self.filterView];
    [self.videoCamera startCameraCapture];
    
    [SKStickersManager loadStickersWithCompletion:^(NSArray<SKSticker *> *stickers) {
        self.stickers = stickers;
        self.stickerFilter.sticker = [stickers firstObject];
    }];
    
    
    UIButton *fireworkButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [fireworkButton setTitle:@"Show Fireworks" forState:UIControlStateNormal];
    [fireworkButton addTarget:self action:@selector(showFirework) forControlEvents:UIControlEventTouchUpInside];
    fireworkButton.frame = CGRectMake(100, 100, 200, 40);
    [self.view addSubview:fireworkButton];
    
    
    UIButton *giftButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [giftButton setTitle:@"Show Gift" forState:UIControlStateNormal];
    [giftButton addTarget:self action:@selector(showGift) forControlEvents:UIControlEventTouchUpInside];
    giftButton.frame = CGRectMake(100, 150, 200, 40);
    [self.view addSubview:giftButton];

    UIButton *removeAllStickers = [UIButton buttonWithType:UIButtonTypeSystem];
    [removeAllStickers setTitle:@"Clear" forState:UIControlStateNormal];
    [removeAllStickers addTarget:self action:@selector(remove) forControlEvents:UIControlEventTouchUpInside];
    removeAllStickers.frame = CGRectMake(100, 200, 200, 40);
    [self.view addSubview:removeAllStickers];
    
    
    _recordButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_recordButton setTitle:@"Record" forState:UIControlStateNormal];
    [_recordButton setTitle:@"Stop" forState:UIControlStateSelected];
    [_recordButton addTarget:self action:@selector(record) forControlEvents:UIControlEventTouchUpInside];
    _recordButton.frame = CGRectMake(100, 250, 200, 40);
    [self.view addSubview:_recordButton];
    
    
    
}

- (void)showFirework {
    self.stickerFilter.sticker = self.stickers.firstObject;
}

- (void)showGift {
    self.stickerFilter.sticker = self.stickers.lastObject;

}

- (void)remove {
    
        self.stickerFilter.sticker = [SKSticker new];
    
}

- (void)record {
    
    
    if (_isRecording) {
        [self endRocrding];
        [_recordButton setSelected:NO];
        return;
    }
    
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

    NSString *path = paths.firstObject;
    
    NSString *moviePath = [path stringByAppendingString:@"/test.mp4"];
    _recordFilePath = moviePath;
//    NSFileManager *mgr = [NSFileManager defaultManager];
//    if([mgr fileExistsAtPath:moviePath]) {
//        [mgr removeItemAtPath:moviePath error:nil];
//    }
    
    unlink([moviePath UTF8String]); // 如果已经存在文件，AVAssetWriter会有异常，删除旧文件
    _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:[NSURL fileURLWithPath:moviePath] size:CGSizeMake(480, 640)];
    _movieWriter.encodingLiveVideo = YES;
    _movieWriter.shouldPassthroughAudio = YES;
    _movieWriter.hasAudioTrack = YES;
    [self.stickerFilter addTarget:_movieWriter];
    self.videoCamera.audioEncodingTarget = _movieWriter;
    [_movieWriter startRecording];
    _isRecording = YES;
    [_recordButton setSelected:YES];
}


- (void)endRocrding {
    
    [self.stickerFilter removeTarget:_movieWriter];
    _videoCamera.audioEncodingTarget = nil;
//    [_movieWriter finishRecording];
    
    
    
    [_movieWriter finishRecordingWithCompletionHandler:^{
        [self saveToCameraRoll];
    }];
    
 
    
    _isRecording = NO;
    _movieWriter = nil;
}

- (void)saveToCameraRoll {
    __weak typeof(self) weakSelf = self;

    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(weakSelf.recordFilePath))
    {
        [library writeVideoAtPathToSavedPhotosAlbum:[NSURL fileURLWithPath:weakSelf.recordFilePath] completionBlock:^(NSURL *assetURL, NSError *error)
         {
             dispatch_async(dispatch_get_main_queue(), ^{
                 
                 if (error) {
                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存失败" message:nil
                                                                    delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                     [alert show];
                 } else {
                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存成功" message:nil
                                                                    delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                     [alert show];
                 }
             });
         }];
    }
    else {
        NSLog(@"error mssg)");
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - GPUImageVideoCameraDelegate
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    // 在这里做人脸的检测
    
    // 使用假数据
    NSString *path = [[NSBundle mainBundle] pathForResource:@"fake_points" ofType:@"json"];
    NSArray *arr = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:path]
                                                     options:0
                                                       error:nil];
    
    NSMutableArray *faces = [NSMutableArray arrayWithCapacity:arr.count];
    for (NSArray *ele in arr) {
        NSMutableArray *points = [NSMutableArray arrayWithCapacity:ele.count];
        for (NSDictionary *dic in ele) {
            CGPoint point = CGPointMake([dic[@"x"] floatValue], [dic[@"y"] floatValue]);
            [points addObject:[NSValue valueWithCGPoint:point]];
        }
        
        [faces addObject:points];
    }
    
    self.stickerFilter.faces = faces;
}

@end
