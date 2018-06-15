//
//  MaskView.h
//  DPFruit
//
//  Created by 孙海涌 on 5/1/2018.
//  Copyright © 2018 dress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MaskModel.h"

@interface MaskView : NSObject

- (NSMutableArray *)maskViewsWithPixelBuffer:(CVPixelBufferRef)buffer;
- (NSMutableArray *)maskViewsWithImage:(UIImage *)image;
- (MaskModel *)depthWithPixelBuffer:(CVPixelBufferRef)buffer;
- (MaskModel *)depthWithImage:(UIImage *)image;
- (void)reset:(float *)detectionMinConfidence;

@end
