//
//  ForwardingExplanationViewController.h
//  Simgo
//
//  Created by Felix on 19/11/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewControllerWithHttp.h"

@interface ForwardingExplanationViewController : ViewControllerWithHttp

@property(nonatomic) BOOL isTurnOnCallForwarding;
@property(nonatomic) BOOL isEarlyTripTermination;


@end
