//
//  DPLatestPhoto.h
//  DPFruit
//
//  Created by caochunyuan on 2017/12/18.
//  Copyright © 2017年 dress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface DPLatestPhoto : NSObject

+ (void)getLastestPhotoHandler:(void(^)(UIImage *))handler;

@end
