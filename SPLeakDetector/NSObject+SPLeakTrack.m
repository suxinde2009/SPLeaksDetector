//
//  NSObject+SPLeakTrack.m
//  SPLeakDetector
//
//  Created by SuXinDe on 2018/5/30.
//  Copyright © 2018年 su xinde. All rights reserved.
//

#import "NSObject+SPLeakTrack.h"
#import "NSObject+SPLeak.h"
#import <objc/runtime.h>

@implementation NSObject (SPLeakTrack)

- (void)watchAllRetainedProperties:(int)level {
    if (level >= 5) { //don't go too deep
        return;
    }
    
    if ([self isKindOfClass:NSClassFromString(@"NSManagedObject")]) {
        return;
    }
    
    NSMutableArray* watchedProperties = @[].mutableCopy;
    
    //track class level1
    NSString* className = NSStringFromClass([self class]);
    if ([className hasPrefix:@"UI"] ||
        [className hasPrefix:@"NS"] ||
        [className hasPrefix:@"_"]) {
        return;
    }
    NSArray* l1Properties = [self getAllPropertyNames:[self class]];
    [watchedProperties addObjectsFromArray:l1Properties];
    
    //track class level2
    NSString* superClassName = NSStringFromClass([self superclass]);
    if ([superClassName hasPrefix:@"UI"] == false &&
        [superClassName hasPrefix:@"NS"] == false &&
        [superClassName hasPrefix:@"_"] == false) {
        NSArray* l2Properties = [self getAllPropertyNames:[self superclass]];
        [watchedProperties addObjectsFromArray:l2Properties];
    }
    
    //track class level3
    if ([[self superclass] superclass]) {
        NSString* superSuperClassName = NSStringFromClass([[self superclass] superclass]);
        if ([superSuperClassName hasPrefix:@"UI"] == false &&
            [superSuperClassName hasPrefix:@"NS"] == false &&
            [superSuperClassName hasPrefix:@"_"] == false) {
            NSArray* l3Properties = [self getAllPropertyNames:[[self superclass] superclass]];
            [watchedProperties addObjectsFromArray:l3Properties];
        }
    }
    
    
    for (NSString* name in watchedProperties) {
        id cur = [self valueForKey:name]; // 是否valueForKey是否存在风险???
        if (cur) {
            if ([cur markAlive]) {
                [cur memoryDebuggerProxy].weakHost = self;
                [cur watchAllRetainedProperties:level+1];
            }
        }
    }
    
}

- (void)didObserveNewValue:(id)value {
    if (value) {
        if ([value markAlive]) {
            [value memoryDebuggerProxy].weakHost = self;
            [value watchAllRetainedProperties:0];
        }
    }
}

- (BOOL)isAlive {
    return (self.memoryDebuggerProxy.weakHost != nil);
}

#pragma mark- mess with runtime

- (NSArray*)getAllPropertyNames:(Class)cls {
    unsigned int i, count = 0;
    objc_property_t* properties = class_copyPropertyList(cls, &count );
    
    if(count == 0) {
        free(properties);
        return nil;
    }
    NSMutableArray* names = @[].mutableCopy;
    
    for (i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        
        NSString* typeName = @"";
        const char* str = property_getTypeString(property);
        if (str != NULL) {
            typeName = [NSString stringWithUTF8String:str];
        }
        
        NSString* name = [NSString stringWithUTF8String:property_getName(property)];
        
        //we are only interested in a very limited group of types
        if ([typeName isEqualToString:@"T@\"SPMemoryDebuggerObjectProxy\""] ||
            [typeName hasPrefix:@"T@\"UI"] ||
            [typeName hasPrefix:@"T@\"NS"] ||
            [typeName rangeOfString:@"KVO"].location != NSNotFound) {
            continue;
        }
        
        bool isStrong = isStrongProperty(property);
        if (isStrong == false) {
            continue;
        }
        [names addObject:name];
    }
    return names;
}


- (SEL)setterForPropertyName:(NSString*)name {
    objc_property_t property = class_getProperty([self class], [name UTF8String]);
    if (property == nil) {
        return nil;
    }
    SEL result = property_getSetter(property);
    if (result != nil) {
        return result;
    }
    NSMutableString* setterName = @"set".mutableCopy;
    NSString* upcaseName = [name stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[name substringToIndex:1] capitalizedString]];
    [setterName appendString:upcaseName];
    [setterName appendString:@":"];
    
    if ([[self class] instancesRespondToSelector:NSSelectorFromString(setterName)] == false) {
        return nil; //no proper setter found
    }
    
    return NSSelectorFromString(setterName);
}

SEL property_getSetter(objc_property_t property) {
    const char* attrs = property_getAttributes(property);
    if (attrs == nil) {
        return nil;
    }
    const char* p = strstr(attrs, ",S");
    if (p == nil) {
        return nil;
    }
    p += 2;
    const char* e = strchr(p, ',');
    if (e == nil) {
        return sel_getUid(p);
    }
    if (e == p) {
        return nil;
    }
    
    int len = (int)(e - p);
    char* selPtr = malloc(len + 1);
    memcpy(selPtr, p, len);
    selPtr[len] = '\0';
    SEL result = sel_getUid(selPtr);
    free(selPtr);
    
    return result;
}

bool isStrongProperty(objc_property_t property) {
    const char* attrs = property_getAttributes( property );
    if (attrs == NULL) {
        return false;
    }
    const char* p = attrs;
    p = strchr(p, '&');
    if (p == NULL) {
        return false;
    } else {
        return true;
    }
}


const char* property_getTypeString( objc_property_t property ) {
    const char * attrs = property_getAttributes( property );
    if (attrs == NULL) {
        return NULL;
    }
    static char buffer[256];
    const char * e = strchr( attrs, ',' );
    if (e == NULL) {
        return NULL;
    }
    int len = (int)(e - attrs);
    memcpy(buffer, attrs, len);
    buffer[len] = '\0';
    return buffer;
}

@end
