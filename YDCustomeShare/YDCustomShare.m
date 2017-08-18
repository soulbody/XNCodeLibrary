//
//  YDCustomShare.m
//  XingNLive
//
//  Created by xuning on 2017/8/17.
//  Copyright © 2017年 XingNLive&Mall. All rights reserved.
//

#import "YDCustomShare.h"
#import <UIKit/UIKit.h>
//腾讯开放平台（对应QQ和QQ空间）SDK头文件
#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/QQApiInterface.h>
//新浪微博SDK头文件
#import "WeiboSDK.h"
#import <ShareSDKConnector/ShareSDKConnector.h>
#import "ImageCenterButton.h"
#import <ShareSDKExtension/SSEThirdPartyLoginHelper.h>

@interface YDCustomShare ()

@property (nonatomic, copy) void(^successBlock)();

@property (nonatomic, strong) UIView *bgView;

@property (nonatomic, strong) UIView *shareView;

@property (nonatomic, strong) NSMutableDictionary *shareParams;

@end

@implementation YDCustomShare


+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static YDCustomShare *instance;
    dispatch_once(&onceToken, ^{
        instance = [[YDCustomShare alloc] init];
    });
    return instance;
}

- (void)registerShareSDK {
    /**
     *  设置ShareSDK的appKey，如果尚未在ShareSDK官网注册过App，请移步到http://mob.com/login 登录后台进行应用注册，
     *  在将生成的AppKey传入到此方法中。
     *  方法中的第二个第三个参数为需要连接社交平台SDK时触发，
     *  在此事件中写入连接代码。第四个参数则为配置本地社交平台时触发，根据返回的平台类型来配置平台信息。
     *  如果您使用的时服务端托管平台信息时，第二、四项参数可以传入nil，第三项参数则根据服务端托管平台来决定要连接的社交SDK。
     */
    //   原始数据 18b47263487ae
    [ShareSDK registerActivePlatforms:@[
                            @(SSDKPlatformTypeSinaWeibo),
                            @(SSDKPlatformSubTypeWechatSession),
                            @(SSDKPlatformSubTypeWechatTimeline),
                            @(SSDKPlatformTypeQQ),
                            @(SSDKPlatformSubTypeQQFriend),
                            @(SSDKPlatformSubTypeQZone)
                            ]
                 onImport:^(SSDKPlatformType platformType)
     {
         switch (platformType)
         {
             case SSDKPlatformTypeWechat:
                 [ShareSDKConnector connectWeChat:[WXApi class]];
                 break;
             case SSDKPlatformTypeQQ:
                 [ShareSDKConnector connectQQ:[QQApiInterface class] tencentOAuthClass:[TencentOAuth class]];
                 break;
             case SSDKPlatformTypeSinaWeibo:
                 [ShareSDKConnector connectWeibo:[WeiboSDK class]];
                 break;
             default:
                 break;
         }
     }
          onConfiguration:^(SSDKPlatformType platformType, NSMutableDictionary *appInfo)
     {
         
         switch (platformType)
         {
             case SSDKPlatformTypeSinaWeibo:
                 //设置新浪微博应用信息,其中authType设置为使用SSO＋Web形式授权
                 [appInfo SSDKSetupSinaWeiboByAppKey:@"****"
                                           appSecret:@"****"
                                         redirectUri:@"http://www.xingnl.com"
                                            authType:SSDKAuthTypeBoth];
                 break;
             case SSDKPlatformTypeWechat:
                 [appInfo SSDKSetupWeChatByAppId:@"***"
                                       appSecret:@"***"];
                 break;
             case SSDKPlatformTypeQQ:
                 [appInfo SSDKSetupQQByAppId:@"***"
                                      appKey:@"***"
                                    authType:SSDKAuthTypeBoth];
                 break;
                 
                 
             default:
                 break;
         }
     }];

    
}


// 有UI
- (void)shareParamsByText:(NSString *)text
                   images:(NSArray *)images
                      url:(NSURL *)url
                    title:(NSString *)title
             successBlock:(void(^)())successBlock {
    
    self.shareParams = [NSMutableDictionary dictionary];
    [self.shareParams SSDKSetupShareParamsByText:text
                                     images:images //传入要分享的图片
                                        url:url
                                      title:title
                                       type:SSDKContentTypeAuto];

    
    self.successBlock = successBlock;

    [self creatShareViewWithAction:@selector(shareButtonClick:)];

}

// 无UI
- (void)shareNoUIByText:(NSString *)text
                 images:(NSArray *)images
                    url:(NSURL *)url
                  title:(NSString *)title
           platformType:(SSDKPlatformType)shareType
           successBlock:(void (^)())successBlock {
    
    self.shareParams = [NSMutableDictionary dictionary];
    [self.shareParams SSDKSetupShareParamsByText:text
                                          images:images //传入要分享的图片
                                             url:url
                                           title:title
                                            type:SSDKContentTypeAuto];
    
    
    self.successBlock = successBlock;
    
    [ShareSDK share:shareType parameters:self.shareParams onStateChanged:^(SSDKResponseState state, NSDictionary *userData, SSDKContentEntity *contentEntity, NSError *error) {
        switch (state) {
            case SSDKResponseStateSuccess:
                if (self.successBlock) {
                    self.successBlock();
                }
                break;
                
            default:
                break;
        }
    }];

}

- (void)shareButtonClick:(UIButton *)shareButton {
    
    SSDKPlatformType shareType = shareButton.tag;
    if (shareButton.selected) {
        return;
    }
    shareButton.selected = YES;
    [ShareSDK share:shareType parameters:self.shareParams onStateChanged:^(SSDKResponseState state, NSDictionary *userData, SSDKContentEntity *contentEntity, NSError *error) {
        shareButton.selected = NO;
        [self dismiss];
        switch (state) {
            case SSDKResponseStateSuccess:
                if (self.successBlock) {
                    self.successBlock();
                }
                break;
                
            default:
                break;
        }
    }];
    
}


- (void)loginByPlatform:(SSDKPlatformType)platform
     loginResultHandler:(void(^)(id result, NSError *error))loginResultHandler {

    [SSEThirdPartyLoginHelper loginByPlatform:platform onUserSync:^(SSDKUser *user, SSEUserAssociateHandler associateHandler) {
        
    } onLoginResult:^(SSDKResponseState state, SSEBaseUser *user, NSError *error) {
        
    }];
}


- (void)creatShareViewWithAction:(SEL)action {

    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    _bgView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
    _bgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    [window addSubview:_bgView];
    /**
     点击退出手势
     */
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
    [_bgView addGestureRecognizer:tap];
    
    _shareView = [[UIView alloc]initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, 93)];
    _shareView.backgroundColor = [UIColor whiteColor];
    [_bgView addSubview:_shareView];
    [UIView animateWithDuration:0.3 animations:^{
        _shareView.frame = CGRectMake(0, kScreenHeight-93, kScreenWidth, 93);
    }];
    
    NSMutableArray *sharePlatforms = [NSMutableArray arrayWithCapacity:5];
    NSArray *wxAPP = @[@{@"imageName":@"zhibo-fenxiang-weixin", @"title":@"微信", @"buttonTag":@(SSDKPlatformSubTypeWechatSession)},
                       @{@"imageName":@"zhibo-fenxiang-pyq", @"title":@"朋友圈", @"buttonTag":@(SSDKPlatformSubTypeWechatTimeline)}];
    
    NSArray *qqAPP = @[@{@"imageName":@"zhibo-fenxiang-qq", @"title":@"QQ", @"buttonTag":@(SSDKPlatformSubTypeQQFriend)},
                       @{@"imageName":@"zhibo-fenxiang-qqkj", @"title":@"QQ空间", @"buttonTag":@(SSDKPlatformSubTypeQZone)}];
    
    if ([WXApi isWXAppInstalled]) { // 安装了微信
        [sharePlatforms addObjectsFromArray:wxAPP];
    }
    if ([QQApiInterface isQQInstalled]) { // 安装了QQ
        [sharePlatforms addObjectsFromArray:qqAPP];
    }
    
    NSArray *weiboAPP = @[@{@"imageName":@"zhibo-fenxiang-weibo",@"title":@"微博", @"buttonTag":@(SSDKPlatformTypeSinaWeibo)}];
    [sharePlatforms addObjectsFromArray:weiboAPP];
    
    CGFloat btnW = kScreenWidth / 5;
    CGFloat btnH = 93;
    CGFloat btnX = 0;
    for (NSInteger i=0; i<sharePlatforms.count; i++) {
        NSDictionary *shareDict = sharePlatforms[i];
        btnX = i * btnW;
        
        ImageCenterButton *shareButton = [[ImageCenterButton alloc]initWithFrame:CGRectMake(btnX, 0, btnW, btnH)];
        shareButton.selected = NO;
        [shareButton setImage:[UIImage imageNamed:shareDict[@"imageName"]] forState:UIControlStateNormal];
        [shareButton setTitle:shareDict[@"title"] forState:UIControlStateNormal];
        [shareButton setTitleColor:kTitleColor forState:UIControlStateNormal];
        shareButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        shareButton.imageTextSpace = 15;
        shareButton.imageViewMaxSize = CGSizeMake(30, 30);
        [_shareView addSubview:shareButton];
        shareButton.tag = [shareDict[@"buttonTag"] integerValue];
        [shareButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    }
    

}


- (void)dismiss {
    
    [UIView animateWithDuration:0.3 animations:^{
        _shareView.frame = CGRectMake(0, kScreenHeight, kScreenWidth, 200);
    } completion:^(BOOL finished) {
        [_shareView removeFromSuperview];
        [_bgView removeFromSuperview];
    }];

}

@end
