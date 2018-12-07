//
//  WebViewDelegateManager.m
//  WebViewDemo
//
//  Created by liuhuan on 17/2/3.
//  Copyright © 2017年 Sogou. All rights reserved.
//

#import "WebViewDelegateManager.h"

@class JSContext;

@implementation WebViewDelegateManager
SINGLETON_IMPLEMENT(WebViewDelegateManager)

-(void)webView:(id)webView didCreateJavaScriptContext:(JSContext *)context forFrame:(id)frame{
    if (self.webDelegate && [self.webDelegate respondsToSelector:@selector(webView:didCreateJavaScriptContext:forFrame:)]) {
        [self.webDelegate webView:webView didCreateJavaScriptContext:context forFrame:frame];
    }
}
@end
