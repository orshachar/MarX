//
//  CallForwardingViewController.m
//  Simgo
//
//  Created by Felix on 29/10/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import "CallForwardingViewController.h"
#import "Utility.h"
#import "ForwardingExplanationViewController.h"
#import "Preferences.h"

@interface CallForwardingViewController ()

@property (weak, nonatomic) IBOutlet UIView *iPhone4View;
@property (weak, nonatomic) IBOutlet UIView *iPhone5View;

- (IBAction)endTripButton:(id)sender;
- (IBAction)callsForwardedButton:(id)sender;

@end

@implementation CallForwardingViewController

- (void)viewDidLoad
{
    self.viewName = @"CallForwardingViewController";

    self.iPhone5View.hidden = [Utility isExtendedScreen] == NO;
    self.iPhone4View.hidden = [Utility isExtendedScreen] == YES;
    
    [super viewDidLoad];
}

- (IBAction)endTripButton:(id)sender
{
    //check Internet connection
    if([Utility isInternetReachable] == YES)
    {
        NSMutableURLRequest *request = [Utility generateDeleteTripRequest:[Preferences getTripId]];
        
        // Create url connection and fire request
        [NSURLConnection connectionWithRequest:request delegate:self];
        
        [Utility showBusyHud:@"Deleting Trip..." view:self.view];
    }
    else
    {
        [Utility showAlertDialog:@"No Internet connection"];
    }
}

- (IBAction)callsForwardedButton:(id)sender
{
    [Preferences setCallsForwardedFlag:YES];
    [self performSegueWithIdentifier: @"HaveSafeTripSeque" sender: self];
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
        [self pushView:@"StartTripViewController" animated:YES];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"SegueToForwardingExplanation"])
    {
        ForwardingExplanationViewController *controller = (ForwardingExplanationViewController *)segue.destinationViewController;
        controller.isTurnOnCallForwarding = YES;
    }
}

@end
