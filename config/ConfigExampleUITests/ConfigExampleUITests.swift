// Copyright 2020 Google LLC
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

import XCTest

class ConfigExampleUITests: XCTestCase {
  var app: XCUIApplication!

  override func setUp() {
    super.setUp()

    continueAfterFailure = false

    app = XCUIApplication()
    app.launch()
  }

  func testConfigStartup() {
    // dismiss dialogue
    #if !targetEnvironment(macCatalyst)
      if app.buttons["OK"].exists {
        app.buttons["OK"].tap()
      }
      // Verify that Config Example app launched successfully
      XCTAssertTrue(app.navigationBars["Firebase Config"].waitForExistence(timeout: 10))
    #endif
    // TODO: Tests on Catalyst
  }
}
