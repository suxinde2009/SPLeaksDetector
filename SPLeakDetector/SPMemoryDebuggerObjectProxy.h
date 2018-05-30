//
//  SPMemoryDebuggerObjectProxy.h
//  SPLeakDetector
//
//  Created by SuXinDe on 2018/5/30.
//  Copyright © 2018年 su xinde. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SPMemoryDebuggerObjectProxyKVODelegate <NSObject>

- (void)didObserveNewValue:(id)value;

@end

@interface SPMemoryDebuggerObjectProxy : NSObject

- (void)prepareProxy:(NSObject*)target;

@property (nonatomic, weak) NSObject*                 weakTarget;
@property (nonatomic, weak) NSObject*                 weakHost;
@property (nonatomic, weak) NSObject*                 weakResponder;

@property (nonatomic, weak) id<SPMemoryDebuggerObjectProxyKVODelegate>                 kvoDelegate;

- (void)observeObject:(id)obj
          withKeyPath:(NSString*)path
         withDelegate:(id<SPMemoryDebuggerObjectProxyKVODelegate>)delegate;

@end
