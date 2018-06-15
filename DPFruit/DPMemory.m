//
//  DPMemory.m
//  DPFruit
//
//  Created by caochunyuan on 2018/2/28.
//  Copyright © 2018年 dress. All rights reserved.
//

#import "DPMemory.h"
#import <sys/sysctl.h>
#import <mach/mach.h>
@implementation DPMemory

- (double)availableMemory {
    vm_statistics_data_t vmStatus;
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStatus, &infoCount);
    if (kernReturn != KERN_SUCCESS) {
        return NSNotFound;
    }
    return ((vm_page_size * vmStatus.free_count) / 1024.0) / 1024.0;
}

- (double)usedMemory {
    task_basic_info_data_t taskInfo;
    mach_msg_type_number_t infoCount = TASK_BASIC_INFO_COUNT;
    kern_return_t kernReturn = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&taskInfo, &infoCount);
    if (kernReturn != KERN_SUCCESS) {
        return NSNotFound;
    }
   // return taskInfo.resident_size / 1024.0 / 1024.0;
    return taskInfo.resident_size >> 20; // MB
}

- (NSUInteger)getResidentMemory
{
    struct mach_task_basic_info info;
    mach_msg_type_number_t count = MACH_TASK_BASIC_INFO_COUNT;
    
    int r = task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)& info, & count);
    if (r == KERN_SUCCESS)
    {
        return info.resident_size;
    }
    else
    {
        return -1;
    }
}

@end
