//
//  GPXTests.swift
//  
//
//  Created by Roderic Campbell on 6/17/22.
//

import XCTest
import CoreGPX
import CoreLocation

class GPXTests: XCTestCase {

  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  func testParseGPX() throws {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    // Any test you write for XCTest can be annotated as throws and async.
    // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
    // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.

//    [[NSBundle bundleForClass:[self class]] resourcePath]

    let testBundle = Bundle(for: type(of: self))
    print(testBundle)
    guard let url = Bundle.module.url(forResource: "BehindAvalon", withExtension: "gpx") else {
      XCTFail("unable to find gpx file")
      return
    }
    print(url)

    guard let gpx = GPXParser(withURL: url)?.parsedData() else {
      XCTFail("unable to parse gpx file")
      return
    }

    XCTAssertEqual(gpx.creator, "Navionics Boating App")
    XCTAssertEqual(gpx.tracks.count, 1)
    XCTAssertNotNil(gpx.metadata)

    guard let points = gpx.tracks.first?.segments.first?.points else {
      XCTFail("GPX has no points")
      return
    }

    guard let startTime = points.first?.time else {
      XCTFail("No start time")
      return
    }
    guard let endTime = points.last?.time else {
      XCTFail("No end time")
      return
    }

//    let locations = points.map({ point -> Point? in
//      guard let latitude = point.latitude, let longitude = point.longitude , let time = point.time else {
//        return nil
//      }
//      return Point(date: Date(), latitude: latitude, longitude: longitude)
//
//    }).compactMap { $0 }
//    let meta = Track(points: locations, startTime: startTime, endTime: endTime)
//    print(meta)
  }

  func testPerformanceExample() throws {
    // This is an example of a performance test case.
    self.measure {
      // Put the code you want to measure the time of here.
    }
  }

}
