//
//  UINavigationController+SPLeak.h
//  SPLeakDetector
//
//  Created by SuXinDe on 2018/5/30.
//  Copyright © 2018年 su xinde. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPMemoryDebugger.h"

@interface UINavigationController (SPLeak) <SPMemoryDebuggerProtocol>

@end
