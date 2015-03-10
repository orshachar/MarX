//
//  testSendSMS.swift
//  Simgo
//
//  Created by Or Shachar on 2/3/15.
//  Copyright (c) 2015 Simgo. All rights reserved.
//

import UIKit
import MessageUI
import XCTest

class testSendSMS: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        
        /*
            var messageVC = MFMessageComposeViewController()
            
            messageVC.body = "Enter a message";
            messageVC.recipients = ["Enter tel-nr"]
            messageVC.messageComposeDelegate 
            
            self.presentViewController(messageVC, animated: false, completion: nil)
    
    */
    
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSendSms() {
        // This is an example of a functional test case.
        
        var url:NSURL = NSURL(string: "sms://972526134557")!
        var DidSendSMS = (UIApplication.sharedApplication().openURL(url));
        
        UIApplication.sharedApplication().registerForRemoteNotifications();
        
        
        
       // var log = convenience init?(forWritingAtPath path:"~Documents");
        
       // var Log:NSString = NSString();
        
        
        //  Log.writeToFile(path: ~, atomically: <#Bool#>, encoding: <#UInt#>, error: <#NSErrorPointer#>)
        
        
        
        XCTAssert(DidSendSMS, "Pass")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }

}
