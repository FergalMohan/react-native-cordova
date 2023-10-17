//
//  CDVCommandDelegateImpl.m
//  CDVCommandDelegateImpl
//
//  Created by fangyunjiang on 15/11/17.
//  Copyright (c) 2015年 remobile. All rights reserved.
//

#import <React/RCTUtils.h>
#import <WebKit/WebKit.h>

#import "CDVAvailability.h"
#import "CDVCommandDelegateImpl.h"
#import "CDVCommandQueue.h"

@implementation CDVCommandDelegateImpl

- (id)initWithViewController:(UIViewController*)viewController
{
    self = [super init];
    if (self != nil) {
        _viewController = viewController;
      // explicitly get the command Q from CDVAwareVC if neccessary
//        _commandQueue = _viewController.commandQueue;

        NSError* err = nil;
        _callbackIdPattern = [NSRegularExpression regularExpressionWithPattern:@"[^A-Za-z0-9._-]" options:0 error:&err];
        if (err != nil) {
            // Couldn't initialize Regex
            NSLog(@"Error: Couldn't initialize regex");
            _callbackIdPattern = nil;
        }
    }
    return self;
}

- (void)evalJsHelper2:(NSString*)js
{
    CDV_EXEC_LOG(@"Exec: evalling: %@", [js substringToIndex:MIN([js length], 160)]);
  
      WKWebView *aWebView = nil;
      if([_viewController respondsToSelector:@selector(webView)])
        aWebView = [_viewController performSelector:@selector(webView)];
  if(aWebView){
    [aWebView evaluateJavaScript:js
               completionHandler:^(id obj, NSError* error) {
      // TODO: obj can be something other than string
      if ([obj isKindOfClass:[NSString class]]) {
        NSString* commandsJSON = (NSString*)obj;
        if ([commandsJSON length] > 0) {
          CDV_EXEC_LOG(@"Exec: Retrieved new exec messages by chaining.");
        }
        
        [self.commandQueue enqueueCommandBatch:commandsJSON];
        [self.commandQueue executePending];
      }
    }];
  }
}

- (void)evalJsHelper:(NSString*)js
{
    // Cycle the run-loop before executing the JS.
    // For _delayResponses -
    //    This ensures that we don't eval JS during the middle of an existing JS
    //    function (possible since UIWebViewDelegate callbacks can be synchronous).
    // For !isMainThread -
    //    It's a hard error to eval on the non-UI thread.
    // For !_commandQueue.currentlyExecuting -
    //     This works around a bug where sometimes alerts() within callbacks can cause
    //     dead-lock.
    //     If the commandQueue is currently executing, then we know that it is safe to
    //     execute the callback immediately.
    // Using    (dispatch_get_main_queue()) does *not* fix deadlocks for some reason,
    // but performSelectorOnMainThread: does.
    if (_delayResponses || ![NSThread isMainThread] || !_commandQueue.currentlyExecuting) {
        [self performSelectorOnMainThread:@selector(evalJsHelper2:) withObject:js waitUntilDone:NO];
    } else {
        [self evalJsHelper2:js];
    }
}

- (BOOL)isValidCallbackId:(NSString*)callbackId
{
    if ((callbackId == nil) || (_callbackIdPattern == nil)) {
        return NO;
    }

    // Disallow if too long or if any invalid characters were found.
    if (([callbackId length] > 100) || [_callbackIdPattern firstMatchInString:callbackId options:0 range:NSMakeRange(0, [callbackId length])]) {
        return NO;
    }
    return YES;
}

- (void)sendPluginResult:(CDVPluginResult*)result forCommand:(CDVInvokedUrlCommand*)command {
  if([command.bridgeName isEqualToString:CDV_BRIDGE_NAME]){
    [self sendPluginResult:result callbackId:command.callbackId];
  }
  else{
    RCTResponseSenderBlock callback = [result.status intValue]==CDVCommandStatus_OK ? command.success : command.error;
    if (callback != nil) {
      callback(@[result.message?:@""]);
    }
  }
}

- (void)sendPluginResult:(CDVPluginResult*)result callbackId:(NSString*)callbackId {
  CDV_EXEC_LOG(@"Exec(%@): Sending result. Status=%@", callbackId, result.status);
  // This occurs when there is are no win/fail callbacks for the call.
  if ([@"INVALID" isEqualToString:callbackId]) {
      return;
  }
  // This occurs when the callback id is malformed.
  if (![self isValidCallbackId:callbackId]) {
      NSLog(@"Invalid callback id received by sendPluginResult");
      return;
  }
  int status = [result.status intValue];
  BOOL keepCallback = [result.keepCallback boolValue];
  NSString* argumentsAsJSON = [result argumentsAsJSON];
  BOOL debug = NO;
  
#ifdef DEBUG
  debug = YES;
#endif

  NSString* js = [NSString stringWithFormat:@"cordova.require('cordova/exec').nativeCallback('%@',%d,%@,%d, %d)", callbackId, status, argumentsAsJSON, keepCallback, debug];

  [self evalJsHelper:js];
}

- (void)evalJs:(NSString*)js
{
    [self evalJs:js scheduledOnRunLoop:YES];
}

- (void)evalJs:(NSString*)js scheduledOnRunLoop:(BOOL)scheduledOnRunLoop
{
    js = [NSString stringWithFormat:@"try{cordova.require('cordova/exec').nativeEvalAndFetch(function(){%@})}catch(e){console.log('exception nativeEvalAndFetch : '+e);};", js];
    if (scheduledOnRunLoop) {
        [self evalJsHelper:js];
    } else {
        [self evalJsHelper2:js];
    }
}

- (id)getCommandInstance:(NSString*)pluginName
{
  id plugin = nil;
  
  if([_viewController respondsToSelector:@selector(getCommandInstance:)])
    plugin = [_viewController performSelector:@selector(getCommandInstance:) withObject:pluginName];
  return plugin;
}


- (void)runInBackground:(void (^)())block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

- (void)runInUIThread:(void (^)())block {
    RCTExecuteOnMainQueue(block);
}

- (NSDictionary*)settings
{
  NSDictionary *viewSettings = nil;
  if(_viewController && [_viewController respondsToSelector:@selector(settings)])
    viewSettings = [_viewController performSelector:@selector(settings)];

  return viewSettings;
}

- (BOOL) URLIsWhitelisted:(NSURL *)navURL
{
  BOOL result = NO;
  if(_viewController && [_viewController respondsToSelector:@selector(URLIsWhitelisted:)])
    result = [_viewController performSelector:@selector(URLIsWhitelisted:) withObject:navURL];
  return result;
}

- (BOOL) URLIsWhitelistedForInAppBrowser:(NSURL *)navURL;
{
  BOOL result = NO;
  if(_viewController && [_viewController respondsToSelector:@selector(URLIsWhitelistedForInAppBrowser:)])
    result = [_viewController performSelector:@selector(URLIsWhitelistedForInAppBrowser:) withObject:navURL];
  return result;
}

-(NSString *)userAgent{
  NSString *userAgent = nil;
  WKWebView *mainWKWebView = nil;
  if([_viewController respondsToSelector:@selector(webView)])
    mainWKWebView = [_viewController performSelector:@selector(webView)];
  if(mainWKWebView)
    userAgent = [mainWKWebView valueForKey:@"userAgent"];
  return userAgent;
}

@end
