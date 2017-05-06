//
//  NSObject+TJMSwizzle.h
//  FeiDan
//
//  Created by 朱鹏 on 2017/4/17.
//  Copyright © 2017年 TianJiMoney. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (TJMSwizzle)

void tjm_ObjcSwizzleMethod(Class cls,
                           SEL originalSelector,
                           SEL swizzledSelector);

@end
