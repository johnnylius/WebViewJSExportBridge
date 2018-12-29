//
//  WKWebView+JSExport.h
//  WebViewJSExportBridge
//
//  Created by liuhuan on 2018/12/17.
//  Copyright © 2018年 Sogou. All rights reserved.
//

#import <WebKit/WebKit.h>

@interface WKWebView (JSExport)

@property (nonatomic, weak) id WebViewJSExportBridge;

@end
