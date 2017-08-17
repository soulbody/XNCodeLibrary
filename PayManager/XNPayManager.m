//
//  XNPayManager.m
//  XingNLive
//
//  Created by xuning on 2017/3/25.
//  Copyright © 2017年 XingNLive&Mall. All rights reserved.
//

#import "XNPayManager.h"
#import "MBProgressHUD.h"

#define kKeyWindow [UIApplication sharedApplication].keyWindow

NSString *const KTransactionReceipt = @"KTransactionReceipt";
NSString *const KOrderId = @"KOrderId";

//字典是否为空
#define kDictIsEmpty(dic) (dic == nil || [dic isKindOfClass:[NSNull class]] || dic.allKeys == 0)

@interface XNPayManager ()<WXApiDelegate,SKPaymentTransactionObserver,SKProductsRequestDelegate>


/**
 成功的回调
 */
@property (nonatomic, copy) void(^successBlock)(PayCode code);


/**
 失败的回调
 */
@property (nonatomic, copy) void(^failBolck)(PayCode code);


/**
 内购产品唯一id
 */
@property (nonatomic, copy) NSString *productId;

/**
 服务器订单号
 */
@property (nonatomic, copy) NSString *orderId;

@property (nonatomic, strong) MBProgressHUD *hud;

@end

@implementation XNPayManager


/**
 支付管理类
 */
+ (instancetype)sharedPayManager {
    static dispatch_once_t onceToken;
    static XNPayManager *instance;
    dispatch_once(&onceToken, ^{
        instance = [[XNPayManager alloc] init];
    });
    return instance;
}

- (void)addTransactionObserver {
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:[XNPayManager sharedPayManager]];
}


- (void)removeTransactionObserver {
    
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:[XNPayManager sharedPayManager]];

}
#pragma mark -----------------------------------微信-----------------------------------

/**
 微信支付
 
 @param dict 微信订单字典(全部由后台拼接好给iOS端)
 @param successBlock 成功的回调
 @param failBolck 失败的回调
 */
- (void)WXPayWithPayDict:(NSDictionary *)dict
                 success:(void(^)(PayCode code)) successBlock
                 failure:(void(^)(PayCode code)) failBolck {
    self.successBlock = successBlock;
    self.failBolck = failBolck;
    NSString *strMsg = nil;
    //1. 判断是否安装微信
    if (![WXApi isWXAppInstalled]) {
        NSLog(@"您尚未安装\"微信App\",请先安装后再返回支付");
        strMsg = @"您尚未安装\"微信App\",请先安装后再返回支付";
        [self tipMessageAlert:nil message:strMsg];
        return;
    }
    
    //2.判断微信的版本是否支持最新Api
    if (![WXApi isWXAppInstalled]) {
        NSLog(@"您微信当前版本不支持此功能,请先升级微信应用");
        strMsg = @"您微信当前版本不支持此功能,请先升级微信应用";
        [self tipMessageAlert:nil message:strMsg];
        return;
    }
    
    if (!kDictIsEmpty(dict)) {
        
        //调起微信支付
        PayReq *req = [[PayReq alloc]init];
        req.openID = dict[@"appid"];
        req.partnerId = dict[@"partnerid"];
        req.prepayId = dict[@"prepayid"];
        req.nonceStr = dict[@"noncestr"];
        req.timeStamp = [dict[@"timestamp"] intValue];
        req.package = @"Sign=WXPay";
        req.sign = dict[@"sign"];
        [WXApi sendReq:req];
    }

}

#pragma mark - WXApiDelegate
//支付结果回调
/// - see [支付结果回调](https://pay.weixin.qq.com/wiki/doc/api/app/app.php?chapter=8_5)
- (void)onResp:(BaseResp *)resp {
    
    NSString *strMsg = [NSString stringWithFormat:@"errcode:%d",resp.errCode];
    
    //回调中errCode值列表：
    // 0 成功 展示成功页面
    //-1 错误 可能的原因：签名错误、未注册APPID、项目设置APPID不正确、注册的APPID与设置的不匹配、其他异常等
    //-2 用户取消 无需处理。发生场景：用户不支付了，点击取消，返回APP
    
    if ([resp isKindOfClass:[PayResp class]]) {
        // 支付返回结果,实际支付结果需要去微信服务器端查询
        switch (resp.errCode) {
            case WXSuccess:{
                strMsg = @"支付结果：成功！";
                if (self.successBlock) {
                    self.successBlock(WXSUCESS);
                }
                DLog(@"支付成功－PaySuccess，retcode = %d", resp.errCode);
                break;
            }
            case WXErrCodeUserCancel:{
                strMsg = @"支付结果：取消";
                if (self.failBolck) {
                    self.failBolck(WXSCANCEL);
                }
                DLog(@"支付取消－PayCancel，retcode = %d", resp.errCode);
            }
            default:{
                strMsg = @"支付结果：失败";
                if (self.failBolck) {
                    self.failBolck(WXERROR);
                }
                DLog(@"错误，retcode = %d, retstr = %@", resp.errCode,resp.errStr);
                break;
            }
        }
        [self tipMessageAlert:@"支付结果" message:strMsg];
    }
    
}

#pragma mark -----------------------------------支付宝-----------------------------------

/**
 支付宝支付
 
 @param params 支付宝支付参数(全部由后台拼接好给iOS端)
 @param successBlock 成功的回调
 @param failBolck 失败的回调
 */
- (void)ALIPayWithPayParams:(NSString *)params
                    success:(void(^)(PayCode code)) successBlock
                    failure:(void(^)(PayCode code)) failBolck {
    
    self.successBlock = successBlock;
    self.failBolck = failBolck;
    NSString *appScheme = @"appScheme";
    [[AlipaySDK defaultService] payOrder:params fromScheme:appScheme callback:^(NSDictionary *resultDic) {
        DLog(@"我这里是payVC%@",resultDic);
        DLog(@"%@",resultDic[@"memo"]);
        [self aliPayResult:resultDic];
    }];


}

#pragma mark - 支付宝支付结果处理

- (void)aliPayResult:(NSDictionary *)resultDic {
    
    // 返回结果需要通过 resultStatus 以及 result 字段的值来综合判断并确定支付结果。 在 resultStatus=9000,并且 success="true"以及 sign="xxx"校验通过的情况下,证明支付成功。其它情况归为失败。较低安全级别的场合,也可以只通过检查 resultStatus 以及 success="true"来判定支付结果
    NSInteger resultStatus = [resultDic[@"resultStatus"] integerValue];
    
    if (resultDic && [resultDic objectForKey:@"resultStatus"]) {
        switch (resultStatus) {
            case 9000:
                [self tipMessageAlert:@"支付结果" message:@"订单支付成功"];
                if (self.successBlock) {
                    self.successBlock(ALIPAYSUCESS);
                }
                break;
            case 8000:
                [self tipMessageAlert:@"支付结果" message:@"正在处理中"];
                if (self.failBolck) {
                    self.failBolck(ALIPAYERROR);
                }
                break;
            case 4000:
                [self tipMessageAlert:@"支付结果" message:@"订单支付失败,请稍后再试"];
                if (self.failBolck) {
                    self.failBolck(ALIPAYERROR);
                }
                break;
            case 6001:
                [self tipMessageAlert:@"支付结果" message:@"已取消支付"];
                if (self.failBolck) {
                    self.failBolck(ALIPAYCANCEL);
                }
                break;
            case 6002:
                [self tipMessageAlert:@"支付结果" message:@"网络连接错误,请稍后再试"];
                if (self.failBolck) {
                    self.failBolck(ALIPAYERROR);
                }
                break;
            default:
                break;
        }
    }
    
}


#pragma mark -----------------------------------内购-----------------------------------

/**
 内购
 
 @param productId productId
 @param successBlock 成功的回调
 @param failBolck 失败的回调
 */
- (void)requestProductData:(NSString *)productId
                   orderId:(NSString *)orderId
                   success:(void(^)(PayCode code)) successBlock
                   failure:(void(^)(PayCode code)) failBolck {

    if ([SKPaymentQueue canMakePayments]) {
        self.successBlock = successBlock;
        self.failBolck = failBolck;
        // 最好设置上
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:kKeyWindow animated:YES];
        hud.labelText = @"正在购买,请不要离开...";
        hud.dimBackground = YES;
        self.productId = productId;
        self.orderId = orderId;
        self.hud = hud;
    
        NSArray *productArr = [[NSArray alloc]initWithObjects:productId, nil];
        
        NSSet *productSet = [NSSet setWithArray:productArr];
        
        SKProductsRequest *request = [[SKProductsRequest alloc]initWithProductIdentifiers:productSet];
        
        request.delegate = self;
        
        [request start];
        
    }else{
        DLog(@"不允许程序内付费");
    }

}


#pragma mark - SKProductsRequestDelegate
// 收到产品返回信息
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    
    NSArray *productArr = response.products;
    
    if ([productArr count] == 0) {
        DLog(@"没有该商品");
        [MBProgressHUD hideAllHUDsForView:kKeyWindow animated:YES];
        return;
    }
    
    DLog(@"productId = %@",response.invalidProductIdentifiers);
    DLog(@"产品付费数量 = %zd",productArr.count);
    
    SKProduct *p = nil;
    
    for (SKProduct *pro in productArr) {
        DLog(@"description:%@",[pro description]);
        DLog(@"localizedTitle:%@",[pro localizedTitle]);
        DLog(@"localizedDescription:%@",[pro localizedDescription]);
        DLog(@"price:%@",[pro price]);
        DLog(@"productIdentifier:%@",[pro productIdentifier]);
        if ([pro.productIdentifier isEqualToString:self.productId]) {
            p = pro;
        }
    }
    
    SKPayment *payment = [SKPayment paymentWithProduct:p];
    
    //发送内购请求
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
}

#pragma mark - SKRequestDelegate

- (void)requestDidFinish:(SKRequest *)request {
    
    DLog(@"获取产品成功");
//    [MBProgressHUD hideHUDForView:kKeyWindow animated:YES];
    
    
}
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    
    [MBProgressHUD hideHUDForView:kKeyWindow animated:YES];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:kKeyWindow animated:YES];
    hud.labelText = @"购买失败";
    hud.mode = MBProgressHUDModeText;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:kKeyWindow animated:YES];
    });
    
}



// 监听购买结果
//SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    
    
    for (SKPaymentTransaction *tran in transactions) {
        switch (tran.transactionState) {
            case SKPaymentTransactionStatePurchased: //交易完成
                [self completeTransaction:tran];
                // Remove the transaction from the payment queue.
                [[SKPaymentQueue defaultQueue] finishTransaction: tran];
                break;
            case SKPaymentTransactionStatePurchasing: //商品添加进列表
                break;
            case SKPaymentTransactionStateRestored: //购买过
                [self restoreTransaction:tran];
                break;
            case SKPaymentTransactionStateFailed: //交易失败
                [self failedTransaction:tran];
                // Remove the transaction from the payment queue.
                [[SKPaymentQueue defaultQueue] finishTransaction: tran];
                break;
                
            default:
                break;
        }
    }
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    NSString * productIdentifier = transaction.payment.productIdentifier;
    DLog(@"productIdentifier Product id：%@", productIdentifier);
    NSString *transactionReceiptString= nil;
    
    //系统IOS7.0以上获取支付验证凭证的方式应该改变，切验证返回的数据结构也不一样了。
    
    // 验证凭据，获取到苹果返回的交易凭据
    // appStoreReceiptURL iOS7.0增加的，购买交易完成后，会将凭据存放在该地址
    NSURL *receiptUrl=[[NSBundle mainBundle] appStoreReceiptURL];
    NSData * receiptData = [NSData dataWithContentsOfURL:receiptUrl];
    
    transactionReceiptString = [receiptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    
    DLog(@"transactionReceiptString == %@",transactionReceiptString);
    
    if ([productIdentifier length] > 0) {

        self.hud.labelText = @"正在验证,请勿离开...";
        // 保存购买凭证
        // 请求自己的服务器去验证用户购买结果        
        [[XNLTool shareAPIConfig] xnliveAdCoinWithAppleReceipt:transactionReceiptString buyId:self.orderId finished:^(id result, NSError *error) {
            // 往后台验证
            [MBProgressHUD hideAllHUDsForView:kKeyWindow animated:YES];
            if ([result[@"code"] integerValue] == 200) {
                // 验证成功
                if (self.successBlock) {
                    self.successBlock(APPSTOREPAYSUCESS);
                }
            }
        }];
    }


}
- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    if(transaction.error.code != SKErrorPaymentCancelled) {
        DLog(@"购买失败");
        if (self.failBolck) {
            self.failBolck(APPSTOREPAYCANCEL);
        }
        
    } else {
        DLog(@"用户取消交易");
        if (self.failBolck) {
            self.failBolck(APPSTOREPAYCANCEL);
        }

    }
    [MBProgressHUD hideHUDForView:kKeyWindow animated:YES];
    [SMGlobalMethod showViewCenter:kKeyWindow.center longMessage:@"购买失败"];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    // 对于已购商品，处理恢复购买的逻辑
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

#pragma mark - 单例类回调
- (BOOL)handleOpenURL:(NSURL *)url {
    
    if ([url.host isEqualToString:@"safepay"])
    {
        //跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            DLog(@"result = %@",resultDic);
            DLog(@"openURL : 支付宝回调 ： result = %@",resultDic);
            [self aliPayResult:resultDic];
        }];
        // 授权跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processAuth_V2Result:url standbyCallback:^(NSDictionary *resultDic) {
            NSLog(@"result = %@",resultDic);
            // 解析 auth code
            NSString *result = resultDic[@"result"];
            NSString *authCode = nil;
            if (result.length>0) {
                NSArray *resultArr = [result componentsSeparatedByString:@"&"];
                for (NSString *subResult in resultArr) {
                    if (subResult.length > 10 && [subResult hasPrefix:@"auth_code="]) {
                        authCode = [subResult substringFromIndex:10];
                        break;
                    }
                }
            }
            DLog(@"授权结果 authCode = %@", authCode?:@"");
        }];
        
        return [url.host isEqualToString:@"safepay"];
    }
    else
    {
        return [WXApi handleOpenURL:url delegate:self];
    }
    
}

#pragma mark - 提示

/**
 提示

 @param title 标题
 @param message 信息
 */
- (void)tipMessageAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }];
    [alertController addAction:cancelAction];
    [kKeyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
}


@end
