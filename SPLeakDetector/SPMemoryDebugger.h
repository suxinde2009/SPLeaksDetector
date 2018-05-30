//
//  SPMemoryDebugger.h
//  SPLeakDetector
//
//  Created by SuXinDe on 2018/5/30.
//  Copyright © 2018年 su xinde. All rights reserved.
//

#import <Foundation/Foundation.h>
#define SPLeakLog(format, ...) NSLog(format, ##__VA_ARGS__)

#define SPMemoryDebuggerPingNotification @"SPMemoryDebuggerPingNotification"
#define SPMemoryDebuggerPongNotification @"SPMemoryDebuggerPongNotification"

@protocol SPMemoryDebuggerProtocol <NSObject>

+ (void)prepareForSniffer;

- (BOOL)markAlive;

- (BOOL)isAlive;

@end

@interface SPMemoryDebugger : NSObject

+ (instancetype)sharedInstance;

- (void)installLeakSniffer;
- (void)addIgnoreList:(NSArray*)ignoreList;
- (void)alertLeaks; //use UIAlertView to notify leaks

@end
