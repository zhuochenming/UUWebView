//
//  UUWebView.m
//
//  Created by zhuochenming on 11/03/16.
//  Copyright (c) 2016 zhuochenming. All rights reserved.
//

#import "UUWebView.h"
#import <WebKit/WebKit.h>

@interface UUWebView () <UIWebViewDelegate, WKNavigationDelegate>

@property (nonatomic, strong) UIWebView *webView;

@property (nonatomic, strong) WKWebView *webViewWK;

@property (nonatomic, strong) dispatch_source_t timer;

@end

@implementation UUWebView

#pragma mark - 初始化
- (instancetype)init {
    NSAssert(NO, @"用initWithFrame替代");
    return nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self configureWebView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self configureWebView];
    }
    return self;
}

- (void)configureWebView {
    if (NSClassFromString(@"WKWebView") == nil) {
        _webView = [[UIWebView alloc] initWithFrame:self.frame];
        _webView.delegate = self;
        _webView.suppressesIncrementalRendering = YES;
        _webView.scalesPageToFit = YES;
        _webView.dataDetectorTypes = UIDataDetectorTypeLink | UIDataDetectorTypeCalendarEvent | UIDataDetectorTypeAddress;
        [self addSubview:_webView];
    } else {
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        configuration.allowsInlineMediaPlayback = YES;
        _webViewWK = [[WKWebView alloc] initWithFrame:self.frame configuration:configuration];
        _webViewWK.navigationDelegate = self;
        [self addSubview:_webViewWK];
    }
}

- (void)dealloc {
    _webView.delegate = nil;
    [_webView stopLoading];
    _webView = nil;
    
    _webViewWK.navigationDelegate = nil;
    [_webViewWK stopLoading];
    _webViewWK = nil;
}

#pragma mark － 属性
+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (UIScrollView *)scrollView {
    if (self.webView) {
        return self.webView.scrollView;
    } else {
        return self.webViewWK.scrollView;
    }
}

- (NSString *)pageTitle {
    NSString *pageTitle = [self.webViewWK title];
    
    if (pageTitle == nil) {
        pageTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    }
    
    return pageTitle;
}

- (NSURLRequest *)request {
    if ([self.webViewWK URL]) {
        return [NSURLRequest requestWithURL:[self.webViewWK URL]];
    }
    return [self.webView request];
}

- (BOOL)canGoBack {
    return [self.webView canGoBack] || [self.webViewWK canGoBack];
}

- (BOOL)canGoForward {
    return [self.webView canGoForward] || [self.webViewWK canGoForward];
}

- (BOOL)isLoading {
    return [self.webView isLoading] || [self.webViewWK isLoading];
}

- (void)timeCountOfLoadWebWithTimeOut:(NSInteger)timeOut {
    __block NSInteger leftTime = timeOut;
    if (_timer == nil) {
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    }
    dispatch_source_cancel(_timer);
    
    dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, 0 * NSEC_PER_SEC, 1.0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(_timer, ^{
        leftTime--;
        if (leftTime == 0) {
            [self stopLoadWebView];
        }
    });
    dispatch_resume(_timer);
}

#pragma mark - 方法
- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [self.webView setBackgroundColor:backgroundColor];
    [self.webViewWK setBackgroundColor:backgroundColor];
}

- (void)loadRequest:(NSURLRequest *)request {
    [self.webView loadRequest:request];
    [self.webViewWK loadRequest:request];
}

- (void)loadRequest:(NSURLRequest *)request timeOut:(NSInteger)timeOut {
    [self timeCountOfLoadWebWithTimeOut:timeOut];
    [self loadRequest:request];
}

- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL {
    [self.webView loadHTMLString:string baseURL:baseURL];
    [self.webViewWK loadHTMLString:string baseURL:baseURL];
}

- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL timeOut:(NSInteger)timeOut {
    [self timeCountOfLoadWebWithTimeOut:timeOut];
    [self loadHTMLString:string baseURL:baseURL];
}

- (void)stopLoadWebView {
    [self stopLoading];
    [self handleError:[NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorTimedOut userInfo:nil]];
}

- (void)evaluateJavaScriptFromString:(NSString *)script completionBlock:(JavaScriptCompletionBlock)block {
    if (self.webView) {
        NSString *jsResult = [self.webView stringByEvaluatingJavaScriptFromString:script];
        block(jsResult, nil);
    } else {
        [self.webViewWK evaluateJavaScript:script completionHandler:^(id result, NSError *error) {
            NSString *jsResult = nil;
            if (!error) {
                if ([result isKindOfClass:[NSString class]]) {
                    jsResult = result;
                } else {
                    jsResult = [NSString stringWithFormat:@"%@", result];
                }
            } else {
                NSLog(@"%@", error);
            }
            block(jsResult, error);
        }];
    }
}

#pragma mark － UIWebView代理
- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self handleStartLoad];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self handleFinishLoad];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self handleError:error];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
//    if ([self.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
//        return [self.delegate webView:self shouldStartLoadWithRequest:request navigationType:[self navigationTypeFromUIWebViewNavigationType:navigationType]];
//    } else {
//        return YES;
//    }
    if ([self.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:)]) {
        return [self.delegate webView:self shouldStartLoadWithRequest:request];
    } else {
        return YES;
    }
}

#pragma mark － WKNavigation代理
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [self handleStartLoad];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self handleFinishLoad];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self handleError:error];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self handleError:error];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
//    if ([self.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
//        if ([self.delegate webView:self shouldStartLoadWithRequest:navigationAction.request navigationType:[self navigationTypeFromWKNavigationType:navigationAction.navigationType]]) {
//            decisionHandler(WKNavigationActionPolicyAllow);
//        } else {
//            decisionHandler(WKNavigationActionPolicyCancel);
//        }
//    } else {
//        decisionHandler(WKNavigationActionPolicyAllow);
//    }
    if ([self.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:)]) {
        BOOL isIntercept = [self.delegate webView:self shouldStartLoadWithRequest:navigationAction.request];
        if (isIntercept) {
            decisionHandler(WKNavigationActionPolicyAllow);
        } else {
            decisionHandler(WKNavigationActionPolicyCancel);
        }
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)reload {
    [self.webView reload];
    [self.webViewWK reload];
}

- (void)goBack {
    [self.webView goBack];
    [self.webViewWK goBack];
}

- (void)goForward {
    [self.webView goForward];
    [self.webViewWK goForward];
}

- (void)stopLoading {
    [self.webView stopLoading];
    [self.webViewWK stopLoading];
}

#pragma mark - 网页事件处理
- (void)handleStartLoad {
    if ([self.delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [self.delegate webViewDidStartLoad:self];
    }
}

- (void)handleFinishLoad {
    if (_timer) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
    
    if ([self.delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [self.delegate webViewDidFinishLoad:self];
    }
}

- (void)handleError:(NSError *)error {
    if (_timer) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
    
    if ([self.delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.delegate webView:self didFailLoadWithError:error];
    }
}

//- (WebViewNavigationType)navigationTypeFromUIWebViewNavigationType:(UIWebViewNavigationType)navigationType {
//    switch (navigationType) {
//        case UIWebViewNavigationTypeLinkClicked:
//        {
//            return WebViewNavigationTypeLinkClicked;
//            break;
//        }
//        case UIWebViewNavigationTypeFormSubmitted:
//        {
//            return WebViewNavigationTypeFormSubmitted;
//            break;
//        }
//        case UIWebViewNavigationTypeBackForward:
//        {
//            return WebViewNavigationTypeBackForward;
//            break;
//        }
//        case UIWebViewNavigationTypeReload:
//        {
//            return WebViewNavigationTypeReload;
//            break;
//        }
//        case UIWebViewNavigationTypeFormResubmitted:
//        {
//            return WebViewNavigationTypeFormResubmitted;
//            break;
//        }
//        case UIWebViewNavigationTypeOther:
//        {
//            return WebViewNavigationTypeOther;
//            break;
//        }
//    }
//}
//
//- (WebViewNavigationType)navigationTypeFromWKNavigationType:(WKNavigationType)navigationType {
//    switch (navigationType) {
//        case WKNavigationTypeLinkActivated:
//        {
//            return WebViewNavigationTypeLinkClicked;
//            break;
//        }
//        case WKNavigationTypeFormSubmitted:
//        {
//            return WebViewNavigationTypeFormSubmitted;
//            break;
//        }
//        case WKNavigationTypeBackForward:
//        {
//            return WebViewNavigationTypeBackForward;
//            break;
//        }
//        case WKNavigationTypeReload:
//        {
//            return WebViewNavigationTypeReload;
//            break;
//        }
//        case WKNavigationTypeFormResubmitted:
//        {
//            return WebViewNavigationTypeFormResubmitted;
//            break;
//        }
//        case WKNavigationTypeOther:
//        {
//            return WebViewNavigationTypeOther;
//            break;
//        }
//    }
//}

@end
