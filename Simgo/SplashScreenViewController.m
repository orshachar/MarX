//
//  SplashScreenViewController.m
//  Simgo
//
//  Created by Felix on 04/11/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import "SplashScreenViewController.h"
#import "Utility.h"
#import "Definitions.h"
#import "Preferences.h"

@interface SplashScreenViewController ()
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *currentStatusLabel;

@property (weak, nonatomic) IBOutlet UIButton *noInternetButtonOutlet;

- (IBAction)noInternetButtonClick:(id)sender;

@property BOOL isRequestPending;
@property BOOL debouncer;

@end

@implementation SplashScreenViewController

- (void)viewDidLoad
{
    self.viewName = @"SplashScreenViewController";

    // Perform initial initialization when app is started for the first time
    if ([Preferences getInitialInitDoneFlag] == NO)
    {
        [Preferences setLoggedInStatus:LOGGED_OUT];
        [Preferences setTripId:UNDEFINED];
        [Preferences setPendingDeleteTripId:UNDEFINED];
        [Preferences setInitialInitDoneFlag:YES];
    }
    
    [super viewDidLoad];
    
    self.noInternetButtonOutlet.hidden = YES;
    self.ignoreNoSim = NO;
}

-(void)viewWillAppear:(BOOL)animated
{
    NSLog(@"Splash view will appear");

    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];   //it hides
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mobileDataConfigUpdated) name:@"MOBILE_DATA_CONFIG_UPDATED" object: nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:(BOOL)animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"MOBILE_DATA_CONFIG_UPDATED" object:nil];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.isRequestPending = NO;
    
    NSLog(@"Carrier Name: %@", [Utility getOperatorName]);
    NSLog(@"MCC: %d", [Utility getMcc]);
    NSLog(@"MNC: %d", [Utility getMnc]);
    
    //used to block another calling to 'findCurrentState' from 'processAppEnteringForegroundEvent'
    self.debouncer = YES;
    [self performSelector:@selector(findCurrentState) withObject:nil afterDelay:0.1];
    //[self findCurrentState];
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

-(void) findCurrentState
{
    NSLog(@"Finding current state");
    
    self.savedMcc = [Utility getMcc];
    self.savedMnc = [Utility getMnc];
    
//    #warning FOR testing only
//    [self pushView:@"SimgoUnavailableViewController" animated:YES];
//    return;

    //Check if user is logged Out
    if ([Preferences getLoggedInStatus] == LOGGED_OUT)
    {
        NSLog(@"Current state: LoggedOut");
        
        [self pushView:@"LoginViewController" animated:YES];
    }
    //Check if user is waiting for SMS or already logged In
    else if([Preferences getLoggedInStatus] == WAITING_FOR_SMS)
    {
        NSLog(@"Current state: WAITING_FOR_SMS");
        
        //Push 'Enter password' and 'Login' views to stack (in case user will want to edit his phone number)
        UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *loginViewController =[storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        
        //SMS was send. Jump to 'Waiting for SMS' scene
        NSMutableArray* viewControllers = [NSMutableArray arrayWithCapacity:2];
        [viewControllers addObject:loginViewController];
        
        UIViewController *enterPasswordViewController = [storyboard instantiateViewControllerWithIdentifier:@"EnterPasswordViewController"];
        [viewControllers addObject:enterPasswordViewController];
        [self.navigationController setViewControllers:[NSArray arrayWithArray:viewControllers] animated:YES];
    }
    else if (self.savedMcc == 0)
    {
        NSLog(@"Current state: NoSim");

        //[Utility showAlertDialog:@"No SIM" message:@"Please connect Simgo or insert your SIM card and try again." delegate:self];

        self.noInternetButtonOutlet.hidden = YES;
        
        [self updateStatusLabel:@"Waiting for SIM..."];
    }
    else if (self.savedMcc == 1) //FOO IMSI
    {
         NSLog(@"Current state: Using FOO SIM");
        
        [self pushView:@"SimgoUnavailableViewController" animated:YES];
    }
    //User is logged In.
    //Is trip started?
    else if([Preferences getTripId] < 0)
    {
        NSLog(@"Current state: NoActiveTrip");

        //User is logged in but no trip started. Jump to 'Start trip' scene
        [self pushView:@"StartTripViewController" animated:YES];
    }
    //Trip started. Query cloud for active allocation
    //check if Internet is available
    else if ([Utility isInternetReachable] == YES)
    {
        NSLog(@"Current state: CheckWithCloud");
        
        self.noInternetButtonOutlet.hidden = YES;

        [self updateStatusLabel:@"Connecting to Simgo..."];
        
        [self sendTripStatusRequest];
    }
    else
    {
        NSLog(@"Current state: WaitingForInternetConnection");
        [self updateStatusLabel:@"Waiting for Internet connection..."];
        [self performSelector:@selector(showNoInternetButton) withObject:nil afterDelay:3];
    }
    
    self.debouncer = NO;
}

-(void)sendTripStatusRequest
{
    if (self.isRequestPending == NO)
    {
        NSLog(@"Dispatching Trip status request");
        
        // Create trip status request.
        NSMutableURLRequest *request = [Utility prepareTripStatusRequest:[Preferences getTripId] status:[Utility generateTripStatusString]];
        
        // Create url connection and fire request
        NSHTTPURLResponse * response = nil;
        NSError * error = nil;
        NSData * data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (error != nil)
        {
            NSLog(@"Error: %@", error);
            
            if (error.code == -1012)
            {
                [self handleExpiredSessionKey];
            }
            else
            {
                NSLog(@"Posting pending FindCurrentState request");
                
                //Retry
                self.isRequestPending = YES;
                [self performSelector:@selector(postPendingFindCurrentStateRequest) withObject:nil afterDelay:3];
            }
        }
        else
        {
            NSLog(@"Received trip status response");
            
            NSInteger responseStatusCode = [response statusCode];
            
            if (responseStatusCode == 401)
            {
                [self handleExpiredSessionKey];
            }
            else if (responseStatusCode == 400)
            {
                [Utility showAlertDialog:@"Invalid server request"];
            }
            else if (responseStatusCode == 412)
            {
                NSLog(@"Trip doesn't exist");
                [Preferences setTripId:UNDEFINED];
                [self pushView:@"StartTripViewController" animated:YES];
            }
            else
            {
                NSDictionary *tripStatusResponse = [Utility parseTripStatusResponse:data statusCode:[response statusCode]];
                [self processTripStatusResponse:tripStatusResponse];
            }
        }
    }
    else
    {
        NSLog(@"Status request already pending. Skipping");
    }
}

- (void) handleExpiredSessionKey
{
    NSLog(@"Session key expired");
    [Preferences setLoggedInStatus:LOGGED_OUT];
    [Utility showAlertDialog:@"Session key expired" message:@"Your phone number must be re-validated." delegate:nil otherButtonTitles:nil];
    [self pushView:@"LoginViewController" animated:YES];
}


- (void)postPendingFindCurrentStateRequest
{
    NSLog(@"Executing pending FindCurrentState request");
    self.isRequestPending = NO;
    [self findCurrentState];
}

- (void)processInternetConnectivityChangedEvent:(NSNotification*)_notification
{
    NSLog(@"InternetConnectivityChangedEvent");
    
    if([Utility getMcc] == 0)
    {
        [self updateStatusLabel:@"Waiting for SIM..."];
    }
    else if(self.savedInternetState != [Utility isInternetReachable])
    {
        [super processInternetConnectivityChangedEvent:_notification];
        
        if ([Utility isInternetReachable])
        {
            [self updateStatusLabel:@"Connecting to Simgo..."];

            [self findCurrentState];
        }
        else
        {
            [self updateStatusLabel:@"Waiting for Internet connection..."];
        }
    }
}

- (void)processSimChangedEvent:(CTCarrier *) carrier
{
    NSLog(@"SIM changed");
    
    self.savedMcc = [Utility getMcc];
    self.savedMnc = [Utility getMnc];
    [super processSimChangedEvent:carrier];
    
    if([Utility getMcc] == 0)
    {
        [self updateStatusLabel:@"Waiting for SIM..."];
        self.noInternetButtonOutlet.hidden = YES;
    }
    else
    {
        [self findCurrentState];
    }
}

- (void)updateStatusLabel:(NSString *)text
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentStatusLabel.text = text;
    });
}

-(void) processTripStatusResponse:(NSDictionary *)tripStatusResponse
{
    if (tripStatusResponse != nil || [Utility getMcc] == 0)
    {
        @try
        {
            NSArray *simHeuristicsResult = [Utility simHeuristics:tripStatusResponse];
            
            SimStatus simStatus = [simHeuristicsResult[0] intValue];
            int overallAllocations = [simHeuristicsResult[1] intValue];
            
            if (simStatus == USING_HSIM)
            {
                [self usingHsim:overallAllocations];
            }
            else if (simStatus == USING_RSIM)
            {
                //Using RSIM
                //In case usage is NOT near/over plan limit display SimgoSim view
                if ([Preferences getCallsUsageState] == WITHIN_PLAN_LIMITS && [Preferences getDataUsageState] == WITHIN_PLAN_LIMITS)
                {
                    [self pushView:@"SimgoSimViewController" animated:YES];
                }
                //overwise push SimgoSim view to stack and display Usage view
                else
                {
                    //Push 'Simgo SIM' and 'Usage' views to stack (so Back button in 'Usage' will pop up 'SIMGO SIM')
                    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                    UIViewController *simgoSimViewController =[storyboard instantiateViewControllerWithIdentifier:@"SimgoSimViewController"];
                    NSMutableArray* viewControllers = [NSMutableArray arrayWithCapacity:2];
                    [viewControllers addObject:simgoSimViewController];
                    
                    UIViewController *usageViewController = [storyboard instantiateViewControllerWithIdentifier:@"UsageViewController"];
                    [viewControllers addObject:usageViewController];
                    [self.navigationController setViewControllers:[NSArray arrayWithArray:viewControllers] animated:YES];
                }
            }
            else if (self.isRequestPending == NO)
            {
                //something went wrong. Try again
                self.isRequestPending = YES;
                [self performSelector:@selector(postPendingFindCurrentStateRequest) withObject:nil afterDelay:3];
            }
        }
        @catch (NSException * e)
        {
            NSLog(@"Exception: %@", e);
            [Utility showAlertDialog:@"Can't determine current connection state"];
        }
    }
    else
    {
        NSLog(@"No SIM or empty Trip status response");
        
        self.isRequestPending = YES;
        [self performSelector:@selector(postPendingFindCurrentStateRequest) withObject:nil afterDelay:3];
    }
}

- (void) usingHsim:(int)overallAllocations
{
    //check if user was abroad and returned home
    if (overallAllocations > 0)
    {
        [self pushView:@"TurnOffCallForwardingViewController" animated:YES];
    }
    //check if calls were forwarded
    else if([Preferences getCallsForwardedFlag] == YES)
    {
        //calls forwarded & using HSIM. Jump to 'Have a safe trip' view
        [self pushView:@"SafeTripViewController" animated:YES];
    }
    else
    {
        //calls NOT forwarded & using HSIM. Jump to 'Forward my calls' view
        [self pushView:@"CallForwardingViewController" animated:YES];
    }
}

- (void)processAppEnteringForegroundEvent:(NSNotification*)_notification
{
    NSLog(@"Entering ForegroundEvent");
    
    if (self.debouncer == NO)
    {
        [self performSelector:@selector(findCurrentState) withObject:nil afterDelay:0.1];
    }
}

- (void) popToRootViewController:(BOOL)animated
{
    //already at Root view
}

- (void) showNoInternetButton
{
    if ([Utility isInternetReachable] == NO && [Utility isMobileDataConfigValid] == YES)
    {
        self.noInternetButtonOutlet.hidden = NO;
    }
    else
    {
        NSLog(@"Conditions for jump to APN Configurator are not met");
    }
}

- (IBAction)noInternetButtonClick:(id)sender
{
    [self performSegueWithIdentifier: @"sequeToApnConfiguration" sender: self];
}

-(void)mobileDataConfigUpdated
{
    NSLog(@"Mobile Data Config Updated");
    
    if ([Utility isInternetReachable] == NO && [Utility isMobileDataConfigValid] == YES)
    {
        [self performSegueWithIdentifier: @"sequeToApnConfiguration" sender: self];
    }
    else
    {
        NSLog(@"Conditions for jump to APN Configurator are not met");
    }
}

@end
