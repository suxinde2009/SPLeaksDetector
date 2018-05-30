//
//  SPMemoryDebugger.m
//  SPLeakDetector
//
//  Created by SuXinDe on 2018/5/30.
//  Copyright © 2018年 su xinde. All rights reserved.
//

#import "SPMemoryDebugger.h"
#import "UINavigationController+SPLeak.h"
#import "UIView+SPLeak.h"
#import "UIViewController+SPLeak.h"
#import "NSObject+SPLeak.h"

#import <FBRetainCycleDetector/FBRetainCycleDetector.h>

const CGFloat kSPMemoryDetectorPingInterval = 0.5f;

@interface SPMemoryDebugger ()

@property (nonatomic, strong) dispatch_source_t pingTimer;
@property (nonatomic, assign) BOOL              useAlert;
@property (nonatomic, strong) NSMutableArray*   ignoreList;

@property (nonatomic, assign) BOOL              prepared;

@end

@implementation SPMemoryDebugger

+ (instancetype)sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.ignoreList = @[].mutableCopy;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(detectPong:)
                                                     name:SPMemoryDebuggerPongNotification
                                                   object:nil];
    }
    return self;
}

- (void)startDebugger {
    if (!self.prepared) {
        [UINavigationController prepareForMemoroyDebugger];
        [UIViewController prepareForMemoroyDebugger];
        [UIView prepareForMemoroyDebugger];
        self.prepared = YES;
    }
    [self startPingTimer];
}

- (void)addIgnoreList:(NSArray*)ignoreList {
    @synchronized (self) {
        for (NSString* item in ignoreList) {
            if ([item isKindOfClass:[NSString class]]) {
                [_ignoreList addObject:item];
            }
        }
    }
}

- (void)alertLeaks {
    _useAlert = true;
}

- (void)startPingTimer {
    if (self.pingTimer) {
        return;
    }
    
    self.pingTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(self.pingTimer, DISPATCH_TIME_NOW, kSPMemoryDetectorPingInterval * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(self.pingTimer, ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:SPMemoryDebuggerPingNotification
                                                            object:nil];
    });
    dispatch_resume(self.pingTimer);
}

- (void)stop {
    if (self.pingTimer) {
        dispatch_source_cancel(self.pingTimer);
        self.pingTimer = nil;
    }
}

- (BOOL)isRunning {
    return self.pingTimer;
}

- (void)sendPing {
    [[NSNotificationCenter defaultCenter] postNotificationName:SPMemoryDebuggerPingNotification
                                                        object:nil];
}

- (NSArray *)defaultIgnoreClasses {
    return @[
             @"UITextFieldLabel",
             @"UIFieldEditor",
             @"UITextSelectionView",
             @"UITableViewCellSelectedBackground",
             @"UIView",
             @"UIAlertController",
             ];
}

- (NSArray *)defaultObserveContainerClasses {
    return @[
             @"NSArray",
             @"NSMutableArray",
             @"NSDictionary",
             @"NSSet",
             @"NSMutableSet"
             ];
}

- (void)detectPong:(NSNotification*)notification {
    NSObject *leakedObject = notification.object;
    NSString *leakedName = NSStringFromClass([leakedObject class]);
    @synchronized (self) {
        if ([_ignoreList containsObject:leakedName]) {
            return;
        }
    }
    
    //we got a leak here
    if (_useAlert) {
        NSString* msg = [NSString stringWithFormat:@"Detect Possible Leak: %@", [leakedObject class]];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"PLeakSniffer"
                                                            message:msg
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil];
        [alertView show];
    } else {
        if ([leakedObject isKindOfClass:[UIViewController class]]) {
            SPLeakLog(@"\n\nDetect Possible Controller Leak: %@ \n\n", [leakedObject class]);
            
            NSString *retainCycleDetectResult = [self detectRetainCycleForCandidate:leakedObject];
            
            NSLog(@"疑似内存泄露的对象循环引用检测结果: %@", retainCycleDetectResult);
            
        } else {
            SPLeakLog(@"\n\nDetect Possible Leak: %@ \n\n", [leakedObject class]);
        }
    }
}

- (NSString *)detectRetainCycleForCandidate:(id)candidate {
    if (!candidate) {
        return nil;
    }
    
    FBRetainCycleDetector *detector = [[FBRetainCycleDetector alloc] init];
    [detector addCandidate:candidate];
    NSSet *retainCycles = [detector findRetainCyclesWithMaxCycleLength:8];
    
    NSMutableString *content = [NSMutableString string];
    for (NSArray *retainCycle in retainCycles) {
        NSInteger index = 0;
        for (FBObjectiveCGraphElement *element in retainCycle) {
            if (element.object == candidate) {
                NSArray *shiftedRetainCycle = [self shiftArray:retainCycle toIndex:index];
                [content appendFormat:@"存在以下循环引用: \n %@ %@ ", NSStringFromClass([candidate class]), shiftedRetainCycle];
                break;
            }
            ++index;
        }
    }
    // 未检测到循环引用
    if (content.length == 0) {
        [content appendString:@"使用 FBRetainCycleDetector 未检测到引用循环，建议使用 Xcode Memory Graph 确认。"];
    }
    
    return content.copy;
}

- (NSArray *)shiftArray:(NSArray *)array toIndex:(NSInteger)index {
    if (index < 0 || index >= array.count) {
        return nil;
    } else if (index == 0) {
        return array;
    }
    
    NSRange range = NSMakeRange(index, array.count - index);
    if (range.length > 0) {
        return nil;
    }
    
    NSMutableArray *result = [[array subarrayWithRange:range] mutableCopy];
    [result addObjectsFromArray:[array subarrayWithRange:NSMakeRange(0, index)]];
    return result;
}


@end
