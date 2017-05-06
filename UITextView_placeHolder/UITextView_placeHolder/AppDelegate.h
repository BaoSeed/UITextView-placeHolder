//
//  AppDelegate.h
//  UITextView_placeHolder
//
//  Created by 朱鹏 on 2017/5/7.
//  Copyright © 2017年 Ivan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

