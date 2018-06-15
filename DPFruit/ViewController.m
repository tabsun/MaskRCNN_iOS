//
//  ViewController.m
//  DPFruit
//
//  Created by caochunyuan on 2017/12/14.
//  Copyright © 2017年 dress. All rights reserved.
//

#import "ViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "DPVideoCapture.h"
#import "DPVideoDetectViewController.h"
#import "DPLatestPhoto.h"
#import "MaskView.h"
#import "UIImageView+image.h"
#import "UIImage+CMSampleBufferRef.h"
#import "DPThresholdViewController.h"
typedef NS_ENUM(NSInteger, PredictionMode) {
    PredictionModeAll,
    PredictionModeMask,
    PredictionModeDepth,
};

@interface ViewController () <VideoCaptureDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIView *videoPreview;
@property (weak, nonatomic) IBOutlet UILabel *predictionLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *albumButton;
@property (nonatomic, strong) DPVideoCapture *videoCapture;
@property (nonatomic, assign) int framesDone;
@property (nonatomic, assign) CFTimeInterval frameCapturingStartTime;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (nonatomic) PredictionMode predictMode;
@property (weak, nonatomic) IBOutlet UIImageView *maskView;
@property (weak, nonatomic) IBOutlet UIImageView *depthView;
@property (weak, nonatomic) IBOutlet UIImageView *segmentationView;
@property (nonatomic, strong) dispatch_group_t group;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.predictMode = PredictionModeAll;
    self.framesDone = 0;
    self.frameCapturingStartTime = CACurrentMediaTime();
    self.semaphore = dispatch_semaphore_create(1);
    self.group = dispatch_group_create();
    self.predictionLabel.text = @"";
    self.timeLabel.text = @"";
    [self setUpCamera];
    [self setAlbumButtonImage];
    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self resizePreviewLayer];
}

- (void)resizePreviewLayer {
    self.videoCapture.previewLayer.frame = self.videoPreview.bounds;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    BOOL showCameraCapture = [[NSUserDefaults standardUserDefaults] boolForKey:@"showCameraCapture"];
    if (showCameraCapture) {
        [self.videoCapture start];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showCameraCapture"];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.videoPreview.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if ( UIDeviceOrientationIsPortrait( deviceOrientation ) || UIDeviceOrientationIsLandscape( deviceOrientation ) ) {
        self.videoCapture.previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
    }
}

- (void)setAlbumButtonImage {
    [DPLatestPhoto getLastestPhotoHandler:^(UIImage *image) {
        if (image) {
            [self.albumButton setImage:image forState:UIControlStateNormal];
            [self.albumButton setImage:image forState:UIControlStateHighlighted];
        }
    }];
}

- (void)setUpCamera {
    self.videoCapture = [[DPVideoCapture alloc] init];
    self.videoCapture.delegate = self;
    self.videoCapture.fps = 50;
    [self.videoCapture setup:^(BOOL success) {
        AVCaptureVideoPreviewLayer *previewLayer = self.videoCapture.previewLayer;
        [self.videoPreview.layer addSublayer:previewLayer];
        [self.videoCapture start];
    }];
}

- (IBAction)predictionModeChange:(id)sender {
    UISegmentedControl *segmentControl = sender;
    switch (segmentControl.selectedSegmentIndex) {
        case 0:
            self.predictMode = PredictionModeAll;
            self.maskView.hidden = NO;
            self.segmentationView.hidden = NO;
            self.depthView.hidden = NO;
            break;
        case 1:
            self.predictMode = PredictionModeMask;
            self.maskView.hidden = NO;
            self.segmentationView.hidden = YES;
            self.depthView.hidden = YES;
            break;
        case 2:
            self.predictMode = PredictionModeDepth;
            self.maskView.hidden = YES;
            self.segmentationView.hidden = NO;
            self.depthView.hidden = NO;
            [self.videoPreview.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            break;
        default:
            break;
    }
}

- (void)predictMask:(CVImageBufferRef)pixelBuffer {
    NSArray *class_names = @[@"backgroud",@"person",@"cat",@"dog",@"table",@"face",@"others"];
    int captureImageWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int captureImageHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    MaskView *mask = [[MaskView alloc] init];
    NSArray *masks = [mask maskViewsWithPixelBuffer:pixelBuffer];
    UIImage *cameraImage = [UIImage imageFromSampleBufferRef:pixelBuffer rotate:0];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.maskView.image = cameraImage;
        [self.videoPreview.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.maskView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        for (MaskModel *maskModel in masks) {
            UIImageView *imageView = [UIImageView getImageViewWithMaskBounds:maskModel.objBox previewSize:self.videoPreview.bounds.size originaImageSize:CGSizeMake(captureImageWidth, captureImageHeight) fromFrontCamera:NO];
            UIImage *image = maskModel.maskImage;
            imageView.image = image;
            [self.videoPreview addSubview:imageView];
            NSString *text = [NSString stringWithFormat:@"%@\n%.2f",[class_names objectAtIndex:maskModel.class_id],maskModel.score];
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
            [self.videoPreview.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        }
        if (model != nil) {
            UIImage *borderImage = [UIImage addBorderToImage:model.sceneImage];
            self.depthView.image = model.depthImage;
            self.segmentationView.image = borderImage;
        }
    });
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

#pragma mark - videoCapture delegate
-(void)videoCaptureDidCaptureVideoFrame:(CVImageBufferRef)buffer withTimestamp:(CMTime)timestamp {
    
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    if (self.predictMode == PredictionModeAll) {
        dispatch_group_async(self.group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self predictDepth:buffer];
        });
        dispatch_group_async(self.group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self predictMask:buffer];
        });
    } else if (self.predictMode == PredictionModeMask) {
        dispatch_group_async(self.group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self predictMask:buffer];
        });
    } else if (self.predictMode == PredictionModeDepth) {
        dispatch_group_async(self.group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self predictDepth:buffer];
        });
    }
    dispatch_group_notify(self.group, dispatch_get_main_queue(), ^{
        double fps = [self measureFPS];
        //double fps1 = 1 / (self.maskDuration);
        self.timeLabel.text = [NSString stringWithFormat:@"%f fps",fps];
        CVPixelBufferRelease(buffer);
        dispatch_semaphore_signal(self.semaphore);
    });
}

#pragma mark - Button Album
- (IBAction)AlbumButtonPressed:(id)sender {
    [self.videoCapture stop];
    [self setupImagePickerController];
}

- (void)setupImagePickerController {
    _imagePicker = [[UIImagePickerController alloc] init];
    _imagePicker.modalPresentationStyle = UIModalTransitionStyleFlipHorizontal;
    _imagePicker.allowsEditing = NO;
    _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    _imagePicker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *)kUTTypeImage, (NSString *)kUTTypeMovie, nil];
    _imagePicker.delegate = self;
    [self presentViewController:_imagePicker animated:YES completion:nil];
}

#pragma mark - imagePickerController delegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSURL *chooseUrl = nil;
    NSURL *imageUrl = info[UIImagePickerControllerImageURL];
    NSURL *videoUrl = info[UIImagePickerControllerMediaURL];
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    if (imageUrl) {
        chooseUrl = imageUrl;
    } else if (videoUrl) {
        chooseUrl = videoUrl;
    }
    [_imagePicker dismissViewControllerAnimated:YES completion:^{
        DPVideoDetectViewController *viewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"DPAlbumDetectViewController"];
        viewController.chooseUrl = chooseUrl;
        viewController.mediaType = mediaType;
        [self presentViewController:viewController animated:YES completion:nil];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [_imagePicker dismissViewControllerAnimated:YES completion:^{
        [self.videoCapture start];
    }];
}

#pragma mark - button switch
- (IBAction)switchCamera:(id)sender {
    [self.videoCapture switchCamera];
}

#pragma mark - button setting
- (IBAction)settingButtonPressed:(id)sender {
    [self.videoCapture stop];
    DPThresholdViewController *thresholdViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"Threshold"];
    [self presentViewController:thresholdViewController animated:YES completion:nil];
}

- (void)dealloc {
    self.videoCapture.delegate = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
