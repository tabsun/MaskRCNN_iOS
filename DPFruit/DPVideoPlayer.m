//
//  DPVideoPlayer.m
//  DPFruit
//
//  Created by caochunyuan on 2017/12/26.
//  Copyright © 2017年 dress. All rights reserved.
//

#import "DPVideoPlayer.h"
#import "CVPixelBufferUtils.h"

@interface DPVideoPlayer ()

@property (nonatomic, strong) AVAssetReader *reader;
@property (nonatomic, strong) AVAssetTrack *videoTrack;
@property (nonatomic, strong) AVURLAsset *urlAsset;
@property (nonatomic, strong) AVAssetReaderTrackOutput *videoReaderOutput;
@property (nonatomic, assign) int rotationConstant;

@end

@implementation DPVideoPlayer

- (instancetype)init {
    self = [super init];
    if (self) {
       
    }
    return self;
}

+ (instancetype) sharedVideoPlayer {
    static DPVideoPlayer *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DPVideoPlayer alloc] init];
    });
    return instance;
}

- (BOOL)setupAVAssetReader:(NSURL *)videoUrl {
    self.urlAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    NSError *error = nil;
    self.reader = [[AVAssetReader alloc] initWithAsset:self.urlAsset error:&error];
    if (error) {
        return NO;
    } else {
        [self trackOutput];
        [self assetReaderTrackOutput];
        [self getCMSampleBufferRef];
    }
    return YES;
}

- (AVAssetReader *)createReader {
    if (self.urlAsset == nil) {
        return nil;
    }
    NSError *error = nil;
    self.reader = [[AVAssetReader alloc] initWithAsset:self.urlAsset error:&error];
    NSDictionary *decompressionVideoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]};
    self.videoReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:self.videoTrack outputSettings:decompressionVideoSettings];
    self.videoReaderOutput.alwaysCopiesSampleData = NO;
    if ([self.reader canAddOutput:self.videoReaderOutput]) {
        [self.reader addOutput:self.videoReaderOutput];
    }
    return self.reader;
}

- (void)start {
    if ([self.reader status] == AVAssetReaderStatusCancelled) {
        self.reader = [self createReader];
        [self.reader startReading];
        [self getCMSampleBufferRef];
    }
}

- (void)trackOutput {
    AVAsset *localAsset = self.reader.asset;
    self.rotationConstant = [self rotationConstantFromVideoFileWithAsset:localAsset];
    // Get the video track to read
    self.videoTrack = [[localAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
}

- (void)assetReaderTrackOutput {
    NSDictionary *decompressionVideoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]};
    self.videoReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:self.videoTrack outputSettings:decompressionVideoSettings];
    self.videoReaderOutput.alwaysCopiesSampleData = NO;
    if ([self.reader canAddOutput:self.videoReaderOutput]) {
        [self.reader addOutput:self.videoReaderOutput];
    }
    [self.reader startReading];
}

- (void)getCMSampleBufferRef {
    dispatch_async(dispatch_queue_create("com.dressplus.videoPlayer", NULL), ^{
        while ([self.reader status] == AVAssetReaderStatusReading && self.videoTrack.nominalFrameRate > 0) {
            // video sample
            CMSampleBufferRef videoBuffer = [self.videoReaderOutput copyNextSampleBuffer];
            CMTime duration = CMSampleBufferGetOutputPresentationTimeStamp(videoBuffer);
            CVPixelBufferRef pixelBuffer = [CVPixelBufferUtils rotateBuffer:videoBuffer withConstant:self.rotationConstant withMirrored:0];
            if (pixelBuffer == NULL) {
                NSLog(@"videobuffer nil %ld",(long)[self.reader status]);
            }
            if (pixelBuffer && self.delegate) {
                [self.delegate moveDecoderOnNewVideoFrameReady:pixelBuffer videoDuration:duration];
                CFRelease(videoBuffer);
                videoBuffer = NULL;
            }
        }
        while ([self.reader status] == AVAssetReaderStatusCompleted) {
            if (self.delegate != nil) {
                [self.delegate moveDecoderOnDecoderFinished];
            }
            return;
        }
    });
}

- (void)assetReaderStopReading {
    if ([self.reader status] == AVAssetReaderStatusReading) {
        [self.reader cancelReading];
    }
}

- (void)assetReaderRestartReading {
   if ([self.reader status] == AVAssetReaderStatusCancelled) {
       self.reader = [[AVAssetReader alloc] initWithAsset:self.urlAsset error:nil];
       [self.reader startReading];
    }
}

// 获取视频角度
- (int)rotationConstantFromVideoFileWithAsset:(AVAsset *)asset {
    int degress = 0;
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
            // Portrait
            degress = 3;
        } else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
            // PortraitUpsideDown
            degress = 1;
        } else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
            // LandscapeRight
            degress = 0;
        } else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
            // LandscapeLeft
            degress = 2;
        }
    }
    return degress;
}

@end
