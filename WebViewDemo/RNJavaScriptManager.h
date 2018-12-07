//
//  RNJavaScriptManager.h
//  SogouYaokan
//
//  Created by Johnny on 2017/3/20.
//  Copyright (c) 2017年 Sogou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

extern NSString *const WebViewCreateJavaScriptContextNotification;

@protocol NewsJavaScriptProtocol <NSObject>

@optional
- (void)onClickNewsItem:(NSDictionary *)dict;

@end

@protocol TaskJavaScriptProtocol <NSObject>

@optional
- (void)shareWithPlatform:(NSString *)platform type:(NSString *)type content:(NSDictionary *)content callback:(void(^)(BOOL))callback;
- (void)shareToWeChatWithParams:(NSDictionary *)params callback:(void(^)(BOOL))callback;
- (void)sharePictureToWeChat:(NSDictionary *)params;
- (void)shareTextToWeChat:(NSDictionary *)params;
- (void)shareToSms:(NSDictionary *)params;
- (void)bindWeChat:(NSDictionary *)params;
- (void)jumpToHome;
- (void)openService;
- (void)closeWebPage;
- (void)openLoginPage;

@end

@interface RNJavaScriptManager : NSObject

@property (nonatomic, weak) id<NewsJavaScriptProtocol> newsDelegate;
@property (nonatomic, weak) id<TaskJavaScriptProtocol> taskDelegate;

// 绑定js对象
- (void)bindJavaScriptObjectWithName:(NSString *)name webView:(WKWebView *)webView;

- (void)clearMessage;

@end
