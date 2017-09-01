//
//  DJZombieCheckHanlder.m
//  DJZombieCheck
//
//  Created by Dokay on 2017/9/1.
//

#import "DJZombieCheckHanlder.h"


@implementation DJZombieCheckHanlder

+ (instancetype)sharedInstance
{
    static id singleInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleInstance = [[self alloc] initUseInner];
    });
    return singleInstance;
}

- (instancetype)init
{
    NSAssert(NO, @"can not be used");
    return nil;
}

- (instancetype)initUseInner
{
    self = [super init];
    if (self) {
    }
    return self;
}

@end
