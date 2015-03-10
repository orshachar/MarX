//
//  UsageViewController.m
//  Simgo
//
//  Created by Felix Gelman on 18/3/14.
//  Copyright (c) 2014 Simgo. All rights reserved.
//

#import "UsageViewController.h"
#import "Utility.h"
#import "Preferences.h"

@interface UsageViewController ()
@property (weak, nonatomic) IBOutlet UILabel *billingPeriodLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *billingPeriodProgressBar;
@property (weak, nonatomic) IBOutlet UILabel *callMinutesQuota;
@property (weak, nonatomic) IBOutlet UILabel *dataMbQuota;
@property (weak, nonatomic) IBOutlet UILabel *minutesUsed;
@property (weak, nonatomic) IBOutlet UILabel *minutesLeft;
@property (weak, nonatomic) IBOutlet UILabel *dataUsed;
@property (weak, nonatomic) IBOutlet UILabel *dataLeft;
@property (weak, nonatomic) IBOutlet UILabel *tripCallsUsed;
@property (weak, nonatomic) IBOutlet UILabel *tripDataUsed;
@property (weak, nonatomic) IBOutlet UILabel *totalCallsUsed;
@property (weak, nonatomic) IBOutlet UILabel *totalDataUsed;
@property (weak, nonatomic) IBOutlet UIImageView *callsUsagePie;
@property (weak, nonatomic) IBOutlet UIImageView *dataUsagePie;
@property (weak, nonatomic) IBOutlet UIImageView *callsLeftSymbol;
@property (weak, nonatomic) IBOutlet UIImageView *dataLeftSymbol;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainViewHeightContraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tripSubViewHeightContraint;

- (IBAction)refreshButton:(UIBarButtonItem *)sender;

@end

@implementation UsageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    self.ignoreNoSim = NO;
    
    [self fetchUsageData];
}

- (void)processAppEnteringForegroundEvent:(NSNotification*)_notification
{
    NSLog(@"Entering foreground. Updating usage data");
    
    [super processAppEnteringForegroundEvent:_notification];
    [self fetchUsageData];

}

- (void)fetchUsageData
{
    if ([Utility isInternetReachable] == YES)
    {
        [self sendTripStatusRequest];
    }
    else
    {
        [Utility showAlertDialog:@"Internet connection is required to update usage statistics.\nDisplayed information may not be up to date."];
        [self updateUsageView];
    }
}

- (void)sendTripStatusRequest
{
    [Utility showBusyHud:@"Updating..." view:self.view];
    
    // Prepare and send Phase II login request to Cloud.
    NSMutableURLRequest *request = [Utility prepareTripStatusRequest:[Preferences getTripId] status:[Utility generateTripStatusString]];
    
    // Create url connection and fire request.
    [NSURLConnection connectionWithRequest:request delegate:self];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // The request is complete and data has been received
    
    [super connectionDidFinishLoading:connection];
    [self processTripStatusResponse:_responseData];
}

- (void)processTripStatusResponse:(NSMutableData *) responseData
{
    [Utility parseTripStatusResponse:responseData statusCode:self.statusCode];
    
    if ([Preferences getTripId] != UNDEFINED)
    {
        [self updateUsageView];
    }
    else
    {
        [Utility showAlertDialog:@"Trip not found" message:nil delegate:self otherButtonTitles:nil];
    }
}

- (void)updateUsageView
{
    PlanType planType = [Preferences getPlanType];
    if (planType == DAILY_PLAN)
    {
        self.billingPeriodLabel.text = @"Daily billing cycle";
    }
    else if (planType == WEEKLY_PLAN)
    {
        self.billingPeriodLabel.text = @"Weekly billing cycle"; 
    }
    else if (planType == MONTHLY_PLAN)
    {
        self.billingPeriodLabel.text = @"Monthly billing cycle";
    }
    else if (planType == TRIP_PLAN)
    {
        self.billingPeriodLabel.text = @"Trip usage";

        //hide 'Current Trip' view
        self.mainViewHeightContraint.constant = 509;
        self.tripSubViewHeightContraint.constant = 0;
        self.billingPeriodProgressBar.hidden = YES;
    }
    
    self.tripCallsUsed.text = [NSString stringWithFormat:@"%d", (int)ceil([Preferences getTripCallsUsage])];
    self.tripDataUsed.text = [NSString stringWithFormat:@"%d",  (int)ceil([Preferences getTripDataUsage])];
    self.totalCallsUsed.text = [NSString stringWithFormat:@"%d",  (int)ceil([Preferences getTotalCallsUsage])];
    self.totalDataUsed.text = [NSString stringWithFormat:@"%d",  (int)ceil([Preferences getTotalDataUsage])];
    
    //get usage figures - for TRIP plan Usage==TripUsage, overwise Usage==RegularUsage
    double callsUsage;
    double dataUsage;
    if (planType != TRIP_PLAN)
    {
        callsUsage = [Preferences getCallsUsage];
        dataUsage = [Preferences getDataUsage];
    }
    else
    {
        callsUsage = [Preferences getTripCallsUsage];
        dataUsage = [Preferences getTripDataUsage];
    }
    
    [self updateUsageTile:self.minutesLeft usedLabel:self.minutesUsed quotaLabel:self.callMinutesQuota leftSymbol:self.callsLeftSymbol usagePie:self.callsUsagePie quota:[Preferences getCallsQuota] usage:callsUsage];
    [self updateUsageTile:self.dataLeft usedLabel:self.dataUsed quotaLabel:self.dataMbQuota leftSymbol:self.dataLeftSymbol usagePie:self.dataUsagePie quota:[Preferences getDataQuota] usage:dataUsage];
    
    if ([Definitions getBillingCycleLength:planType] != UNDEFINED_BILLING_CYCLE)
    {
        NSNumber *elapsedBillingCycle = [Preferences getElapsedBillingCycle];
        if (elapsedBillingCycle == nil)
        {
            elapsedBillingCycle = 0;
        }
        float progress = [elapsedBillingCycle longLongValue] / (long double)[Definitions getBillingCycleLength:planType];
        
        self.billingPeriodProgressBar.progress = progress;
    }
    
    [Utility hideHud:self.view];
}

- (void)updateUsageTile:(UILabel *)leftLabel usedLabel:(UILabel *)usedLabel quotaLabel:(UILabel *)quotaLabel leftSymbol:(UIImageView *)leftSymbol usagePie:(UIImageView *)usagePie quota:(int)quota usage:(double)usage
{
    int usage_int = (int)ceil(usage);
    
    usedLabel.text = [NSString stringWithFormat:@"%d Used", usage_int];
    if (quota == UNLIMITED)
    {
        leftSymbol.hidden = YES;
        leftLabel.hidden = YES;
        
        quotaLabel.text = @"Unlimited";
        [quotaLabel setFont:[UIFont boldSystemFontOfSize:14]];
    }
    else
    {
        leftSymbol.hidden = NO;
        leftLabel.hidden = NO;
        
        if (quota >= usage_int)
        {
            quotaLabel.text = [NSString stringWithFormat:@"%d", quota];
            leftLabel.text = [NSString stringWithFormat:@"%d Left", quota - usage_int];
            leftSymbol.image = [UIImage imageNamed:@"used_symbol.png"];
        }
        else
        {
            quotaLabel.text = [NSString stringWithFormat:@"%d", usage_int];
            leftLabel.text = [NSString stringWithFormat:@"%d Exceed", usage_int - quota];
            leftSymbol.image = [UIImage imageNamed:@"exceeded_symbol.png"];
        }
        [quotaLabel setFont:[UIFont boldSystemFontOfSize:20]];
    }
    
    usagePie.image = [UIImage imageNamed:[self getPieImage:usage_int total:quota]];
}


- (NSString *)getPieImage:(double)fraction total:(double)total
{
    if (fraction == 0 || total == UNLIMITED)
    {
        return @"pie_0.png";
    }
    else if (total == 0 || fraction > total)
    {
       return @"exceeded_pie.png";
    }
    else
    {
        NSArray *pieArray = [NSArray arrayWithObjects: @"pie_0.png", @"pie_5.png", @"pie_10.png", @"pie_15.png", @"pie_20.png", @"pie_25.png", @"pie_30.png", @"pie_35.png", @"pie_40.png", @"pie_45.png", @"pie_50.png", @"pie_55.png", @"pie_60.png", @"pie_65.png", @"pie_70.png", @"pie_75.png", @"pie_80.png", @"pie_85.png", @"pie_90.png", @"pie_95.png", @"pie_100.png", @"exceeded_pie.png", nil];
        
        int pieSlice = (int) ceil(fraction / total * 20);
        
        return pieArray[pieSlice];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if([title isEqualToString:@"OK"])
    {
        NSLog(@"Trip not found");
        
        [self popToRootViewController:YES];
    }
}

- (IBAction)refreshButton:(UIBarButtonItem *)sender
{
    //reset 'Current Trip' view
    self.mainViewHeightContraint.constant = 650;
    self.tripSubViewHeightContraint.constant = 141;
    self.billingPeriodProgressBar.hidden = NO;
    
    [self fetchUsageData];
}
@end
