//
//  ViewControllerWithHttp.h
//  Simgo
//
//  Created by Felix on 14/10/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreTelephony/CTCarrier.h>


@interface ViewControllerWithHttp : UIViewController <UITextFieldDelegate, NSURLConnectionDelegate>
{
    NSMutableData *_responseData;
}

@property NSString* viewName;

@property BOOL isKeyboardVisible;
@property BOOL savedInternetState;
@property NSInteger statusCode;

@property BOOL ignoreNoSim;

@property NSTimer* simPollingTimer;

@property int savedMcc;
@property int savedMnc;

@property NSURLConnection *connection;

- (void)viewDidLoad;

- (void)processAppEnteringForegroundEvent:(NSNotification*)_notification;

- (void)processSimChangedEvent:(CTCarrier *) carrier;

- (void)processInternetConnectivityChangedEvent:(NSNotification*)_notification;

- (void) popToRootViewController:(BOOL)animated;

- (void) pushView:(NSString *)viewIdentifier animated:(BOOL)animated;

- (void)refreshView;

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;

@end
