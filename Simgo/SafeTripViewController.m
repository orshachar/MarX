//
//  SafeTripViewController.m
//  Simgo
//
//  Created by Felix on 10/11/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import "SafeTripViewController.h"
#import "Utility.h"
#import "ForwardingExplanationViewController.h"

@interface SafeTripViewController ()

@property (weak, nonatomic) IBOutlet UIView *iPhone5View;
@property (weak, nonatomic) IBOutlet UIView *iPhone4View;

- (IBAction)endTripBtn:(id)sender;

@end

@implementation SafeTripViewController

- (void)viewDidLoad
{
    self.viewName = @"SafeTripViewController";

    [super viewDidLoad];
    
    self.navigationItem.hidesBackButton = YES;
    
    self.iPhone5View.hidden = [Utility isExtendedScreen] == NO;
    self.iPhone4View.hidden = [Utility isExtendedScreen] == YES;
}


- (IBAction)endTripBtn:(id)sender
{
    //[super endTripButton:sender];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"SequeToEndTripCancelCf"])
    {
        ForwardingExplanationViewController *controller = (ForwardingExplanationViewController *)segue.destinationViewController;
        controller.isTurnOnCallForwarding = NO;
        controller.isEarlyTripTermination = YES;
    }
}

@end
