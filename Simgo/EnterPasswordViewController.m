//
//  EnterPasswordViewController.m
//  Simgo
//
//  Created by Felix on 12/10/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import "EnterPasswordViewController.h"
#import "MBProgressHUD.h"
#import "Utility.h"
#import "Definitions.h"
#import "Preferences.h"

@interface EnterPasswordViewController ()
- (IBAction)enterPassword:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *passwordTxtField;
@property NSURLConnection *loginConnection;
@property NSURLConnection *verifyLoginConnection;
@property NSURLResponse *lastHttpResponse;


@end

@implementation EnterPasswordViewController

- (void)viewDidLoad
{
    self.viewName = @"EnterPasswordViewController";

    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    //get User phone number from preferences
    self.userPhoneNumber = [Preferences getUserPhoneNumber];
    
    //display user phone number in title
    self.title = self.userPhoneNumber;
    
    //change TxtField placeholder text color
    UIColor *color = [UIColor lightGrayColor];
    self.passwordTxtField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Enter Verification Code" attributes:@{NSForegroundColorAttributeName: color}];
    
    NSLog(@"User phone number: %@", self.userPhoneNumber);
    
    //show keyboard
    [self.passwordTxtField becomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(passwordChangedNotification:) name:@"PASSWORD_UPDATED" object: nil];

    //check if password was received while view was not active
    [self passwordChangedNotification:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:(BOOL)animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PASSWORD_UPDATED" object:nil];
}

-(void)passwordChangedNotification:(NSNotification*)_notification
{
    NSString *password = [Preferences getUserPassword];
    
    NSLog(@"User password: %@", password);
    if (password != nil && [password length] >= MIN_PASSWORD_LENGTH)
    {
        self.passwordTxtField.text = password;
        [self validatePassword:password];
    }
}

//hide keyboard
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.passwordTxtField resignFirstResponder];
}

//user entered the password. Start phase II verification
- (IBAction)enterPassword:(id)sender {
    
    if (self.userPhoneNumber == nil || [self.userPhoneNumber length]  < MIN_PHONE_NUMBER_LENGTH)
    {
        [Utility showAlertDialog:@"Something went wrong. Please try again"];
    }
    else
    {
        //clear whitespaces from password
        NSString *password = [self.passwordTxtField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        [self validatePassword:password];
    }
}

- (void)validatePassword:(NSString *)password
{
    //check if password is valid
    if(password != nil && [password length] >= MIN_PASSWORD_LENGTH)
    {
        //password valid. Send to Cloud
        
        NSLog(@"Verifying password [%@]", password);
        
        //check if Internet is available
        if ([Utility isInternetReachable] == YES)
        {
            //hide keyboard
            [self.passwordTxtField resignFirstResponder];
            
            [self performLogin:self.userPhoneNumber password:[password stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
            
            [Utility showBusyHud:@"Verifying..." view:self.view];
        }
        else
        {
            [Utility showAlertDialog:@"No Internet connection"];
        }
    }
    else
    {
        //password not valid. Display error message
        [Utility showAlertDialog:@"Please enter valid password"];
    }
}

- (void)performLogin:(NSString *)userPhoneNumber password:(NSString *)userPassword
{
    // Prepare and send Phase II login request to Cloud.
    NSMutableURLRequest *request = [Utility prepareLoginRequest:userPhoneNumber country:[Preferences getUserCountryCode] password:userPassword];
    
    // Create url connection and fire request. Connection is saved to distinguish between login request and login verification responses
    self.loginConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

//Verify login was successful
- (void)verifyCloudConnection:(NSString *)userPhoneNumber
{
    // Create the request.
    NSString *urlString = [NSString stringWithFormat: @"%@/users/session?hnum=%@",[Utility getCloudAddress], userPhoneNumber];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    //update header with auth session key
    NSDictionary * headers = [Utility getHeadersWithSessionKey];
    [request setAllHTTPHeaderFields:headers];
    
    request.HTTPMethod = @"GET";
    
    // Create url connection and fire request. Connection is saved to distinguish between login request and login verification responses
    self.verifyLoginConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}


#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    
    [super connection:connection didReceiveResponse:response];
   
    //save response to enable session key extraction once login verification succeed.
    self.lastHttpResponse = response;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // The request is complete and data has been received
    
    //[super connectionDidFinishLoading:connection];
    
    //find if this is login or login verification response
    if (connection == self.loginConnection)
    {
        [self parseLoginResponse:_responseData];
    }
    else if (connection == self.verifyLoginConnection)
    {
        [Utility hideHud:self.view];
        [self parseLoginVerificationResponse:_responseData];
    }
}

- (void)parseLoginResponse:(NSMutableData *) responseData
{
    NSLog(@"Login response");
    
    NSError *jsonParsingError = nil;
    bool hideHud = YES;
    
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
        //json parse successfully. Extract parameters.
        NSString *error = responseJson[@"error"];
        NSDictionary *internalJson = responseJson[@"object"];

        if (error != nil)
        {
            //login request succeded but Cloud returned an error. Show error message
            [Utility showAlertDialog:error];
            [Preferences setUserPassword:nil];
        }
        else if (internalJson != nil)
        {
            //parse login phase (sanity check)
            int phase = [internalJson[@"login_phase"] intValue];
            if (phase == 2)
            {
                NSLog(@"Logged In");
                
                //extract incoming phone number
                NSString *formatedPhoneNumber = internalJson[@"formated_number"];
                if(formatedPhoneNumber != nil)
                {
                    //save incoming phone number
                    [Preferences setUserPhoneNumber:formatedPhoneNumber];
                    self.userPhoneNumber = formatedPhoneNumber;
                }
                
                //Login Phase II. Everything Ok. Moving on.
                
                //extract user name
                [Preferences setUserName:internalJson[@"user_name"]];
                //save session key
                [Utility saveSessionKey:self.lastHttpResponse];
                //verify cloud connection
                [self verifyCloudConnection:self.userPhoneNumber];
                [Preferences setUserPassword:nil];
                hideHud = NO;
            }
            else
            {
                [Utility showAlertDialog:@"Invalid server response. Please contact tech support."];
            }
        }
        else
        {
            //Invalid response. Show error message
            [Utility showAlertDialog:@"Failed to parse server response"];
        }
        
        if (hideHud)
        {
            [Utility hideHud:self.view];
        }
    }
}

//verify connection to cloud with auth key
- (void)parseLoginVerificationResponse:(NSMutableData *) responseData
{
    NSLog(@"LoginVerification response");
    
    NSString* responseStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    
    //parse response json
    NSError *jsonParsingError = nil;
    NSDictionary *responseJson = [NSJSONSerialization JSONObjectWithData:_responseData options:NSJSONReadingMutableContainers error:&jsonParsingError];
    
    //check if json parsing succeed
    if (jsonParsingError != nil)
    {
        NSLog(@"JSON error: %@", jsonParsingError);
    }
    else
    {
        NSString *error = responseJson[@"error"];
        if (error != nil)
        {
            //Cloud returned an error. Show error message
            [Utility showAlertDialog:error];
        }
        else if ([responseStr  isEqual: @"{}"])
        {
            NSLog(@"Verification completed successfully");
            
            //update loggin status
            [Preferences setLoggedInStatus:LOGGED_IN];
            
            [self performSegueWithIdentifier:@"SegueToStartTrip" sender:self];
        }
    }
}

@end
