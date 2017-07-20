//
//  YDUploadManager.h
//  XingNLive
//
//  Created by xuning on 2017/7/20.
//  Copyright © 2017年 XingNLive&Mall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QiniuSDK.h>

/**
 *    上传完成后的回调函数
 *
 *    @param info 上下文信息，包括状态码，错误值
 *    @param key  上传时指定的key，原样返回
 *    @param resp 上传成功会返回文件信息，失败为nil; 可以通过此值是否为nil 判断上传结果
 */
typedef void (^YDUpCompletionHandler)(QNResponseInfo *info, NSString *key, NSDictionary *resp);

/**
 *    上传进度回调函数
 *
 *    @param key     上传时指定的存储key
 *    @param percent 进度百分比
 */
typedef void (^YDUpProgressHandler)(NSString *key, float percent);

// 文件管理
@interface YDUploadFile : NSObject

@property (nonatomic, strong) NSString* filePath;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *token;

- (instancetype)initWithFile:(NSString *)filePath key:(NSString *)key token:(NSString *)token;

@end



@interface YDUploadManager : NSObject


//单例
+ (instancetype)defaultUploader;


/**
 *    上传文件
 *
 *    @param filePath          文件路径
 *    @param key               上传到云存储的key，为nil时表示是由七牛生成
 *    @param token             上传需要的token, 由服务器生成
 *    @param completionHandler 上传完成后的回调函数
 *    @param progressHandler   上传进度回调函数
 */
- (void)uploadFile:(NSString *)filePath
               key:(NSString *)key
             token:(NSString *)token
   progressHandler:(YDUpProgressHandler)progressHandler
          complete:(YDUpCompletionHandler)completionHandler;

//取消上传某个文件;
- (void)cancelUpload;

//继续上传某个文件，根据filePath 判断
- (void)continueUpload;

@end
