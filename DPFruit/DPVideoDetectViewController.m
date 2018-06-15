//
//  DPAlbumDetectViewController.m
//  DPFruit
//
//  Created by caochunyuan on 2017/12/16.
//  Copyright © 2017年 dress. All rights reserved.
//

#import "DPVideoDetectViewController.h"
#import "DPModelNet.h"
#import "DPVideoPlayer.h"
#import "UIImage+CMSampleBufferRef.h"
#import "MaskView.h"
#import "UIImageView+image.h"

typedef NS_ENUM(NSInteger, PredictionMode) {
    PredictionModeAll,
    PredictionModeMask,
    PredictionModeDepth,
};

@interface DPVideoDetectViewController () <VideoTransformDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIView *resultView;
@property (nonatomic, strong) UIImage *chooseImage;
@property (nonatomic, assign) CMTime lastTime;
@property (atomic, assign) int framesDone;
@property (nonatomic, assign) CFTimeInterval frameCapturingStartTime;
@property (nonatomic, strong) DPVideoPlayer *videoPlayer;
@property (weak, nonatomic) IBOutlet UIImageView *maskView;
@property (weak, nonatomic) IBOutlet UIImageView *depthView;
@property (weak, nonatomic) IBOutlet UIImageView *segmentationView;
@property (nonatomic, strong) NSArray *class_names;
@property (nonatomic) PredictionMode predictMode;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (nonatomic, strong) NSBlockOperation *operation;
@property (nonatomic, strong) NSOperationQueue *queue;

@end

@implementation DPVideoDetectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.class_names = @[@"backgroud",@"person",@"cat",@"dog",@"table",@"face",@"others"];
    self.lastTime = kCMTimeZero;
    self.framesDone = 0;
    self.timeLabel.text = @"";
    self.frameCapturingStartTime = CACurrentMediaTime();
    self.queue = [[NSOperationQueue alloc] init];
    self.queue.maxConcurrentOperationCount = 2;
    [NSLayoutConstraint constraintWithItem:self.imageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view.safeAreaLayoutGuide attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([self.mediaType containsString:@"image"]) {
//        MaskView *mask = [[MaskView alloc] init];
//        [mask reset];
        self.segmentControl.hidden = YES;
        self.resultView.hidden = YES;
        self.chooseImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:self.chooseUrl]];
        self.imageView.image = self.chooseImage;
        UIImage *rotatedImage = [self.chooseImage fixOrientation:self.chooseImage.imageOrientation];
        [self predictWithImage:rotatedImage];
    } else if ([self.mediaType containsString:@"movie"]) {
//        MaskView *mask = [[MaskView alloc] init];
//        [mask reset];
        self.videoPlayer = [DPVideoPlayer sharedVideoPlayer];
        self.videoPlayer.delegate = self;
        [self.videoPlayer setupAVAssetReader:self.chooseUrl];
    }
}

- (void)predictWithImage:(UIImage *)image {
    int captureImageWidth = image.size.width;
    int captureImageHeight = image.size.height;
    MaskView *mask = [[MaskView alloc] init];
    NSArray *masks = [mask maskViewsWithImage:image];
    MaskModel *model = [mask depthWithImage:image];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.maskView.image = image;
        for (MaskModel *maskModel in masks) {
            UIImageView *maskView = [UIImageView getImageViewWithMaskBounds:maskModel.objBox previewSize:self.imageView.bounds.size originaImageSize:CGSizeMake(captureImageWidth, captureImageHeight) fromFrontCamera:NO];
            maskView.image = maskModel.maskImage;
            [self.imageView addSubview:maskView];
            NSString *text = [NSString stringWithFormat:@"%@\n%.2f",[self.class_names objectAtIndex:maskModel.class_id],maskModel.score];
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(2, 0, 70, 30)];
            label.numberOfLines = 0;
            label.text = text;
            label.font = [UIFont systemFontOfSize:11];
            [maskView addSubview:label];
            
        }
        for (MaskModel *maskModel in masks) {
            UIImageView *imageView = [UIImageView getImageViewWithMaskBounds:maskModel.objBox previewSize:self.maskView.bounds.size originaImageSize:CGSizeMake(captureImageWidth, captureImageHeight) fromFrontCamera:NO];
            imageView.image = maskModel.maskImage;
            [self.maskView addSubview:imageView];
          
        }
        self.depthView.image = model.depthImage;
        UIImage *borderImage = [UIImage addBorderToImage:model.sceneImage];
        self.segmentationView.image = borderImage;
    });
}

- (void)predictMask:(CVImageBufferRef)pixelBuffer {
    int captureImageWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int captureImageHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    MaskView *mask = [[MaskView alloc] init];
    NSArray *masks = [mask maskViewsWithPixelBuffer:pixelBuffer];
    UIImage *cameraImage = [UIImage imageFromSampleBufferRef:pixelBuffer rotate:0];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.maskView.image = cameraImage;
        [self.imageView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.maskView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        for (MaskModel *maskModel in masks) {
            UIImageView *imageView = [UIImageView getImageViewWithMaskBounds:maskModel.objBox previewSize:self.imageView.bounds.size originaImageSize:CGSizeMake(captureImageWidth, captureImageHeight) fromFrontCamera:NO];
            UIImage *image = maskModel.maskImage;
            imageView.image = image;
            [self.imageView addSubview:imageView];
            NSString *text = [NSString stringWithFormat:@"%@\n%.2f",[self.class_names objectAtIndex:maskModel.class_id],maskModel.score];
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(2, 0, 70, 30)];
            label.numberOfLines = 0;
            label.text = text;
            label.font = [UIFont systemFontOfSize:11];
            [imageView addSubview:label];
            
            UIImageView *imageViewSmall = [UIImageView getImageViewWithMaskBounds:maskModel.objBox previewSize:self.maskView.bounds.size originaImageSize:CGSizeMake(captureImageWidth, captureImageHeight) fromFrontCamera:NO];
            imageViewSmall.image = maskModel.maskImage;
            [self.maskView addSubview:imageViewSmall];
        }
    });
}

- (void)predictDepth:(CVImageBufferRef)pixelBuffer {
    MaskView *mask = [[MaskView alloc] init];
    MaskModel *model = [mask depthWithPixelBuffer:pixelBuffer];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.predictMode == PredictionModeDepth) {
            [self.imageView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        }
        if (model != nil) {
            self.depthView.image = model.depthImage;
            UIImage *borderImage = [UIImage addBorderToImage:model.sceneImage];
            self.segmentationView.image = borderImage;
        }
    });
}

#pragma mark - SegmentControl
- (IBAction)predictionModeChange:(id)sender {
    //NSLog(@"mode change%@",[NSThread currentThread]);
    UISegmentedControl *segment = sender;
    switch (segment.selectedSegmentIndex) {
        case 0:
            self.predictMode = PredictionModeAll;
            self.maskView.hidden = NO;
            self.segmentationView.hidden = NO;
            self.depthView.hidden = NO;
            [self.maskView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            break;
        case 1:
            self.predictMode = PredictionModeMask;
            self.maskView.hidden = NO;
            self.segmentationView.hidden = YES;
            self.depthView.hidden = YES;
            [self.maskView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            break;
        case 2:
            self.predictMode = PredictionModeDepth;
            self.maskView.hidden = YES;
            self.segmentationView.hidden = NO;
            self.depthView.hidden = NO;
            [self.imageView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            break;
        default:
            break;
    }
}

- (double)measureFPS {
    self.framesDone += 1;
    NSTimeInterval frameCapturingElapsed = CACurrentMediaTime() - self.frameCapturingStartTime;
    double currentFPSDelivered = self.framesDone / frameCapturingElapsed;
    if (frameCapturingElapsed > 1) {
        self.framesDone = 0;
        self.frameCapturingStartTime = CACurrentMediaTime();
    }
    return currentFPSDelivered;
}

#pragma mark - DPVideoPlayerDelegate
- (void)moveDecoderOnNewVideoFrameReady:(CVPixelBufferRef)buffer videoDuration:(CMTime)duration {
    UIImage *image = [UIImage imageFromSampleBufferRef:buffer rotate:0];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.image = image;
    });
    CMTime pauseTime = CMTimeSubtract(duration, self.lastTime);
    self.lastTime = duration;
    [NSThread sleepForTimeInterval:CMTimeGetSeconds(pauseTime)];
    
    __weak typeof(self) weakSelf = self;
    if (self.predictMode == PredictionModeAll) {
        if (self.operation == nil || self.operation.isFinished) {
            self.operation = [NSBlockOperation blockOperationWithBlock:^{
                [self predictMask:buffer];
            }];
            [self.operation addExecutionBlock:^{
                [weakSelf predictDepth:buffer];
            }];
            [self.queue addOperation:self.operation];
            self.operation.completionBlock = ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    double fps = [weakSelf measureFPS];
                    weakSelf.timeLabel.text = [NSString stringWithFormat:@"%f fps",fps];
                });
                CVPixelBufferRelease(buffer);
            };
        } else {
            CVPixelBufferRelease(buffer);
        }
    } else if (self.predictMode == PredictionModeMask) {
        if (self.operation == nil || self.operation.isFinished) {
            self.operation = [NSBlockOperation blockOperationWithBlock:^{
                [self predictMask:buffer];
            }];
            [self.queue addOperation:self.operation];
            self.operation.completionBlock = ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    double fps = [weakSelf measureFPS];
                    weakSelf.timeLabel.text = [NSString stringWithFormat:@"%f fps",fps];
                });
                CVPixelBufferRelease(buffer);
            };
        } else {
            CVPixelBufferRelease(buffer);
        }
    } else if (self.predictMode == PredictionModeDepth) {
        if (self.operation == nil || self.operation.isFinished) {
            self.operation = [NSBlockOperation blockOperationWithBlock:^{
                [self predictDepth:buffer];
            }];
            [self.queue addOperation:self.operation];
            self.operation.completionBlock = ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    double fps = [weakSelf measureFPS];
                    weakSelf.timeLabel.text = [NSString stringWithFormat:@"%f fps",fps];
                });
                CVPixelBufferRelease(buffer);
            };
        } else {
            CVPixelBufferRelease(buffer);
        }
    }
}

- (void)moveDecoderOnDecoderFinished {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.segmentControl.enabled = NO;
    });
}

- (IBAction)backToForward:(id)sender {
    [self.videoPlayer assetReaderStopReading];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showCameraCapture"];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
    self.videoPlayer.delegate = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
