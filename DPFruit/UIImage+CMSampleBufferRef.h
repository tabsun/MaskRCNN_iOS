//
//  UIImage+CMSampleBufferRef.h
//  DPFruit
//
//  Created by caochunyuan on 2017/12/26.
//  Copyright © 2017年 dress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@interface UIImage (CMSampleBufferRef)

+ (UIImage *)imageFromSampleBufferRef:(CVImageBufferRef)imageBuffer rotate:(int)degree;
+ (CGImageRef)CGImageFromSampleBufferRef:(CMSampleBufferRef)sampleBufferRef;
- (UIImage *)fixOrientation:(UIImageOrientation)imageOrientation;
//+ (UIImage *)addBpolygonToImage:(UIImage *)image withLineWidth:(CGFloat)lineW andColor:(UIColor *)color;
+ (UIImage *)addBorderToImage:(UIImage *)image;

@end
