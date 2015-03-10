//
//  Utility.m
//  Simgo
//
//  Created by Felix on 13/10/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import "Utility.h"
#import "MBProgressHUD.h"
#import "Preferences.h"

#import <SystemConfiguration/SystemConfiguration.h>

#import <netinet/in.h>
#import <netinet6/in6.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "Definitions.h"
#import <sys/utsname.h>
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCallCenter.h>
#include <arpa/inet.h>
#include <net/if.h> 
#include <ifaddrs.h> 
#include <net/if_dl.h>

@implementation Utility


+(void)showAlertDialog:(NSString *)title
{
    [Utility showAlertDialog:title message:nil delegate:nil otherButtonTitles:nil];
}

+(void)showAlertDialog:(NSString *)title message:(NSString *)message delegate:(NSObject *)delegate  otherButtonTitles:(NSString *)otherButtonTitles
{
    [Utility showAlertDialog:title message:message delegate:delegate cancelButtonTitle:@"OK" otherButtonTitles:otherButtonTitles tag:nil];
}

+(void)showAlertDialog:(NSString *) title message:(NSString *)message delegate:(NSObject *)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles tag:(NSInteger *)tag
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:delegate
                                          cancelButtonTitle:cancelButtonTitle
                                          otherButtonTitles:otherButtonTitles, nil];
    if (tag != nil)
    {
        alert.tag = *(tag);
    }
    
    [alert show];
}

+(NSMutableURLRequest *)prepareLoginRequest:(NSString *)userPhoneNumber country:(NSString *)userCountry password:(NSString *)userPassword
{
    // Create the request.
    
    //remove whitespaces from user name
    userPhoneNumber = [userPhoneNumber stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    //init cloud URL
    NSString *urlString = [NSString stringWithFormat: @"%@/users/session?hnum=%@",[Utility getCloudAddress], userPhoneNumber];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    // Specify that it will be a POST request
    request.HTTPMethod = @"POST";
    [request setHTTPShouldHandleCookies:NO];
    
    // This set header fields
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    // Set country name to empty string if country is nil
    if (userCountry == nil)
    {
        userCountry = @"";
    }
    
    //create json
    NSString *jsonRequest;
    if (userPassword == nil)
    {
        //jsonRequest = [NSString stringWithFormat:@"{\"country\":\"%@\", \"simulate_sms\":\"0\"}", userCountry];
        jsonRequest = [NSString stringWithFormat:@"{\"country\":\"%@\", \"device_type\":%d, \"mcc\":%d, \"mnc\":%d, %@}", userCountry, DEVICE_TYPE, [Utility getMcc], [Utility getMnc], [Utility getUserInfoJson]];
    }
    else
    {
        jsonRequest = [NSString stringWithFormat:@"{\"country\":\"%@\", \"pass\":\"%@\", %@}", userCountry, userPassword, [Utility getUserInfoJson]];
    }
    
    //add json to request
    NSData *requestBodyData = [NSData dataWithBytes:[jsonRequest UTF8String] length:[jsonRequest length]];
    
    request.HTTPBody = requestBodyData;
    [request setTimeoutInterval:20.0];

    return request;
}

+(void)showBusyHud:(NSString *)hudMessage view:(UIView *)view
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.opacity = 0.9f;
    hud.labelText = hudMessage;
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    });
}

+(void)hideHud:(UIView *)view
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:view animated:YES];
    });
}

//get header with auth (session) key
+(NSDictionary *)getHeadersWithSessionKey
{
    NSDictionary *headers;
    NSData *httpCookiesData = [[NSUserDefaults standardUserDefaults] objectForKey:@"loginCookie"];
    if([httpCookiesData length])
    {
        NSArray *savedCookies = [NSKeyedUnarchiver unarchiveObjectWithData:httpCookiesData];
        headers = [NSHTTPCookie requestHeaderFieldsWithCookies:savedCookies];
    }
    return headers;
}

//save user's auth (session) key
+(void)saveSessionKey:(NSURLResponse *) response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[httpResponse allHeaderFields] forURL:[NSURL URLWithString:@""]];
    NSData *httpCookiesData = [NSKeyedArchiver archivedDataWithRootObject:cookies];
    
    [[NSUserDefaults standardUserDefaults] setObject:httpCookiesData forKey:@"loginCookie"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

//create countries list from phone's locale
+(NSDictionary *)getCountryList
{
    NSArray *countryCodes = [NSLocale ISOCountryCodes];
    NSMutableArray *countries = [NSMutableArray arrayWithCapacity:[countryCodes count]];
    
    for (NSString *countryCode in countryCodes)
    {
        NSString *identifier = [NSLocale localeIdentifierFromComponents: [NSDictionary dictionaryWithObject: countryCode forKey: NSLocaleCountryCode]];
        NSString *country = [[NSLocale currentLocale] displayNameForKey: NSLocaleIdentifier value: identifier];
        [countries addObject: country];
    }
    
    return [[NSDictionary alloc] initWithObjects:countryCodes forKeys:countries];
}

+(NetworkStatus) getNetworkStatus
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    return [reachability currentReachabilityStatus];
}

+(BOOL)isInternetReachable
{
    /*
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);
    SCNetworkReachabilityFlags flags;
    
    if(reachability == NULL)
        return false;
    
    if (!(SCNetworkReachabilityGetFlags(reachability, &flags)))
        return false;
    
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
        // if target host is not reachable
        return false;
    
    BOOL isReachable = false;
    
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
    {
        // if target host is reachable and no connection is required
        //  then we'll assume (for now) that your on Wi-Fi
        isReachable = true;
    }
    
    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
    {
        // ... and the connection is on-demand (or on-traffic) if the
        //     calling application is using the CFSocketStream or higher APIs
        
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
        {
            // ... and no [user] intervention is needed
            isReachable = true;
        }
    }
    
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
    {
        // ... but WWAN connections are OK if the calling application
        //     is using the CFNetwork (CFSocketStream?) APIs.

        isReachable = true;
    }
    
    //NSLog(@"Flags: %d", flags);

    return isReachable;
     */
    
    return !([Utility getNetworkStatus] == NotReachable);
}

+(int) getMcc
{
    CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netInfo subscriberCellularProvider];
    
    NSString *mcc = [carrier mobileCountryCode];
    
    if (mcc != nil)
    {
        return [mcc intValue];
    }
    
    return 0;
}

+(int) getMnc
{
    CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netInfo subscriberCellularProvider];
    
    NSString *mnc = [carrier mobileNetworkCode];
    
    if (mnc != nil)
    {
        return [mnc intValue];
    }
    
    return 0;
}

+(NSString *) getOperatorName
{
    CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netInfo subscriberCellularProvider];
    return [carrier carrierName];
}


+(NSString *) getDeviceType
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *iOSDeviceModelsPath = [[NSBundle mainBundle] pathForResource:@"iOSDeviceModelMapping" ofType:@"plist"];
    NSDictionary *iOSDevices = [NSDictionary dictionaryWithContentsOfFile:iOSDeviceModelsPath];
    
    NSString* deviceModel = [NSString stringWithCString:systemInfo.machine
                                               encoding:NSUTF8StringEncoding];
    
    return [iOSDevices valueForKey:deviceModel];
}


+(NSString *) getCloudAddress
{
    
    //#warning @"USING PRIVATE CLOUD"
    
    //return @"http://10.0.0.22:8000";
    
    if ([Preferences getUserCloud] != nil)
    {
        return [NSString stringWithFormat:@"http://d.%@:5350", [Preferences getUserCloud]];
    }
    
    return @"http://d.eos.simgo.me:5350";
}

+(NSMutableURLRequest *) generateDeleteTripRequest:(int)tripId
{
    // Create the request.
    NSString *urlString = [NSString stringWithFormat: @"%@/trips/%d", [Utility getCloudAddress], tripId];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];

    // Specify that it will be a POST request
    request.HTTPMethod = @"DELETE";
    [request setHTTPShouldHandleCookies:NO];

    // Set header fields
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];

    // Define timeout
    [request setTimeoutInterval:10.0];

    // Set user's auth (session) key
    NSDictionary * headers = [Utility getHeadersWithSessionKey];
    [request setAllHTTPHeaderFields:headers];

    return request;
}

+(BOOL) parseDeleteTripResponse:(NSData *) responseData statusCode:(NSInteger)statusCode
{
    BOOL result = FALSE;
    
    NSLog(@"Delete Trip Cloud response [%ld]", (long)statusCode);
    
        NSError *jsonParsingError = nil;
    
    //parse response json
    NSDictionary *responseJson = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&jsonParsingError];
    
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
        if (error != nil && statusCode != 412 /*Trip doesn't exist*/)
        {
            //delete trip request succeded but Cloud returned an error. Show error message
            [Utility showAlertDialog:error];
        }
        else
        {
            [Preferences setTripId:UNDEFINED];
            [Preferences setPendingDeleteTripId:UNDEFINED];
            [Preferences setCallsForwardedFlag:NO];
            result = TRUE;
        }
    }
    
    return result;
}


+(NSMutableURLRequest *)prepareTripStatusRequest:(int)tripId status:(NSString *)status
{
    // Create the request.
    
    //init cloud URL
    NSString *urlString = [NSString stringWithFormat: @"%@/trips/%d",[Utility getCloudAddress], tripId];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    // Specify that it will be a PUT request
    request.HTTPMethod = @"PUT";
    [request setHTTPShouldHandleCookies:NO];
    
    // This set header fields
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    //create json
    NSString *jsonRequest;
    if (status != nil)
    {
        UIDevice *myDevice = [UIDevice currentDevice];
        [myDevice setBatteryMonitoringEnabled:YES];
        int battery = (int)[myDevice batteryLevel] * 100;
        int chargingStatus = [myDevice batteryState];
        [myDevice setBatteryMonitoringEnabled:NO];
        
        NSDate *currentDate =[NSDate date];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"dd-MM-yyyy HH:mm"];
        
        jsonRequest = [NSString stringWithFormat:@"{\"object\": {\"status\": \"%@\", \"battery\":%d, \"charging\":%d, \"timestamp\":\"%@\"}}", status, battery, chargingStatus, [formatter stringFromDate:currentDate]];
        
        //add json to request
        NSData *requestBodyData = [NSData dataWithBytes:[jsonRequest UTF8String] length:[jsonRequest length]];
        request.HTTPBody = requestBodyData;
    }
    
    // Define timeout
    [request setTimeoutInterval:10.0];
    
    // Set user's auth (session) key
    NSDictionary * headers = [Utility getHeadersWithSessionKey];
    [request setAllHTTPHeaderFields:headers];
    
    return request;
}

+(NSDictionary *) parseTripStatusResponse:(NSData *) responseData statusCode:(NSInteger)statusCode
{
    NSLog(@"Trip Status response [%ld]", (long)statusCode);
    
    if (statusCode == 401)
    {
        NSLog(@"Session key expired");
        [Preferences setLoggedInStatus:LOGGED_OUT];
    }
    else if (statusCode == 412)
    {
        NSLog(@"Trip doesn't exist");
        [Preferences setTripId:UNDEFINED];
        [Preferences setPendingDeleteTripId:UNDEFINED];
    }
    
    NSError *jsonParsingError = nil;
    
    //parse response json
    NSDictionary *responseJson = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&jsonParsingError];
    
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
        if (error != nil)
        {
            //trip status request succeded but Cloud returned an error. Log error message
            NSLog(@"Trip Status error: %@", error);
        }
        else
        {
            NSDictionary *result = [responseJson objectForKey:@"object"];

            [Utility updatePlanDetails:result];
            [Utility updateUsageDetails:result];
            [Utility updateDataUsageCounters:result];
            [Utility issueUsageNotifications:result];

            return result;
        }
    }
    
    return nil;
}

+(void)updatePlanDetails:(NSDictionary *)planJson
{
   if (planJson != nil)
   {
       NSDictionary *planDetails = [planJson objectForKey:@"plan"];
       
       if (planDetails != nil)
       {
           PlanType planType = [[planDetails objectForKey:@"type"] intValue];
           [Preferences setPlanType:planType];
           NSLog(@"Trip plan type: %d", planType);
           
           int callsQuota;
           int dataQuota;
           if ([planDetails objectForKey:@"calls_limit"])
           {
               callsQuota = [[planDetails objectForKey:@"calls_limit"] intValue];
           }
           else
           {
               callsQuota = UNLIMITED;
           }
           
           if ([planDetails objectForKey:@"data_limit"])
           {
               dataQuota = [[planDetails objectForKey:@"data_limit"] intValue];
           }
           else
           {
               dataQuota = UNLIMITED;
           }

           [Preferences setCallsQuota:callsQuota];
           NSLog(@"Calls quota: %d", callsQuota);
           
           [Preferences setDataQuota:dataQuota];
           NSLog(@"Data quota: %d", dataQuota);
       }
       else
       {
           NSLog(@"Failed to parse plan details");
       }
   }
}

+(void)updateDataUsageCounters:(NSDictionary *)tripStatusResponse
{
    //find out if RSIM or HSIM is used
    NSArray *simHeuristicsResult = [Utility simHeuristics:tripStatusResponse];
    SimStatus simStatus = [simHeuristicsResult[0] intValue];
    
    NSArray *dataUsage = [Utility getDataCounters];
    //Calculate total data usage (send+received)
    double totalMobileUsage = ([dataUsage[2] longLongValue] + [dataUsage[3] longLongValue]) / (float)(1024 * 1024);
    
    if(simStatus == USING_HSIM)
    {
        //Save current data counter status in case HSIM->RSIM switch without powering off
        [Preferences setLastDataCounterValue:totalMobileUsage];
    }
    //If RSIM is used, update data usage
    else if (simStatus == USING_RSIM && [Preferences getTripId] >= 0)
    {
        NSLog(@"Data Usage: WiFi - Send:%lld / Received:%lld[bytes], Mobile - Send:%lld / Received:%lld[bytes]", [dataUsage[0] longLongValue], [dataUsage[1] longLongValue], [dataUsage[2] longLongValue], [dataUsage[3] longLongValue]);
        
        //Get data counter state during previous update
        double lastDataCounterValue = [Preferences getLastDataCounterValue];
        
        double dataUsed;
        
        //check if data counter was reset after last data update
        if (totalMobileUsage < lastDataCounterValue)
        {
            //Data counter was reset. Just add it's value to TripDataUsage
            [Preferences setTripDataUsage:([Preferences getTripDataUsage] + totalMobileUsage)];
            dataUsed = totalMobileUsage;
        }
        else
        {
            //Data counter was NOT reset. Calculate delta since last update and add it to TripDataUsage
            dataUsed = totalMobileUsage - lastDataCounterValue;
            [Preferences setTripDataUsage:([Preferences getTripDataUsage] + dataUsed)];
        }
        
        NSLog(@"Data usage update. Since last update %.2f[MB]. Total Trip usage: %.2f[MB]", dataUsed, [Preferences getTripDataUsage]);
        
        //Update Current & Total data usage counters
        [Preferences setTotalDataUsage:([Preferences getTotalDataUsage] + dataUsed)];
        [Preferences setDataUsage:([Preferences getDataUsage] + dataUsed)];
    
        //Save current data counter status for next update
        [Preferences setLastDataCounterValue:totalMobileUsage];
    }
    else
    {
        NSLog(@"Not using RSIM. Skipping Data counter update");
    }
}

+(void)updateUsageDetails:(NSDictionary *)usageJson
{
    if (usageJson != nil)
    {
        NSDictionary *usageDetails = [usageJson objectForKey:@"usage"];
        
        if (usageDetails != nil)
        {
            if ([usageDetails objectForKey:@"total_calls_usage"])
            {
                double totalCallsUsage = [[usageDetails objectForKey:@"total_calls_usage"] doubleValue];
                [Preferences setTotalCallsUsage:totalCallsUsage];
                NSLog(@"Total Calls usage: %f", totalCallsUsage);
            }
            if ([usageDetails objectForKey:@"total_data_usage"])
            {
                double totalDataUsage = [[usageDetails objectForKey:@"total_data_usage"] doubleValue];
                [Preferences setTotalDataUsage:totalDataUsage];
                NSLog(@"Total Data usage: %f", totalDataUsage);
            }
            
            if ([usageDetails objectForKey:@"trip_calls_usage"])
            {
                double tripCallsUsage = [[usageDetails objectForKey:@"trip_calls_usage"] doubleValue];
                [Preferences setTripCallsUsage:tripCallsUsage];
                NSLog(@"Trip Calls usage: %f", tripCallsUsage);
            }
            if ([usageDetails objectForKey:@"trip_data_usage"])
            {
                double tripDataUsage = [[usageDetails objectForKey:@"trip_data_usage"] doubleValue];
                if (tripDataUsage > [Preferences getTripDataUsage])
                {
                    [Preferences setTripDataUsage:tripDataUsage];
                    NSLog(@"Overriding Trip Data usage: %f", tripDataUsage);
                }
            }
            
            if ([usageDetails objectForKey:@"calls_usage"])
            {
                double callsUsage = [[usageDetails objectForKey:@"calls_usage"] doubleValue];
                [Preferences setCallsUsage:callsUsage];
                NSLog(@"Calls usage: %f", callsUsage);
            }
            if ([usageDetails objectForKey:@"data_usage"])
            {
                double dataUsage = [[usageDetails objectForKey:@"data_usage"] doubleValue];
                [Preferences setDataUsage:dataUsage];
                NSLog(@"Data usage: %f", dataUsage);
            }
            
            if ([usageDetails objectForKey:@"elapsed_billing_cycle"])
            {
                NSNumber *elapsedBillingCycle = [NSNumber numberWithLongLong:[[usageDetails objectForKey:@"elapsed_billing_cycle"] longLongValue]];
                [Preferences setElapsedBillingCycle:elapsedBillingCycle];
                NSLog(@"Elapsed billing cycle: %@", elapsedBillingCycle);
            }
            else
            {
                [Preferences setElapsedBillingCycle:0];
            }
        }
        else
        {
            NSLog(@"Failed to parse usage details");
        }
    }
}

+(void)issueUsageNotifications:(NSDictionary *)tripStatusResponse
{
    //find out if RSIM or HSIM is used
    NSArray *simHeuristicsResult = [Utility simHeuristics:tripStatusResponse];
    SimStatus simStatus = [simHeuristicsResult[0] intValue];
    
    //If RSIM is used, check if usage is near/exceeded plan limits
    if (simStatus == USING_RSIM && [Preferences getTripId] >= 0)
    {
        int callsUsage;
        int dataUsage;
        int callsQuota = [Preferences getCallsQuota];
        int dataQuota = [Preferences getDataQuota];
        
        if ([Preferences getPlanType] != TRIP_PLAN)
        {
            callsUsage = (int)ceil([Preferences getCallsUsage]);
            dataUsage = (int)ceil([Preferences getDataUsage]);
        }
        else
        {
            callsUsage = (int)ceil([Preferences getTripCallsUsage]);
            dataUsage = (int)ceil([Preferences getTripDataUsage]);
        }
        
        int callsUsageState = [Preferences getCallsUsageState];
        int dataUsageState = [Preferences getDataUsageState];

        if (callsQuota != UNLIMITED && callsUsage > callsQuota)
        {
            if (callsUsageState != PLAN_EXCEEDED)
            {
                [Preferences setCallsUsageState:PLAN_EXCEEDED];
                [self sendLocalNotification:@"Your calls plan quota has been exceeded" delay:0 includeSound:YES];
                NSLog(@"Calls plan exceeded. Issuing notification");
            }
        }
        else if (callsQuota != UNLIMITED && (callsUsage > callsQuota * CLOSE_TO_PLAN_LIMITS_THRESHOLD / 100))
        {
            if (callsUsageState != CLOSE_TO_PLAN_LIMITS)
            {
                [Preferences setCallsUsageState:CLOSE_TO_PLAN_LIMITS];
                [self sendLocalNotification:[NSString stringWithFormat:@"%.0f\uFF05 of your calls plan has been used", callsUsage / (float)callsQuota * 100] delay:0 includeSound:YES];
                NSLog(@"Calls plan near limit. Issuing notification");
            }
        }
        else
        {
            [Preferences setCallsUsageState:WITHIN_PLAN_LIMITS];
        }

        if (dataQuota != UNLIMITED && dataUsage > dataQuota)
        {
            if (dataUsageState != PLAN_EXCEEDED)
            {
                [Preferences setDataUsageState:PLAN_EXCEEDED];
                [self sendLocalNotification:@"Your data plan quota has been exceeded" delay:0 includeSound:YES];
                NSLog(@"Data plan exceeded. Issuing notification");
            }
        }
        else if (dataQuota != UNLIMITED && (dataUsage > dataQuota * CLOSE_TO_PLAN_LIMITS_THRESHOLD / 100))
        {
            if (dataUsageState != CLOSE_TO_PLAN_LIMITS)
            {
                [Preferences setDataUsageState:CLOSE_TO_PLAN_LIMITS];
                [self sendLocalNotification:[NSString stringWithFormat:@"%.0f\uFF05 of your data plan has been used", dataUsage / (float)dataQuota * 100] delay:0 includeSound:YES];
                NSLog(@"Data plan near limit. Issuing notification");
            }
        }
        else
        {
            [Preferences setDataUsageState:WITHIN_PLAN_LIMITS];
        }
    }
}

+(NSArray *)simHeuristics:(NSDictionary *)tripStatusResponse
{
    //#warning remove force to HSIM
    //return [NSArray arrayWithObjects:[NSNumber numberWithInt:USING_HSIM], [NSNumber numberWithInt:1], nil];
    
    SimStatus result = SIM_UNKNOWN;
    int overallAllocations = 0;
    
    if (tripStatusResponse != nil)
    {
        //extract allocation dictionary
        NSDictionary *allocation = [tripStatusResponse objectForKey:@"allocation"];
        if (allocation != nil)
        {
            @try
            {
                //parse allocation parameters
                BOOL isActive = [[allocation objectForKey:@"is_active"] boolValue];
                int mcc = [[allocation objectForKey:@"mcc"] intValue];
                int mnc = [[allocation objectForKey:@"mnc"] intValue];
                overallAllocations = [[allocation objectForKey:@"overall_allocations"] intValue];

                //is allocation MCC+MNC different from current MCC+MNC?
                if (mcc != [Utility getMcc] || mnc != [Utility getMnc])
                {
                    //MCC+MNC different. Definitely using HSIM
                    result = USING_HSIM;
                }
                else if ([Preferences getUserHomeMcc] > 1 && [Preferences getUserHomeMnc] > 0 &&
                         (mcc != [Preferences getUserHomeMcc] || mnc != [Preferences getUserHomeMnc]))
                {
                    //MCC+MNC different from MCC+MNC user used to login. Most likely using RSIM
                    result = USING_RSIM;
                }
                else if (isActive == NO)
                {
                    //MCC+MNC is the same but allocaton is stall (old). Assume HSIM
                    result = USING_HSIM;
                }
                else
                {
                    //Using RSIM
                    result = USING_RSIM;
                }
            }
            @catch (NSException * e)
            {
                NSLog(@"Exception: %@", e);
            }
        }
    }
    else
    {
        NSLog(@"Trip status response is NIL");
    }
    
    return [NSArray arrayWithObjects:[NSNumber numberWithInt:result], [NSNumber numberWithInt:overallAllocations], nil];
}

+(NSString *) generateTripStatusString
{
    CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netInfo subscriberCellularProvider];
    NSString *mcc = [carrier mobileCountryCode];
    NSString *mnc = [carrier mobileNetworkCode];
    
    
    NSArray *batteryStatus = [NSArray arrayWithObjects:
                              @"Unknown",
                              @"No",
                              @"Yes",
                              @"Full", nil];
    
    UIDevice *myDevice = [UIDevice currentDevice];
    [myDevice setBatteryMonitoringEnabled:YES];
    double battery = (float)[myDevice batteryLevel] * 100;
    NSString *chargingStatus = [batteryStatus objectAtIndex:[myDevice batteryState]];
    [myDevice setBatteryMonitoringEnabled:NO];
    
    
    
    return [NSString stringWithFormat:@"Phone: %@/%@, MCC/NAME: %@%@/%@, CallState: %@, DataState: %@, Battery: %.f%%, Charging: %@, Trip Data Usage: %.2fMB, Event ID: %lli",
                                                                        [Utility getDeviceType], [[UIDevice currentDevice] systemVersion],
                                                                        mcc, mnc, [Utility getOperatorName],
                                                                        [Utility getCallState],
                                                                        [Utility getDataState],
                                                                        battery,
                                                                        chargingStatus,
                                                                        [Preferences getTripDataUsage],
                                                                        [@(floor([[NSDate date] timeIntervalSince1970] * 1000)) longLongValue]];
}

+(NSString *) getCallState
{
    CTCallCenter *callCenter = [[CTCallCenter alloc] init];
    for (CTCall *call in callCenter.currentCalls)
    {
        if (call.callState == CTCallStateConnected || call.callState == CTCallStateDialing)
        {
            return @"OFFHOOK";
        }
        else if (call.callState == CTCallStateIncoming)
        {
           return @"RINGING";
        }
    }
    
    return @"IDLE";
}

+(NSString *) getDataState
{
    NetworkStatus networkStatus = [Utility getNetworkStatus];
    if (networkStatus == ReachableViaWiFi)
    {
        return @"WIFI";
    }
    else if (networkStatus == ReachableViaWWAN)
    {
        return @"CONNECTED";
    }
    else if (networkStatus == NotReachable)
    {
        return @"DISCONNECTED";
    }
    else
    {
        return @"UNKNOWN";
    }
}

+(NSArray *) getDataCounters
{
    BOOL   success;
    struct ifaddrs *addrs;
    const struct ifaddrs *cursor;
    const struct if_data *networkStatisc;
    
    long long WiFiSent = 0;
    long long WiFiReceived = 0;
    long long WWANSent = 0;
    long long WWANReceived = 0;
    
    NSString *name;//=[[NSString alloc] init];
    
    success = getifaddrs(&addrs) == 0;
    if (success)
    {
        cursor = addrs;
        while (cursor != NULL)
        {
            name=[NSString stringWithFormat:@"%s",cursor->ifa_name];
            //NSLog(@"ifa_name %s == %@\n", cursor->ifa_name,name);
            // names of interfaces: en0 is WiFi ,pdp_ip0 is WWAN
            
            if (cursor->ifa_addr->sa_family == AF_LINK)
            {
                if ([name hasPrefix:@"en"])
                {
                    networkStatisc = (const struct if_data *) cursor->ifa_data;
                    WiFiSent+=networkStatisc->ifi_obytes;
                    WiFiReceived+=networkStatisc->ifi_ibytes;
                    //NSLog(@"WiFiSent %d ==%d",WiFiSent,networkStatisc->ifi_obytes);
                    //NSLog(@"WiFiReceived %d ==%d",WiFiReceived,networkStatisc->ifi_ibytes);
                }
                
                if ([name hasPrefix:@"pdp_ip"])
                {
                    networkStatisc = (const struct if_data *) cursor->ifa_data;
                    WWANSent+=networkStatisc->ifi_obytes;
                    WWANReceived+=networkStatisc->ifi_ibytes;
                    //NSLog(@"WWANSent %d ==%d",WWANSent,networkStatisc->ifi_obytes);
                    //NSLog(@"WWANReceived %d ==%d",WWANReceived,networkStatisc->ifi_ibytes);
                }
            }
            
            cursor = cursor->ifa_next;
        }
        
        freeifaddrs(addrs);
    }
    
    return [NSArray arrayWithObjects:[NSNumber numberWithLongLong:WiFiSent], [NSNumber numberWithLongLong:WiFiReceived],[NSNumber numberWithLongLong:WWANSent],[NSNumber numberWithLongLong:WWANReceived], nil];
}

+(NSString *) getUserInfoJson
{
    NSString *apnsToken;
    if ([Preferences getApnsToken])
    {
        apnsToken = [NSString stringWithFormat:@", \"apns_token\":\"%@\"", [Preferences getApnsToken]];
    }
    else
    {
        apnsToken = @"";
    }
    
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    
    return [NSString stringWithFormat:@"\"device_type\":1, \"app_version\":\"%@\"%@", appVersion, apnsToken];
}

+(BOOL) isExtendedScreen
{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        CGSize result = [[UIScreen mainScreen] bounds].size;
        if(result.height == 568)
        {
            // iPhone 5
            return YES;
        }
        //else if(result.height == 480)
        //{
            // iPhone Classic
        //}
    }
    return NO;
}

+(void) copyToClipboad:(NSString *)textToCopy
{
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    [pb setString:textToCopy];
}

+(BOOL) isMobileDataConfigValid
{
    int mccInt = -1;
    int mncInt = -1;
    
    NSDictionary *apnConfiguration = [Preferences getMobileDataConfiguration];
    
    if (apnConfiguration != nil)
    {
        
        //#warning @"For testing only. REMOVE!!!"
        //return YES;
        
        NSString *mcc = [apnConfiguration objectForKey:@"mcc"];
        NSString *mnc = [apnConfiguration objectForKey:@"mnc"];
        
        if ([Utility isNumeric:mcc])
        {
            mccInt = [mcc intValue];
        }
        
        if ([Utility isNumeric:mnc])
        {
            mncInt = [mnc intValue];
        }
        
        if (mccInt == [Utility getMcc] && mncInt == [Utility getMnc])
        {
            return YES;
        }
    }
    return NO;
}

+(BOOL) isNumeric:(NSString *)inputString
{
    BOOL isNumeric = NO;
    if (inputString != nil && [inputString length] > 0)
    {
        NSCharacterSet *alphaNumbersSet = [NSCharacterSet decimalDigitCharacterSet];
        NSCharacterSet *stringSet = [NSCharacterSet characterSetWithCharactersInString:inputString];
        isNumeric = [alphaNumbersSet isSupersetOfSet:stringSet];
    }
    
    return isNumeric;
}

+(void) parseSupportInfo:(NSDictionary *)responseJson
{
    if (responseJson != nil)
    {
        NSDictionary *supportJson = responseJson[@"support"];
        if (supportJson != nil)
        {
            NSString *supportPhone = supportJson[@"support_phone"];
            NSString *supportEmail = supportJson[@"support_email"];
            NSString *supportSkype = supportJson[@"support_skype"];
            NSString *supportWhatsapp = supportJson[@"support_whatsapp"];
            
            if (supportPhone != nil && [supportPhone length] > 0)
            {
                [Preferences setSupportPhone:supportPhone];
            }
            if (supportEmail != nil && [supportEmail length] > 0)
            {
                [Preferences setSupportEmail:supportEmail];
            }
            if (supportSkype != nil && [supportSkype length] > 0)
            {
                [Preferences setSupportSkype:supportSkype];
            }
            if (supportWhatsapp != nil && [supportWhatsapp length] > 0)
            {
                [Preferences setSupportWhatsapp:supportWhatsapp];
            }
        }
    }
}

+(void) sendLocalNotification:(NSString *)notificationText delay:(int)delaySeconds includeSound:(bool)includeSound
{
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:delaySeconds];
    if (includeSound)
    {
        localNotification.soundName = UILocalNotificationDefaultSoundName;
    }
    localNotification.alertBody = notificationText;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

//finds current country based on locale
+(NSString *)findCurrentCountry
{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    
    if([standardUserDefaults stringForKey:@"UserCountry"] == nil)
    {
        NSLocale *locale = [NSLocale currentLocale];
        NSString *countryCode = [locale objectForKey: NSLocaleCountryCode];
        NSString *currentCountry = currentCountry = [locale displayNameForKey:NSLocaleCountryCode value:countryCode];
        
        [standardUserDefaults setObject:countryCode forKey:@"UserCountryCode"];
        [standardUserDefaults setObject:currentCountry forKey:@"UserCountry"];
        [standardUserDefaults synchronize];
        
        return currentCountry;
    }
    
    return nil;
}

@end
