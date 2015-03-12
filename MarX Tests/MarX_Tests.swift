//
//  MarX_Tests.swift
//  MarX Tests
//
//  Created by Or Shachar on 2/22/15.
//  Copyright (c) 2015 Simgo. All rights reserved.
//

import UIKit
import XCTest
import CoreTelephony

class MarX_Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        
        
        var url:NSURL = NSURL(string: "tel://972526134557")!
        // UIApplication.sharedApplication().openURL(url);
        
        var url2:NSURL = NSURL(string: "http://www.ynet.co.il")!
        UIApplication.sharedApplication().openURL(url);
        
        
        var Call = CTCall();
        var CallID = Call.callID!
        var CallState = Call.callState
        
        println (CallID)
        println (CallState)
        
        
        
        
        XCTAssert(true, "Pass")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
