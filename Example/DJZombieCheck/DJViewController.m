//
//  DJViewController.m
//  DJZombieCheck
//
//  Created by dokay_dou@163.com on 08/17/2017.
//  Copyright (c) 2017 dokay_dou@163.com. All rights reserved.
//

#import "DJViewController.h"
#import "DJZombieTest.h"

BOOL DJZombieCheckEnable = YES;

@interface DJViewController ()

@end

@implementation DJViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    DJZombieTest *zombieTest = [DJZombieTest new];
    [zombieTest test];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
