//
//  StartTripViewController.m
//  Simgo
//
//  Created by Felix on 13/10/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import "StartTripViewController.h"
#import "MBProgressHUD.h"
#import "Utility.h"
#import "Preferences.h"

@interface StartTripViewController ()
- (IBAction)startTrip:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *scanBarcodeButton;
@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;
@property (weak, nonatomic) IBOutlet UITextField *simgoDeviceIdTxtField;

@end

@implementation StartTripViewController


- (void)viewDidLoad
{
    self.viewName = @"StartTripViewController";

    [super viewDidLoad];

    //restore Simgo Plug ID from preferences (if present) and update TxtField
    NSString *userPlugId = [Preferences getUserPlug];
    if (userPlugId != nil)
    {
        self.simgoDeviceIdTxtField.text = userPlugId;
    }
    else
    {
        //change TxtField placeholder text color
        UIColor *color = [UIColor lightGrayColor];
        self.simgoDeviceIdTxtField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Simgo Device ID" attributes:@{NSForegroundColorAttributeName: color}];
    }
    
    //Get and display user name
    NSString *userName = [Preferences getUserName];
    if (userName != nil)
    {
        //isolate first name (from the last)
        NSMutableArray *words = [NSMutableArray arrayWithArray:[userName componentsSeparatedByString:@" "]];

        if ([words count] > 0)
        {
            self.welcomeLabel.text = [NSString stringWithFormat:@"%@%@%@", @"Hi ", words[0], @"!"];
        }
        else
        {
            self.welcomeLabel.text = [NSString stringWithFormat:@"%@%@%@", @"Hi ", userName, @"!"];
        }
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        self.scanBarcodeButton.hidden = NO;
    }
    
    [Preferences setTripId:UNDEFINED];
}

//hide keyboard
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.simgoDeviceIdTxtField resignFirstResponder];
}

- (IBAction)startTrip:(id)sender {
    
    //hide keyboard
    [self.simgoDeviceIdTxtField resignFirstResponder];
    
    NSString *userPhoneNumber = [[NSUserDefaults standardUserDefaults] stringForKey:@"userPhoneNumber"];
    
    if (userPhoneNumber == nil || [userPhoneNumber length]  < 6)
    {
        //Invalid phone number. User must login again
        [Utility showAlertDialog:@"Something went wrong. Your phone number must be re-verified"];
        [self executeLogout];
    }
    else
    {
        NSString *userPlug = [self.simgoDeviceIdTxtField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        //check if user plud ID is valid
        if (userPlug != nil && [userPlug length] >= MIN_PLUG_ID_LENGTH && [userPlug length] <= MAX_PLUG_ID_LENGTH)
        {
             //save plug id for later use (this will also add '0' padding)
            [Preferences setUserPlug:userPlug];
            
            //get plug ID with padded '0'
            NSString *paddedUserPlugId =[Preferences getUserPlug];
            //update TxtField
            self.simgoDeviceIdTxtField.text = paddedUserPlugId;
            
            //check Internet connection
            if([Utility isInternetReachable] == YES)
            {
                [Preferences setPendingDeleteTripId:UNDEFINED];
                
                // Create the request.
                NSString *urlString = [NSString stringWithFormat: @"%@/trips", [Utility getCloudAddress]];
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
                
                // Specify that it will be a POST request
                request.HTTPMethod = @"POST";
                [request setHTTPShouldHandleCookies:NO];
                
                // Set header fields
                [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
                
                NSString *jsonRequest = [NSString stringWithFormat:@"{\"hnum\":\"%@\", \"plug_id\":\"%@\", %@}", userPhoneNumber, [paddedUserPlugId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]], [Utility getUserInfoJson]];

                // Add json to request body
                NSData *requestBodyData = [NSData dataWithBytes:[jsonRequest UTF8String] length:[jsonRequest length]];
                request.HTTPBody = requestBodyData;
                
                // Define timeout
                [request setTimeoutInterval:10.0];
                
                // Set user's auth (session) key
                NSDictionary * headers = [Utility getHeadersWithSessionKey];
                [request setAllHTTPHeaderFields:headers];
                
                // Create url connection and fire request
                [NSURLConnection connectionWithRequest:request delegate:self];
                
                [Utility showBusyHud:@"Starting Trip..." view:self.view];
            }
            else
            {
                [Utility showAlertDialog:@"No Internet connection"];
            }
        }
        else
        {
            [Utility showAlertDialog:@"Please enter valid Simgo device ID"];
        }
    }
}

- (void)executeLogout
{
    // update login status
    [Preferences setLoggedInStatus:LOGGED_OUT];
    // return to login view
    //[self popToRootViewController:YES];
    [self pushView:@"LoginViewController" animated:YES];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    
    //skip 'super' because 'parseStartTripResponse' may perform additional 'TripStatus' request. Thus, HUD should be hidden only after 'parseStartTripResponse' is finished
    //[super connectionDidFinishLoading:connection];
    [self parseStartTripResponse:_responseData];
}

- (void)parseStartTripResponse:(NSMutableData *) responseData
{
    NSLog(@"Cloud response");
    
    if (self.statusCode == 401)
    {
        NSLog(@"Session key expired");
        [Preferences setLoggedInStatus:LOGGED_OUT];
        [Utility showAlertDialog:@"Session key expired" message:@"Your phone number must be re-validated." delegate:nil otherButtonTitles:nil];
        [self pushView:@"LoginViewController" animated:YES];
    }
    else if (self.statusCode == 412)
    {
        NSLog(@"Account not found");
        [Preferences setLoggedInStatus:LOGGED_OUT];
        [Utility showAlertDialog:@"Your user account is no longer exist"];
        [self pushView:@"LoginViewController" animated:YES];
    }
    else
    {
        NSError *jsonParsingError = nil;
        
        //parse response json
        NSDictionary *responseJson = [NSJSONSerialization JSONObjectWithData:_responseData options:NSJSONReadingMutableContainers error:&jsonParsingError];
        
        //check if json parsing succeed
        if (jsonParsingError != nil)
        {
            NSLog(@"JSON error: %@", jsonParsingError);
            [Utility showAlertDialog:@"Failed to parse server respose"];
        }
        else
        {
            //json parsed successfully. Extract parameters.
            
            [Utility parseSupportInfo:responseJson];
            
            NSString *error = responseJson[@"error"];
            NSDictionary *internalJson = responseJson[@"object"];
            if (error != nil)
            {
                //start trip request succeded but Cloud returned an error. Show error message
                [Utility showAlertDialog:error];
            }
            else if (internalJson != nil)
            {
                //parse trip ID and Access number
                NSString *accessNumber = internalJson[@"access_number"];
                NSNumber *trip =internalJson[@"trip_id"];
                
                if(accessNumber != nil && trip != nil)
                {
                    //save Access number in preferences
                    [Preferences setIncomingAccessNumber:accessNumber];
                    NSLog(@"IAN: %@", accessNumber);
                    
                    //save plug ID in preferences
                    int tripId = [trip intValue];
                    [Preferences setTripId:tripId];
                    [Preferences setTripDataUsage:0.0];
                    [Preferences setPendingDeleteTripId:UNDEFINED];

                    //clear call forwarding flag
                    [Preferences setCallsForwardedFlag:NO];
                    
                    NSLog(@"Trip Started. TripID: %d, IAN: %@", [Preferences getTripId], [Preferences getIncomingAccessNumber]);
                    
                    SimStatus simStatus = [self getCurrentSimStatus];
                    
                    if (simStatus == USING_RSIM)
                    {
                        [self pushView:@"SimgoSimViewController" animated:YES];
                    }
                    else if (simStatus == USING_FSIM)
                    {
                        [self pushView:@"SimgoUnavailableViewController" animated:YES];
                    }
                    else
                    {
                        [self performSegueWithIdentifier: @"FromStartTripToCf" sender: self];
                    }
                }
                else
                {
                    //either trip ID or access number is missing. Display error message
                    [Utility showAlertDialog:@"Invalid server response. Please contact tech support."];
                }
            }
            else
            {
                //Invalid response. Show error message
                [Utility showAlertDialog:@"Failed to parse server response"];
            }
        }
    }
    
    //hide HUD
    [Utility hideHud:self.view];
}

-(SimStatus) getCurrentSimStatus
{
    NSMutableURLRequest *urlRequest = [Utility prepareTripStatusRequest:[Preferences getTripId] status:[Utility generateTripStatusString]];
    NSHTTPURLResponse * response = nil;
    NSError * error = nil;
    NSData * data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    
    if (error != nil)
    {
        NSLog(@"Cloud Status Error");
    }
    else
    {
        NSDictionary *tripStatusResponse = [Utility parseTripStatusResponse:data statusCode:[response statusCode]];
        NSArray *simHeuristicsResult = [Utility simHeuristics:tripStatusResponse];
        return [simHeuristicsResult[0] intValue];
    }
    
    return SIM_UNKNOWN;
}

- (IBAction)helpButton:(id)sender {
}
@end
