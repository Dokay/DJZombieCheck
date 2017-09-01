//
//  NSObject+ZombieCheck.m
//  DJZombieCheck
//
//  advance implementation for __dealloc_zombie
//
//  Created by Dokay on 2017/3/26.
//  Copyright © 2017年 dj226. All rights reserved.
//

#import "NSObject+ZombieCheck.h"
#import <objc/runtime.h>
#import "DJZombieCheckHanlder.h"

#define kXcodeZombieENVKey      "NSZombieEnabled"
#define kDJZombieShort          "_NSZombie_"
#define kDJZombieLong           @"__Zombie_"
#define kDJZombieErrorParam     @"kDJZombieErrorParam"
#define kDJZombieExceptionName  @"DJZombieException"

#define DJ_ARG_CASE(_typeChar, _type) \
case _typeChar: {   \
_type arg;  \
[invocation getArgument:&arg atIndex:i];    \
[argList addObject:@(arg)]; \
break;  \
}

extern void _objc_rootDealloc (void);
extern void *objc_destructInstance(id obj);

__attribute__((weak)) BOOL DJZombieCheckEnable = YES;
__attribute__((weak)) BOOL methodCountLogEnable = NO;

NS_INLINE void DumpObjcMethods(Class clz)
{
    if (methodCountLogEnable) {
        unsigned int methodCount = 0;
        Method *methods = class_copyMethodList(clz, &methodCount);
        printf("Find %d methods on '%s'\n", methodCount, class_getName(clz));
        
        for (unsigned int i = 0; i < methodCount; i++) {
            Method method = methods[i];
            
            printf("\t'%s' has method named '%s' of encoding '%s'\n",
                   class_getName(clz),
                   sel_getName(method_getName(method)),
                   method_getTypeEncoding(method));
        }
        
        free(methods);
    }
}

NS_INLINE void MethodSwizzle(Class originalClass, SEL originalSelector, Class swizzledClass, SEL swizzledSelector, BOOL isInstanceMethod)
{
    Method (*class_getMethod)(Class, SEL) = &class_getInstanceMethod;
    if (!isInstanceMethod) {
        class_getMethod = &class_getClassMethod;
        originalClass = object_getClass(originalClass);
        swizzledClass = object_getClass(swizzledClass);
    }
    Method originalMethod = class_getMethod(originalClass, originalSelector);
    Method swizzledMethod = class_getMethod(swizzledClass, swizzledSelector);
    if (class_addMethod(originalClass, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) {
        class_replaceMethod(originalClass, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@implementation NSObject (Zombie)

+ (void)load {
    if (DJZombieCheckEnable == NO) {
        return;
    }
    
    char *NSZombieEnabledEnv = getenv(kXcodeZombieENVKey);//set NSZombieEnabled in Xcode will set this env value
    
    if (NSZombieEnabledEnv == NULL
        || strcmp(NSZombieEnabledEnv, "YES") != 0) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            SEL originalSelector = @selector(dealloc);
            SEL swizzledSelector = @selector(dj_zombie_dealloc);
            MethodSwizzle(NSObject.class,originalSelector,NSObject.class,swizzledSelector,YES);
        });
    }
}

- (void)dj_zombie_dealloc
{
    BOOL zombieClassHasRegisted = YES;
    NSString *className = NSStringFromClass(self.class);
    NSString *zombieClassName = [kDJZombieLong stringByAppendingString:className];
    const char *zombieClassNameUtf8 = zombieClassName.UTF8String;
    
    Class zombieClass = objc_lookUpClass(zombieClassNameUtf8);
    if (!zombieClass) {
        zombieClassHasRegisted = NO;
        Class tmpClass = objc_lookUpClass(kDJZombieShort);
        DumpObjcMethods(tmpClass);
        zombieClass = objc_duplicateClass(tmpClass,zombieClassNameUtf8,0);
        DumpObjcMethods(zombieClass);
    }
    
    objc_destructInstance((id)self);
    object_setClass((id)self,zombieClass);
    
    if (zombieClassHasRegisted == NO) {
        SEL originalSignatureSelector = @selector(methodSignatureForSelector:);
        SEL swizzledSignatureSelector = @selector(dj_methodSignatureForSelector:);
        //_NSZombie_ has no method ,just add it.
        Method swizzledSignatureMethod = class_getInstanceMethod(NSObject.class, swizzledSignatureSelector);
        class_addMethod(zombieClass, originalSignatureSelector, method_getImplementation(swizzledSignatureMethod), method_getTypeEncoding(swizzledSignatureMethod));
        
        SEL originalInvocationSelector = @selector(forwardInvocation:);
        SEL swizzledInvocationSelector = @selector(dj_forwardInvocation:);
        Method swizzledInvocationMethod = class_getInstanceMethod(NSObject.class, swizzledInvocationSelector);
        class_addMethod(zombieClass, originalInvocationSelector, method_getImplementation(swizzledInvocationMethod), method_getTypeEncoding(swizzledInvocationMethod));
        
        DumpObjcMethods(zombieClass);
    }
}

- (NSMethodSignature*)dj_methodSignatureForSelector:(SEL)selector
{
    Class selfClass = object_getClass(self);
    NSString *orignalClassName = [NSStringFromClass(selfClass) stringByReplacingOccurrencesOfString:kDJZombieLong withString:@""];
    
    id instance = class_createInstance(NSClassFromString(orignalClassName), 0);
    NSMethodSignature *signature = [instance methodSignatureForSelector:selector];
    if (!signature) {
        dj_throwExceptionForSelector(self,selector,nil);
    }
    return signature;
}

- (void)dj_forwardInvocation:(NSInvocation *)invocation
{
    NSMethodSignature *methodSignature = [invocation methodSignature];
    NSInteger numberOfArguments = [methodSignature numberOfArguments];

    NSString *selectorName = NSStringFromSelector(invocation.selector);
    NSMutableArray *argList = [[NSMutableArray alloc] init];
    if (selectorName >0) {
        for (NSUInteger i = 2; i < numberOfArguments; i++) {
            const char *argumentType = [methodSignature getArgumentTypeAtIndex:i];
            switch(argumentType[0] == 'r' ? argumentType[1] : argumentType[0]) {
                    DJ_ARG_CASE('c', char)
                    DJ_ARG_CASE('C', unsigned char)
                    DJ_ARG_CASE('s', short)
                    DJ_ARG_CASE('S', unsigned short)
                    DJ_ARG_CASE('i', int)
                    DJ_ARG_CASE('I', unsigned int)
                    DJ_ARG_CASE('l', long)
                    DJ_ARG_CASE('L', unsigned long)
                    DJ_ARG_CASE('q', long long)
                    DJ_ARG_CASE('Q', unsigned long long)
                    DJ_ARG_CASE('f', float)
                    DJ_ARG_CASE('d', double)
                    DJ_ARG_CASE('B', BOOL)
                case '@': {
                    __unsafe_unretained id arg;
                    [invocation getArgument:&arg atIndex:i];
                    [argList addObject:(arg ? arg: kDJZombieErrorParam)];
                    break;
                }
                case ':': {
                    SEL selector;
                    [invocation getArgument:&selector atIndex:i];
                    NSString *selectorName = NSStringFromSelector(selector);
                    [argList addObject:(selectorName ? selectorName: kDJZombieErrorParam)];
                    break;
                }
                case '^':
                case '*': {
                    void *arg;
                    [invocation getArgument:&arg atIndex:i];
                    [argList addObject:[NSValue valueWithPointer:arg]];
                    break;
                }
                case '#': {
                    Class arg;
                    [invocation getArgument:&arg atIndex:i];
                    [argList addObject:(Class)arg];
                    break;
                }
                default: {
                    NSLog(@"error type %s", argumentType);
                    [argList addObject:kDJZombieErrorParam];
                    break;
                }
            }
        }
    }
    
    dj_throwExceptionForSelector(self,invocation.selector,argList);
}

void dj_throwExceptionForSelector(id selfInstance,SEL selector,NSArray *paramList)
{
    Class selfClass = object_getClass(selfInstance);
    NSString *zombieClassName = [NSString stringWithUTF8String:class_getName(selfClass)];
    NSString *originalClassName = [zombieClassName stringByReplacingOccurrencesOfString:kDJZombieLong withString:@""];
    
    id paramLog = paramList ? paramList : @"empty";//empty string is also param,so use "empty" to replace
    NSString *zombieLog = [NSString stringWithFormat:@"Find zombie,class:%@ address:%p selector:%@ param:%@\r\n",originalClassName,selfInstance,NSStringFromSelector(selector),paramLog];
    NSLog(@"%@", zombieLog);
    
    if ([DJZombieCheckHanlder sharedInstance].zombieHandler) {
        [DJZombieCheckHanlder sharedInstance].zombieHandler(originalClassName, selector, paramList);
    }
    
    NSException *zombieException = [NSException exceptionWithName:@"DJZombieException" reason:zombieLog userInfo:nil];
    [zombieException raise];
}

@end

