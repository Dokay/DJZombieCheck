//
//  NSObject+ZombieCheck.h
//  DJZombieCheck
//
//  Created by Dokay on 2017/3/26.
//  Copyright © 2017年 dj226. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,DJZombieCheckType){
    DJZombieCheckTypeDefault,//does not release memory for object has called release, memory usage will grow continuously.
    DJZombieCheckTypeRelease,//release memory for object has called release. if zombie object called after its memory has rewrited,zombie check may not work.
    DJZombieCheckTypeAdvance,//release object's memory when UIApplicationDidReceiveMemoryWarningNotification is post.
};

typedef void(^DJZombieBlock)(NSString *className, NSString *selectorName, NSArray *paramList);
typedef BOOL(^DJBizPreBlock)(NSString *className);

@interface NSObject (Zombie)

/**
 start zombie check

 @param block zombie info block call back when zombie object founded.
 */
+ (void)startZombieCheckWithZombieBlock:(DJZombieBlock)block;

/**
 start zombie check

 @param checkType when object memory release, see DJZombieCheckType
 @param block zombie info block call back when zombie object founded.
 */
+ (void)startZombieCheckWithType:(DJZombieCheckType)checkType zombieBlock:(DJZombieBlock)block;

/**
 start zombie check
 
 @param bizPreBlock call back to detimine whether the class of release object is biz. if DJZombieCheckType is  DJZombieCheckTypeAdvance, DJZombieCheck will use two queue to manage free of object,not biz object will free first.
 @param block zombie info block call back when zombie object founded.
 */
+ (void)startZombieCheckWithType:(DJZombieCheckType)checkType bizPreBlock:(DJBizPreBlock)bizPreBlock zombieBlock:(DJZombieBlock)block;

@end

