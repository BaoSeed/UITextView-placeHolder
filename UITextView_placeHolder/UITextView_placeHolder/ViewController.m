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
    

    dispatch_semaphore_t semaphore1 = dispatch_semaphore_create(0);
    dispatch_semaphore_t semaphore2 = dispatch_semaphore_create(0);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSLog(@"thread 2");
            sleep(2);
            dispatch_semaphore_signal(semaphore2);
        });
        
        
        dispatch_semaphore_wait(semaphore2, DISPATCH_TIME_FOREVER);
        NSLog(@"thread 1");
        sleep(2);
        
        dispatch_semaphore_signal(semaphore1);
    });
    
    
    dispatch_semaphore_wait(semaphore1, DISPATCH_TIME_FOREVER);
    NSLog(@"main thread");
    
}






- (id)af_dataTask_sendSynchronousDataTaskWithURL:(NSString *)URL {
    
    
    NSURLRequest  *request  = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    
    [[[AFHTTPSessionManager manager]  dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        
        //af 的是主线程，这里根本进不来
        NSLog(@"%@",[NSThread currentThread]);
        
    
        if (!error) {
            
            NSLog(@"成功");
            NSLog(@"成功");
            NSLog(@"成功");
            
        }else{
            
            NSLog(@"失败");
            NSLog(@"失败");
            NSLog(@"失败");
        }
        
        
        
        dispatch_semaphore_signal(semaphore);
        
    }]resume];
    
    
    
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    
    NSLog(@"完成");
    NSLog(@"完成");
    NSLog(@"完成");
    
    return nil;
}

- (NSData *)session_sendSynchronousDataTaskWithURL:(NSString *)URL{
    
    
    
    NSURLRequest  *request  = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block NSData *data = nil;
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                     completionHandler:^(NSData *taskData, NSURLResponse *taskResponse, NSError *taskError) {
                                         
                                         
        //2017-06-30 18:52:36.113 UITextView_placeHolder[75064:1710634] <NSThread: 0x60000006dec0>{number = 3, name = (null)}
        NSLog(@"%@",[NSThread currentThread]);
        
                                     
        dispatch_async(dispatch_get_main_queue(), ^{
            
            
            data = taskData;
            
            if (!taskError) {
                
                NSLog(@"成功");
                NSLog(@"成功");
                NSLog(@"成功");
                
            }else{
                
                NSLog(@"失败");
                NSLog(@"失败");
                NSLog(@"失败");
            }
            
            
            dispatch_semaphore_signal(semaphore);
            
        });
                                         
                                        
    }] resume];
    
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    NSLog(@"完成");
    NSLog(@"完成");
    NSLog(@"完成");
    
    return data;
}


- (id)af_session_sendSynchRequest:(NSString *)URLString
                       parameters:(NSDictionary *)parameters
                            error:(NSError **)returnError {
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    
    __block id data = nil;
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    
    [manager GET:URLString
      parameters:parameters
        progress:NULL
         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        
        data = responseObject;
        
        dispatch_semaphore_signal(semaphore);
        
        NSLog(@"成功");
        NSLog(@"成功");
        NSLog(@"成功");
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        
        if (returnError) {
            
            *returnError = error;
        }
        
        dispatch_semaphore_signal(semaphore);
        
        NSLog(@"失败");
        NSLog(@"失败");
        NSLog(@"失败");
        
    }];
    
    
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    
    NSLog(@"哈哈哈");
    NSLog(@"哈哈哈");
    NSLog(@"哈哈哈");
    
    
    return data;
}



- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
   
    [super touchesBegan:touches withEvent:event];
    
    
    
    [self af_dataTask_sendSynchronousDataTaskWithURL:@"www.bnaidu.com"];
    
    
    
    /*
     NSError *error = nil;
        [self af_session_sendSynchRequest:@"www.baidu.com"
                               parameters:nil
                                    error:&error];
     */
    
    

}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
