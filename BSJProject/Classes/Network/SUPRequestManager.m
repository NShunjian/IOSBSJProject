//
//  SUPRequestManager.m
//  SuperProject
//
//  Created by NShunJian on 2018/1/20.
//  Copyright © 2018年 superMan. All rights reserved.
//
#import "SUPRequestManager.h"


@implementation SUPRequestManager


#pragma mark - POST_GET
// post
- (void)POST:(NSString *)urlString parameters:(id)parameters completion:(void (^)(SUPBaseResponse *))completion
{
    [self request:@"POST" URL:urlString parameters:parameters completion:completion];
}

//get
- (void)GET:(NSString *)urlString parameters:(id)parameters completion:(void (^)(SUPBaseResponse *))completion
{
    [self request:@"GET" URL:urlString parameters:parameters completion:completion];
}



#pragma mark - post & get
- (void)request:(NSString *)method URL:(NSString *)urlString parameters:(id)parameters completion:(void (^)(SUPBaseResponse *response))completion
{
    
    
    if (self.isLocal) {
        [self requestLocal:urlString completion:completion];
        return;
    }
    
    if (self.currentNetworkStatus == AFNetworkReachabilityStatusNotReachable) {
        SUPBaseResponse *response = [SUPBaseResponse new];
        response.error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil];
        response.errorMsg = @"网络无法连接";
        completion(response);
        return;
    }
    
    
    void(^success)(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) = ^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        
        [self wrapperTask:task responseObject:responseObject error:nil completion:completion];
    };
    
    void(^failure)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) = ^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [self wrapperTask:task responseObject:nil error:error completion:completion];
    };
    
    
    
    if ([method isEqualToString:@"GET"]) {
        
        [self GET:urlString parameters:parameters progress:nil success:success failure:failure];
        
    }
    
    
    if ([method isEqualToString:@"POST"]) {
        
        [self POST:urlString parameters:parameters progress:nil success:success failure:failure];
    }
    
}


#pragma mark - 加载本地数据
- (void)requestLocal:(NSString *)urlString completion:(void (^)(SUPBaseResponse *response))completion
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSError *fileError = nil;
        NSError *jsonError = nil;
        
        NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:[urlString lastPathComponent] withExtension:@"json"];
        
        NSData *jsonData = [NSData dataWithContentsOfURL:fileUrl options:0 error:&fileError];
        
        
        id responseObj = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&jsonError];
        
        
        [self wrapperTask:nil responseObject:responseObj error:fileError ?: jsonError completion:completion];
        
    });
    
}


#pragma mark - 处理数据
- (void)wrapperTask:(NSURLSessionDataTask *)task responseObject:(id)responseObject error:(NSError *)error completion:(void (^)(SUPBaseResponse *response))completion
{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        SUPBaseResponse *response = [self convertTask:task responseObject:responseObject error:error];
        
        [self LogResponse:task.currentRequest.URL.absoluteString response:response];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            !completion ?: completion(response);
            
        });
        
    });
    
}



#pragma mark - 包装返回的数据
- (SUPBaseResponse *)convertTask:(NSURLSessionDataTask *)task responseObject:(id)responseObject error:(NSError *)error
{
    
    SUPBaseResponse *response = [SUPBaseResponse new];
    
    if (responseObject) {
        response.responseObject = responseObject;
    }
    
    if (error) {
        response.error = error;
        response.statusCode = error.code;
    }
    
    
    if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
        
        NSHTTPURLResponse *HTTPURLResponse = (NSHTTPURLResponse *)task.response;
        
        response.headers = HTTPURLResponse.allHeaderFields.mutableCopy;
        
    }
    
    if (self.responseFormat) {
        response = self.responseFormat(response);
    }
    
    
    return response;
    
}




#pragma mark - 打印返回日志
- (void)LogResponse:(NSString *)urlString response:(SUPBaseResponse *)response
{
    NSLog(@"[%@]---%@", urlString, response);

}



#pragma mark - 上传文件
//  data 图片对应的二进制数据
//  name 服务端需要参数
//  fileName 图片对应名字,一般服务不会使用,因为服务端会直接根据你上传的图片随机产生一个唯一的图片名字
//  mimeType 资源类型
//  不确定参数类型 可以这个 octet-stream 类型, 二进制流
- (void)upload:(NSString *)urlString parameters:(id)parameters formDataBlock:(void(^)(id<AFMultipartFormData> formData))formDataBlock progress:(void (^)(NSProgress *progress))progress completion:(void (^)(SUPBaseResponse *response))completion
{
    
    [self POST:urlString parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
//        NSString *mineType = @"application/octet-stream";
        
//        [formData appendPartWithFileData:data name:name fileName:@"test" mimeType:mineType];
        
        !formDataBlock ?: formDataBlock(formData);
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            !progress ?: progress(uploadProgress);
        });
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [self wrapperTask:task responseObject:responseObject error:nil completion:completion];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [self wrapperTask:task responseObject:nil error:error completion:completion];
        
    }];
    
}







#pragma mark - 初始化设置
- (void)configSettings
{
    self.requestSerializer = [AFJSONRequestSerializer serializer];
    //设置可接收的数据类型
    self.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/plain", @"application/xml", @"text/xml", @"*/*", nil];
    self.currentNetworkStatus = AFNetworkReachabilityStatusUnknown;
    
    SUPWeakSelf(self);
    //记录网络状态
    [self.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        weakself.currentNetworkStatus = status;
    }];
    
    [self.reachabilityManager startMonitoring];
    
    //自定义处理数据
    self.responseFormat = ^SUPBaseResponse *(SUPBaseResponse *response) {
        return response;
    };
    
}

#pragma mark - 处理返回序列化
- (void)setResponseSerializer:(AFHTTPResponseSerializer<AFURLResponseSerialization> *)responseSerializer
{
    [super setResponseSerializer:responseSerializer];
    
    if ([responseSerializer isKindOfClass:[AFJSONResponseSerializer class]]) {
        AFJSONResponseSerializer *JSONserializer = (AFJSONResponseSerializer *)responseSerializer;
        JSONserializer.removesKeysWithNullValues = YES;
        JSONserializer.readingOptions = NSJSONReadingMutableContainers;
        
    }
    
    
}


//- (instancetype)init
//{
//    self = [super init];
//    if (self) {
//
//        [self configSettings];
//    }
//    return self;
//}
//
//static SUPRequestManager *_instance = nil;
//
//+ (instancetype)sharedManager
//{
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//
//        _instance = [[self alloc] init];
//
//
//    });
//
//    return _instance;
//}
+ (instancetype)manager {
    SUPRequestManager *manager = [super manager];
    [manager configSettings];
    return manager;
}

static SUPRequestManager *_instance = nil;
+ (instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [self manager];
    });
    return _instance;
}
@end
