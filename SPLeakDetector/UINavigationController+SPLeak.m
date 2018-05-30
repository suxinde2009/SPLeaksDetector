//
//  UINavigationController+SPLeak.m
//  SPLeakDetector
//
//  Created by SuXinDe on 2018/5/30.
//  Copyright © 2018年 su xinde. All rights reserved.
//

#import "UINavigationController+SPLeak.h"
#import <objc/runtime.h>
#import "NSObject+SPLeak.h"

@implementation UINavigationController (SPLeak)

+ (void)prepareForSniffer {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleSEL:@selector(pushViewController:animated:)
                 withSEL:@selector(swizzled_pushViewController:animated:)];
    });
}

- (void)swizzled_pushViewController:(UIViewController *)viewController
                           animated:(BOOL)animated {
    [self swizzled_pushViewController:viewController
                             animated:animated];
    [viewController markAlive];
}

@end
