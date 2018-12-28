//
//  WebViewJSExportBridgeProxy.h
//  WebViewJSExportBridge
//
//  Created by liuhuan on 2018/12/6.
//  Copyright © 2018年 Sogou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface WebViewJSExportBridgeProxy : NSObject <WKUIDelegate>

+ (instancetype)proxyWithTarget:(id)target;
+ (instancetype)proxyWithTarget:(id)target UIDelegate:(id<WKUIDelegate>)UIDelegate;

@property (nonatomic, weak, readonly) id target;
@property (nonatomic, weak, readonly) id<WKUIDelegate> UIDelegate;

@end
