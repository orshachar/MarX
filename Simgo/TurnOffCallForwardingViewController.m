//
//  TurnOffCallForwardingViewController.m
//  Simgo
//
//  Created by Felix on 12/11/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import "TurnOffCallForwardingViewController.h"
#import "Utility.h"
#import "ForwardingExplanationViewController.h"
#import "Preferences.h"

@interface TurnOffCallForwardingViewController ()

@property (weak, nonatomic) IBOutlet UIView *iPhone5View;
@property (weak, nonatomic) IBOutlet UIView *iPhone4View;

- (IBAction)finishButton:(id)sender;

@end

@implementation TurnOffCallForwardingViewController


- (void)viewDidLoad
{
    self.viewName = @"TurnOffCallForwardingViewController";
    
    [super viewDidLoad];
    
    self.iPhone5View.hidden = [Utility isExtendedScreen] == NO;
    self.iPhone4View.hidden = [Utility isExtendedScreen] == YES;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    
    [super connectionDidFinishLoading:connection];
    [self processDeleteTripResponse:_responseData];
}

- (void)processDeleteTripResponse:(NSMutableData *) responseData
{
    BOOL result = [Utility parseDeleteTripResponse:responseData statusCode:self.statusCode];
    
    if(result)
    {
        [self pushView:@"FeedbackViewController" animated:YES];
    }
}

- (IBAction)finishButton:(id)sender
{
    //check Internet connection
    if([Utility isInternetReachable] == YES)
    {
        NSMutableURLRequest *request = [Utility generateDeleteTripRequest:[Preferences getTripId]];
        
        // Create url connection and fire request
        [NSURLConnection connectionWithRequest:request delegate:self];
        
        [Utility showBusyHud:@"Closing Trip..." view:self.view];
    }
    else
    {
        [Utility showAlertDialog:@"No Internet connection"];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"SegueToCancelForwardingExplanation"])
    {
        ForwardingExplanationViewController *controller = (ForwardingExplanationViewController *)segue.destinationViewController;
        controller.isTurnOnCallForwarding = NO;
    }
}

@end
