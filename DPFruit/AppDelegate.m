//
//  AppDelegate.m
//  DPFruit
//
//  Created by caochunyuan on 2017/12/14.
//  Copyright © 2017年 dress. All rights reserved.
//

#import "AppDelegate.h"
#import "DPVideoPlayer.h"
#import <Bugly/Bugly.h>
#import "DPMonitor.h"
@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Bugly startWithAppId:@"0e5649acd2"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showCameraCapture"];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
   
    [[DPMonitor sharedInstance] startMonitorWithTimeInterval:1];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    [[DPVideoPlayer sharedVideoPlayer] assetReaderStopReading];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    
   // [[DPVideoPlayer sharedVideoPlayer] assetReaderRestartReading];
    [[DPVideoPlayer sharedVideoPlayer] start];
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
