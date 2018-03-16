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
#import "hd_zombie_object_cache.h"

#define kHDZombieLong @"__Zombie_"
#define kHDZombieShort "_NSZombie_"
#define kHDZombieErrorParam @"kHDZombieErrorParam"

#define HD_ARG_CASE(_typeChar, _type) \
case _typeChar: {   \
_type arg;  \
[invocation getArgument:&arg atIndex:i];    \
[argList addObject:@(arg)]; \
break;  \
}

extern void _objc_rootDealloc (void);
extern void *objc_destructInstance(id obj);

BOOL methodCountLogEnable = NO;

static DJZombieCheckType _checkType;
static DJZombieBlock _zombieBlock;
static DJBizPreBlock _bizPreBlock;

@implementation NSObject (Zombie)

+ (void)startZombieCheckWithZombieBlock:(DJZombieBlock)block
{
    [NSObject startZombieCheckWithType:DJZombieCheckTypeDefault zombieBlock:block];
}

+ (void)startZombieCheckWithType:(DJZombieCheckType)checkType zombieBlock:(DJZombieBlock)block
{
    [NSObject startZombieCheckWithType:DJZombieCheckTypeDefault bizPreBlock:nil zombieBlock:block];
}

+ (void)startZombieCheckWithType:(DJZombieCheckType)checkType bizPreBlock:(DJBizPreBlock)bizPreBlock zombieBlock:(DJZombieBlock)block
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _checkType = checkType;
        _zombieBlock = [block copy];
        _bizPreBlock = [bizPreBlock copy];
        
        SEL originalSelector = @selector(dealloc);
        SEL swizzledSelector = @selector(hd_zombie_dealloc);
        MethodSwizzle(NSObject.class,originalSelector,NSObject.class,swizzledSelector,YES);
        
        if (_checkType == DJZombieCheckTypeAdvance) {
            hd_zombie_init_current();
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveMemoryWarningNotify:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        }
    });
}

- (void)receiveMemoryWarningNotify:(NSNotification *)notify
{
    hd_zombie_release_memory_for_memory_warning();
}

- (void)hd_zombie_dealloc
{
    NSString *className = NSStringFromClass(self.class);
    NSString *zombieClassName = [kHDZombieLong stringByAppendingString:className];
    const char *zombieClassNameUtf8 = zombieClassName.UTF8String;
    
    Class zombieClass = objc_lookUpClass(zombieClassNameUtf8);
    if (!zombieClass) {
        Class tmpClass = objc_lookUpClass(kHDZombieShort);
        DumpObjcMethods(tmpClass);
        zombieClass = objc_duplicateClass(tmpClass,zombieClassNameUtf8,0);
        DumpObjcMethods(zombieClass);
        hd_addForwordMethodsWithZombieClass(zombieClass);
        DumpObjcMethods(zombieClass);
    }
    
    objc_destructInstance((id)self);
    object_setClass((id)self,zombieClass);
    
    switch (_checkType) {
        case DJZombieCheckTypeRelease:
            free((void*)self);
            break;
        case DJZombieCheckTypeAdvance:
        {
            if (_bizPreBlock && _bizPreBlock(className)) {
                hd_zombie_add_biz((void*)self,className.UTF8String);
            }else{
                hd_zombie_add_base((void*)self,className.UTF8String);
            }
        }
            break;
            
        default:
            break;
    }
}

static NSMethodSignature* dj_methodSignatureForSelector(id obj,SEL sel, SEL selector)
{
    Class selfClass = object_getClass(obj);
    NSString *orignalClassName = [NSStringFromClass(selfClass) stringByReplacingOccurrencesOfString:kHDZombieLong withString:@""];
    
    id instance = class_createInstance(NSClassFromString(orignalClassName), 0);
    NSMethodSignature *signature = [instance methodSignatureForSelector:selector];
    if (!signature) {
        hd_throwExceptionForSelector(obj,selector,nil);
    }
    return signature;
}

static void dj_forwardInvocation(id obj, SEL sel, NSInvocation* invocation)
{
    NSMethodSignature *methodSignature = [invocation methodSignature];
    NSInteger numberOfArguments = [methodSignature numberOfArguments];
    
    NSString *selectorName = NSStringFromSelector(invocation.selector);
    NSMutableArray *argList = [[NSMutableArray alloc] init];
    if (selectorName >0) {
        for (NSUInteger i = 2; i < numberOfArguments; i++) {
            const char *argumentType = [methodSignature getArgumentTypeAtIndex:i];
            switch(argumentType[0] == 'r' ? argumentType[1] : argumentType[0]) {
                    HD_ARG_CASE('c', char)
                    HD_ARG_CASE('C', unsigned char)
                    HD_ARG_CASE('s', short)
                    HD_ARG_CASE('S', unsigned short)
                    HD_ARG_CASE('i', int)
                    HD_ARG_CASE('I', unsigned int)
                    HD_ARG_CASE('l', long)
                    HD_ARG_CASE('L', unsigned long)
                    HD_ARG_CASE('q', long long)
                    HD_ARG_CASE('Q', unsigned long long)
                    HD_ARG_CASE('f', float)
                    HD_ARG_CASE('d', double)
                    HD_ARG_CASE('B', BOOL)
                case '@': {
                    __unsafe_unretained id arg;
                    [invocation getArgument:&arg atIndex:i];
                    [argList addObject:(arg ? arg: kHDZombieErrorParam)];
                    break;
                }
                case ':': {
                    SEL selector;
                    [invocation getArgument:&selector atIndex:i];
                    NSString *selectorName = NSStringFromSelector(selector);
                    [argList addObject:(selectorName ? selectorName: kHDZombieErrorParam)];
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
                    [argList addObject:kHDZombieErrorParam];
                    break;
                }
            }
        }
    }
    
    hd_throwExceptionForSelector(obj,invocation.selector,argList);
}

NS_INLINE void hd_addForwordMethodsWithZombieClass(Class zombieClass)
{
    SEL originalSignatureSelector = @selector(methodSignatureForSelector:);
    //    SEL swizzledSignatureSelector = @selector(hd_methodSignatureForSelector:);
    //_NSZombie_ has no method ,just add it.
    Method swizzledSignatureMethod = class_getInstanceMethod(NSObject.class, originalSignatureSelector);
    class_addMethod(zombieClass, originalSignatureSelector, (IMP)dj_methodSignatureForSelector, method_getTypeEncoding(swizzledSignatureMethod));
    
    SEL originalInvocationSelector = @selector(forwardInvocation:);
    Method swizzledInvocationMethod = class_getInstanceMethod(NSObject.class, originalInvocationSelector);
    class_addMethod(zombieClass, originalInvocationSelector, (IMP)dj_forwardInvocation, method_getTypeEncoding(swizzledInvocationMethod));
}

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

NS_INLINE void hd_throwExceptionForSelector(id selfInstance,SEL selector,NSArray *paramList)
{
    Class selfClass = object_getClass(selfInstance);
    NSString *className = NSStringFromClass(selfClass);
    
    if (_zombieBlock) {
        _zombieBlock(className,NSStringFromSelector(selector),paramList);
    }else{
        NSString *exceptionReason = [NSString stringWithFormat:@"Zombie Class:%@,SEL: %@, Param:%@",className,NSStringFromSelector(selector),paramList];
        NSException *exception = [NSException exceptionWithName:@"DJZombie" reason:exceptionReason userInfo:nil];
        [exception raise];
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

@end

//
//when zombie enable,__CFZombifyNSObject in __CFInitialize will be called.

//assemble code for __CFZombifyNSObject is:
//CoreFoundation`__CFZombifyNSObject:
//->  0x11165cbe0 <+0>:  pushq  %rbp
//0x11165cbe1 <+1>:  movq   %rsp, %rbp
//0x11165cbe4 <+4>:  pushq  %r15
//0x11165cbe6 <+6>:  pushq  %r14
//0x11165cbe8 <+8>:  pushq  %rbx
//0x11165cbe9 <+9>:  pushq  %rax
//0x11165cbea <+10>: leaq   0x1f46fb(%rip), %rdi      ; "NSObject"
//0x11165cbf1 <+17>: callq  0x1116a8b44               ; symbol stub for: objc_lookUpClass
//0x11165cbf6 <+22>: movq   %rax, %rbx
//0x11165cbf9 <+25>: movq   0x248168(%rip), %rsi      ; "dealloc"
//0x11165cc00 <+32>: movq   0x2493a9(%rip), %r14      ; "__dealloc_zombie"
//0x11165cc07 <+39>: movq   %rbx, %rdi
//0x11165cc0a <+42>: callq  0x1116a8aa8               ; symbol stub for: class_getInstanceMethod
//0x11165cc0f <+47>: movq   %rax, %r15
//0x11165cc12 <+50>: movq   %rbx, %rdi
//0x11165cc15 <+53>: movq   %r14, %rsi
//0x11165cc18 <+56>: callq  0x1116a8aa8               ; symbol stub for: class_getInstanceMethod
//0x11165cc1d <+61>: movq   %r15, %rdi
//0x11165cc20 <+64>: movq   %rax, %rsi
//0x11165cc23 <+67>: addq   $0x8, %rsp
//0x11165cc27 <+71>: popq   %rbx
//0x11165cc28 <+72>: popq   %r14
//0x11165cc2a <+74>: popq   %r15
//0x11165cc2c <+76>: popq   %rbp
//0x11165cc2d <+77>: jmp    0x1116a8ad2               ; symbol stub for: method_exchangeImplementations
//0x11165cc32 <+82>: nopw   %cs:(%rax,%rax)
//

//assemble code for __dealloc_zombie
//CoreFoundation`-[NSObject(NSObject) __dealloc_zombie]:
//->  0x11165d020 <+0>:   pushq  %rbp
//0x11165d021 <+1>:   movq   %rsp, %rbp
//0x11165d024 <+4>:   pushq  %r14
//0x11165d026 <+6>:   pushq  %rbx
//0x11165d027 <+7>:   subq   $0x10, %rsp
//0x11165d02b <+11>:  movq   %rdi, %rbx
//0x11165d02e <+14>:  testq  %rbx, %rbx
//0x11165d031 <+17>:  js     0x11165d0d5               ; <+181>
//0x11165d037 <+23>:  leaq   0x25b38a(%rip), %rax      ; __CFZombieEnabled
//0x11165d03e <+30>:  cmpb   $0x0, (%rax)
//0x11165d041 <+33>:  je     0x11165d0de               ; <+190>
//0x11165d047 <+39>:  movq   %rbx, %rdi
//0x11165d04a <+42>:  callq  0x1116a8bb0               ; symbol stub for: object_getClass
//0x11165d04f <+47>:  movq   $0x0, -0x18(%rbp)
//0x11165d057 <+55>:  movq   %rax, %rdi
//0x11165d05a <+58>:  callq  0x1116a8ab4               ; symbol stub for: class_getName
//0x11165d05f <+63>:  movq   %rax, %rcx
//0x11165d062 <+66>:  leaq   0x1ea4f5(%rip), %rsi      ; "_NSZombie_%s"
//0x11165d069 <+73>:  leaq   -0x18(%rbp), %rdi
//0x11165d06d <+77>:  xorl   %eax, %eax
//0x11165d06f <+79>:  movq   %rcx, %rdx
//0x11165d072 <+82>:  callq  0x1116a8d60               ; symbol stub for: asprintf
//0x11165d077 <+87>:  movq   -0x18(%rbp), %rdi
//0x11165d07b <+91>:  callq  0x1116a8b44               ; symbol stub for: objc_lookUpClass
//0x11165d080 <+96>:  movq   %rax, %r14
//0x11165d083 <+99>:  testq  %r14, %r14
//0x11165d086 <+102>: jne    0x11165d0a5               ; <+133>
//0x11165d088 <+104>: leaq   0x1e9eed(%rip), %rdi      ; "_NSZombie_"
//0x11165d08f <+111>: callq  0x1116a8b44               ; symbol stub for: objc_lookUpClass
//0x11165d094 <+116>: movq   -0x18(%rbp), %rsi
//0x11165d098 <+120>: xorl   %edx, %edx
//0x11165d09a <+122>: movq   %rax, %rdi
//0x11165d09d <+125>: callq  0x1116a8b02               ; symbol stub for: objc_duplicateClass
//0x11165d0a2 <+130>: movq   %rax, %r14
//0x11165d0a5 <+133>: movq   -0x18(%rbp), %rdi
//0x11165d0a9 <+137>: callq  0x1116a8fbe               ; symbol stub for: free
//0x11165d0ae <+142>: movq   %rbx, %rdi
//0x11165d0b1 <+145>: callq  0x1116a8afc               ; symbol stub for: objc_destructInstance
//0x11165d0b6 <+150>: movq   %rbx, %rdi
//0x11165d0b9 <+153>: movq   %r14, %rsi
//0x11165d0bc <+156>: callq  0x1116a8bc8               ; symbol stub for: object_setClass
//0x11165d0c1 <+161>: leaq   0x25b301(%rip), %rax      ; __CFDeallocateZombies
//0x11165d0c8 <+168>: cmpb   $0x0, (%rax)
//0x11165d0cb <+171>: je     0x11165d0d5               ; <+181>
//0x11165d0cd <+173>: movq   %rbx, %rdi
//0x11165d0d0 <+176>: callq  0x1116a8fbe               ; symbol stub for: free
//0x11165d0d5 <+181>: addq   $0x10, %rsp
//0x11165d0d9 <+185>: popq   %rbx
//0x11165d0da <+186>: popq   %r14
//0x11165d0dc <+188>: popq   %rbp
//0x11165d0dd <+189>: retq
//0x11165d0de <+190>: movq   %rbx, %rdi
//0x11165d0e1 <+193>: addq   $0x10, %rsp
//0x11165d0e5 <+197>: popq   %rbx
//0x11165d0e6 <+198>: popq   %r14
//0x11165d0e8 <+200>: popq   %rbp
//0x11165d0e9 <+201>: jmp    0x1116a8a7e               ; symbol stub for: _objc_rootDealloc
//0x11165d0ee <+206>: nop


