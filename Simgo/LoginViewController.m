//
//  SimgoViewController.m
//  Simgo
//
//  Created by Felix on 11/10/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import "LoginViewController.h"
#import "MBProgressHUD.h"
#import "Utility.h"
#import "StartTripViewController.h"
#import "CallforwardingViewController.h"
#import "Preferences.h"


@interface LoginViewController ()
- (IBAction)verifyPhoneNumber:(id)sender;
- (IBAction)selectCountry:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *internationalFormatWarning;
@property (weak, nonatomic) IBOutlet UIButton *countrySelector;
@property (weak, nonatomic) IBOutlet UITextField *phoneNumberTxtField;
@property (weak, nonatomic) IBOutlet UITextField *countryBackgroundTxtField;

@end

@implementation LoginViewController

NSInteger CONFIRM_HNUM_ALERT_DIALOG = 1;
NSInteger NO_SIM_ALERT_DIALOG = 2;
NSInteger RSIM_IN_USE_ALERT_DIALOG = 3;

- (void)viewDidLoad
{
    self.viewName = @"LoginViewController";
    [super viewDidLoad];
    
    self.navigationItem.hidesBackButton = YES;
    [Preferences setLoggedInStatus:LOGGED_OUT];
    [Preferences setUserPassword:nil];
    
    [self initTxtFields];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self initTxtFields];
    
    if (self.isKeyboardVisible == YES)
    {
        self.isKeyboardVisible = NO;
        [self.view endEditing:YES];
    }
}

- (void)initTxtFields
{
    //Restore previous User country and phone number (if present)
    
    //User country selector is composed from Button which triggers Countries Table View and underlaying TxtField used for placeholder text and background image
    NSString *userCountry = [Preferences getUserCountry];
    
    if (userCountry != nil)
    {
        //Previous User country found. Clear placeholder text and update Button text to the country name
        [self.countrySelector setTitle:userCountry forState:UIControlStateNormal];
        self.countryBackgroundTxtField.text = @" ";
    }
    else
    {
        //Country not found set underlaying Txtview placeholder
        self.countryBackgroundTxtField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Your Phone Number" attributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor]}];
    }
    
    self.internationalFormatWarning.hidden = (userCountry != nil && (BOOL)[userCountry compare:@"Other" options:NSCaseInsensitiveSearch]);
    
    //Restore previous phone number (if found)
    NSString *savedUserNumber = [Preferences getUserPhoneNumber];
    
    if (savedUserNumber != nil)
    {
        NSString *cloudPrefix = @"";
        
        NSString *savedUserCloud = [Preferences getUserCloud];
        if (savedUserCloud == nil || [savedUserCloud compare:@"eos.simgo.me" options:NSCaseInsensitiveSearch] == NSOrderedSame)
        {
            cloudPrefix = @"";
        }
        else if ([savedUserCloud compare:@"dev.gimso.net" options:NSCaseInsensitiveSearch] == NSOrderedSame)
        {
            cloudPrefix = @",,,";
        }
        else if ([savedUserCloud compare:@"qa.gimso.net" options:NSCaseInsensitiveSearch] == NSOrderedSame)
        {
            cloudPrefix = @",,";
        }
        else if ([savedUserCloud compare:@"staging.gimso.net" options:NSCaseInsensitiveSearch] == NSOrderedSame)
        {
            cloudPrefix = @",";
        }
        
        self.phoneNumberTxtField.text = [NSString stringWithFormat:@"%@%@", cloudPrefix, savedUserNumber];
    }
    else
    {
        self.phoneNumberTxtField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Your Phone Number" attributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor]}];
    }
}

-(NSString *)extractCloudNameAndRemovePrefix:(NSString *)rawNumber
{
    if (rawNumber == nil || rawNumber.length < 4)
    {
        return rawNumber;
    }
    
    NSString* output = rawNumber;
    if([rawNumber hasPrefix:@",,,"])
    {
        output = [rawNumber substringFromIndex:3];
        [Preferences setUserCloud:@"dev.gimso.net"];
    }
    else if ([rawNumber hasPrefix:@",,"])
    {
        output = [rawNumber substringFromIndex:2];
        [Preferences setUserCloud:@"qa.gimso.net"];
    }
    else if ([rawNumber hasPrefix:@","])
    {
        output = [rawNumber substringFromIndex:1];
        [Preferences setUserCloud:@"staging.gimso.net"];
    }
    else
    {
        [Preferences setUserCloud:@"eos.simgo.me"];
    }
    
    return output;
}

//hide keyboard when touched outside of TxtField
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.phoneNumberTxtField resignFirstResponder];
}

- (IBAction)verifyPhoneNumber:(id)sender
{
    //get user phone number from TxtField and filter whitespaces
    NSString *numberWithoutCloudPrefix = [self extractCloudNameAndRemovePrefix:self.phoneNumberTxtField.text];
    self.userPhoneNumber = [numberWithoutCloudPrefix stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    //check if phone number length is greater than minimum
    if(self.userPhoneNumber != nil && [self.userPhoneNumber length] >= MIN_PHONE_NUMBER_LENGTH)
    {
        //hide keyboard
        [self.phoneNumberTxtField resignFirstResponder];
        
        //save user phone number in preferences
        [Preferences setUserPhoneNumber:self.userPhoneNumber];

        //check if Internet is available
        if ([Utility isInternetReachable] == NO)
        {
            //No Internet show alert
            [Utility showAlertDialog:@"No Internet connection"];
        }
        else if ([Utility getMcc] <= 1)
        {
            [Utility showAlertDialog:@"Connection to cellular network is needed for phone number verificaiton" message:nil delegate:self cancelButtonTitle:@"Enter manually" otherButtonTitles:@"OK" tag:&NO_SIM_ALERT_DIALOG];
        }
        else
        {
            //Internet is present. Start verification
            
            NSString *title = [NSString stringWithFormat:@"NUMBER CONFIRMATION\n\n%@", self.userPhoneNumber];
            
            [Utility showAlertDialog:title message:@"\nPlease confirm your phone number" delegate:self cancelButtonTitle:@"Edit" otherButtonTitles:@"Confirm" tag:&CONFIRM_HNUM_ALERT_DIALOG];
        }
    }
    else
    {
        //User phone number is not valid. Show alert
        [Utility showAlertDialog:@"Please enter valid phone number"];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    NSInteger alertViewType = alertView.tag;
    
    if (alertViewType == CONFIRM_HNUM_ALERT_DIALOG)
    {
        if([title isEqualToString:@"Confirm"])
        {
            NSLog(@"Verifying phone number = %@", self.userPhoneNumber);
            
            [Preferences setUserPassword:nil];
            
            [self performLogin:self.userPhoneNumber];
            [Utility showBusyHud:@"Verifying..." view:self.view];
        }
    }
    else if (alertViewType == NO_SIM_ALERT_DIALOG || alertViewType == RSIM_IN_USE_ALERT_DIALOG)
    {
        if([title isEqualToString:@"Enter manually"])
        {
            NSLog(@"Manuall login. Skipping SMS");
            
            [Preferences setUserPassword:nil];
            
            //Login Phase I. Everything Ok. Moving on.
            [Preferences setLoggedInStatus:WAITING_FOR_SMS];
            [self performSegueWithIdentifier:@"SegueToEnterPassword" sender:self];
        }
    }
}

- (IBAction)selectCountry:(id)sender
{
    //User selected 'Countries table view'.

    //Save user phone number for later user
    [Preferences setUserPhoneNumber:[self extractCloudNameAndRemovePrefix:self.phoneNumberTxtField.text]];
    
    //Jump to 'Countries table view'
    [self.phoneNumberTxtField resignFirstResponder];
    [self performSegueWithIdentifier:@"SegueToCountryList" sender:self];
}

- (void)performLogin:(NSString *)userPhoneNumber
{
    //Save current user network codes (will be used later to find out if HSIM or RSIM is used)
    [Preferences setUserHomeMcc:[Utility getMcc]];
    [Preferences setUserHomeMnc:[Utility getMnc]];
    
    // Create login request.
    NSMutableURLRequest *request = [Utility prepareLoginRequest:userPhoneNumber country:[Preferences getUserCountryCode] password:nil];
    
    // Create url connection and fire request
    [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // The request is complete and data has been received
    [super connectionDidFinishLoading:connection];

    //parse login response
    [self parseLoginResponse:_responseData];
}

- (void)parseLoginResponse:(NSMutableData *) responseData
{
    NSLog(@"Cloud response");
    
    NSError *jsonParsingError = nil;
    
    //parse response json
    NSDictionary *responseJson = [NSJSONSerialization JSONObjectWithData:_responseData options:NSJSONReadingMutableContainers error:&jsonParsingError];
    
    //check if json parsing failed
    if (jsonParsingError != nil)
    {
        NSLog(@"JSON error: %@", jsonParsingError);
        [Utility showAlertDialog:@"Failed to parse server respose"];
    }
    else
    {
        //json parsed successfully. Extract parameters.
        
        //Update support info
        [Utility parseSupportInfo:responseJson];
        
        NSString *error = responseJson[@"error"];
        NSDictionary *internalJson = responseJson[@"object"];
        
        if (error != nil)
        {
            //login request succeded but Cloud returned an error.
            
            //if login failed because RSIM is used. Display alert dialog with manuall login option
            if ([error compare:@"Can't verify phone number while Simgo SIM is in use" options:NSCaseInsensitiveSearch] == NSOrderedSame)
            {
                [Utility showAlertDialog:error message:nil delegate:self cancelButtonTitle:@"Enter manually" otherButtonTitles:@"OK" tag:&RSIM_IN_USE_ALERT_DIALOG];
            }
            else
            {
                //Show error message
                [Utility showAlertDialog:error];
            }
        }
        else if (internalJson != nil)
        {
            //extract incoming phone number
            NSString *formatedPhoneNumber = internalJson[@"formated_number"];
            if(formatedPhoneNumber != nil)
            {
                //save incoming phone number and update TxtField
                [Preferences setUserPhoneNumber:formatedPhoneNumber];
                self.userPhoneNumber = formatedPhoneNumber;
            }
            
            //extract login phase (sanity check)
            int phase = [internalJson[@"login_phase"] intValue];
            if (phase == 1)
            {
                //Login Phase I. Everything Ok. Moving on.
                [Preferences setLoggedInStatus:WAITING_FOR_SMS];
                [self performSegueWithIdentifier:@"SegueToEnterPassword" sender:self];
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
    }
}

@end
