//
// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import XCTest

class UITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testStaticUI() throws {
    let app = XCUIApplication()
    app.launch()
    #if !os(macOS)
      XCTAssertTrue(
        app.navigationBars["Crashlytics Example"].exists,
        "Crashlytics Example is missing from the navigation bar"
      )
    #endif
    XCTAssertTrue(app.buttons["Crash"].exists, "Crash button does not exist.")
    XCTAssertTrue(app.buttons["Crash"].isEnabled, "Crash button is not enabled.")
    XCTAssertTrue(app.buttons["Crash"].isHittable, "Crash button is missing from the view.")
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
