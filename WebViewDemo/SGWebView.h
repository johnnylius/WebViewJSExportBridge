//
//  SGWebView.h
//  SGWebView
//
//  Created by Johnny on 2018/12/6.
//  Copyright © 2018年 Sogou. All rights reserved.
//

#import <WebKit/WebKit.h>

@protocol SG_JSExport <NSObject>

@end

NS_ASSUME_NONNULL_BEGIN

@interface SGWebView : WKWebView

- (void)createWithObject:(NSObject *)object;

@end

NS_ASSUME_NONNULL_END
