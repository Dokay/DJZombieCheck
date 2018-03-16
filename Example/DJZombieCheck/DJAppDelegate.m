//
//  DJAppDelegate.m
//  DJZombieCheck
//
//  Created by dokay_dou@163.com on 08/17/2017.
//  Copyright (c) 2017 dokay_dou@163.com. All rights reserved.
//

#import "DJAppDelegate.h"
#import "NSObject+ZombieCheck.h"

@implementation DJAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //read last crash log and send it to server.
    
    [NSObject startZombieCheckWithType:DJZombieCheckTypeAdvance zombieBlock:^(NSString *className, NSString *selectorName, NSArray *paramList) {
        id paramLog = paramList ? paramList : @"hd_no_param";
        NSString *zombieLog = [NSString stringWithFormat:@"Find Zombie,class:%@ selector:%@ param:%@\r\n",className,selectorName,paramLog];
        NSLog(@"%@", zombieLog);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Zombie Object find" message:zombieLog delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        
        //upload zombie object info and raise exception here.
        //        abort();
    }];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
