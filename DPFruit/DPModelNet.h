//
//  DPModelNet.h
//  DPFruit
//
//  Created by caochunyuan on 2017/12/19.
//  Copyright © 2017年 dress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "depth_unpool1.h"
#import "depth_unpool2.h"
#import "depth_unpool3.h"
#import "depth_unpool4.h"
#import "depth_final_conv.h"
#import "scene_segment.h"
#import "mask_class_box.h"
#import "mask_branch_noalign.h"
#import "mask_rpn.h"
@interface DPModelNet : NSObject

//+ (maskrpn *)maskrpn;
+ (mask_rpn *)mask_rpn;
+ (mask_class_box *)maskClassBox;
+ (mask_branch_noalign *)maskBranchNoalign;
+ (depth_unpool1 *)depth_unpool1;
+ (depth_unpool2 *)depth_unpool2;
+ (depth_unpool3 *)depth_unpool3;
+ (depth_unpool4 *)depth_unpool4;
+ (depth_final_conv *)depth_final_conv;
+ (scene_segment *)scene_segment;
@end
