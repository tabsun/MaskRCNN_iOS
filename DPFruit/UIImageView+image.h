//
//  UIImageView+image.h
//  DPFruit
//
//  Created by 曹春园 on 2018/1/6.
//  Copyright © 2018年 dress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (image)

+ (UIImageView *)getImageViewWithMaskBounds:(CGRect)objBox previewSize:(CGSize)previewSize originaImageSize:(CGSize)imageSize fromFrontCamera:(BOOL)isFrontCamera;

@end
