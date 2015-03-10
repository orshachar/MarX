//
//  ConfigurationVariables.m
//  Simgo
//
//  Created by Felix on 12/11/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import "Definitions.h"

@implementation Definitions

const int UNDEFINED = -1;

const int UNLIMITED = INT_MAX;

const int DEVICE_TYPE = 1; //iPhone

const int MIN_PASSWORD_LENGTH = 4;
const int MIN_PHONE_NUMBER_LENGTH = 6;

const int MIN_PLUG_ID_LENGTH = 5; //characters
const int MAX_PLUG_ID_LENGTH = 12; //characters

const int BACKGROUND_FETCH_INTERVAL = 5; //minutes

const int SIM_STATUS_POLLING_TIMER = 1; //sec

const int CLOSE_TO_PLAN_LIMITS_THRESHOLD = 80; //percent

NSString *const SUPPORT_PHONE_NUMBER = @"+972-3-374-1364";
NSString *const SUPPORT_EMAIL = @"support@simgo-mobile.com";
NSString *const SUPPORT_SKYPE = @"simgo.mobile.support";
NSString *const SUPPORT_WHATSAPP = @"+972-52-369-5032";


+(BillingCycleLength)getBillingCycleLength:(PlanType)planType
{
    if (planType == DAILY_PLAN)
    {
        return DAYILY_BILLING_CYCLE;
    }
    else if (planType == WEEKLY_PLAN)
    {
        return WEEKLY_BILLING_CYCLE;
    }
    else if (planType == MONTHLY_PLAN)
    {
        return MONTHLY_BILLING_CYCLE;
    }
    else
    {
        return UNDEFINED_BILLING_CYCLE;
    }
}

@end
