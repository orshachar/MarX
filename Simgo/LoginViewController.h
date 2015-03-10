//
//  SimgoViewController.h
//  Simgo
//
//  Created by Felix on 11/10/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewControllerWithHttp.h"

@interface LoginViewController : ViewControllerWithHttp

@property (copy, nonatomic) NSString *userPhoneNumber;

@end
