//
//  CDVCommandDelegateImpl.h
//  CDVCommandDelegateImpl
//
//  Created by fangyunjiang on 15/11/17.
//  Copyright (c) 2015年 remobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTBridgeModule.h>
#import "CDVPluginResult.h"
#import "CDVInvokedUrlCommand.h"
#import "CDVCommandDelegate.h"


@class CDVCommandQueue;

@interface CDVCommandDelegateImpl : NSObject <CDVCommandDelegate> {
@private
  __weak UIViewController* _viewController;
  NSRegularExpression* _callbackIdPattern;
@protected
  BOOL _delayResponses;
}
#define IsAtLeastiOSVersion(X) ([[[UIDevice currentDevice] systemVersion] compare:X options:NSNumericSearch] != NSOrderedAscending)
@property (nonatomic, weak) CDVCommandQueue* commandQueue;  // owned by VC

- (id)initWithViewController:(UIViewController*)viewController;

- (id)getCommandInstance:(NSString*)pluginName;

- (void)sendPluginResult:(CDVPluginResult*)result callbackId:(id)callbackId;
- (void)evalJs:(NSString*)js;
- (void)evalJs:(NSString*)js scheduledOnRunLoop:(BOOL)scheduledOnRunLoop;

- (void)runInBackground:(void (^)())block;
- (void)runInUIThread:(void (^)())block;

-(NSString *)userAgent;

@end
