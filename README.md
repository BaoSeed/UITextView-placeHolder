# UITextView-placeHolder
a category for UITextView to set  placeHolder like UITextField

//example

UITextView *text           = [[UITextView alloc]init];
text.delegate              = self;
text.tintColor             = kColor;
text.scrollIndicatorInsets = UIEdgeInsetsMake(10.0f, 0.0f, 10.0f, 8.0f);
text.contentInset          = UIEdgeInsetsZero;
text.keyboardAppearance    = UIKeyboardAppearanceDefault;
text.keyboardType          = UIKeyboardTypeDefault;
text.returnKeyType         = UIReturnKeyDefault;
text.textAlignment         = NSTextAlignmentLeft;
text.alwaysBounceVertical  = YES;
text.frame  = CGRectMake(0, 0, KSCREEWIDTH, KSCREEWIDTH * 340 / 750.0);
text.textColor             = [UIColor grayColor];

//set placeholder
text.zp_placeholder        = text_placeholder;

博客地址：http://www.jianshu.com/p/4e1bac661ad0
