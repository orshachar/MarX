//
//  SimgoUnavailableViewController.m
//  Simgo
//
//  Created by Felix on 15/11/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import "SimgoUnavailableViewController.h"
#import "Utility.h"

@interface SimgoUnavailableViewController ()

@property (weak, nonatomic) IBOutlet UIView *iPhone5View;
@property (weak, nonatomic) IBOutlet UIView *iPhone4View;
@property (weak, nonatomic) IBOutlet UILabel *errorMessageLabelIphone4;
@property (weak, nonatomic) IBOutlet UILabel *errorMessageLabelIphone5;
@property (weak, nonatomic) IBOutlet UIImageView *errorIconIphone4;
@property (weak, nonatomic) IBOutlet UIImageView *errorIconIphone5;

@property UILabel *errorMessageLabel;
@property UIImageView *errorIcon;

@end

@implementation SimgoUnavailableViewController

- (void)viewDidLoad
{
    self.viewName = @"SimgoUnavailableViewController";

    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.navigationItem.hidesBackButton = YES;
    
    self.iPhone5View.hidden = [Utility isExtendedScreen] == NO;
    self.iPhone4View.hidden = [Utility isExtendedScreen] == YES;
    
    if ([Utility isExtendedScreen])
    {
        self.errorMessageLabel = self.errorMessageLabelIphone5;
        self.errorIcon = self.errorIconIphone5;
    }
    else
    {
        self.errorMessageLabel = self.errorMessageLabelIphone4;
        self.errorIcon = self.errorIconIphone4;
    }
    
    int mcc = [Utility getMcc];
    int mnc = [Utility getMnc] & 0x7;
    
    if (mcc != 1)
    {
        [self popToRootViewController:YES];
    }
    else if (mnc == PLUG_STATUS_PROVISIONING)
    {
        self.errorMessageLabel.text = @"Simgo is currently unavailable at this location. We'll connect you automatically as soon as you're in range.";
        self.errorIcon.image = [UIImage imageNamed:@"unavailable_icon.png"];
    }
    else if (mnc == PLUG_STATUS_PROVISIONED_FAILED_REJECTED_BY_CLOUD || mnc == PLUG_STATUS_PROVISIONED_FAILED_INVALID_CLOUD_RESPONSE)
    {
        self.errorMessageLabel.text = @"Simgo has encounterd a configuration error. Please contact technical support.";
        self.errorIcon.image = [UIImage imageNamed:@"fatal_error_icon.png"];
    }
    else if (mnc == PLUG_STATUS_PROVISIONED_FAILED_NO_HSIM)
    {
        self.errorMessageLabel.text = @"Please insert your SIM card into Simgo device and restart your phone.";
        self.errorIcon.image = [UIImage imageNamed:@"sim_symbol.png"];
    }
    else if (mnc == PLUG_STATUS_PROVISIONING_INHIBITED)
    {
        self.errorMessageLabel.text = @"Please disconnect your Simgo device from USB and restart your phone.";
        self.errorIcon.image = [UIImage imageNamed:@"usb_silver.png"];

    }
    else if (mnc == PLUG_STATUS_DEAD_BATTERY)
    {
        self.errorIcon.image = [UIImage imageNamed:@"low_battery_icon.png"];
        self.errorMessageLabel.text = @"Simgo battery is depleted. Please disconnect your Simgo device from the phone and recharge it.";
    }

}

@end
