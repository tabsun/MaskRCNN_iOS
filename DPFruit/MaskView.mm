//
//  MaskView.m
//  DPFruit
//
//  Created by 孙海涌 on 5/1/2018.
//  Copyright © 2018 dress. All rights reserved.
//

#import "MaskView.h"
#import "Detect_obj.h"
#include <vector>
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>

@interface MaskView ()

@property (nonatomic, strong) NSMutableArray *models;

@end

@implementation MaskView

- (instancetype)init {
    self = [super init];
    if (self) {
        _models = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Reset
- (void)reset:(float *)detectionMinConfidence {
    Detect_obj *detector = [Detect_obj detectOBJ];
    //Detect_obj *detector = [[Detect_obj alloc] init];
    [detector reset:detectionMinConfidence];
}


#pragma mark - Mask Detect
- (NSMutableArray *)maskViewsWithPixelBuffer:(CVPixelBufferRef)buffer {
    Detect_obj *detector = [Detect_obj detectOBJ];
//    Detect_obj *detector = [[Detect_obj alloc] init];
    cv::Mat mat = [self matFromPixelBuffer:buffer];
    NSMutableArray *imageViews = [self detectWithCVMat:mat detector:detector];
    return imageViews;
}

- (NSMutableArray *)maskViewsWithImage:(UIImage *)image {
    Detect_obj *detector = [Detect_obj detectOBJ];
//    Detect_obj *detector = [[Detect_obj alloc] init];

    cv::Mat mat = [self cvMatFromUIImage:image];
    NSMutableArray *imageViews = [self detectWithCVMat:mat detector:detector];
    return imageViews;
}

- (NSMutableArray *)detectWithCVMat:(cv::Mat)mat detector:(Detect_obj *)detector {
    std::vector<OneMaskObject> objects = [detector testDetect:mat];
    std::vector<cv::Vec4b> colors;
    colors.push_back(cv::Vec4b(255, 0, 0, 122));        // background
    colors.push_back(cv::Vec4b(255, 255, 0, 122));      // person
    colors.push_back(cv::Vec4b(255, 0, 255, 122));      // cat
    colors.push_back(cv::Vec4b(0, 255, 0, 122));        // dog
    colors.push_back(cv::Vec4b(0, 0, 255, 122));        // table
    colors.push_back(cv::Vec4b(249, 162, 200, 122));    // face
    colors.push_back(cv::Vec4b(74, 186, 200, 122));     // others

    //
    for (int i = 0; i < objects.size(); i++) {
        cv::Mat obj_mask = objects[i].mask;
        cv::Mat roi(obj_mask.rows, obj_mask.cols, CV_8UC4);
        int class_id = objects[i].class_id;
        float score = objects[i].score;
        MaskModel *model = [[MaskModel alloc] init];
        for( int i = 0; i < roi.rows; ++i) {
            //获取第 i 行首像素指针
            double * ptr = obj_mask.ptr<double>(i);
            cv::Vec4b *p = roi.ptr<cv::Vec4b>(i);
            for(int j = 0; j < roi.cols; ++j) {
                if (ptr[j] > 0.5) {
                    p[j] = colors[class_id];
                } else {
                    p[j][3] = 0;
                }
            }
        }
        UIImage *image = MatToUIImage(roi);
        model.objBox = CGRectMake(objects[i].x1, objects[i].y1, obj_mask.cols, obj_mask.rows);
        model.maskImage = image;
        model.class_id = class_id;
        model.score = score;
        [self.models addObject:model];
    }
    return self.models;
}

#pragma mark - Depth Detect
- (MaskModel *)depthWithPixelBuffer:(CVPixelBufferRef)buffer {
    Detect_obj *detector = [Detect_obj detectOBJ];
//    Detect_obj *detector = [[Detect_obj alloc] init];

    cv::Mat mat = [self matFromPixelBuffer:buffer];
    MaskModel *model = [self detectDepthWithCVMat:mat detector:detector];
    return model;
}

- (MaskModel *)depthWithImage:(UIImage *)image {
    Detect_obj *detector = [Detect_obj detectOBJ];
//    Detect_obj *detector = [[Detect_obj alloc] init];

    cv::Mat mat = [self cvMatFromUIImage:image];
    MaskModel *model = [self detectDepthWithCVMat:mat detector:detector];
    return model;
}

- (MaskModel *)detectDepthWithCVMat:(cv::Mat)mat detector:(Detect_obj *)detector {
    std::vector<cv::Mat> objects = [detector testDepthDetect:mat];
    if (objects.size() < 2) {
        return nil;
    }
    cv::Mat depthMat = objects[0];
    cv::Mat sceneMat = objects[1];
    UIImage *depthImage = MatToUIImage(depthMat);
    UIImage *sceneImage = MatToUIImage(sceneMat);
    MaskModel *model = [[MaskModel alloc] init];
    model.depthImage = depthImage;
    model.sceneImage = sceneImage;
    return model;
}

- (cv::Mat)cvMatFromBuffer:(CVPixelBufferRef)pixelBuffer
{
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *bufAddr = CVPixelBufferGetBaseAddress(pixelBuffer);

    int cols = (int)CVPixelBufferGetWidth(pixelBuffer);;
    int rows = (int)CVPixelBufferGetHeight(pixelBuffer);
    //cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
   // memcpy(cvMat.data, bufAddr, cols * rows * 4);
    cv::Mat cvMat(rows, cols, CV_8UC4, bufAddr, 0);

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    cv::Mat outMat;
    cv::cvtColor(cvMat, outMat, CV_BGRA2BGR);
    return outMat;
}
- (cv::Mat)matFromPixelBuffer:(CVPixelBufferRef)buffer
{
    CVPixelBufferLockBaseAddress(buffer, 0);
    unsigned char *base = (unsigned char *)CVPixelBufferGetBaseAddress(buffer);
    //size_t width = CVPixelBufferGetWidth( buffer );
    size_t height = CVPixelBufferGetHeight( buffer );
    size_t stride = CVPixelBufferGetBytesPerRow( buffer );
    //OSType type =  CVPixelBufferGetPixelFormatType(buffer);
    size_t extendedWidth = stride / 4;  // each pixel is 4 bytes/32 bits
    cv::Mat bgraImage = cv::Mat( (int)height, (int)extendedWidth, CV_8UC4, base);
    CVPixelBufferUnlockBaseAddress(buffer,0);
    cv::Mat outMat;
    cv::cvtColor(bgraImage, outMat, CV_BGRA2BGR);
    return outMat;
}

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    cv::Mat outMat;
    cv::cvtColor(cvMat, outMat, CV_BGRA2BGR);
    return outMat;
}


@end
