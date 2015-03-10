//
//  ViewControllerWithHttp.m
//  Simgo
//
//  Created by Felix on 14/10/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import "ViewControllerWithHttp.h"
#import "MBProgressHUD.h"
#import "Reachability.h"
#import "Utility.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

@interface ViewControllerWithHttp ()
{
    Reachability *internetReachable;
}

@end

@implementation ViewControllerWithHttp

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    NSLog(@"%@ viewDidLoad", self.viewName);
    
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    //set background image
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"applicaton_background.png"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    
    self.isKeyboardVisible = NO;
    self.ignoreNoSim = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    NSLog(@"%@ viewWillAppear", self.viewName);
    
    [super viewWillAppear:(BOOL)animated];

    self.savedMcc = [Utility getMcc];
    self.savedMnc = [Utility getMnc];
    self.savedInternetState = [Utility isInternetReachable];
    
    [self.navigationController setNavigationBarHidden:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processAppEnteringForegroundEvent:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processInternetConnectivityChangedEvent:) name:kReachabilityChangedNotification object:nil];
    
    internetReachable = [Reachability reachabilityForInternetConnection];
    [internetReachable startNotifier];
    
    self.simPollingTimer = [NSTimer scheduledTimerWithTimeInterval:SIM_STATUS_POLLING_TIMER target:self selector:@selector(timerTicked:) userInfo:nil repeats:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    NSLog(@"%@ viewDidDisappear", self.viewName);

    NSLog(@"%@ Timer stopped", self.viewName);
    [self.simPollingTimer invalidate];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [internetReachable stopNotifier];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [super viewDidDisappear:(BOOL)animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)timerTicked:(NSTimer*)timer
{
    int currentMcc = [Utility getMcc];
    int currentMnc = [Utility getMnc];
    
    //iOS "SIM change" notification doesn't fire on 'NO SIM' condition. Will use polling instead.
    
    if (self.ignoreNoSim == YES && currentMcc <= 1)
    {
        return;
    }
    
    if (self.savedMcc != currentMcc || self.savedMnc != currentMnc)
    {
        CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
        CTCarrier *carrier = [netInfo subscriberCellularProvider];
        [self processSimChangedEvent:carrier];
    }
}

- (void)processAppEnteringForegroundEvent:(NSNotification*)_notification
{
    int currentMcc = [Utility getMcc];
    int currentMnc = [Utility getMnc];
    
    NSLog(@"%@ Entering ForeGroundEvent. MCC:%d, MNC:%d", self.viewName, currentMcc, currentMnc);
    
    if (self.ignoreNoSim == YES && currentMcc <= 1)
    {
        return;
    }

    if (self.savedMcc != currentMcc || self.savedMnc != currentMnc)
    {
        [self popToRootViewController:YES];
    }
}

- (void)processInternetConnectivityChangedEvent:(NSNotification*)_notification
{
    BOOL currentInternetState = [Utility isInternetReachable];
    
    if (self.savedInternetState == currentInternetState)
    {
        NSLog(@"Internet Connectivity Changed Event debouncer. Skipping");
    }
    else if ([Utility isInternetReachable])
    {
        NSLog(@"Internet status changed: Reachable");
    }
    else
    {
        NSLog(@"Internet status changed: NOT Reachable");
    }
    
    self.savedInternetState = currentInternetState;
}

- (void)processSimChangedEvent:(CTCarrier *) carrier
{
    NSLog(@"%@ Sim changed Event", self.viewName);
    int currentMcc = [Utility getMcc];
    int currentMnc = [Utility getMnc];
    
    NSLog(@"Current MCC:%d, MNC:%d", currentMcc, currentMnc);
    NSLog(@"Saved MCC:%d, MNC:%d", self.savedMcc, self.savedMnc);

    if (carrier == nil)
    {
        NSLog(@"Carrier state changed to NIL");
        self.savedMcc = 0;
        self.savedMnc = 0;
    }
    else
    {
        NSString *info = [NSString stringWithFormat:@"\ncarrierName: %@\nmobileNetworkCode: %@\n"
                          "mobileCountryCode: %@\nisoCountryCode: %@\nallowsVOIP: %d",
                          carrier.carrierName,
                          carrier.mobileNetworkCode,
                          carrier.mobileCountryCode,
                          carrier.isoCountryCode,
                          carrier.allowsVOIP];
        
        NSLog(@"%@", info);
        
        [self conditionalViewRefresh];
        
        self.savedMcc = [Utility getMcc];
        self.savedMnc = [Utility getMnc];
    }
}

- (void) popToRootViewController:(BOOL)animated
{
    NSLog(@"%@ Jumping to Root View Controller", self.viewName);
    //[self.navigationController popToRootViewControllerAnimated:animated];
    
//    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//    UIViewController *viewToPush =[storyboard instantiateViewControllerWithIdentifier:@"SplashScreenViewController"];
//    
//    NSMutableArray* viewControllers = [NSMutableArray arrayWithCapacity:1];
//    [viewControllers addObject:viewToPush];
//    [self.navigationController setViewControllers:[NSArray arrayWithArray:viewControllers] animated:animated];
    
    [self pushView:@"SplashScreenViewController" animated:animated];
}

- (void) pushView:(NSString *)viewIdentifier animated:(BOOL)animated
{
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *viewToPush =[storyboard instantiateViewControllerWithIdentifier:viewIdentifier];
    
    //[self.navigationController pushViewController:viewToPush animated:animated];
    
    NSMutableArray* viewControllers = [NSMutableArray arrayWithCapacity:1];
    [viewControllers addObject:viewToPush];
    [self.navigationController setViewControllers:[NSArray arrayWithArray:viewControllers] animated:animated];
  
}

- (void)conditionalViewRefresh
{
    NSLog(@"%@ Checking condition for View Refresh", self.viewName);
    int currentMcc = [Utility getMcc];
    int currentMnc = [Utility getMnc];
    
    if (self.ignoreNoSim == YES && currentMcc <= 1)
    {
        return;
    }
    
    if (self.savedMcc != currentMcc || self.savedMnc != currentMnc)
    {
        NSLog(@"Sim changed. Refreshing View.");
        
        [self refreshView];
    }
}

- (void)refreshView
{
    self.savedMcc = [Utility getMcc];
    self.savedMnc = [Utility getMnc];
    [self popToRootViewController:NO];
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    
    _responseData = [[NSMutableData alloc] init];
    
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    self.statusCode = [httpResponse statusCode];
    
    NSLog(@"Response received");
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
    [_responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    
    NSLog(@"Finished loading");
    
    //hide HUD
    [Utility hideHud:self.view];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    
    //Connection failed. Hide HUD and show an error dialog
    [Utility showAlertDialog:@"Internet Connectivity Error" message:nil delegate:self otherButtonTitles:nil];
    [Utility hideHud:self.view];
}


//Move view upwards to prevent keyboard from hiding TxtField
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if(self.isKeyboardVisible == NO)
    {
        [self animateTextField:textField up:YES];
        self.isKeyboardVisible = YES;
    }
}

//Restore original view when keyboard is hided
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if(self.isKeyboardVisible == YES)
    {
        [self animateTextField:textField up:NO];
        self.isKeyboardVisible = NO;
    }
}

//View animation
- (void) animateTextField: (UITextField*) textField up: (BOOL) up
{
    int screenHeight = (int)[UIScreen mainScreen].bounds.size.height - 20/*status bar*/ - 44/*navigation bar*/;
    
    int animatedDistance;
    //find lower corner of TxtField
    int moveUpValue = textField.frame.origin.y + textField.frame.size.height;
    //check orientation
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        animatedDistance = 216 -(screenHeight-moveUpValue-15);
    }
    else
    {
        //We use only Portrait view. These numbers should be tweeked to support navigation bar and etc.
        animatedDistance = 162-(320-moveUpValue-10);
    }
    
    if(animatedDistance>0)
    {
        //move the view
        const int movementDistance = animatedDistance;
        const float movementDuration = 0.3f;
        int movement = (up ? -movementDistance : movementDistance);
        [UIView beginAnimations: nil context: nil];
        [UIView setAnimationBeginsFromCurrentState: YES];
        [UIView setAnimationDuration: movementDuration];
        self.view.frame = CGRectOffset(self.view.frame, 0, movement);
        [UIView commitAnimations];
    }
}

//hide keyboard
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [textField resignFirstResponder];
    return YES;
}

@end
