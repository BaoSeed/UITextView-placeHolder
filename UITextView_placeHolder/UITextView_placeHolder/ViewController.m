//
//  ViewController.m
//  UITextView_placeHolder
//
//  Created by 朱鹏 on 2017/5/7.
//  Copyright © 2017年 Ivan. All rights reserved.
//

#import "ViewController.h"
#import <AFNetworking.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    [self af_sessionManager_Test];
    
}


- (void)af_sessionManager_Test{


    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    [manager GET:@"www.baidu.com" parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSURLSessionDataTask *dataTask = task;
        id dresponseObject = responseObject;
        
        NSLog(@"%@",dataTask);
        NSLog(@"%@",dresponseObject);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSURLSessionDataTask *dataTask = task;
        NSError *taskError = error;
        
        NSLog(@"%@",dataTask);
        NSLog(@"%@",taskError);
    
    }];
  
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
