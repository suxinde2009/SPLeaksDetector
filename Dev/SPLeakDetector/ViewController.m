//
//  ViewController.m
//  SPLeakDetector
//
//  Created by SuXinDe on 2018/5/30.
//  Copyright © 2018年 su xinde. All rights reserved.
//

#import "ViewController.h"
#import "LeakingViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self gotoLeakController];
    });
}

- (void)gotoLeakController {
    LeakingViewController* c = [LeakingViewController new];
    [self presentViewController:c animated:true completion:nil];
}


@end
