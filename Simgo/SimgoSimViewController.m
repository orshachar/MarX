//
//  SimgoSimViewController.m
//  Simgo
//
//  Created by Felix on 13/11/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import "SimgoSimViewController.h"
#import "Utility.h"
#import "Definitions.h"
#import "Preferences.h"

@interface SimgoSimViewController ()

@property (weak, nonatomic) IBOutlet UIView *iPhone5View;
@property (weak, nonatomic) IBOutlet UIView *iPhone4View;
@property (weak, nonatomic) IBOutlet UIButton *noInternetButtonOutletIphone4;
@property (weak, nonatomic) IBOutlet UILabel *everythingOkLabelIphone4;
@property (weak, nonatomic) IBOutlet UIButton *noInternetButtonOutletIphone5;
@property (weak, nonatomic) IBOutlet UILabel *everythingOkLabelIphone5;

@end

@implementation SimgoSimViewController

- (void)viewDidLoad
{
    self.viewName = @"SimgoSimViewController";

    [super viewDidLoad];
    
    self.navigationItem.hidesBackButton = YES;
    
    self.ignoreNoSim = NO;
    
    self.iPhone5View.hidden = [Utility isExtendedScreen] == NO;
    self.iPhone4View.hidden = [Utility isExtendedScreen] == YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mobileDataConfigUpdated) name:@"MOBILE_DATA_CONFIG_UPDATED" object: nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:(BOOL)animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"MOBILE_DATA_CONFIG_UPDATED" object:nil];
}

- (void)processAppEnteringForegroundEvent:(NSNotification*)_notification
{
    NSLog(@"Entering foreground. Checking current network code");

    if([self handleNoAndFooSimCondition] == NO)
    {
        [super processAppEnteringForegroundEvent:_notification];
        
        [self showUsageViewForPlanLimit];
    }
}

- (void) showUsageViewForPlanLimit
{
    if (([Preferences getCallsUsageState] != WITHIN_PLAN_LIMITS || [Preferences getDataUsageState] != WITHIN_PLAN_LIMITS) && [Utility isInternetReachable] == YES)
    {
        [self performSegueWithIdentifier: @"sequeToUsageView" sender: self];
    }
}

- (void)processInternetConnectivityChangedEvent:(NSNotification*)_notification
{
    [self mobileDataConfigUpdated];
    [super processInternetConnectivityChangedEvent:_notification];
}

-(void) mobileDataConfigUpdated
{
    if ([Utility isMobileDataConfigValid])
    {
        self.noInternetButtonOutletIphone4.hidden = [Utility isInternetReachable] == YES;
        self.noInternetButtonOutletIphone5.hidden = [Utility isInternetReachable] == YES;
        self.everythingOkLabelIphone4.hidden = [Utility isInternetReachable] == NO;
        self.everythingOkLabelIphone5.hidden = [Utility isInternetReachable] == NO;
    }
    else
    {
        self.noInternetButtonOutletIphone4.hidden = YES;
        self.noInternetButtonOutletIphone5.hidden = YES;
        
        if ([Utility isInternetReachable])
        {
            self.everythingOkLabelIphone4.text = @"Everything looks fine here";
            self.everythingOkLabelIphone5.text = @"Everything looks fine here";
        }
        else
        {
            self.everythingOkLabelIphone4.text = @"No Internet connectivity";
            self.everythingOkLabelIphone5.text = @"No Internet connectivity";
            self.everythingOkLabelIphone4.textColor = [UIColor magentaColor];
            self.everythingOkLabelIphone5.textColor = [UIColor magentaColor];
        }
    }
}

- (BOOL)handleNoAndFooSimCondition
{
    
    if ([Utility getMcc] == 0)
    {
        NSLog(@"No Sim. Refreshing View.");
        [self refreshView];
        return YES;
    }
    else if ([Utility getMcc] == 1)
    {
        NSLog(@"FOO IMSI detected. Jumping to Unavailable view");
        [self pushView:@"SimgoUnavailableViewController" animated:NO];
        return YES;
    }
    
    return NO;
}

- (void)processSimChangedEvent:(CTCarrier *) carrier
{
    if([self handleNoAndFooSimCondition] == NO)
    {
        [super processSimChangedEvent:carrier];
    }
}

@end
