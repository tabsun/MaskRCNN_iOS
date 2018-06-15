//
//  DPMonitor.h
//  DPFruit
//
//  Created by caochunyuan on 2018/2/28.
//  Copyright © 2018年 dress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DPMonitor : NSObject

+ (instancetype)sharedInstance;
- (void)startMonitorWithTimeInterval:(NSTimeInterval)timeInterval;

@end
