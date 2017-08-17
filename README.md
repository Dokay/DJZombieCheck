DJZombieCheck
==========

[![Version](https://img.shields.io/cocoapods/v/DJZombieCheck.svg?style=flat)](http://cocoapods.org/pods/DJZombieCheck)
[![License](https://img.shields.io/cocoapods/l/DJZombieCheck.svg?style=flat)](http://cocoapods.org/pods/DJZombieCheck)
[![Platform](https://img.shields.io/cocoapods/p/DJZombieCheck.svg?style=flat)](http://cocoapods.org/pods/DJZombieCheck)

## What

__A Objective-C zombie object detect tool,it can work in release mode.__

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
```
    BOOL DJZombieCheckEnable = NO;
```

    2.Xcode Zombie Objects able too
    If Xcode Zombie Objects and DJZombieCheck are enable,DJZombieCheck will disable itself auto.

## Contact

Dokay Dou

- https://github.com/Dokay
- http://www.douzhongxu.com
- dokay_dou@163.com

## License

DJZombieCheck is available under the MIT license. See the LICENSE file for more info.
