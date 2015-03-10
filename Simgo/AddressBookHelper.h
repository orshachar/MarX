//
//  AddressBookHelper.h
//  Simgo
//
//  Created by Felix on 29/10/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AddressBookHelper : NSObject

+(BOOL)getAddressBookPermission;

+(BOOL)createNewContact:(NSString *)firstName lastName:(NSString *)lastName phoneNumber:(NSString *)phoneNumber;

@end
