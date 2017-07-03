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
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://app.qianhtj.com/app_img/appPic/TJ20170606100399_1496740048498.jpg"]];
    
    
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc]init] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        
        
        
        //@"image/jpeg"
        NSString *MIMEType = response.MIMEType;
        //615203
        long long expectedContentLength = response.expectedContentLength;
        //TJ20170606100399_1496740048498.jpg
        NSString *suggestedFilename =  response.suggestedFilename;
        //
        NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
        
        NSDictionary *allHeaderFields = res.allHeaderFields;
        
        NSLog(@"%@",allHeaderFields);
        /*
        {
            "Accept-Ranges"     = bytes;
            Connection          = "keep-alive";
            "Content-Length"    = 615203;
            "Content-Type"      = "image/jpeg";
            Date                = "Sat, 01 Jul 2017 06:26:35 GMT";
            Etag                = "\"593670d0-96323\"";
            "Last-Modified"     = "Tue, 06 Jun 2017 09:07:28 GMT";
            Server              = nginx;
        }
         */
        
        
        CGSize size    =  [self JPGImageSizeWithRangeHeader:data];
        
        NSLog(@"%@",NSStringFromCGSize(size));
        
        CGSize pngSize = [self PNGImageSizeWithRangeHeader:data];
        
        NSLog(@"%@",NSStringFromCGSize(pngSize));
        
        CGSize gifSize = [self GIFImageSizeWithRangeHeader:data];
        
        NSLog(@"%@",NSStringFromCGSize(gifSize));
        
    }];
    

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



- (CGSize)GIFImageSizeWithRangeHeader:(NSData *)data{
    short w1 = 0, w2 = 0;
    [data getBytes:&w1 range:NSMakeRange(0, 1)];
    [data getBytes:&w2 range:NSMakeRange(1, 1)];
    short w = w1 + (w2 << 8);
    
    short h1 = 0, h2 = 0;
    [data getBytes:&h1 range:NSMakeRange(2, 1)];
    [data getBytes:&h2 range:NSMakeRange(3, 1)];
    short h = h1 + (h2 << 8);
    return CGSizeMake(w, h);
}

- (CGSize)PNGImageSizeWithRangeHeader:(NSData *)data{
    int w1 = 0, w2 = 0, w3 = 0, w4 = 0;
    [data getBytes:&w1 range:NSMakeRange(0, 1)];
    [data getBytes:&w2 range:NSMakeRange(1, 1)];
    [data getBytes:&w3 range:NSMakeRange(2, 1)];
    [data getBytes:&w4 range:NSMakeRange(3, 1)];
    int w = (w1 << 24) + (w2 << 16) + (w3 << 8) + w4;
    int h1 = 0, h2 = 0, h3 = 0, h4 = 0;
    [data getBytes:&h1 range:NSMakeRange(4, 1)];
    [data getBytes:&h2 range:NSMakeRange(5, 1)];
    [data getBytes:&h3 range:NSMakeRange(6, 1)];
    [data getBytes:&h4 range:NSMakeRange(7, 1)];
    int h = (h1 << 24) + (h2 << 16) + (h3 << 8) + h4;
    
    return CGSizeMake(w, h);
}

- (CGSize)JPGImageSizeWithRangeHeader:(NSData *)data{
    
    
    if ([data length] <= 0x58) {
        return CGSizeZero;
    }
    
    if ([data length] < 210) {// 肯定只有一个DQT字段
        
        short w1 = 0, w2 = 0;
        [data getBytes:&w1 range:NSMakeRange(0x60, 0x1)];
        [data getBytes:&w2 range:NSMakeRange(0x61, 0x1)];
        short w = (w1 << 8) + w2;
        short h1 = 0, h2 = 0;
        
        [data getBytes:&h1 range:NSMakeRange(0x5e, 0x1)];
        [data getBytes:&h2 range:NSMakeRange(0x5f, 0x1)];
        short h = (h1 << 8) + h2;
        return CGSizeMake(w, h);
        
    } else {
        
        short word = 0x0;
        [data getBytes:&word range:NSMakeRange(0x15, 0x1)];
        
        if (word == 0xdb) {
            
            [data getBytes:&word range:NSMakeRange(0x5a, 0x1)];
            if (word == 0xdb) {// 两个DQT字段
                
                short w1 = 0, w2 = 0;
                [data getBytes:&w1 range:NSMakeRange(0xa5, 0x1)];
                [data getBytes:&w2 range:NSMakeRange(0xa6, 0x1)];
                short w = (w1 << 8) + w2;
                
                short h1 = 0, h2 = 0;
                [data getBytes:&h1 range:NSMakeRange(0xa3, 0x1)];
                [data getBytes:&h2 range:NSMakeRange(0xa4, 0x1)];
                short h = (h1 << 8) + h2;
                return CGSizeMake(w, h);
                
            } else {// 一个DQT字段
                
                short w1 = 0, w2 = 0;
                [data getBytes:&w1 range:NSMakeRange(0x60, 0x1)];
                [data getBytes:&w2 range:NSMakeRange(0x61, 0x1)];
                short w = (w1 << 8) + w2;
                short h1 = 0, h2 = 0;
                
                [data getBytes:&h1 range:NSMakeRange(0x5e, 0x1)];
                [data getBytes:&h2 range:NSMakeRange(0x5f, 0x1)];
                short h = (h1 << 8) + h2;
                return CGSizeMake(w, h);
                
            }
        }
        
        else {
            return CGSizeZero;
        }
    }
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
