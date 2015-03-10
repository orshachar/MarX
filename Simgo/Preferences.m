//
//  Preferences.m
//  Simgo
//
//  Created by Felix on 05/12/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import "Preferences.h"
#import "Utility.h"

@implementation Preferences

+(void)setUserPhoneNumber:(NSString *)userPhoneNumber
{
    [[NSUserDefaults standardUserDefaults] setObject:[userPhoneNumber stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"userPhoneNumber"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(NSString *)getUserPhoneNumber
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"userPhoneNumber"];
}

+(void)setLoggedInStatus:(int)loggedInStatus
{
    [[NSUserDefaults standardUserDefaults] setInteger:loggedInStatus forKey:@"loggedInStatus"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(LoggedInStatus)getLoggedInStatus
{
    int loggedInStatus = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"loggedInStatus"];
    return (LoggedInStatus)loggedInStatus;
}

+(void)setUserCountry:(NSString *)userCountry
{
    [[NSUserDefaults standardUserDefaults] setObject:userCountry forKey:@"UserCountry"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


+(NSString *)getUserCountry
{
    NSString *savedUserCountry = [[NSUserDefaults standardUserDefaults] stringForKey:@"UserCountry"];
    
    // if no country is found in preferences, guess country base on phone's locale
    if (savedUserCountry == nil)
    {
        savedUserCountry = [Utility findCurrentCountry];
    }
    
    return savedUserCountry;
}

+(void)setUserCountryCode:(NSString *)userCountryCode
{
    [[NSUserDefaults standardUserDefaults] setObject:userCountryCode forKey:@"UserCountryCode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(NSString *)getUserCountryCode
{
    NSString *savedCountryCode = [[NSUserDefaults standardUserDefaults] stringForKey:@"UserCountryCode"];
    
    // if no country is found in preferences, guess country base on phone's locale and fetch country code again
    if (savedCountryCode ==nil)
    {
        [Utility findCurrentCountry];
        savedCountryCode = [[NSUserDefaults standardUserDefaults] stringForKey:@"UserCountryCode"];
    }
    
    return savedCountryCode;
}

+(void)setUserPlug:(NSString *)userPlug
{
    //add padding '0'
    NSString *padded = [@"000000000000" stringByAppendingString:userPlug];
    NSString *paddedPlugNumber = [padded substringFromIndex:[padded length] - 12];
    
    
    [[NSUserDefaults standardUserDefaults] setObject:paddedPlugNumber forKey:@"UserPlug"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(NSString *)getUserPlug
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"UserPlug"];
}

+(void)setUserName:(NSString *)userName
{
    [[NSUserDefaults standardUserDefaults] setObject:userName forKey:@"userName"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(NSString *)getUserName
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"userName"];
}

+(void)setUserPassword:(NSString *)userPassword
{
    [[NSUserDefaults standardUserDefaults] setObject:userPassword forKey:@"userPassword"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(NSString *)getUserPassword
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"userPassword"];
}

+(void)setUserHomeMcc:(int)userHomeMcc
{
    [[NSUserDefaults standardUserDefaults] setInteger:userHomeMcc forKey:@"userHomeMcc"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(int)getUserHomeMcc
{
    return (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"userHomeMcc"];
}

+(void)setUserHomeMnc:(int)userHomeMnc
{
    [[NSUserDefaults standardUserDefaults] setInteger:userHomeMnc forKey:@"userHomeMnc"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(int)getUserHomeMnc
{
    return (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"userHomeMnc"];
}


+(void)setTripId:(int)tripId
{
    [[NSUserDefaults standardUserDefaults] setInteger:tripId forKey:@"tripId"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(int)getTripId
{
    return (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"tripId"];
}

+(void)setPendingDeleteTripId:(int)tripId
{
    [[NSUserDefaults standardUserDefaults] setInteger:tripId forKey:@"pendingDeleteTripId"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(int)getPendingDeleteTripId
{
    return (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"pendingDeleteTripId"];
}

+(void)setIncomingAccessNumber:(NSString *)incomingAccessNumber
{
    [[NSUserDefaults standardUserDefaults] setObject:incomingAccessNumber forKey:@"incomingAccessNumber"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(NSString *)getIncomingAccessNumber
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"incomingAccessNumber"];
}

+(void)setCallsForwardedFlag:(BOOL)isCallsForwarded
{
    [[NSUserDefaults standardUserDefaults] setBool:isCallsForwarded forKey:@"callsForwardedFlag"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(BOOL)getCallsForwardedFlag
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"callsForwardedFlag"];
}

+(void)setUserCloud:(NSString *)userCloud
{
    [[NSUserDefaults standardUserDefaults] setObject:userCloud forKey:@"userCloud"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(NSString *)getUserCloud
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"userCloud"];
}


+(void)setInitialInitDoneFlag:(BOOL)initialInitDone
{
    [[NSUserDefaults standardUserDefaults] setBool:initialInitDone forKey:@"initialInitDone"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(BOOL)getInitialInitDoneFlag
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"initialInitDone"];
}

+(void)setApnsToken:(NSString *)apnsToken
{
    [[NSUserDefaults standardUserDefaults] setObject:apnsToken forKey:@"apnsToken"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(NSString *)getApnsToken
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"apnsToken"];
}


+(void)setCallsQuota:(int)callsQuota
{
    [[NSUserDefaults standardUserDefaults] setInteger:callsQuota forKey:@"callsQuota"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(int)getCallsQuota
{
    return (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"callsQuota"];
}

+(void)setDataQuota:(int)dataQuota
{
    [[NSUserDefaults standardUserDefaults] setInteger:dataQuota forKey:@"dataQuota"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(int)getDataQuota
{
    return (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"dataQuota"];
}

+(void)setPlanType:(PlanType)planType
{
    [[NSUserDefaults standardUserDefaults] setInteger:planType forKey:@"planType"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(PlanType)getPlanType
{
    return (PlanType)[[NSUserDefaults standardUserDefaults] integerForKey:@"planType"];
}


+(void)setCallsUsage:(double)callsUsage
{
    [[NSUserDefaults standardUserDefaults] setDouble:callsUsage forKey:@"callsUsage"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(double)getCallsUsage
{
    return [[NSUserDefaults standardUserDefaults] doubleForKey:@"callsUsage"];
}

+(void)setDataUsage:(double)dataUsage
{
    [[NSUserDefaults standardUserDefaults] setDouble:dataUsage forKey:@"dataUsage"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(double)getDataUsage
{
    return [[NSUserDefaults standardUserDefaults] doubleForKey:@"dataUsage"];
}

+(void)setTripCallsUsage:(double)tripCallsUsage
{
    [[NSUserDefaults standardUserDefaults] setDouble:tripCallsUsage forKey:@"tripCallsUsage"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(double)getTripCallsUsage
{
    return [[NSUserDefaults standardUserDefaults] doubleForKey:@"tripCallsUsage"];
}

+(void)setTripDataUsage:(double)tripDataUsage
{
    [[NSUserDefaults standardUserDefaults] setDouble:tripDataUsage forKey:@"tripDataUsage"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(double)getTripDataUsage
{
    return [[NSUserDefaults standardUserDefaults] doubleForKey:@"tripDataUsage"];
}

+(void)setLastDataCounterValue:(double)lastDataCounterValue
{
    [[NSUserDefaults standardUserDefaults] setDouble:lastDataCounterValue forKey:@"lastDataCounterValue"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(double)getLastDataCounterValue
{
    return [[NSUserDefaults standardUserDefaults] doubleForKey:@"lastDataCounterValue"];
}

+(void)setElapsedBillingCycle:(NSNumber *)elapsedBillingCycle
{
    [[NSUserDefaults standardUserDefaults] setObject:elapsedBillingCycle forKey:@"elapsedBillingCycle"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(NSNumber *)getElapsedBillingCycle
{
    return (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"elapsedBillingCycle"];
}

+(void)setTotalCallsUsage:(double)totalCallsUsage
{
    [[NSUserDefaults standardUserDefaults] setDouble:totalCallsUsage forKey:@"totalCallsUsage"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(double)getTotalCallsUsage
{
    return [[NSUserDefaults standardUserDefaults] doubleForKey:@"totalCallsUsage"];
}

+(void)setTotalDataUsage:(double)totalDataUsage
{
    [[NSUserDefaults standardUserDefaults] setDouble:totalDataUsage forKey:@"totalDataUsage"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(double)getTotalDataUsage
{
    return [[NSUserDefaults standardUserDefaults] doubleForKey:@"totalDataUsage"];
}

+(void)setCallsUsageState:(UsageState)usageState
{
    [[NSUserDefaults standardUserDefaults] setInteger:usageState forKey:@"callsUsageState"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(UsageState)getCallsUsageState
{
    return (UsageState)[[NSUserDefaults standardUserDefaults] integerForKey:@"callsUsageState"];
}

+(void)setDataUsageState:(UsageState)usageState
{
    [[NSUserDefaults standardUserDefaults] setInteger:usageState forKey:@"dataUsageState"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(UsageState)getDataUsageState
{
    return (UsageState)[[NSUserDefaults standardUserDefaults] integerForKey:@"dataUsageState"];
}


+(void)setMobileDataConfiguration:(NSDictionary *)mobileDataConfiguration
{
    [[NSUserDefaults standardUserDefaults] setObject:mobileDataConfiguration forKey:@"mobileDataConfiguration"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(NSDictionary *)getMobileDataConfiguration
{
    return [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"mobileDataConfiguration"];
}


+(void)setSupportPhone:(NSString *)supportPhone
{
    [[NSUserDefaults standardUserDefaults] setObject:supportPhone forKey:@"supportPhone"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(NSString *)getSupportPhone
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"supportPhone"];
}

+(void)setSupportEmail:(NSString *)supportEmail
{
    [[NSUserDefaults standardUserDefaults] setObject:supportEmail forKey:@"supportEmail"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(NSString *)getSupportEmail
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"supportEmail"];
}

+(void)setSupportSkype:(NSString *)supportSkype
{
    [[NSUserDefaults standardUserDefaults] setObject:supportSkype forKey:@"supportSkype"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(NSString *)getSupportSkype
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"supportSkype"];
}

+(void)setSupportWhatsapp:(NSString *)supportWhatsapp
{
    [[NSUserDefaults standardUserDefaults] setObject:supportWhatsapp forKey:@"supportWhatsapp"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(NSString *)getSupportWhatsapp
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"supportWhatsapp"];
}

@end
