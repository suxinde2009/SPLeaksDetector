//
//  NSObject+SPLeak.h
//  SPLeakDetector
//
//  Created by SuXinDe on 2018/5/30.
//  Copyright © 2018年 su xinde. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPMemoryDebugger.h"
#import "SPMemoryDebuggerObjectProxy.h"

@interface NSObject (SPLeak) <SPMemoryDebuggerProtocol>

+ (void)swizzleSEL:(SEL)originalSEL withSEL:(SEL)swizzledSEL;

@property (nonatomic, strong) SPMemoryDebuggerObjectProxy *memoryDebuggerProxy;

- (BOOL)isObjectAsSingleton;

@end
