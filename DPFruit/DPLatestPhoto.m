//
//  DPLatestPhoto.m
//  DPFruit
//
//  Created by caochunyuan on 2017/12/18.
//  Copyright © 2017年 dress. All rights reserved.
//

#import "DPLatestPhoto.h"

@implementation DPLatestPhoto

+ (void)getLastestPhotoHandler:(void(^)(UIImage *))handler
{
    // PHPhotoLibrary
    PHFetchOptions *fetchOption = [[PHFetchOptions alloc] init];
    fetchOption.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    PHFetchResult *allPhotos = [PHAsset fetchAssetsWithOptions:fetchOption];
    PHImageRequestOptions *requestOption = [[PHImageRequestOptions alloc] init];
    requestOption.resizeMode = PHImageRequestOptionsResizeModeExact;
    [[PHImageManager defaultManager] requestImageForAsset:[allPhotos lastObject] targetSize:CGSizeMake(80, 80) contentMode:PHImageContentModeAspectFill options:requestOption resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        handler(result);
    }];
}

@end
