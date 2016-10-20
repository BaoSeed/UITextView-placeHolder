

#import <UIKit/UIKit.h>

@interface UITextView (Extensions)

/**
 * 占位提示语
 */
@property (nonatomic, copy)   NSString *zp_placeholder;

/**
 * 占位提示语的字体颜色
 */
@property (nonatomic, strong) UIColor *zp_placeholderColor;

/**
 * 占位提示语的字体
 */
@property (nonatomic, strong) UIFont  *zp_placeholderFont;


@end
