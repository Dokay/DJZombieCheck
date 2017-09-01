//
//  DJZombieCheckHanlder.h
//  DJZombieCheck
//
//  Created by Dokay on 2017/9/1.
//

#import <Foundation/Foundation.h>

typedef void(^HandleZombieExceptionBlock)(NSString *className, SEL selector, NSArray *paramList);

@interface DJZombieCheckHanlder : NSObject

@property (nonatomic, copy) HandleZombieExceptionBlock zombieHandler;

+ (instancetype)sharedInstance;



@end
