//
//  DPVideoCapture.h
//  DPFruit
//
//  Created by caochunyuan on 2017/12/14.
//  Copyright © 2017年 dress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol VideoCaptureDelegate <NSObject>

- (void)videoCaptureDidCaptureVideoFrame:(CVImageBufferRef)buffer withTimestamp:(CMTime)timestamp;

@end

@interface DPVideoCapture : NSObject

@property (nonatomic, assign) int fps;
@property (nonatomic, weak) id<VideoCaptureDelegate>delegate;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

- (void)setup:(void(^)(BOOL))completion;
- (void)start;
- (void)stop;
- (void)switchCamera;

@end


