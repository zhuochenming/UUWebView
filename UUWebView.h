//
//  UUWebView.h
//
//  Created by zhuochenming on 11/03/16.
//  Copyright (c) 2016 zhuochenming. All rights reserved.
//

#import <UIKit/UIKit.h>

//在Safari中打开链接地址
//typedef NS_ENUM(NSInteger, WebViewNavigationType) {
//    WebViewNavigationTypeLinkClicked,
//    WebViewNavigationTypeFormSubmitted,
//    WebViewNavigationTypeBackForward,
//    WebViewNavigationTypeReload,
//    WebViewNavigationTypeFormResubmitted,
//    WebViewNavigationTypeOther
//};

@class UUWebView;

@protocol UUWebViewDelegate <NSObject>

@optional

- (void)webViewDidStartLoad:(UUWebView *)webView;

- (void)webViewDidFinishLoad:(UUWebView *)webView;

- (void)webView:(UUWebView *)webView didFailLoadWithError:(NSError *)error;

//- (BOOL)webView:(UUWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(WebViewNavigationType)navigationType;

//是否拦截JS
- (BOOL)webView:(UUWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request;

@end

typedef void(^JavaScriptCompletionBlock)(NSString *result, NSError *error);

@interface UUWebView : UIView

@property (nonatomic, weak) id<UUWebViewDelegate> delegate;

@property (nonatomic, readonly, weak) UIScrollView *scrollView;

@property (nonatomic, readonly) NSString *pageTitle;

@property (nonatomic, readonly, getter=canGoBack) BOOL canGoBack;

@property (nonatomic, readonly, getter=canGoForward) BOOL canGoForward;

@property (nonatomic, readonly, getter=isLoading) BOOL loading;

@property (nonatomic, readonly, strong) NSURLRequest *request;

- (void)loadRequest:(NSURLRequest *)request;

- (void)loadRequest:(NSURLRequest *)request timeOut:(NSInteger)timeOut;

- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL;

- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL timeOut:(NSInteger)timeOut;

- (void)evaluateJavaScriptFromString:(NSString *)script completionBlock:(JavaScriptCompletionBlock)block;

- (void)stopLoading;

- (void)reload;

- (void)goBack;

- (void)goForward;

@end
