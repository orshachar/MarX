//
//  ForwardingExplanationViewController.m
//  Simgo
//
//  Created by Felix on 19/11/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import "ForwardingExplanationViewController.h"
#import "Utility.h"
#import "Preferences.h"

#import <QuartzCore/QuartzCore.h>
#import "AVFoundation/AVFoundation.h"


@interface ForwardingExplanationViewController ()

- (IBAction)iPhoneDialerButton:(id)sender;
- (IBAction)backButton:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *clickOnVideoButtonOutlet;
@property (weak, nonatomic) IBOutlet UIView *videoContainer;

@property bool isAlertViewDisplayed;

@end

@implementation ForwardingExplanationViewController

- (void)viewDidLoad
{
    self.viewName = @"ForwardingExplanationViewController";
    
    [super viewDidLoad];
    
    self.isAlertViewDisplayed = NO;
    
    if (self.isTurnOnCallForwarding == NO)
    {
        //copy to clipboard Call Forwarding de-activation code
        [Utility copyToClipboad:@"##21#"];
    }
    else
    {
        //copy to clipboard Call Forwarding activation code
        NSString *callForwardingActivationCode = [NSString stringWithFormat:@"%@ %@ %@", @"*21*+", [Preferences getIncomingAccessNumber], @"#"];
        [Utility copyToClipboad:callForwardingActivationCode];
    }
    
    NSString * url = [[NSBundle mainBundle] pathForResource:@"ux-demo-iphone5-retina" ofType:@"mov"];
    AVPlayer *player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:url]];
    AVPlayerLayer *layer = [AVPlayerLayer layer];
    player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    [layer setPlayer:player];
    [layer setFrame:CGRectMake(0, 0, 320, 568)];
    
    [self.videoContainer.layer addSublayer:layer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:[player currentItem]];
    
    [player play];
}

-(void)viewWillAppear:(BOOL)animated
{
    NSLog(@"Forwarding explanation viewWillAppear");
    
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];   //it hides
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:(BOOL)animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}


- (void)processAppEnteringForegroundEvent:(NSNotification*)_notification
{
    [super processAppEnteringForegroundEvent:_notification];
    
    if (self.isAlertViewDisplayed == YES)
    {
        NSLog(@"Alert view already displayed. Skipping");
        return;
    }
    
    if (self.isTurnOnCallForwarding)
    {
        [Utility showAlertDialog:@"Was call forwarding successful?" message:nil delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes" tag:nil];
    }
    else
    {
        [Utility showAlertDialog:@"Was call forwarding successfully de-activated?" message:nil delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes" tag:nil];
    }
    
    self.isAlertViewDisplayed = YES;
}

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    AVPlayerItem *player = [notification object];
    [player seekToTime:kCMTimeZero];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if([title isEqualToString:@"Yes"])
    {
        [self callForwardingSucceeded];
    }
    else if([title isEqualToString:@"No"])
    {
        [self returnToPreviousView];
    }
}

- (void)returnToPreviousView
{
    if (self.isTurnOnCallForwarding)
    {
        [self pushView:@"CallForwardingViewController" animated:YES];
    }
    else if (self.isEarlyTripTermination)
    {
        [self pushView:@"SafeTripViewController" animated:YES];
    }
    else
    {
        [self pushView:@"TurnOffCallForwardingViewController" animated:YES];
    }
}

- (void)callForwardingDone
{
    if (self.isEarlyTripTermination)
    {
        [self pushView:@"StartTripViewController" animated:YES];
    }
    else
    {
        [Preferences setTripId:UNDEFINED];
        [Preferences setCallsForwardedFlag:NO];
        [self pushView:@"FeedbackViewController" animated:YES];
    }
}

// Add this method
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)callForwardingSucceeded
{
    if (self.isTurnOnCallForwarding)
    {
        [Preferences setCallsForwardedFlag:YES];
        [self pushView:@"SafeTripViewController" animated:YES];
    }
    else
    {
        [Preferences setCallsForwardedFlag:NO];

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
            NSLog(@"Failed to delete trip. Updating pending delete Trip ID");
            [Preferences setPendingDeleteTripId:[Preferences getTripId]];
            [self callForwardingDone];
            //[Utility showAlertDialog:@"No Internet connection"];
        }
    }
}

- (IBAction)iPhoneDialerButton:(id)sender
{
    [Utility showAlertDialog:@"Code Generated" message:@"Press 'Home', open Phone app, hold down the blank area above the dial pad, click 'Paste' & hit 'Call'" delegate:nil otherButtonTitles:nil];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    
    [super connectionDidFinishLoading:connection];
    [self processDeleteTripResponse:_responseData];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    
    NSLog(@"Failed to delete trip. Moving next");

    //Connection failed. Hide HUD and update pending delete Trip ID
    [Utility hideHud:self.view];
    [Preferences setPendingDeleteTripId:[Preferences getTripId]];
    [self callForwardingDone];
}

- (void)processDeleteTripResponse:(NSMutableData *) responseData
{
    BOOL result = [Utility parseDeleteTripResponse:responseData statusCode:self.statusCode];
    
    if(result)
    {
        [self callForwardingDone];
    }
}
- (IBAction)backButton:(id)sender
{
    [self returnToPreviousView];
}
@end
