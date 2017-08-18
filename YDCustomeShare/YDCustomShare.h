//
//  YDCustomShare.h
//  XingNLive
//
//  Created by xuning on 2017/8/17.
//  Copyright © 2017年 XingNLive&Mall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ShareSDK/ShareSDK.h>

typedef NS_ENUM(NSUInteger, YDShareType) {
    
    YDShareTypeQZone = SSDKPlatformSubTypeQZone, // QQ空间
    YDShareTypeWechatSession = SSDKPlatformSubTypeWechatSession, // 微信好友
    YDShareTypeSinaWeibo = SSDKPlatformTypeSinaWeibo, // 新浪微博
    YDShareTypeWechatTimeline = SSDKPlatformSubTypeWechatTimeline, //朋友圈
    YDShareTypeQQFirend = SSDKPlatformSubTypeQQFriend //QQ好友
};
@interface YDCustomShare : NSObject

- (void)registerShareSDK;

+ (instancetype)shareInstance;

/**
 设置分享参数(有UI)

 @param text 文本
 @param images 图片集合,传入参数可以为单张图片信息，也可以为一个NSArray，数组元素可以为UIImage、NSString（图片路径）、NSURL（图片路径）、SSDKImage。如: @"http://www.mob.com/images/logo_black.png" 或 @[@"http://www.mob.com/images/logo_black.png"]
 @param url 网页路径/应用路径
 @param title 标题
 @param successBlock 成功的回调
 */
- (void)shareParamsByText:(NSString *)text
                   images:(NSArray *)images
                      url:(NSURL *)url
                    title:(NSString *)title
             successBlock:(void(^)())successBlock;


// 无UI
- (void)shareNoUIByText:(NSString *)text
                 images:(NSArray *)images
                    url:(NSURL *)url
                  title:(NSString *)title
           platformType:(SSDKPlatformType)shareType
           successBlock:(void(^)())successBlock;


/**
 用户登录

 @param platform 平台类型
 @param loginResultHandler 登录返回事件处理
 */
- (void)loginByPlatform:(SSDKPlatformType)platform
     loginResultHandler:(void(^)(id result, NSError *error))loginResultHandler;

@end
