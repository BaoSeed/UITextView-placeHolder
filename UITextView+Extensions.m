//
//  UITextView+TJMPlaceHolder.m
//  FeiDan
//
//  Created by 朱鹏 on 2017/3/24.
//  Copyright © 2017年 TianJiMoney. All rights reserved.
//

#import "UITextView+TJMPlaceHolder.h"
#import <objc/runtime.h>
#import "NSObject+TJMSwizzle.h"

static void * TJMTextViewTextChangedContext= & TJMTextViewTextChangedContext;

@interface UITextView ()

/**
 *  bool 是否添加通知
 */
@property (nonatomic, assign) BOOL isExcuteNoti;


@end

@implementation UITextView (TJMPlaceHolder)
+ (void)load
{
    // [super load];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      
                      tjm_ObjcSwizzleMethod([self class],
                                            @selector(drawRect:),
                                            @selector(place_drawRect:));
                      
                      tjm_ObjcSwizzleMethod([self class],
                                            NSSelectorFromString(@"dealloc"),
                                            @selector(place_dealloc));
                  });
}


- (void)place_dealloc
{
    if(self.isExcuteNoti){
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:self];
        
        [self removeObserver:self forKeyPath:@"text" context:TJMTextViewTextChangedContext];
    }
    
    [self place_dealloc];
}

- (void)place_drawRect:(CGRect)rect
{
    //设置默认字体颜色
    UIFont  *placeFont  = self.tjm_placeholderFont? self.tjm_placeholderFont:[UIFont systemFontOfSize:14.0];
    UIColor *placeColor = self.tjm_placeholderColor?self.tjm_placeholderColor:[UIColor lightGrayColor];
    
    BOOL isZero = UIEdgeInsetsEqualToEdgeInsets(self.tjm_placeContainerInset, UIEdgeInsetsZero);
    UIEdgeInsets placeInsets = isZero?self.textContainerInset:self.tjm_placeContainerInset;
    
    if([self.text length] == 0 && self.tjm_placeholder)
    {
        
        CGRect InsetRect =  UIEdgeInsetsInsetRect(rect, placeInsets);
        CGRect placeHolderRect = InsetRect;
        
        [placeColor set];
        
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_0)
        {
            
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
            paragraphStyle.alignment = self.textAlignment;
            paragraphStyle.paragraphSpacing   = 2;
            paragraphStyle.firstLineHeadIndent= 7;
            //            paragraphStyle.headIndent=2;
            //            paragraphStyle.paragraphSpacingBefore=2;
            //            paragraphStyle.defaultTabInterval=2;
            
            [self.tjm_placeholder drawInRect:placeHolderRect
                              withAttributes:
             
             @{ NSFontAttributeName :            placeFont,
                NSForegroundColorAttributeName:  placeColor,
                NSParagraphStyleAttributeName :   paragraphStyle
                }
             ];
        }
        
        else
        {
            
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
            
            [self.tjm_placeholder drawInRect:placeHolderRect
                                    withFont:placeFont
                               lineBreakMode:NSLineBreakByTruncatingTail
                                   alignment:self.textAlignment];
            
            
#pragma clang diagnostic pop
        }
    }
    
    
    [self place_drawRect:rect];
}
#pragma mark - UITextViewTextDidChangeNotification
#pragma mark - 监听键盘输入text改变通知
- (void)didReceiveTextDidChangeNotification:(NSNotification *)notification
{
    [self setNeedsDisplay];
}
#pragma mark - KVO  监听手动设置text
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    if (object == self &&
        [keyPath isEqualToString:@"text"]
        && context==TJMTextViewTextChangedContext) {
        
        
        [self setNeedsDisplay];
        
    } else {
        // Make sure to call the superclass's implementation in the else block in case it is also implementing KVO
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
}

#pragma mark - setters && getters
- (void)setTjm_placeholder:(NSString *)tjm_placeholder
{
    
    objc_setAssociatedObject(self,
                             @selector(tjm_placeholder),
                             tjm_placeholder,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    if(!self.isExcuteNoti)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveTextDidChangeNotification:)
                                                     name:UITextViewTextDidChangeNotification
                                                   object:self];
        
        [self addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew context:TJMTextViewTextChangedContext];
        
        self.isExcuteNoti = 1;
    }
    
    [self setNeedsDisplay];
    
}
- (NSString *)tjm_placeholder
{
    return objc_getAssociatedObject(self, _cmd);
}
- (void)setTjm_placeholderColor:(UIColor *)tjm_placeholderColor
{
    objc_setAssociatedObject(self,
                             @selector(tjm_placeholderColor),
                             tjm_placeholderColor,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self setNeedsDisplay];
}
- (UIColor *)tjm_placeholderColor
{
    return objc_getAssociatedObject(self, _cmd);
}
- (void)setTjm_placeholderFont:(UIFont *)tjm_placeholderFont
{
    objc_setAssociatedObject(self,
                             @selector(tjm_placeholderFont),
                             tjm_placeholderFont,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self setNeedsDisplay];
}
- (UIFont *)tjm_placeholderFont
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setTjm_placeContainerInset:(UIEdgeInsets)tjm_placeContainerInset{
    
    objc_setAssociatedObject(self,
                             @selector(tjm_placeContainerInset),
                             [NSValue valueWithUIEdgeInsets:tjm_placeContainerInset],
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self setNeedsDisplay];
}
- (UIEdgeInsets)tjm_placeContainerInset{
    
    NSValue *insetValue = objc_getAssociatedObject(self, _cmd);
    return [insetValue UIEdgeInsetsValue];
}

- (void)setIsExcuteNoti:(BOOL)isExcuteNoti
{
    objc_setAssociatedObject(self, @selector(isExcuteNoti), @(isExcuteNoti), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (BOOL)isExcuteNoti
{
    
    //id object   const void *key
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}



@end

