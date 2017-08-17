//
//  XNPayManager.h
//  XingNLive
//
//  Created by xuning on 2017/3/25.
//  Copyright © 2017年 XingNLive&Mall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WXApi.h"
#import <StoreKit/StoreKit.h>


FOUNDATION_EXPORT NSString *const KTransactionReceipt;
FOUNDATION_EXPORT NSString *const KOrderId;

/**
 支付状态码
 */
typedef NS_ENUM(NSInteger, PayCode) {
    WXSUCESS            = 1001,   /**成功*/
    WXERROR             = 1002,   /**失败*/
    WXSCANCEL           = 1003,   /**取消*/
    
    ALIPAYSUCESS        = 1101,   /**支付宝支付成功*/
    ALIPAYERROR         = 1102,   /**支付宝支付错误*/
    ALIPAYCANCEL        = 1103,   /**支付宝支付取消*/
    
    APPSTOREPAYSUCESS   = 1201,   /**内购支付成功*/
    APPSTOREPAYERROR    = 1202,   /**内购支付出错*/
    APPSTOREPAYCANCEL   = 1203,   /**内购支付取消*/
};


@interface XNPayManager : NSObject<SKPaymentTransactionObserver,SKProductsRequestDelegate>


/**
 支付管理类
 */
+ (instancetype)sharedPayManager;

- (void)addTransactionObserver;

- (void)removeTransactionObserver;

/**
 微信支付

 @param dict 微信订单字典(全部由后台拼接好给iOS端)
 @param successBlock 成功的回调
 @param failBolck 失败的回调
 */
- (void)WXPayWithPayDict:(NSDictionary *)dict
                 success:(void(^)(PayCode code)) successBlock
                 failure:(void(^)(PayCode code)) failBolck;


/**
 支付宝支付

 @param params 支付宝支付参数(全部由后台拼接好给iOS端)
 @param successBlock 成功的回调
 @param failBolck 失败的回调
 */
- (void)ALIPayWithPayParams:(NSString *)params
                    success:(void(^)(PayCode code)) successBlock
                    failure:(void(^)(PayCode code)) failBolck;


/**
 内购
 
 @param productId productId
 @param successBlock 成功的回调
 @param failBolck 失败的回调
 */
- (void)requestProductData:(NSString *)productId
                   orderId:(NSString *)orderId
                   success:(void(^)(PayCode code)) successBlock
                   failure:(void(^)(PayCode code)) failBolck;


/**
 单例类回调处理

 @param url url
 */
- (BOOL)handleOpenURL:(NSURL *)url;

@end
