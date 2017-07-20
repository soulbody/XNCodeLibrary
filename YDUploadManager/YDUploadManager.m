//
//  YDUploadManager.m
//  XingNLive
//
//  Created by xuning on 2017/7/20.
//  Copyright © 2017年 XingNLive&Mall. All rights reserved.
//

#import "YDUploadManager.h"
#import <HappyDNS.h>

@implementation YDUploadFile


- (instancetype)initWithFile:(NSString *)filePath key:(NSString *)key token:(NSString *)token {
    if (self = [self init]) {
        self.filePath = filePath;
        self.key = key;
        self.token = token;
    }
    return self;
    
}

@end

@interface YDUploadManager ()

@property (nonatomic, strong) QNUploadManager *upmanager;

// 上传完成的回调函数
@property (nonatomic, copy) YDUpCompletionHandler completionHandler;
// 上传进度的回调函数
@property (nonatomic, copy) YDUpProgressHandler progressHandler;

// 上传进度
@property (nonatomic, assign) CGFloat percent;

// 上传是否取消
@property (nonatomic, assign, getter=isCancelFlag) BOOL cancelFlag;

// 当前上传信息(便于继续上传)
@property (nonatomic, strong) YDUploadFile *file;


@end

@implementation YDUploadManager

//单例
+ (instancetype)defaultUploader {

    static YDUploadManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc]init];
    });
    return manager;
}

- (void)uploadFile:(NSString *)filePath
               key:(NSString *)key
             token:(NSString *)token
   progressHandler:(YDUpProgressHandler)progressHandler
          complete:(YDUpCompletionHandler)completionHandler {
    
    self.file = [[YDUploadFile alloc]initWithFile:filePath key:key token:token];
    self.completionHandler = completionHandler;
    self.progressHandler = progressHandler;
    [self uploadFile:filePath key:key token:token];
    
}

- (void)uploadFile:(NSString *)filePath key:(NSString *)key token:(NSString *)token {

    // 记录本次上传任务
    self.cancelFlag = NO;
    
    // 上传过程中实时执行此函数
    QNUploadOption *uploadOption = [[QNUploadOption alloc]initWithMime:nil progressHandler:^(NSString *key, float percent) {
        // 上传进度
        self.percent = percent;
        // 上传进度
        self.progressHandler(key, percent);
    } params:nil checkCrc:NO cancellationSignal:^BOOL{
         //上传中途取消函数 如果想取消，返回True, 否则返回No
        return self.cancelFlag;
    }];
    
    [self.upmanager putFile:filePath key:key token:token complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
        
        // 完成回调
        self.completionHandler(info, key, resp);
        if (info.ok) { // 请求成功
            self.file = nil;
        }else{ // 请求失败, 这里可以把info信息上报自己的服务器，便于后面分析上传错误原因
            
        }
    } option:uploadOption];
}

// 取消上传
- (void)cancelUpload {
    self.cancelFlag = YES;
}

// 继续上传
- (void)continueUpload {
    self.cancelFlag = NO;
    [self uploadFile:self.file.filePath key:self.file.key token:self.file.token];
}



#pragma mark - lazy
- (QNUploadManager *)upmanager {
    if (_upmanager == nil) {
        QNConfiguration *config =[QNConfiguration build:^(QNConfigurationBuilder *builder) {
            NSMutableArray *array = [[NSMutableArray alloc] init];
            [array addObject:[QNResolver systemResolver]];
            QNDnsManager *dns = [[QNDnsManager alloc] init:array networkInfo:[QNNetworkInfo normal]];
            //是否选择  https  上传
            builder.zone = [[QNAutoZone alloc] initWithHttps:YES dns:dns];
            //设置断点续传
            NSError *error;
            builder.recorder =  [QNFileRecorder fileRecorderWithFolder:[NSTemporaryDirectory() stringByAppendingString:@"YDUploadFileRecord"] error:&error];
        }];
        
        _upmanager = [[QNUploadManager alloc]initWithConfiguration:config];

    }
    
    return _upmanager;
}

@end
