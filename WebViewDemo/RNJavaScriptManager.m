//
//  RNJavaScriptManager.m
//  SogouYaokan
//
//  Created by Johnny on 2017/3/20.
//  Copyright (c) 2017年 Sogou. All rights reserved.
//

#import "RNJavaScriptManager.h"
#import "WebViewJSExportBridge.h"

NSString *const WebViewCreateJavaScriptContextNotification  = @"WebViewCreateJavaScriptContextNotification";

@protocol NewsJavaScriptExport <JSExport>

@required

JSExportAs(SendMessage /** newsDetailSendMessage 作为js方法的别名 */,
- (void)newsDetailSendMessageWithName:(NSString *)name content:(NSString *)content callBack:(NSString *)callBack
);

@end

@protocol TaskJavaScriptExport <JSExport>

@required

- (void)shareArticleToWxFriend:(NSString *)params;
- (void)shareArticleToWxMoment:(NSString *)params;
- (void)sharePictureToWxFriend:(NSString *)params;
- (void)shareTextToWxFriend:(NSString *)params;
- (void)shareToSms:(NSString *)params;
- (void)bindWx:(NSString *)params;
- (void)readNews;
- (void)openService;
- (void)closeWebPage;
- (NSString *)getUserId;

JSExportAs(shareToMoment,
- (void)shareToMoment:(NSString *)json callback:(NSString *)callback
);
JSExportAs(shareToFriend,
- (void)shareToFriend:(NSString *)json callback:(NSString *)callback
);
JSExportAs(ykShare,
- (void)shareWithPlatform:(NSString *)platform type:(NSString *)type content:(NSString *)content callback:(NSString *)callback
);
- (NSString *)getAppVersion;
- (void)openLoginPage;
- (BOOL)isPushEnabled;
- (void)enablePush;
- (NSString *)getEncryptData:(NSString *)content;
// 1.9.6及以后版本
- (void)showToast:(NSString *)text;

//- (void)testBlock:(void (^)(void))block;
//- (void)testCStr:(const char *)text;
//- (void)testClass:(Class)class;
//- (void)testNumber:(NSNumber *)number;
//- (void)testArray:(NSArray *)array;
//- (void)testDict:(NSDictionary *)dict;
//- (void)testDate:(NSDate *)date;
//- (void)testParam1:(NSString *)param1 param2:(NSString *)param2;

- (NSString *)returnString;
- (NSArray *)returnArray;
- (NSDictionary *)returnDictionary;
- (NSInteger)returnInteger;
- (long double)returnDouble;
- (char *)returnCStr;
- (void (^)(void))returnBlock;

@end

@implementation NSObject (UIWebView)
-(void)webView:(id)webView didCreateJavaScriptContext:(JSContext *)context forFrame:(id)frame {
    [[NSNotificationCenter defaultCenter] postNotificationName:WebViewCreateJavaScriptContextNotification object:context];
}

@end


@interface RNJavaScriptManager () <NewsJavaScriptExport, TaskJavaScriptExport>

@property (nonatomic, strong) JSContext *context;
//@property (nonatomic, strong) RNPushStateManager *manager;

@end

@implementation RNJavaScriptManager

#pragma mark - Public Method
- (void)bindJavaScriptObjectWithName:(NSString *)name webView:(UIWebView *)webView {
    NSString *javaScriptContext = @"documentView.webView.mainFrame.javaScriptContext";
    self.context = [webView valueForKeyPath:javaScriptContext];
    self.context[name] = self;
}

- (void)clearMessage {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.context evaluateScript:@"window.h5.clear_message()"];
    });
}

#pragma mark - Private Method
- (void)finishEnablePush {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.context evaluateScript:@"window.SGS_FE_CBS.finishEnablePush()"];
    });
}

#pragma mark - NewsJavaScriptExport
- (void)newsDetailSendMessageWithName:(NSString *)name content:(NSString *)content callBack:(NSString *)callBack {
    if ([name isEqualToString:@"onClickNewsItem"]) {
        if ([self.newsDelegate respondsToSelector:@selector(onClickNewsItem:)]) {
            NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.newsDelegate onClickNewsItem:dict];
            });
        }
    }
}

#pragma mark - TaskJavaScriptExport
- (void)shareArticleToWxFriend:(NSString *)params {
    if ([self.taskDelegate respondsToSelector:@selector(shareToWeChatWithParams:callback:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.taskDelegate shareToWeChatWithParams:nil callback:nil];
        });
    }
}

- (void)shareArticleToWxMoment:(NSString *)params {
    if ([self.taskDelegate respondsToSelector:@selector(shareToWeChatWithParams:callback:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.taskDelegate shareToWeChatWithParams:nil callback:nil];
        });
    }
}

- (void)sharePictureToWxFriend:(NSString *)params {
    if ([self.taskDelegate respondsToSelector:@selector(sharePictureToWeChat:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.taskDelegate sharePictureToWeChat:nil];
        });
    }
}

- (void)shareTextToWxFriend:(NSString *)params {
    if ([self.taskDelegate respondsToSelector:@selector(shareTextToWeChat:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.taskDelegate shareTextToWeChat:nil];
        });
    }
}

- (void)shareToSms:(NSString *)params {
    if ([self.taskDelegate respondsToSelector:@selector(shareToSms:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.taskDelegate shareToSms:nil];
        });
    }
}

- (void)bindWx:(NSString *)params {
    if ([self.taskDelegate respondsToSelector:@selector(bindWeChat:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.taskDelegate bindWeChat:nil];
        });
    }
}

- (void)readNews {
    if ([self.taskDelegate respondsToSelector:@selector(jumpToHome)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.taskDelegate jumpToHome];
        });
    }
}

- (void)openService {
    if ([self.taskDelegate respondsToSelector:@selector(openService)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.taskDelegate openService];
        });
    }
}

- (void)closeWebPage {
    if ([self.taskDelegate respondsToSelector:@selector(closeWebPage)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.taskDelegate closeWebPage];
        });
    }
}

- (NSString *)getUserId {
    return @"";
}

- (void)shareToMoment:(NSString *)json callback:(NSString *)callback {
    if ([self.taskDelegate respondsToSelector:@selector(shareToWeChatWithParams:callback:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.taskDelegate shareToWeChatWithParams:nil callback:^(BOOL success) {
                // 0代表成功，1代表失败😂
                NSString *javascript = [NSString stringWithFormat:@"%@(%d)", callback, success?0:1];
                [self.context evaluateScript:javascript];
            }];
        });
    }
}

- (void)shareToFriend:(NSString *)json callback:(NSString *)callback {
    [self shareToMoment:json callback:callback];
}

- (void)shareWithPlatform:(NSString *)platform type:(NSString *)type content:(NSString *)content callback:(NSString *)callback {
    
    if (callback.length != 0) {
        WebViewJSExportBridge *bridge = [WebViewJSExportBridge currentBridge];
        NSString *script = [NSString stringWithFormat:@"%@(%d)", callback, 0];
        [bridge evaluateJavaScript:script completionHandler:^(id obj, NSError *error) {
            
        }];
    }
    
    if ([self.taskDelegate respondsToSelector:@selector(shareWithPlatform:type:content:callback:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.taskDelegate shareWithPlatform:platform type:type content:nil callback:^(BOOL success) {
                // 0代表成功，1代表失败😂
                NSString *javascript = [NSString stringWithFormat:@"%@(%d)", callback, success?0:1];
                [self.context evaluateScript:javascript];
            }];
        });
    }
}

- (NSString *)getAppVersion {
    return @"1.9.7";
}

- (void)openLoginPage {
    if ([self.taskDelegate respondsToSelector:@selector(openLoginPage)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.taskDelegate openLoginPage];
        });
    }
}

- (BOOL)isPushEnabled {
    __block BOOL enable = NO;
    if ([NSThread isMainThread]) {
        enable = YES;
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
//            RNPushStateManager *manager = [[RNPushStateManager alloc] init];
//            enable = [manager pushState];
            enable = YES;
        });
    }
    return enable;
}

- (void)enablePush {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.manager = [[RNPushStateManager alloc] init];
//        __weak typeof(self) weakSelf = self;
//        [self.manager setPushState:YES completionBlock:^(BOOL on) {
//            if (on) {
//                [weakSelf finishEnablePush];
//            }
//        }];
//    });
}

- (NSString *)getEncryptData:(NSString *)content {
    return @"";
    //return [RNServiceTask getEncryptData:content];
}

- (void)showToast:(NSString *)text {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [[UIApplication sharedApplication].keyWindow showHUDOnlyTextWithMessage:text];
//    });
}

- (NSString *)returnString {
    return @"testString";
}
- (NSArray *)returnArray {
    return @[@"string", @(3.14), @(10), @(YES)];
}

- (NSDictionary *)returnDictionary {
    return @{@"number":@(123), @"bool":@(YES), @"string":@"text"};
}

- (NSInteger)returnInteger {
    return 2018;
}

- (long double)returnDouble {
    return 3.14;
}

- (char *)returnCStr {
    return "testCString";
}

- (void (^)(void))returnBlock {
    void (^block)(void) = ^{
        
    };
    return block;
}

@end
