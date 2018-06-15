//
//  DPVideoCapture.m
//  DPFruit
//
//  Created by caochunyuan on 2017/12/14.
//  Copyright © 2017年 dress. All rights reserved.
//

#import "DPVideoCapture.h"
#import "CVPixelBufferUtils.h"
@interface DPVideoCapture () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, assign) CMTime lastTimestamp;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;

@end

@implementation DPVideoCapture

- (instancetype)init {
    if (self = [super init]) {
        self.captureSession = [[AVCaptureSession alloc] init];
        self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        self.queue = dispatch_queue_create("com.dressplus.cameraQueue", NULL);
        self.lastTimestamp = CMTimeMake(1, 1);
        self.fps = 15;
    }
    return self;
}

- (void)setup:(void(^)(BOOL))completion {
    dispatch_async(self.queue, ^{
        BOOL success = [self setUpCamera];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(success);
        });
    });
}

- (BOOL)setUpCamera {
    [self.captureSession beginConfiguration];
    self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
    self.captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!self.captureDevice) {
        NSLog(@"Error: no video devices available");
        return false;
    }
    
    NSError *error;
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&error];
    if (!videoInput) {
        NSLog(@"Error: could not create AVCaptureDeviceInput");
        return false;
    }
    
    if ([self.captureSession canAddInput:videoInput]) {
        [self.captureSession addInput:videoInput];
    }
    
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    self.previewLayer = previewLayer;
    self.videoOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    self.videoOutput.alwaysDiscardsLateVideoFrames = true;
    [self.videoOutput setSampleBufferDelegate:self queue:self.queue];
    if ([self.captureSession canAddOutput:self.videoOutput]) {
        [self.captureSession addOutput:self.videoOutput];
    }
    
    // buffers to be in portrait orientation
    //[self.videoOutput connectionWithMediaType:AVMediaTypeVideo].videoOrientation = AVCaptureVideoOrientationPortrait;
    [self.captureSession commitConfiguration];
    return true;
}
    
- (void)switchCamera {
    AVCaptureDevicePosition desiredPosition;
    if ([self.captureDevice position] == AVCaptureDevicePositionFront)
        desiredPosition = AVCaptureDevicePositionBack;
    else
        desiredPosition = AVCaptureDevicePositionFront;
    
    AVCaptureDeviceDiscoverySession *deviceSession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:desiredPosition];
    for (AVCaptureDevice *d in deviceSession.devices) {
        if ([d position] == desiredPosition) {
            [[self.previewLayer session] beginConfiguration];
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            for (AVCaptureInput *oldInput in [[self.previewLayer session] inputs]) {
                [[self.previewLayer session] removeInput:oldInput];
            }
            [[self.previewLayer session] addInput:input];
            self.captureDevice = d;
            [[self.previewLayer session] commitConfiguration];
            break;
        }
    }
}

- (void)start {
    if (!self.captureSession.isRunning) {
        [self.captureSession startRunning];
    }
}

- (void)stop {
    if (self.captureSession.isRunning) {
        [self.captureSession stopRunning];
    }
}

- (uint8_t)deviceOritation {
    BOOL isMirrored = self.captureDevice.position == AVCaptureDevicePositionFront;

    uint8_t orientation = 0;
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            orientation = isMirrored ? 3 : 3;
            break;
        case UIDeviceOrientationLandscapeLeft:
            orientation = isMirrored ? 2 : 0;
            break;
        case UIDeviceOrientationLandscapeRight:
            orientation = isMirrored ? 0 : 2;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            orientation = isMirrored ? 1 : 1;
            break;
        default:
            orientation = 0;
            break;
    }
    return orientation;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    CMTime deltaTime = CMTimeSubtract(timestamp, self.lastTimestamp);
    [self deviceOritation];
    if (CMTimeCompare(deltaTime, CMTimeMake(1, self.fps))) {
        self.lastTimestamp = timestamp;
        //CVImageBufferRef imageBuffer1 = CMSampleBufferGetImageBuffer(sampleBuffer);
        BOOL isMirrored = self.captureDevice.position == AVCaptureDevicePositionFront;
        uint8_t oritention = [self deviceOritation];
        CVPixelBufferRef imageBuffer = [CVPixelBufferUtils rotateBuffer:sampleBuffer withConstant:oritention withMirrored:isMirrored];
        if (self.delegate != nil) {
            [self.delegate videoCaptureDidCaptureVideoFrame:imageBuffer withTimestamp:timestamp];
        }
    } else {
        NSLog(@"未执行代理方法");
    }
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    //print("dropped frame")
}

@end
