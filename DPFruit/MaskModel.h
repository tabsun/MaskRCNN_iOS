//
//  MaskModel.h
//  DPFruit
//
//  Created by 曹春园 on 2018/1/6.
//  Copyright © 2018年 dress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface MaskModel : NSObject

@property (nonatomic, assign) int class_id;
@property (nonatomic, assign) float score;
@property (nonatomic, assign) CGRect objBox;
@property (nonatomic, strong) UIImage *maskImage;

@property (nonatomic, assign) CGRect faceBox;
@property (nonatomic, strong) UIImage *faceImage;

@property (nonatomic, strong) UIImage *depthImage;
@property (nonatomic, strong) UIImage *sceneImage;


@end
