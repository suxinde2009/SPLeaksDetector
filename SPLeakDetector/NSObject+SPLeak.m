//
//  NSObject+SPLeak.m
//  SPLeakDetector
//
//  Created by SuXinDe on 2018/5/30.
//  Copyright © 2018年 su xinde. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NSObject+SPLeak.h"
#import <objc/runtime.h>
#import "NSObject+SPLeakTrack.h"


@implementation NSObject (SPLeak)

@dynamic memoryDebuggerProxy;

- (void)setMemoryDebuggerProxy:(SPMemoryDebuggerObjectProxy *)memoryDebuggerProxy {
    objc_setAssociatedObject(self,
                             @selector(memoryDebuggerProxy),
                             memoryDebuggerProxy,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (SPMemoryDebuggerObjectProxy *)memoryDebuggerProxy {
    id curProxy = objc_getAssociatedObject(self,
                                           @selector(memoryDebuggerProxy));
    return curProxy;
}

+ (void)swizzleSEL:(SEL)originalSEL
           withSEL:(SEL)swizzledSEL {
    Class class = [self class];
    Method originalMethod = class_getInstanceMethod(class, originalSEL);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSEL);

    BOOL didAddMethod =
    class_addMethod(class,
                    originalSEL,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSEL,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    }
    else
    {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
    
}

+ (void)prepareForMemoroyDebugger {
}

- (BOOL)markAlive {
    if ([self memoryDebuggerProxy] != nil) {
        return false;
    }
    //skip system class
    NSString* className = NSStringFromClass([self class]);
    if ([className hasPrefix:@"_"] || [className hasPrefix:@"UI"] || [className hasPrefix:@"NS"]) {
        return false;
    }
    
    //view object needs a super view to be alive
    if ([self isKindOfClass:[UIView class]]) {
        UIView* v = (UIView*)self;
        if (v.superview == nil) {
            return false;
        }
    }
    
    //controller object needs a parent to be alive
    if ([self isKindOfClass:[UIViewController class]]) {
        UIViewController* c = (UIViewController*)self;
        if (c.navigationController == nil && c.presentingViewController == nil) {
            return false;
        }
    }
    
    //skip some weird system classes
    static NSMutableDictionary* ignoreList = nil;
    @synchronized (self) {
        if (ignoreList == nil) {
            ignoreList = @{}.mutableCopy;
            NSArray* arr = @[@"UITextFieldLabel", @"UIFieldEditor", @"UITextSelectionView",
                             @"UITableViewCellSelectedBackground", @"UIView", @"UIAlertController"];
            for (NSString* str in arr) {
                ignoreList[str] = @":)";
            }
        }
        if ([ignoreList objectForKey:NSStringFromClass([self class])]) {
            return false;
        }
    }
    
    
    SPMemoryDebuggerObjectProxy* proxy = [SPMemoryDebuggerObjectProxy new];
    [self setMemoryDebuggerProxy:proxy];
    [proxy prepareProxy:self];
    
    
    return true;
}

- (BOOL)isAlive {
    return (self.memoryDebuggerProxy.weakHost != nil);
}

- (BOOL)isObjectAsSingleton {
    Class theClass = object_getClass([self class]);
    unsigned int clsMethodCount = 0;
    
    BOOL isSingleton = NO;
    Method *methods = class_copyMethodList(theClass, &clsMethodCount);
    for (unsigned int i = 0; i < clsMethodCount; ++i) {
        Method method = methods[i];
        const char *typeEncoding = method_getTypeEncoding(method);
        if (strcmp(typeEncoding, "@16@0:8") == 0) {
            SEL selector = method_getName(method);
            IMP imp = method_getImplementation(method);
            id singletonInstance = ((id(*)(Class, SEL))(void *)imp)([self class], selector);
            if (singletonInstance == self) {
                isSingleton = YES;
            }
            break;
        }
    }
    free(methods);
    
    return isSingleton;
}

@end
