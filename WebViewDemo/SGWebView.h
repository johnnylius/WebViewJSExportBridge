//
//  SGWebView.h
//  SGWebView
//
//  Created by liuhuan on 2018/12/6.
//  Copyright © 2018年 Sogou. All rights reserved.
//

#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface SGWebView : WKWebView

- (void)bindJSExportObject:(NSObject *)object name:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
