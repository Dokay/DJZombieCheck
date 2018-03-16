DJZombieCheck
==========

[![Version](https://img.shields.io/cocoapods/v/DJZombieCheck.svg?style=flat)](http://cocoapods.org/pods/DJZombieCheck)
[![License](https://img.shields.io/cocoapods/l/DJZombieCheck.svg?style=flat)](http://cocoapods.org/pods/DJZombieCheck)
[![Platform](https://img.shields.io/cocoapods/p/DJZombieCheck.svg?style=flat)](http://cocoapods.org/pods/DJZombieCheck)

## What

__A Objective-C zombie object detect tool,it can work in release mode.__

[**中文介绍**](http://blog.douzhongxu.com/2017/08/ZombieObjectCheck/)

## Features
* works in release and debug mode;
* print param in selector that zombie object perform;

## Requirements
* Xcode 8 or higher
* iOS 7.0 or higher

## Demo

To run the example project, clone the repo, and run `pod install` from the Example directory first.


## Installation

###  CocoaPods
Edit your Podfile and add DJZombieCheck:

``` bash
pod 'DJZombieCheck'
```

## Quickstart

### Sample log
  If DJZombieCheck detect a zombie object ,log will like this:
```objc
    DJZombieCheck_Example[16900:6214512] Find zombie,class:__NSArrayM address:0x610000059110 selector:addObject: param:(
1
)
```

### Details
    1.DJZombieCheck is Enable default,if you want to disable it,just set  DJZombieCheckEnable(global variable) to NO:
```objc
    BOOL DJZombieCheckEnable = NO;
```

    2.Xcode Zombie Objects open also:
    If Xcode Zombie Objects and DJZombieCheck are enable,DJZombieCheck will disable itself auto.

    3.Want to Save crash log and send it to server:
```objc
	- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
	{
	    //read last crash log and send it to server.
    
	    [NSObject startZombieCheckWithType:DJZombieCheckTypeAdvance zombieBlock:^(NSString *className, NSString *selectorName, NSArray *paramList) {
	        id paramLog = paramList ? paramList : @"dj_no_param";
	        NSString *zombieLog = [NSString stringWithFormat:@"Find Zombie,class:%@ selector:%@ param:%@\r\n",className,selectorName,paramLog];
	        NSLog(@"%@", zombieLog);
	        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Zombie Object find" message:zombieLog delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
	        [alert show];
        
	        //upload zombie object info and raise exception here.
	        //        abort();
	    }];
	    return YES;
	}
```
	4.Memory release type:
```objc
	typedef NS_ENUM(NSInteger,DJZombieCheckType){
	    DJZombieCheckTypeDefault,//does not release memory for object has called release, memory usage will grow continuously.
	    DJZombieCheckTypeRelease,//release memory for object has called release. if zombie object called after its memory has rewrited,zombie check may not work.
	    DJZombieCheckTypeAdvance,//release object's memory when UIApplicationDidReceiveMemoryWarningNotification is post.
	};
```


## Contact

Dokay Dou

- https://github.com/Dokay
- http://www.douzhongxu.com
- dokay_dou@163.com

## License

DJZombieCheck is available under the MIT license. See the LICENSE file for more info.
