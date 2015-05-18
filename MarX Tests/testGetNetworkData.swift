//
//  testGetNetworkData.swift
//  Simgo
//
//  Created by Or Shachar on 2/1/15.
//  Copyright (c) 2015 Simgo. All rights reserved.
//

import XCTest
import CoreTelephony



//import XCGLogger













class testGetNetworkData: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        
        
            
        
    
        
        
       
        
        
        
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // Verify that there is a data connection
    
    
    func testHasConnectivity()  {
        
        
        
        let reachability: Reachability = Reachability.reachabilityForInternetConnection()
        
        
        let DataStatus: Int = reachability.currentReachabilityStatus().value
        
        
        XCTAssert(DataStatus != 0, "there is no data connection")
        
    }
    
    

    func testGetNetworkInfo() {
        
        
        // This is an example of a functional test case.

        
        
        
        
      
        
        var NetworkInfo = CTTelephonyNetworkInfo ();
        
        
        var subscriberCellularProviderDidUpdateNotifier: ((CTCarrier!) -> Void)!
        
        var Carrier = CTCarrier();
        var temp = Carrier.mobileCountryCode;
        
        
        
        
        var CellularProvider = NetworkInfo.subscriberCellularProvider;
        
        var MCC = CellularProvider.mobileCountryCode
        var MNC = CellularProvider.mobileNetworkCode
        
        
        
        println(MCC);
        println(MNC);
        
        CellularProvider.carrierName
        
        
        var isUpdateCellular = NetworkInfo.subscriberCellularProviderDidUpdateNotifier;
        
        
        
      
        XCTAssertNotNil(CellularProvider, "Cellular Provider Updated")
    
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }

}
