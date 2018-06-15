//
//  DPVideoPlayer.h
//  DPFruit
//
//  Created by caochunyuan on 2017/12/26.
//  Copyright © 2017年 dress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol VideoTransformDelegate <NSObject>

- (void)moveDecoderOnNewVideoFrameReady:(CVPixelBufferRef)buffer videoDuration:(CMTime)duration;
- (void)moveDecoderOnDecoderFinished;

@end

@interface DPVideoPlayer : NSObject

@property (nonatomic, weak) id<VideoTransformDelegate> delegate;
- (BOOL)setupAVAssetReader:(NSURL *)videoUrl;
- (void)assetReaderStopReading;
- (void)assetReaderRestartReading;
+ (instancetype)sharedVideoPlayer;
- (void)start;
@end
