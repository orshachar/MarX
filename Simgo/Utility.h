//
//  Utility.h
//  Simgo
//
//  Created by Felix on 13/10/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Definitions.h"
#import "Reachability.h"

@interface Utility : NSObject

+(void)showAlertDialog:(NSString *) title;
+(void)showAlertDialog:(NSString *) title message:(NSString *)message delegate:(NSObject *)delegate otherButtonTitles:(NSString *)otherButtonTitles;
+(void)showAlertDialog:(NSString *) title message:(NSString *)message delegate:(NSObject *)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles tag:(NSInteger *)tag;

+(NSMutableURLRequest *)prepareLoginRequest:(NSString *)userPhoneNumber country:(NSString *)userCountry password:(NSString *)userPassword;

+(void)showBusyHud:(NSString *)hudMessage view:(UIView *)view;
+(void)hideHud:(UIView *)view;

+(NSDictionary *)getHeadersWithSessionKey;
+(void)saveSessionKey:(NSURLResponse *) response;

+(NSDictionary *)getCountryList;

+(NetworkStatus) getNetworkStatus;
+(BOOL)isInternetReachable;

+(int) getMcc;
+(int) getMnc;
+(NSString *) getOperatorName;

+(NSString *) getDeviceType;

+(NSString *) getCloudAddress;

+(NSMutableURLRequest *) generateDeleteTripRequest:(int)tripId;
+(BOOL) parseDeleteTripResponse:(NSData *) responseData statusCode:(NSInteger)statusCode;

+(NSMutableURLRequest *)prepareTripStatusRequest:(int)tripId status:(NSString *)status;
+(NSDictionary *) parseTripStatusResponse:(NSData *) responseData statusCode:(NSInteger)statusCode;
+(NSArray *)simHeuristics:(NSDictionary *)currentStatus;
+(NSString *) generateTripStatusString;

+(NSString *) getCallState;
+(NSString *) getDataState;

+(NSArray *)getDataCounters;

+(NSString *) getUserInfoJson;

+(BOOL) isExtendedScreen;

+(void) copyToClipboad:(NSString *)textToCopy;

+(BOOL) isMobileDataConfigValid;

+(BOOL) isNumeric:(NSString *)inputString;

+(void) parseSupportInfo:(NSDictionary *)responseJson;

+(NSString *)findCurrentCountry;

@end
