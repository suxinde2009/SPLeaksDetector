//
//  NSObject+SPLeakTrack.h
//  SPLeakDetector
//
//  Created by SuXinDe on 2018/5/30.
//  Copyright © 2018年 su xinde. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPMemoryDebuggerObjectProxy.h"

@interface NSObject (SPLeakTrack) <SPMemoryDebuggerObjectProxyKVODelegate>

- (void)watchAllRetainedProperties:(int)level;

@end
