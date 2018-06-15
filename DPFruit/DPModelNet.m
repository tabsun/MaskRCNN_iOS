//
//  DPModelNet.m
//  DPFruit
//
//  Created by caochunyuan on 2017/12/19.
//  Copyright © 2017年 dress. All rights reserved.
//

#import "DPModelNet.h"

@implementation DPModelNet

+ (depth_unpool1 *)depth_unpool1 {
    static depth_unpool1 *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[depth_unpool1 alloc] init];
    });
    return instance;
}
+ (depth_unpool2 *)depth_unpool2 {
    static depth_unpool2 *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[depth_unpool2 alloc] init];
    });
    return instance;
}
+ (depth_unpool3 *)depth_unpool3 {
    static depth_unpool3 *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[depth_unpool3 alloc] init];
    });
    return instance;
}
+ (depth_unpool4 *)depth_unpool4 {
    static depth_unpool4 *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[depth_unpool4 alloc] init];
    });
    return instance;
}
+ (depth_final_conv *)depth_final_conv {
    static depth_final_conv *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[depth_final_conv alloc] init];
    });
    return instance;
}
+ (scene_segment *)scene_segment {
    static scene_segment *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[scene_segment alloc] init];
    });
    return instance;
}
+ (mask_rpn *)mask_rpn {
    static mask_rpn *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[mask_rpn alloc] init];
    });
    return instance;
}

+ (mask_class_box *)maskClassBox {
    static mask_class_box *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[mask_class_box alloc] init];
    });
    return instance;
}

+ (mask_branch_noalign *)maskBranchNoalign {
    static mask_branch_noalign *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[mask_branch_noalign alloc] init];
    });
    return instance;
}

@end
