//
//  UIWebViewJSExportBridge.h
//  WebViewJSExportBridge
//
//  Created by liuhuan on 2018/12/6.
//  Copyright © 2018年 Sogou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIWebViewJSExportBridge : NSObject

+ (instancetype)bridgeWithWebView:(UIWebView *)webView;
- (void)bindJSExportObject:(NSString *)name object:(id<JSExport>)object;
- (void)removeJSExportObject:(NSString *)name;
- (void)removeAllJSExportObject;

+ (instancetype)currentBridge;
- (void)evaluateJavaScript:(NSString *)script completionHandler:(void (^ _Nullable)(_Nullable id result, NSError * _Nullable error))completionHandler;

- (void)startBindJSExportObject;

@end

NS_ASSUME_NONNULL_END
