//
//  FeedbackViewController.m
//  Simgo
//
//  Created by Felix on 25/11/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import "FeedbackViewController.h"
#import "RateView.h"
#import "Utility.h"
#import "Preferences.h"

@interface FeedbackViewController ()

@property (weak, nonatomic) IBOutlet RateView *internetSpeedRateView;
@property (weak, nonatomic) IBOutlet RateView *voiceQualityRateView;
@property (weak, nonatomic) IBOutlet RateView *serviceUptimeRateView;
@property (weak, nonatomic) IBOutlet RateView *satisfactionRateView;
@property (weak, nonatomic) IBOutlet UITextField *userFeedbackTextField;

- (IBAction)doneButton:(id)sender;
- (IBAction)sendFeedbackButton:(id)sender;
- (IBAction)skipButton:(id)sender;

@property BOOL isTouched;
@property BOOL feedbackDone;

@end

@implementation FeedbackViewController

- (void)viewDidLoad
{
    self.viewName = @"FeedbackViewController";

    [super viewDidLoad];
    
    self.navigationItem.hidesBackButton = YES;
    self.isTouched = NO;
    self.feedbackDone = NO;
    
    //init rate views (stars)
    [self initRateView:self.voiceQualityRateView];
    [self initRateView:self.internetSpeedRateView];
    [self initRateView:self.serviceUptimeRateView];
    [self initRateView:self.satisfactionRateView];
    
    self.userFeedbackTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@" Write your feedback here..." attributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor]}];
}

-(void)viewWillAppear:(BOOL)animated
{
    //if feedback was send, jump to 'Start trip'
    if (self.feedbackDone == YES)
    {
        [self pushView:@"StartTripViewController" animated:YES];
    }
    else
    {
        [super viewWillAppear:animated];
    }
}

- (void)processAppEnteringForegroundEvent:(NSNotification*)_notification
{
    //if feedback was send, jump to 'Start trip'
    if (self.feedbackDone == YES)
    {
        [self pushView:@"StartTripViewController" animated:YES];
    }
}

- (void)processSimChangedEvent:(CTCarrier *) carrier
{
    //do nothing
}

//hide keyboard when touched outside of TxtField
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.userFeedbackTextField resignFirstResponder];
}

- (void)initRateView:(RateView *)rateViewToInit
{
    rateViewToInit.notSelectedImage = [UIImage imageNamed:@"StarEmpty.png"];
    rateViewToInit.halfSelectedImage = [UIImage imageNamed:@"StarFull.png"];
    rateViewToInit.fullSelectedImage = [UIImage imageNamed:@"StarFull.png"];
    rateViewToInit.rating = 2.5;
    rateViewToInit.editable = YES;
    rateViewToInit.maxRating = 5;
    rateViewToInit.delegate = self;
}


- (void)rateView:(RateView *)rateView ratingDidChange:(float)rating
{
    //one of the rateViews was changed
    
    NSLog(@"voiceQualityRateView %.f", self.voiceQualityRateView.rating);
    NSLog(@"internetSpeedRateView %.f", self.internetSpeedRateView.rating);
    NSLog(@"voiceQualityRateView %.f", self.serviceUptimeRateView.rating);
    NSLog(@"satisfactionRateView %.f", self.satisfactionRateView.rating);
    
    self.isTouched = YES;
}


- (IBAction)doneButton:(id)sender
{
    self.feedbackDone = YES;
    
    if ((self.userFeedbackTextField != nil && [self.userFeedbackTextField.text length] > 0) || self.isTouched == YES)
    {
        [self sendFeedbackButton:nil];
    }
    else
    {
        [self pushView:@"StartTripViewController" animated:YES];
    }

}

- (IBAction)sendFeedbackButton:(id)sender
{
    NSLog(@"Generating feedback report");
    
    self.feedbackDone = YES;
    
    /* create mail subject */
    NSString *userName = [Preferences getUserName];
    NSString *subject;
    if (userName != nil && [userName length] > 0)
    {
        subject = [NSString stringWithFormat:@"Feedback from %@", userName];
    }
    else
    {
        subject = @"Enter your name here";
    }
    
    NSString *customUserFeedback = @"";
    if (self.userFeedbackTextField != nil && [self.userFeedbackTextField.text length] > 0)
    {
        customUserFeedback = self.userFeedbackTextField.text;
    }
    
    NSString *body = [NSString stringWithFormat:@"Voice quality: %.1f\nInternet Speed: %.1f\nService Uptime: %.1f\nSatisfaction: %.1f\n\n%@",
                                                                        self.voiceQualityRateView.rating,
                                                                        self.internetSpeedRateView.rating,
                                                                        self.serviceUptimeRateView.rating,
                                                                        self.satisfactionRateView.rating,
                                                                        customUserFeedback];
    
    /* define email address */
    NSString *mail = SUPPORT_EMAIL;
    
    /* create the URL */
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"mailto:?to=%@&subject=%@&body=%@",
                                                [mail stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                                                [subject stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                                                [body stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
    
    /* load the URL */
    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction)skipButton:(id)sender
{
    [self pushView:@"StartTripViewController" animated:YES];
}
@end
