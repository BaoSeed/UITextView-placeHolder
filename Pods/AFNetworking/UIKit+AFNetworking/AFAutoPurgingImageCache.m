// AFAutoPurgingImageCache.m
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <TargetConditionals.h>

#if TARGET_OS_IOS || TARGET_OS_TV 

#import "AFAutoPurgingImageCache.h"




@interface AFCachedImage : NSObject

@property (nonatomic, strong) UIImage  *image;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, assign) UInt64   totalBytes;
@property (nonatomic, strong) NSDate   *lastAccessDate;
@property (nonatomic, assign) UInt64   currentMemoryUsage;

@end

@implementation AFCachedImage

-(instancetype)initWithImage:(UIImage *)image
                  identifier:(NSString *)identifier {
    
    if (self = [self init]) {
        
        self.image            = image;
        self.identifier       = identifier;

        CGSize imageSize      = CGSizeMake(image.size.width * image.scale, image.size.height * image.scale);
        CGFloat bytesPerPixel = 4.0;
        CGFloat bytesPerSize  = imageSize.width * imageSize.height;
        self.totalBytes       = (UInt64)bytesPerPixel * (UInt64)bytesPerSize;
        self.lastAccessDate   = [NSDate date];
    }
    return self;
}

- (UIImage*)accessImage {
    
    self.lastAccessDate = [NSDate date];
    return self.image;
}

- (NSString *)description {
    
    NSString *descriptionString = [NSString stringWithFormat:@"Idenfitier: %@  lastAccessDate: %@ ", self.identifier, self.lastAccessDate];
    return descriptionString;

}

@end





@interface AFAutoPurgingImageCache ()

@property (nonatomic, strong) NSMutableDictionary <NSString* , AFCachedImage*> *cachedImages;
@property (nonatomic, assign) UInt64           currentMemoryUsage;
@property (nonatomic, strong) dispatch_queue_t synchronizationQueue;
@end

@implementation AFAutoPurgingImageCache

- (instancetype)init {
    
    //默认为内存100M，后者为缓存溢出后保留的内存
    return [self initWithMemoryCapacity:100 * 1024 * 1024 preferredMemoryCapacity:60 * 1024 * 1024];
}

- (instancetype)initWithMemoryCapacity:(UInt64)memoryCapacity
               preferredMemoryCapacity:(UInt64)preferredMemoryCapacity {
    
    if (self = [super init]) {
        
        
        //内存大小
        self.memoryCapacity       = memoryCapacity;
        //缓存溢出后保留的内存
        self.preferredMemoryUsageAfterPurge = preferredMemoryCapacity;
        
        
        
        //cache的字典
        self.cachedImages         = [[NSMutableDictionary alloc] init];

        
        
        //队列并行
        NSString *queueName       = [NSString stringWithFormat:@"com.alamofire.autopurgingimagecache-%@", [[NSUUID UUID] UUIDString]];
        
        self.synchronizationQueue = dispatch_queue_create([queueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);

        
         //收到内存警告的通知
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(removeAllImages)
         name:UIApplicationDidReceiveMemoryWarningNotification
         object:nil];

    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UInt64)memoryUsage {
    
    __block UInt64 result = 0;
    dispatch_sync(self.synchronizationQueue, ^{
        
        result = self.currentMemoryUsage;
        
    });
    
    return result;
}



//收到内存警告后移除所有的图片
- (BOOL)removeAllImages {
    
    __block BOOL removed = NO;
    
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        
        if (self.cachedImages.count > 0) {
            
            [self.cachedImages removeAllObjects];
            self.currentMemoryUsage = 0;
            removed = YES;
        }
    });
    return removed;
}



//withIdentifier
- (void)addImage:(UIImage *)image withIdentifier:(NSString *)identifier {
    
    
    //dispatch_barrier_sync和dispatch_barrier_async只在自己创建的并发队列上有效，在全局(Global)并发队列、串行队列上，效果跟dispatch_(a)sync效果一样。
    //dispatch_barrier_sync在串行队列和全局并行队列里面和dispatch_sync同样的效果，所以需考虑同dispatch_sync一样的死锁问题。
    
    //1、添加图片
    //用dispatch_barrier_async，来同步这个并行队列
    dispatch_barrier_async(self.synchronizationQueue, ^{
        
        //生成cache对象
        AFCachedImage *cacheImage = [[AFCachedImage alloc] initWithImage:image identifier:identifier];

        //去之前cache的字典里取
        AFCachedImage *previousCachedImage = self.cachedImages[identifier];
        
        //如果有被缓存过
        if (previousCachedImage != nil) {
            
            //当前已经使用的内存大小减去图片的大小
            self.currentMemoryUsage -= previousCachedImage.totalBytes;
        }

         //把新cache的image加上去
        self.cachedImages[identifier] = cacheImage;
        
         //加上内存大小
        self.currentMemoryUsage += cacheImage.totalBytes;
        
    });
    
    
    
    
    //2、做缓存溢出的清楚，清除的是早期的缓存
    dispatch_barrier_async(self.synchronizationQueue, ^{
        
        //如果使用的内存大于我们设置的内存容量
        if (self.currentMemoryUsage > self.memoryCapacity) {
            
             //拿到使用内存 - 被清空后首选内存 =  需要被清除的内存
            UInt64 bytesToPurge = self.currentMemoryUsage - self.preferredMemoryUsageAfterPurge;
            
            //拿到所有缓存的数据
            NSMutableArray <AFCachedImage*> *sortedImages = [NSMutableArray arrayWithArray:self.cachedImages.allValues];
            
            
            //根据lastAccessDate排序 升序，越晚的越后面
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastAccessDate" ascending:YES];
            
            [sortedImages sortUsingDescriptors:@[sortDescriptor]];

            
            //移除早期的cache bytesToPurge大小
            UInt64 bytesPurged = 0;

            for (AFCachedImage *cachedImage in sortedImages) {
                
                
                [self.cachedImages removeObjectForKey:cachedImage.identifier];
                
                bytesPurged += cachedImage.totalBytes;
                
                if (bytesPurged >= bytesToPurge) {
                    
                    break ;
                }
                
            }
            
            
            //减去被清掉的内存
            self.currentMemoryUsage -= bytesPurged;
            
        }
        
    });
    
}

- (nullable UIImage *)imageWithIdentifier:(NSString *)identifier {
    
    __block UIImage *image = nil;
    dispatch_sync(self.synchronizationQueue, ^{
        AFCachedImage *cachedImage = self.cachedImages[identifier];
        image = [cachedImage accessImage];
    });
    return image;
}


- (BOOL)removeImageWithIdentifier:(NSString *)identifier {
    
    
    __block BOOL removed = NO;
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        
        AFCachedImage *cachedImage = self.cachedImages[identifier];
        
        if (cachedImage != nil) {
            
            [self.cachedImages removeObjectForKey:identifier];
            
            self.currentMemoryUsage -= cachedImage.totalBytes;
            
            removed = YES;
        }
    });
    return removed;
}








//forRequest
- (void)addImage:(UIImage *)image forRequest:(NSURLRequest *)request withAdditionalIdentifier:(NSString *)identifier {
    [self addImage:image withIdentifier:[self imageCacheKeyFromURLRequest:request withAdditionalIdentifier:identifier]];
}

- (BOOL)removeImageforRequest:(NSURLRequest *)request withAdditionalIdentifier:(NSString *)identifier {
    return [self removeImageWithIdentifier:[self imageCacheKeyFromURLRequest:request withAdditionalIdentifier:identifier]];
}

- (nullable UIImage *)imageforRequest:(NSURLRequest *)request withAdditionalIdentifier:(NSString *)identifier {
    return [self imageWithIdentifier:[self imageCacheKeyFromURLRequest:request withAdditionalIdentifier:identifier]];
}

- (NSString *)imageCacheKeyFromURLRequest:(NSURLRequest *)request withAdditionalIdentifier:(NSString *)additionalIdentifier {
    NSString *key = request.URL.absoluteString;
    if (additionalIdentifier != nil) {
        key = [key stringByAppendingString:additionalIdentifier];
    }
    return key;
}

@end

#endif





