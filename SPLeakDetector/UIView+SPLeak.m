//
//  UIView+SPLeak.m
//  SPLeakDetector
//
//  Created by SuXinDe on 2018/5/30.
//  Copyright © 2018年 su xinde. All rights reserved.
//

#import "UIView+SPLeak.h"
#import <objc/runtime.h>
#import "NSObject+SPLeak.h"

@implementation UIView (SPLeak)

+ (void)prepareForMemoroyDebugger {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleSEL:@selector(didMoveToSuperview)
                 withSEL:@selector(swizzled_didMoveToSuperview)];
    });
}

- (void)swizzled_didMoveToSuperview {
    [self swizzled_didMoveToSuperview];
    
    BOOL hasAliveParent = false;
    
    UIResponder *responder = self.nextResponder;
    while (responder) {
        if ([responder memoryDebuggerProxy] != nil) {
            hasAliveParent = true;
            break;
        }
        responder = responder.nextResponder;
    }
    
    if (hasAliveParent) {
        [self markAlive];
    }
}

- (BOOL)isAlive {
    BOOL alive = true;
    
    BOOL onUIStack = false;
    
    UIView *view = self;
    while (view.superview != nil) {
        view = view.superview;
    }
    if ([view isKindOfClass:[UIWindow class]]) {
        onUIStack = true;
    }
    
    //save responder
    if (self.memoryDebuggerProxy.weakResponder == nil) {
        UIResponder *responder = self.nextResponder;
        while (responder) {
            if (responder.nextResponder == nil) {
                break;
            } else {
                responder = responder.nextResponder;
            }
            
            if ([responder isKindOfClass:[UIViewController class]]) {
                break;
            }
        }
        self.memoryDebuggerProxy.weakResponder = responder;
    }
    
    if (onUIStack == false) {
        alive = false;
        //if controller is active, view should be considered alive too
        if ([self.memoryDebuggerProxy.weakResponder isKindOfClass:[UIViewController class]]) {
            alive = true;
        } else {
            // no active controller found
            // SPLeakLog(@"dangling object: %@", [self class]);
        }
    }
    
    if (alive == false) {
        // SPLeakLog(@"leaked object: %@ ?", [self class]);
    }
    return alive;
}


@end
