//
//  UITextView+TJMPlaceHolder.h
//  FeiDan
//
//  Created by 朱鹏 on 2017/3/24.
//  Copyright © 2017年 TianJiMoney. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface UITextView (TJMPlaceHolder)

/**
 * 占位提示语
 */
@property (nonatomic, copy,) IBInspectable  NSString *tjm_placeholder;

/**
 * 占位提示语的字体颜色
 */
@property (nonatomic, strong) IBInspectable UIColor *tjm_placeholderColor;

/**
 * 占位提示语的字体
 */
@property (nonatomic, strong) UIFont  *tjm_placeholderFont;

/**
 *  显示区域Insets
 */
@property (nonatomic, assign) UIEdgeInsets tjm_placeContainerInset;


@end
