//
//  Keyboard.m
//  TouchBarClient
//
//  Created by Andreas Verhoeven on 07/11/2016.
//  Copyright © 2016 Bikkelbroeders. All rights reserved.
//

#import "KeyboardView.h"

@import AudioToolbox;
@import WebKit;

@interface KeyboardView () <UIScrollViewDelegate, WKScriptMessageHandler, WKNavigationDelegate>
@end

@implementation KeyboardView {
	WKWebView* _webView;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self != nil) {
        WKUserContentController *userContentController = [WKUserContentController new];
        [userContentController addScriptMessageHandler:self name:@"keyEvent"];
        
        _aspectRatio = CGSizeMake(200, 100);
        
        WKWebViewConfiguration* config = [WKWebViewConfiguration new];
        config.userContentController = userContentController;
        _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, 200, 100) configuration:config];
        _webView.opaque = NO;
        _webView.backgroundColor = [UIColor clearColor];
        _webView.navigationDelegate = self;
        _webView.scrollView.scrollEnabled = NO;
        _webView.scrollView.delegate = self;
        [self insertSubview:_webView atIndex:0];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _webView.frame = self.bounds;
}

- (void)setHtmlData:(NSData *)htmlData {
    if (htmlData) {
        [_webView loadData:htmlData MIMEType:@"text/html" characterEncodingName:@"utf-8" baseURL:[NSURL new]];
    }
}

- (void)externalKeyEvent:(KeyEvent)keyEvent {
    NSDictionary *event = @{
                            @"type": @(keyEvent.type),
                            @"key": @(keyEvent.key),
                            @"modifiers": @(keyEvent.modifiers),
                            };
    
    NSData* json = [NSJSONSerialization dataWithJSONObject:event options:0 error:nil];
    NSString* jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];

    NSString *javascript = [NSString stringWithFormat:@"externalKeyEvent(%@)", jsonString];
    [_webView evaluateJavaScript:javascript completionHandler:^(id result, NSError *error) {}];
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    scrollView.contentOffset = CGPointZero;
}

#pragma mark WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
	[webView evaluateJavaScript:@"document.getElementsByTagName('svg')[0].getAttribute('viewBox')" completionHandler:^(id result, NSError *error) {
		NSArray* items = [result componentsSeparatedByString:@" "];
		if(items.count >= 4) {
			_aspectRatio.width = [items[2] doubleValue];
			_aspectRatio.height = [items[3] doubleValue];
            
            if ([_delegate respondsToSelector:@selector(keyboardViewDidLoad:)]) {
                [_delegate keyboardViewDidLoad:self];
            }
		}
	}];
}

#pragma mark WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
	if ([message.name isEqualToString:@"keyEvent"] && [_delegate respondsToSelector:@selector(keyboardView:keyEvent:)]) {
        NSDictionary *event = message.body;

        if ([event[@"click"] boolValue]) AudioServicesPlaySystemSound(1104);

        KeyEvent keyEvent;
        keyEvent.type = [event[@"type"] integerValue];
        keyEvent.key = [event[@"key"] integerValue];
        keyEvent.modifiers = [event[@"modifiers"] integerValue];
        [_delegate keyboardView:self keyEvent:keyEvent];
    }
}

@end
