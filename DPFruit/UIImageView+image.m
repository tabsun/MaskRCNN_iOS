//
//  UIImageView+image.m
//  DPFruit
//
//  Created by 曹春园 on 2018/1/6.
//  Copyright © 2018年 dress. All rights reserved.
//

#import "UIImageView+image.h"

@implementation UIImageView (image)

// mask bounds
+ (UIImageView *)getImageViewWithMaskBounds:(CGRect)objBox previewSize:(CGSize)previewSize originaImageSize:(CGSize)imageSize fromFrontCamera:(BOOL)isFrontCamera {
    int imageWidth = imageSize.width;
    int imageHeight = imageSize.height;
    CGFloat scale_w = previewSize.width * 1.0 / imageWidth;
    CGFloat scale_h = previewSize.height * 1.0 / imageHeight;
    CGFloat scale = 1.0;
    if (scale_w < scale_h) {
        scale = scale_w;
    } else {
        scale = scale_h;
    }
    CGFloat offsetX = (previewSize.width - imageWidth * scale) / 2;
    CGFloat offsetY = (previewSize.height - imageHeight * scale) / 2;
    UIImageView *maskView = [[UIImageView alloc] initWithFrame:CGRectMake(objBox.origin.x *scale + offsetX, objBox.origin.y * scale + offsetY, objBox.size.width * scale, objBox.size.height * scale)];
    CALayer * layer = [maskView layer];
    layer.borderColor = [[UIColor greenColor] CGColor];
    layer.borderWidth = 1.0f;
    return maskView;
}

@end
