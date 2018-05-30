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

#define kPLeakSnifferPingInterval       0.5f

@interface SPMemoryDebugger ()

@property (nonatomic, strong) NSTimer*                 pingTimer;
@property (nonatomic, assign) BOOL                     useAlert;
@property (nonatomic, strong) NSMutableArray*          ignoreList;

@end

@implementation SPMemoryDebugger

+ (instancetype)sharedInstance {
    static SPMemoryDebugger* instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [SPMemoryDebugger new];
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

- (void)installLeakSniffer {
    [UINavigationController prepareForSniffer];
    [UIViewController prepareForSniffer];
    [UIView prepareForSniffer];
    
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
    if ([NSThread isMainThread] == false) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self startPingTimer];
            return ;
        });
    }
    
    if (self.pingTimer) {
        return;
    }
    
    self.pingTimer = [NSTimer scheduledTimerWithTimeInterval:kPLeakSnifferPingInterval target:self selector:@selector(sendPing) userInfo:nil repeats:true];
}

- (void)sendPing
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SPMemoryDebuggerPingNotification object:nil];
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
        } else {
            SPLeakLog(@"\n\nDetect Possible Leak: %@ \n\n", [leakedObject class]);
        }
    }
}

@end
