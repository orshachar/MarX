//
//  ApnConfigurationViewController.m
//  Simgo
//
//  Created by Felix on 01/12/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import "ApnConfigurationViewController.h"
#import "Utility.h"
#import "Preferences.h"

@interface ApnConfigurationViewController ()
@property (weak, nonatomic) IBOutlet UITableView *apnConfigurationTable;
@property (weak, nonatomic) IBOutlet UILabel *apnPathLabelNoRoaming;
@property (weak, nonatomic) IBOutlet UILabel *apnPathLabelWithRoaming;

@property (weak, nonatomic) IBOutlet UIView *roamingGuidelinesView;
@property (weak, nonatomic) IBOutlet UIView *withoutRoamingGuidelinesView;


@property NSArray *apnFieldNames;
@property NSMutableDictionary *apnFields;

@end

@implementation ApnConfigurationViewController


- (void)viewDidLoad
{
    self.viewName = @"ApnConfigurationViewController";
    
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.apnFieldNames = [NSArray arrayWithObjects: @"APN",@"Username",@"Password", nil];

}

-(void)viewWillAppear:(BOOL)animated
{
    self.apnFields = [NSMutableDictionary dictionary];
    NSDictionary *mobileDataConfiguration = [Preferences getMobileDataConfiguration];
    int roamingMode = ROAMING_PROHIBITED;
    
    if (mobileDataConfiguration != nil)
    {
        NSString *apn = [mobileDataConfiguration objectForKey:@"APN"];
        NSString *username = [mobileDataConfiguration objectForKey:@"User"];
        NSString *password = [mobileDataConfiguration objectForKey:@"Pass"];
        NSString *roaming = [mobileDataConfiguration objectForKey:@"Roam"];
       
        if (apn != nil)
        {
            [self.apnFields setObject:apn forKey:self.apnFieldNames[0]];
        }
        if (username != nil)
        {
            [self.apnFields setObject:username forKey:self.apnFieldNames[1]];
        }
        if (password != nil)
        {
            [self.apnFields setObject:password forKey:self.apnFieldNames[2]];
        }
        if ([Utility isNumeric:roaming] && [roaming intValue] == ROAMING_ENABLED)
        {
            roamingMode = ROAMING_ENABLED;
        }
    }
    
    if (SYSTEM_VERSION_LESS_THAN(@"7.0"))
    {
        self.apnPathLabelNoRoaming.text = @"'Settings' -> 'General' -> 'Cellular' -> 'Cellular Data Network'";
        [[self apnPathLabelNoRoaming] setFont:[UIFont boldSystemFontOfSize:17]];
        
        self.apnPathLabelWithRoaming.text = @"'Settings' -> 'General' -> 'Cellular'";
    }

    self.roamingGuidelinesView.hidden = !(roamingMode == ROAMING_ENABLED);
    self.withoutRoamingGuidelinesView.hidden = !(roamingMode != ROAMING_ENABLED);
    
    [super viewWillAppear:(BOOL)animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.apnFieldNames count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ApnCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    UIButton *copyButton = (UIButton *)[cell viewWithTag:101];
    
    NSString *apnLabelStr;
    
    UILabel *apnLabel = (UILabel *)[cell viewWithTag:100];
    apnLabelStr = [NSString stringWithFormat:@"%@: ", [self.apnFieldNames objectAtIndex:indexPath.row]];

    if([self.apnFields count] > indexPath.row)
    {
        apnLabelStr = [apnLabelStr stringByAppendingString:[self.apnFields objectForKey:[self.apnFieldNames objectAtIndex:indexPath.row]]];
        
        [copyButton addTarget:self action:@selector(processCopyButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        copyButton.tag = indexPath.row;
    }
    else
    {
        copyButton.enabled = NO;
        apnLabel.enabled = NO;
    }
    
    apnLabel.text = apnLabelStr;
    
    return cell;
}

-(void)processCopyButtonPressed:(UIButton *) sender
{
    //sender.tag will be equal to indexPath.row
    
    [self copyApnField:sender.tag];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self copyApnField:indexPath.row];
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
}

-(void)copyApnField:(NSInteger)fieldId
{
    if (self.apnFieldNames.count > fieldId)
    {
        NSString *apnFieldValue = [self.apnFields objectForKey:[self.apnFieldNames objectAtIndex:fieldId]];
        
        if (apnFieldValue != nil)
        {
            UIPasteboard *pb = [UIPasteboard generalPasteboard];
            [pb setString:apnFieldValue];
            
            [Utility showAlertDialog:[NSString stringWithFormat:@"'%@' was copied to clipboard", apnFieldValue]];
        }
    }
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a story board-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 
 */

@end
