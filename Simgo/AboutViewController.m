//
//  AboutViewController.m
//  Simgo
//
//  Created by Felix on 18/11/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import "AboutViewController.h"
#import "Definitions.h"
#import "Utility.h"
#import "Preferences.h"

@interface AboutViewController ()
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UIButton *supportPhoneNumberTitle;
@property (weak, nonatomic) IBOutlet UIButton *supportEmailTitle;
@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (weak, nonatomic) IBOutlet UILabel *cloudLabel;
@property (weak, nonatomic) IBOutlet UIButton *supportSkypeTitle;
@property (weak, nonatomic) IBOutlet UIButton *supportWhatsappTitle;
@property (weak, nonatomic) IBOutlet UIButton *logoutButtonLabel;

- (IBAction)logoutButton:(id)sender;
- (IBAction)supportEmailButton:(id)sender;
- (IBAction)supportPhoneNumberButton:(id)sender;
- (IBAction)backButton:(id)sender;

@property NSString *supportPhoneNumber;
@property NSString *supportEmailAddress;

@property int savedMcc;
@property int savedMnc;
@property UINavigationController* navController;

@end

@implementation AboutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    //set background image
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"applicaton_background.png"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    
    self.versionLabel.text = [NSString stringWithFormat:@"%@%@", @"Version: ", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    
    if ([Preferences getSupportPhone] != nil && [[Preferences getSupportPhone] length] > 0)
    {
        self.supportPhoneNumber = [Preferences getSupportPhone];
    }
    else
    {
        self.supportPhoneNumber = SUPPORT_PHONE_NUMBER;
    }
    
    if ([Preferences getSupportEmail] != nil && [[Preferences getSupportEmail] length] > 0)
    {
        self.supportEmailAddress = [Preferences getSupportEmail];
    }
    else
    {
        self.supportEmailAddress = SUPPORT_EMAIL;
    }
    
    [self addUnderlineTitle:self.supportPhoneNumberTitle title:self.supportPhoneNumber];
    [self addUnderlineTitle:self.supportEmailTitle title:self.supportEmailAddress];
    
    
    if ([Preferences getSupportSkype] != nil && [[Preferences getSupportSkype] length] > 0)
    {
        [self.supportSkypeTitle setTitle: [Preferences getSupportSkype] forState: UIControlStateNormal];
    }
    if ([Preferences getSupportWhatsapp] != nil && [[Preferences getSupportWhatsapp] length] > 0)
    {
        [self.supportWhatsappTitle setTitle: [Preferences getSupportWhatsapp] forState: UIControlStateNormal];
    }
    
    if ([Preferences getUserName] == nil || [[Preferences getUserName] length] == 0 || [Preferences getLoggedInStatus] != LOGGED_IN)
    {
        self.userLabel.text = @"";
    }
    else
    {
        self.userLabel.text = [NSString stringWithFormat:@"%@: %@", [Preferences getUserName], [Preferences getUserPhoneNumber]];
    }
    
    NSString *savedUserCloud = [Preferences getUserCloud];
    if (savedUserCloud != nil && [savedUserCloud compare:@"eos.simgo.me" options:NSCaseInsensitiveSearch] != NSOrderedSame)
    {
        self.cloudLabel.hidden = NO;
        self.cloudLabel.text = savedUserCloud;
    }
    
    self.navController = self.navigationController;
}

-(void)viewWillAppear:(BOOL)animated
{
    NSLog(@"viewWillAppear");
    
    [super viewWillAppear:(BOOL)animated];
    
    self.savedMcc = [Utility getMcc];
    self.savedMnc = [Utility getMnc];
    
    if ([Preferences getLoggedInStatus] != LOGGED_IN)
    {
        self.logoutButtonLabel.hidden = YES;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)addUnderlineTitle:(UIButton *)button title:(NSString *)title
{
    NSMutableAttributedString *supportNumber = [[NSMutableAttributedString alloc] initWithString:title];
    
    [supportNumber addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:NSMakeRange(0, [supportNumber length])];
    [supportNumber addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:65.0/255.0 green:155.0/255.0 blue:220.0/255.0 alpha:1] range:NSMakeRange(0, [supportNumber length])];
    [button setAttributedTitle:supportNumber forState:UIControlStateNormal];
}

- (IBAction)logoutButton:(id)sender
{
    NSString *title = [NSString stringWithFormat:@"Warning"];
    
    [Utility showAlertDialog:title message:@"Logging back in will require inserting your SIM card into your phone and re-verifying your phone number.\n Are you sure you want to logout?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK" tag:nil];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if([title isEqualToString:@"OK"])
    {
        NSLog(@"Logout confirmed. Executing.");
        
        // update login status
        [Preferences setLoggedInStatus:LOGGED_OUT];
        
        // return to login view
        [self pushView:@"LoginViewController" animated:YES];
    }
}


- (IBAction)supportEmailButton:(id)sender
{
    NSLog(@"Email support button pressed");
    
    /* create mail subject */
    NSString *userName = [Preferences getUserName];
    NSString *subject;
    if (userName != nil && [userName length] > 0)
    {
        subject = [NSString stringWithFormat:@"Support request from %@", userName];
    }
    else
    {
        subject = @"Enter your name here";
    }
    
    NSString *body = @"I have a problem with ....";
    
    /* define email address */
    NSString *mail = self.supportEmailAddress;
    
    /* create the URL */
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"mailto:?to=%@&subject=%@&body=%@",
                                                [mail stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                                                [subject stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                                                [body stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
    
    /* load the URL */
    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction)supportPhoneNumberButton:(id)sender
{
    NSLog(@"Call support button pressed");
    
    NSString *dialingString = [NSString stringWithFormat:@"tel://%@", self.supportPhoneNumber];
    
    NSURL *url = [NSURL URLWithString:dialingString];
    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction)backButton:(id)sender
{
    if (self.savedMcc != [Utility getMcc] || self.savedMnc != [Utility getMnc])
    {
        NSLog(@"Sim changed. Refreshing View.");
        
        UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *viewToPush =[storyboard instantiateViewControllerWithIdentifier:@"SplashScreenViewController"];
        
        NSMutableArray* viewControllers = [NSMutableArray arrayWithCapacity:1];
        [viewControllers addObject:viewToPush];
        [self.navigationController setViewControllers:[NSArray arrayWithArray:viewControllers] animated:YES];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}
@end
