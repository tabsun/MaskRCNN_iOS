//
//  UIImage+CMSampleBufferRef.m
//  DPFruit
//
//  Created by caochunyuan on 2017/12/26.
//  Copyright © 2017年 dress. All rights reserved.
//

#import "UIImage+CMSampleBufferRef.h"
#import <Accelerate/Accelerate.h>

@implementation UIImage (CMSampleBufferRef)
+ (UIImage *)imageFromSampleBufferRef:(CVImageBufferRef)imageBuffer rotate:(int)degree {
    //CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBufferRef);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytePerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytePerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    UIImage *image = nil;
    if (degree == 0) {
        image = [UIImage imageWithCGImage:quartzImage scale:1.0 orientation:UIImageOrientationUp];
    } else if (degree == 90) {
        image = [UIImage imageWithCGImage:quartzImage scale:1.0 orientation:UIImageOrientationRight];
    } else if (degree == 180) {
        image = [UIImage imageWithCGImage:quartzImage scale:1.0 orientation:UIImageOrientationDown];
    } else if (degree == 270) {
        image = [UIImage imageWithCGImage:quartzImage scale:1.0 orientation:UIImageOrientationLeft];
    }
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(quartzImage);
    return image;
}

+ (CGImageRef)CGImageFromSampleBufferRef:(CMSampleBufferRef)sampleBufferRef {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBufferRef);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytePerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytePerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return quartzImage;
}

- (UIImageOrientation)imageOrientationFromDegress:(int)angle {
    UIImageOrientation orientation = UIImageOrientationUp;
    
    int ratio = angle / 90;
    switch (ratio) {
        case 0:
            orientation = UIImageOrientationUp;
            break;
        case 1:
            orientation = UIImageOrientationLeft;
            break;
        case 2:
            orientation = UIImageOrientationDown;
            break;
        case 3:
            orientation = UIImageOrientationRight;
            break;
        default:
            orientation = UIImageOrientationUp;
            break;
    }
    return orientation;
}

- (UIImage *)fixOrientation:(UIImageOrientation)imageOrientation {
    //CGImageRef imageref = self.CGImage;
    if (imageOrientation == UIImageOrientationUp) {
        return self;
    }
    CGAffineTransform transform = CGAffineTransformIdentity;
    switch (imageOrientation) {
        case UIImageOrientationDown:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            CGAffineTransformTranslate(transform, self.size.width, 0);
            CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationLeft:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            CGAffineTransformTranslate(transform, self.size.height, 0);
            CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationRight:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            CGAffineTransformTranslate(transform, self.size.height, 0);
            CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
            break;
        case UIImageOrientationUpMirrored:
            CGAffineTransformTranslate(transform, self.size.width, 0);
            CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    CGContextRef ctx = CGBitmapContextCreate(nil, self.size.width, self.size.height, CGImageGetBitsPerComponent(self.CGImage), CGImageGetBytesPerRow(self.CGImage), CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextConcatCTM(ctx, transform);
    switch (imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0, 0, self.size.height, self.size.width), self.CGImage);
            break;
        default:
            CGContextDrawImage(ctx, CGRectMake(0, 0, self.size.width, self.size.height), self.CGImage);
            break;
    }
    CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
    return [UIImage imageWithCGImage:cgImage];
}

//+ (UIImage *)addBpolygonToImage:(UIImage *)image withLineWidth:(CGFloat)lineW andColor:(UIColor *)color{
//    //
//    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0);
//    //
//    CGContextRef ctx = UIGraphicsGetCurrentContext();
//    //
//    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
//    CGFloat lineWidth = lineW;
//    UIBezierPath *path = [UIBezierPath bezierPathWithRect:rect];
//
//    path.lineWidth = lineWidth;
//    path.lineJoinStyle = kCGLineJoinRound;
//    [color setStroke];
//    [path stroke];
//    //
//    CGContextSaveGState(ctx);
//    [path addClip];
//    CGContextDrawImage(ctx, rect, image.CGImage);
//    CGContextRestoreGState(ctx);
//    //
//    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    return newImage;
//}

+ (UIImage *)addBorderToImage:(UIImage *)image {
    CGImageRef bgimage = [image CGImage];
    float width = CGImageGetWidth(bgimage);
    float height = CGImageGetHeight(bgimage);
    // create a temporary texture data buffer
    void *data = malloc(width * height * 4);
    // draw the image into the buffer
    CGContextRef ctx = CGBitmapContextCreate(data,
                                             width,
                                             height,
                                             8,
                                             width * 4,
                                             CGImageGetColorSpace(image.CGImage),
                                             kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(ctx, CGRectMake(0, 0, (CGFloat)width, (CGFloat)height), bgimage);
    CGFloat lineWidth = 5.0;
    CGContextSetRGBStrokeColor(ctx,205,193,193,1.0);
    CGContextSetLineWidth(ctx, lineWidth);
    CGContextAddRect(ctx, CGRectMake(0, 0, image.size.width, image.size.height));
    CGContextDrawPath(ctx, kCGPathStroke); // draw path
    CGContextStrokePath(ctx);
    // draw it to a new image
    CGImageRef cgimage = CGBitmapContextCreateImage(ctx);
    UIImage *newImage = [UIImage imageWithCGImage:cgimage];
    CFRelease(cgimage);
    CGContextRelease(ctx);
    return newImage;
}

@end
