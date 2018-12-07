//
//  WebViewDelegateManager.h
//  WebViewDemo
//
//  Created by liuhuan on 17/2/3.
//  Copyright © 2017年 Sogou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UICommonMacro.h"

@class JSContext;

@interface WebViewDelegateManager : NSObject
SINGLETON_DEFINE(WebViewDelegateManager);

@property (nonatomic,weak) id webDelegate;

@end
