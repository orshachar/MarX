//
//  Preferences.h
//  Simgo
//
//  Created by Felix on 05/12/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Definitions.h"

@interface Preferences : NSObject

+(void)setUserPhoneNumber:(NSString *)userPhoneNumber;
+(NSString *)getUserPhoneNumber;

+(void)setLoggedInStatus:(int)loggedInStatus;
+(LoggedInStatus)getLoggedInStatus;


+(void)setUserCountry:(NSString *)userCountry;
+(NSString *)getUserCountry;

+(void)setUserCountryCode:(NSString *)userCountryCode;
+(NSString *)getUserCountryCode;

+(void)setUserPlug:(NSString *)userPlug;
+(NSString *)getUserPlug;

+(void)setUserName:(NSString *)userName;
+(NSString *)getUserName;

+(void)setUserPassword:(NSString *)userPassword;
+(NSString *)getUserPassword;

+(void)setUserHomeMcc:(int)userHomeMcc;
+(int)getUserHomeMcc;

+(void)setUserHomeMnc:(int)userHomeMnc;
+(int)getUserHomeMnc;


+(void)setTripId:(int)tripId;
+(int)getTripId;

+(void)setPendingDeleteTripId:(int)tripId;
+(int)getPendingDeleteTripId;

+(void)setIncomingAccessNumber:(NSString *)incomingAccessNumber;
+(NSString *)getIncomingAccessNumber;

+(void)setCallsForwardedFlag:(BOOL)isCallsForwarded;
+(BOOL)getCallsForwardedFlag;

+(void)setUserCloud:(NSString *)userCloud;
+(NSString *)getUserCloud;


+(void)setInitialInitDoneFlag:(BOOL)initialInitDone;
+(BOOL)getInitialInitDoneFlag;

+(void)setApnsToken:(NSString *)apnsToken;
+(NSString *)getApnsToken;


+(void)setCallsQuota:(int)callsQuota;
+(int)getCallsQuota;

+(void)setDataQuota:(int)dataQuota;
+(int)getDataQuota;

+(void)setPlanType:(PlanType)planType;
+(PlanType)getPlanType;


+(void)setCallsUsage:(double)callsUsage;
+(double)getCallsUsage;

+(void)setDataUsage:(double)dataUsage;
+(double)getDataUsage;

+(void)setTripCallsUsage:(double)tripCallsUsage;
+(double)getTripCallsUsage;

+(void)setTripDataUsage:(double)tripDataUsage;
+(double)getTripDataUsage;

+(void)setLastDataCounterValue:(double)lastDataCounterValue;
+(double)getLastDataCounterValue;

+(void)setElapsedBillingCycle:(NSNumber *)billingTimeMarker;
+(NSNumber *)getElapsedBillingCycle;

+(void)setTotalCallsUsage:(double)totalCallsUsage;
+(double)getTotalCallsUsage;

+(void)setTotalDataUsage:(double)totalDataUsage;
+(double)getTotalDataUsage;

+(void)setCallsUsageState:(UsageState)usageState;
+(UsageState)getCallsUsageState;

+(void)setDataUsageState:(UsageState)usageState;
+(UsageState)getDataUsageState;


+(void)setMobileDataConfiguration:(NSDictionary *)mobileDataConfiguration;
+(NSDictionary *)getMobileDataConfiguration;


+(void)setSupportPhone:(NSString *)supportPhone;
+(NSString *)getSupportPhone;

+(void)setSupportEmail:(NSString *)supportEmail;
+(NSString *)getSupportEmail;

+(void)setSupportSkype:(NSString *)supportSkype;
+(NSString *)getSupportSkype;

+(void)setSupportWhatsapp:(NSString *)supportWhatsapp;
+(NSString *)getSupportWhatsapp;


@end
