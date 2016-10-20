

#import "UITextView+Extensions.h"
#import <objc/runtime.h>

@interface UIButton ()

/**
 *  bool 是否添加通知
 */
@property (nonatomic, assign) BOOL isExcuteNoti;


@end

@implementation UITextView (Extensions)


void TextViewSwizzleMethod(Class cls, SEL originalSelector, SEL swizzledSelector)
{
    Method originalMethod = class_getInstanceMethod(cls, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
    
    BOOL didAddMethod =
    class_addMethod(cls,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(cls,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}


+ (void)load
{
    [super load];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        TextViewSwizzleMethod([self class],
                        @selector(drawRect:),
                        @selector(place_drawRect:));
        
        TextViewSwizzleMethod([self class],
                              NSSelectorFromString(@"dealloc"),
                              @selector(place_dealloc));
    });
}


- (void)place_dealloc
{
    if(self.isExcuteNoti)
      [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:self];
    
    [self place_dealloc];
}

- (void)place_drawRect:(CGRect)rect
{
    //设置默认字体颜色
    UIFont  *placeFont  = self.zp_placeholderFont? self.zp_placeholderFont:[UIFont systemFontOfSize:14.0];
    UIColor *placeColor = self.zp_placeholderColor?self.zp_placeholderColor:[UIColor lightGrayColor];
    
    if([self.text length] == 0 && self.zp_placeholder)
    {
        
        CGRect placeHolderRect = CGRectMake(10.0f,
                                            7.0f,
                                            rect.size.width,
                                            rect.size.height);
        
        [placeColor set];
        
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_0)
        {
            
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
            paragraphStyle.alignment = self.textAlignment;
            
            [self.zp_placeholder drawInRect:placeHolderRect withAttributes:
  
                                          @{ NSFontAttributeName :            placeFont,
                                             NSForegroundColorAttributeName:  placeColor,
                                             NSParagraphStyleAttributeName :   paragraphStyle}];
        }
        
        else
        {
            
            [self.zp_placeholder drawInRect:placeHolderRect
                                withFont:placeFont
                           lineBreakMode:NSLineBreakByTruncatingTail
                               alignment:self.textAlignment];
        }
    }


    [self place_drawRect:rect];
}


#pragma mark - UITextViewTextDidChangeNotification
- (void)didReceiveTextDidChangeNotification:(NSNotification *)notification
{
    [self setNeedsDisplay];
}



#pragma mark - setters && getters
- (void)setZp_placeholder:(NSString *)zp_placeholder
{
    
    objc_setAssociatedObject(self,
                              @selector(zp_placeholder),
                             zp_placeholder,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    if(!self.isExcuteNoti)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveTextDidChangeNotification:)
                                                     name:UITextViewTextDidChangeNotification
                                                   object:self];
        
        self.isExcuteNoti = 1;
    }
    
      [self setNeedsDisplay];
    
}
- (NSString *)zp_placeholder
{
    return objc_getAssociatedObject(self, _cmd);
}



- (void)setZp_placeholderColor:(UIColor *)zp_placeholderColor
{
    objc_setAssociatedObject(self,
                             @selector(zp_placeholderColor),
                             zp_placeholderColor,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
       [self setNeedsDisplay];
}
- (UIColor *)zp_placeholderColor
{
      return objc_getAssociatedObject(self, _cmd);
}


- (void)setZp_placeholderFont:(UIFont *)zp_placeholderFont
{
    objc_setAssociatedObject(self,
                             @selector(zp_placeholderFont),
                             zp_placeholderFont,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
      [self setNeedsDisplay];
}
- (UIFont *)zp_placeholderFont
{
      return objc_getAssociatedObject(self, _cmd);
}

- (void)setIsExcuteNoti:(BOOL)isExcuteNoti
{
    objc_setAssociatedObject(self, @selector(isExcuteNoti), @(isExcuteNoti), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isExcuteNoti
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

@end
