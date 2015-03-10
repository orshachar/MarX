//
//  ConfigurationVariables.h
//  Simgo
//
//  Created by Felix on 12/11/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Definitions : NSObject

extern const int UNDEFINED;

extern const int UNLIMITED;

extern const int DEVICE_TYPE;

extern const int MIN_PASSWORD_LENGTH;
extern const int MIN_PHONE_NUMBER_LENGTH;
extern const int MIN_PLUG_ID_LENGTH;
extern const int MAX_PLUG_ID_LENGTH;

extern const int BACKGROUND_FETCH_INTERVAL;

extern const int SIM_STATUS_POLLING_TIMER;

extern const int CLOSE_TO_PLAN_LIMITS_THRESHOLD;

extern NSString *const SUPPORT_PHONE_NUMBER;
extern NSString *const SUPPORT_EMAIL;
extern NSString *const SUPPORT_SKYPE;
extern NSString *const SUPPORT_WHATSAPP;

typedef enum LoggedInStatus : int LoggedInStatus;
enum LoggedInStatus : int {
    LOGGED_OUT = 0,
    WAITING_FOR_SMS = 1,
    LOGGED_IN = 2
};

typedef enum SimStatus : int SimStatus;
enum SimStatus : int {
    SIM_UNKNOWN = 0,
    USING_RSIM = 1,
    USING_FSIM = 2,
    USING_HSIM = 3
};

typedef enum PlugStatus : int PlugStatus;
enum PlugStatus : int {
    PLUG_STATUS_PROVISIONING = 1,
    PLUG_STATUS_PROVISIONED_FAILED_REJECTED_BY_CLOUD = 2,
    PLUG_STATUS_PROVISIONED_FAILED_NO_HSIM = 3,
    PLUG_STATUS_PROVISIONED_FAILED_INVALID_CLOUD_RESPONSE = 4,
    PLUG_STATUS_PROVISIONING_INHIBITED = 5,
    PLUG_STATUS_DEAD_BATTERY = 6
};

typedef enum RoamingMode : int RoamingMode;
enum RoamingMode : int {
    ROAMING_PROHIBITED = 0,
    ROAMING_ENABLED = 1
};

typedef enum PlanType : int PlanType;
enum PlanType : int {
    DAILY_PLAN = 0,
    WEEKLY_PLAN = 1,
    MONTHLY_PLAN = 2,
    TRIP_PLAN = 3
};

typedef enum BillingCycleLength : long long BillingCycleLength; //Seconds
enum BillingCycleLength : long long {
    DAYILY_BILLING_CYCLE = 24 * 60 * 60,
    WEEKLY_BILLING_CYCLE = 7 * 24 * 60 * 60,
    MONTHLY_BILLING_CYCLE = 30 * 24 * 60 * 60,
    UNDEFINED_BILLING_CYCLE = -1
};

typedef enum UsageState : int UsageState;
enum UsageState : int {
    WITHIN_PLAN_LIMITS = 0,
    CLOSE_TO_PLAN_LIMITS = 1,
    PLAN_EXCEEDED = 2,
};

+(BillingCycleLength)getBillingCycleLength:(PlanType)planType;

/*
 *  System Versioning Preprocessor Macros
 */

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)



@end
