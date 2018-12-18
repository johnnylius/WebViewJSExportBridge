//
//  WebViewJSExportBridgeProxy.h
//  WebViewJSExportBridge
//
//  Created by liuhuan on 2018/12/6.
//  Copyright © 2018年 Sogou. All rights reserved.
//

#import "WebViewJSExportBridge.h"

@interface WebViewJSExportBridgeProxy : NSObject <WKUIDelegate>

+ (instancetype)proxyWithTarget:(WebViewJSExportBridge *)target;
+ (instancetype)proxyWithTarget:(WebViewJSExportBridge *)target UIDelegate:(id<WKUIDelegate>)UIDelegate;

@property (nonatomic, weak, readonly) id target;
@property (nonatomic, weak, readonly) id<WKUIDelegate> UIDelegate;

@end
