//
//  WebViewJSExportBridge.h
//  WebViewJSExportBridge
//
//  Created by liuhuan on 2018/12/6.
//  Copyright © 2018年 Sogou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

typedef id WebViewType;

NS_ASSUME_NONNULL_BEGIN

@interface WebViewJSExportBridge : NSObject

+ (instancetype)bridgeWithWebView:(WebViewType)webView;
- (void)bindJSExportObject:(NSString *)name object:(NSObject<JSExport> *)object;
- (void)removeJSExportObject:(NSString *)name;
- (void)removeAllJSExportObject;

+ (instancetype)currentBridge;
- (void)evaluateJavaScript:(NSString *)script completionHandler:(void (^ _Nullable)(_Nullable id result, NSError * _Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
