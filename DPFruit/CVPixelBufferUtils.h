//
//  CVPixelBufferUtils.h
//  DPFruit
//
//  Created by 孙海涌 on 9/1/2018.
//  Copyright © 2018 dress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>
#import <AVFoundation/AVFoundation.h>
@interface CVPixelBufferUtils : NSObject
+ (CVPixelBufferRef)rotateBuffer:(CMSampleBufferRef)sampleBuffer withConstant:(uint8_t)rotationConstant withMirrored:(uint8_t)mirrorConstant;

@end
