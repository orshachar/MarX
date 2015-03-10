//
//  SimgoAppDelegate.m
//  Simgo
//
//  Created by Felix on 11/10/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import "SimgoAppDelegate.h"
#import "Utility.h"
#import "Definitions.h"
#import "Preferences.h"

@implementation SimgoAppDelegate


-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"########### Received Backgroudn Fetch ###########");
    
    BOOL result = [self sendStatusToCloud];
    
    if (result)
    {
        completionHandler(UIBackgroundFetchResultNewData);
    }
    else
    {
        completionHandler(UIBackgroundFetchResultFailed);
    }
}


- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    NSString *cleanToken = [[NSString stringWithFormat:@"%@", deviceToken] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    NSString *finalToken = [cleanToken stringByReplacingOccurrencesOfString:@" " withString:@""];

    NSLog(@"My token is: %@", finalToken);
    
    [Preferences setApnsToken:finalToken];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
	NSLog(@"Failed to get token, error: %@", error);
    
    [Preferences setApnsToken:nil];
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler
{
    NSLog(@"************ Received Remote Notification ************");
    
    BOOL result = [self sendStatusToCloud];
    
    if (result)
    {
        handler(UIBackgroundFetchResultNewData);
    }
    else
    {
        handler(UIBackgroundFetchResultFailed);
    }
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    [[UIApplication sharedApplication] setStatusBarHidden: NO];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        //Initialize backgroudn fetch.
        //    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:BACKGROUND_FETCH_INTERVAL * 60];
    }
    
    // Let the device know we want to receive push notifications
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeNewsstandContentAvailability | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
   [self.window endEditing:YES];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSLog(@"url recieved: %@", url);
    //NSLog(@"scheme string: %@", [url scheme]);
    //NSLog(@"query string: %@", [url query]);
    //NSLog(@"url path: %@", [url path]);
    //NSLog(@"host string: %@", [url host]);

    if ([[url scheme] isEqualToString:@"simgo"])
    {
        if ([[url host] isEqualToString:@"greeting"] && [[url path] isEqualToString:@"/apn"])
        {
            //SIMGO APN SMS
            NSLog(@"Received greeting SMS");

            //parse URL encoding to dictionary
            NSMutableDictionary *mobieDataConfDict = [[NSMutableDictionary alloc] initWithCapacity:6];
            NSArray *pairs = [[url query] componentsSeparatedByString:@"&"];
            
            for (NSString *pair in pairs)
            {
                NSArray *elements = [pair componentsSeparatedByString:@"="];
                NSString *key = [[elements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                NSString *val = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                
                [mobieDataConfDict setObject:val forKey:key];
            }
            
            if ([mobieDataConfDict count] >= 3) //Mcc, Mnc, APN
            {
                [Preferences setMobileDataConfiguration:mobieDataConfDict];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MOBILE_DATA_CONFIG_UPDATED" object:nil];
            }
        }
        else if ([[url host] isEqualToString:@"password"] && [[url path] length] > 0)
        {
            //SIMGO password SMS
            NSLog(@"Received password SMS");;
            [self processPasswordSms:[[url path] substringFromIndex:1]];
        }
        else
        {
            //Old SIMGO password SMS compatibility
            
            if ([Utility isNumeric:[url host]])
            {
                [self processPasswordSms:[url host]];
            }
        }
    }
    else
    {
        return NO;
    }

    return YES;
}

- (void)processPasswordSms:(NSString *)password
{
    if ([Preferences getLoggedInStatus] != WAITING_FOR_SMS)
    {
        NSLog(@"Current state is not WAITING_FOR_SMS. Ignoring password.");
        return;
    }
    
    NSLog(@"password: %@", password);
    
    //check password validity
    if (password != nil && [password length] >= MIN_PASSWORD_LENGTH)
    {
        //Save user password
        [Preferences setUserPassword:password];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PASSWORD_UPDATED" object:nil];
    }
    else
    {
        NSLog(@"Illegal password. Ignoring");
    }
}

- (BOOL)sendStatusToCloud
{
    //if there is a pending delete trip request, execute it.
    if ([Preferences getPendingDeleteTripId] > 0 && [Utility isInternetReachable] == YES)
    {
        NSLog(@"Performing pending detele trip");

        NSMutableURLRequest *urlRequest = [Utility generateDeleteTripRequest:[Preferences getPendingDeleteTripId]];
        NSHTTPURLResponse * response = nil;
        NSError * error = nil;
        NSData * data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
        
        if (error != nil)
        {
            NSLog(@"Cloud Delete Trip Error");
            
            if (error.code == -1012)
            {
                NSLog(@"Session key expired");
                [Preferences setLoggedInStatus:LOGGED_OUT];
                return NO;
            }
        }
        else if ([Preferences getPendingDeleteTripId] > 0)
        {
            [Utility parseDeleteTripResponse:data statusCode:[response statusCode]];
        }
    }
    
    
    if ([Preferences getTripId] >= 0 && [Preferences getLoggedInStatus] == LOGGED_IN)
    {
        NSMutableURLRequest *urlRequest = [Utility prepareTripStatusRequest:[Preferences getTripId] status:[Utility generateTripStatusString]];
        NSHTTPURLResponse * response = nil;
        NSError * error = nil;
        NSData * data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
        
        if (error != nil)
        {
            NSLog(@"Cloud Status Error");
            
            if (error.code == -1012)
            {
                NSLog(@"Session key expired");
                [Preferences setLoggedInStatus:LOGGED_OUT];
            }
            
            return NO;
        }
        else
        {
            /*NSDictionary *tripStatusResponse = */[Utility parseTripStatusResponse:data statusCode:[response statusCode]];
        }
    }
    
    return YES;
}

@end
