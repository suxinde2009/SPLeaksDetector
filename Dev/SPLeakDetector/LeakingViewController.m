//
//  LeakingViewController.m
//  SPLeakDetector
//
//  Created by SuXinDe on 2018/5/30.
//  Copyright © 2018年 su xinde. All rights reserved.
//

#import "LeakingViewController.h"

@interface LeakingViewController ()
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation LeakingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor grayColor];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                  target:self
                                                selector:@selector(test)
                                                userInfo:nil
                                                 repeats:true];
    UIButton* btn = [UIButton new];
    [btn setTitle:@"Close"
         forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor blackColor];
    [btn setTitleColor:[UIColor whiteColor]
              forState:UIControlStateNormal];
    btn.frame = CGRectMake(self.view.frame.size.width/2-100/2,
                           200,
                           100,
                           50);
    [btn addTarget:self
            action:@selector(btnCloseClick)
  forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)test{
    NSLog(@"timer is still alive");
}

- (void)btnCloseClick {
    [self dismissViewControllerAnimated:true completion:^{}];
}

@end
