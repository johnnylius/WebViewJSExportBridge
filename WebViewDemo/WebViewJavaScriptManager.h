//
//  WebViewJavaScriptManager.h
//  WebViewDemo
//
//  Created by liuhuan on 2018/12/20.
//  Copyright (c) 2018年 Sogou. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WebViewJavaScriptDelegate <NSObject>

@optional
- (void)testDelegateMethod;

@end

@interface WebViewJavaScriptManager : NSObject

@property (nonatomic, weak) id<WebViewJavaScriptDelegate> delegate;

@end
