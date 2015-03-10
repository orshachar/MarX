//
//  AddressBookHelper.m
//  Simgo
//
//  Created by Felix on 29/10/13.
//  Copyright (c) 2013 Simgo. All rights reserved.
//

#import "AddressBookHelper.h"
#import <AddressBook/AddressBook.h>

@interface AddressBookHelper ()

@end

@implementation AddressBookHelper


+(BOOL)getAddressBookPermission
{
    __block BOOL result = false;
    
    // Request authorization to Address Book
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
    {
        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error)
                                                 {
                                                     if (granted)
                                                     {
                                                         // First time access has been granted, add the contact
                                                         result = true;
                                                     }
                                                     else
                                                     {
                                                         // User denied access
                                                         // Display an alert telling user the contact could not be added
                                                     }
                                                 });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
    {
        // The user has previously given access, add the contact
        result = true;
    }
    else
    {
        // The user has previously denied access
        // Send an alert telling user to change privacy setting in settings app
    }
    
    return result;
}

+(BOOL)createNewContact:(NSString *)firstName lastName:(NSString *)lastName phoneNumber:(NSString *)phoneNumber
{
    if ([self getAddressBookPermission] == false)
    {
        NSLog(@"Can't access address book");
        return false;
    }
    
    CFErrorRef error = NULL;
    ABAddressBookRef iPhoneAddressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    ABRecordRef newPerson = ABPersonCreate();
    
    ABRecordSetValue(newPerson, kABPersonFirstNameProperty, (__bridge CFTypeRef)(firstName), &error);
    ABRecordSetValue(newPerson, kABPersonLastNameProperty, (__bridge CFTypeRef)(lastName), &error);
    
    ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    ABMultiValueAddValueAndLabel(multiPhone, (__bridge CFTypeRef)(phoneNumber), kABOtherLabel, NULL);
    ABRecordSetValue(newPerson, kABPersonPhoneProperty, multiPhone,nil);
    CFRelease(multiPhone);
    
    ABAddressBookAddRecord(iPhoneAddressBook, newPerson, &error);
    ABAddressBookSave(iPhoneAddressBook, &error);
    
    if (error != NULL)
    {
        NSLog(@"Failed to create call forwarding phonebook record");
        return false;
    }
    
    return true;
}

@end
