//
//  Copyright 2021 Google LLC
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import XCTest
import CoreGraphics

class UITests: XCTestCase {
  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in
    // the class.
    #if !(os(iOS) || os(tvOS) || os(macOS) || os(watchOS))
      fatalError("Unsupported platform.")
    #endif

    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false

    // In UI tests it’s important to set the initial state - such as interface orientation -
    // required for your tests before they run. The setUp method is a good place to do this.
  }

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in
    // the class.
  }

  func testStaticUI() throws {
    // UI tests must launch the application that they test.
    let app = XCUIApplication()
    app.launch()

    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    #if !os(macOS)
      XCTAssertTrue(app.navigationBars["Firenotes"].exists,
                    "Firenotes is missing from the navigation bar")
    #else
      XCTAssert(app.windows.firstMatch.staticTexts["Firenotes"].exists,
                "Firenotes is missing from window")
    #endif

    XCTAssertTrue(app.buttons["Refresh"].exists, "Refresh button does not exist.")
    XCTAssertTrue(app.buttons["Refresh"].isEnabled, "Refresh button is not enabled.")
    XCTAssertTrue(app.buttons["Refresh"].isHittable, "Refresh button is missing from view.")

    #if !os(watchOS)
      let texts = [
        "Getting Started with Firebase", "An Introduction to Firebase",
        "Google Firestore", "Powerful Querying and Automatic Scaling",
        "Analytics", "Simple App Insights",
        "Remote Config", "Parameterize App Behavior",
        "A/B Testing", "Optimize App Experience through Experiments",
      ]
    #else
      let texts = ["Getting Started with Firebase", "An Introduction to Firebase"]
    #endif
    for text in texts {
      let element = app.staticTexts[text]
      // TODO: This if should be removed.
      #if targetEnvironment(macCatalyst)
        XCTAssertTrue(element.exists)
      #else
        XCTAssertTrue(element.isHittable, "Text '\(text)' is missing from view.")
      #endif
    }
  }

  func testDynamicUI() throws {
    let app = XCUIApplication()
    app.launch()

    #if os(iOS) || os(watchOS)
      app.buttons["Refresh"].tap()
    #elseif os(tvOS)
      XCUIRemote.shared.press(.select)
    #elseif os(macOS)
      app.buttons["Refresh"].click()
    #endif

    #if os(iOS) && swift(>=5.5)
      if #available(iOS 15, *) {
        let top = app.staticTexts["Getting Started with Firebase"]
          .coordinate(withNormalizedOffset: CGVector())
        let bottom = app.staticTexts["A/B Testing"]
          .coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 3))
        top.press(forDuration: 0, thenDragTo: bottom)
      }
    #endif
  }

  func testLaunchPerformance() throws {
    if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
      // This measures how long it takes to launch your application.
      measure(metrics: [XCTApplicationLaunchMetric()]) {
        XCUIApplication().launch()
      }
    }
  }
}
