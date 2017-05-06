//
//  NSObject+TJMSwizzle.m
//  FeiDan
//
//  Created by 朱鹏 on 2017/4/17.
//  Copyright © 2017年 TianJiMoney. All rights reserved.
//

#import "NSObject+TJMSwizzle.h"
#import <objc/runtime.h>
@implementation NSObject (TJMSwizzle)

void tjm_ObjcSwizzleMethod(Class cls,
                                    SEL originalSelector,
                                    SEL swizzledSelector)
{
    Method originalMethod = class_getInstanceMethod(cls, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
    
    BOOL didAddMethod =
    class_addMethod(cls,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod)
    {
        class_replaceMethod(cls,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    }
    else
    {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@end
