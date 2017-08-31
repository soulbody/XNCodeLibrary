//
//  YDUserDefaultsManager.h
//  XingNLive
//
//  Created by xuning on 2017/8/31.
//  Copyright © 2017年 XingNLive&Mall. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YDUserDefaultsManager : NSObject


//保存float值
+ (void)setFloat:(float)f forKey:(NSString *)key;

//读取float值
+ (float)floatForKey:(NSString *)key;

//保存BOOL值
+ (void)setBool:(BOOL)b forKey:(NSString *)key;

//读取BOOL值
+ (BOOL)boolForKey:(NSString *)key;

//保存字符串
+ (void)setValue:(id)value forKey:(NSString *)key;

//读取字符串
+ (id)valueForKey:(NSString *)key;


@end
