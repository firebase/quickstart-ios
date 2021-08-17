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

class UITests: XCTestCase {
  var app: XCUIApplication = XCUIApplication()

  override func setUpWithError() throws {
    #if !os(iOS) && !os(tvOS)
      throw Error("Unsupported platform.")
    #endif

    continueAfterFailure = false

    app.launch()
  }

  override func tearDownWithError() throws {
    app.terminate()
  }

  func checkButtons(_ functions: [String], timeout: TimeInterval = 1) throws {
    for function in functions {
      let button = app.buttons["\(function) Image"]
      XCTAssert(button.waitForExistence(timeout: timeout), "Missing \(function) button.")
      XCTAssert(button.isEnabled, "\(function) button not enabled.")
      XCTAssert(button.isHittable, "\(function) button not in view.")
    }
  }

  func checkText(_ text: String, timeout: TimeInterval = 1) throws {
    let element = app.staticTexts[text]
    XCTAssert(element.waitForExistence(timeout: timeout), "Missing text '\(text)'.")
    XCTAssert(element.isHittable, "Text '\(text)' not in view.")
  }

  func checkStatus(_ status: String, timeout: TimeInterval = 1) throws {
    #if os(iOS)
      try checkText(status, timeout: timeout)
    #endif
  }

  func goBack(timeout: TimeInterval = 1) throws {
    #if os(iOS)
      XCTAssert(app.buttons["Performance"].isHittable, "Reached invalid state.")
      app.buttons["Performance"].tap()
    #else
      XCUIRemote.shared.press(.menu)
      XCTAssert(app.navigationBars["Performance"].waitForExistence(timeout: timeout), "Timeout.")
    #endif
  }

  func classify(image: Bool = false) throws {
    #if os(iOS)
      XCTAssert(app.buttons["Classify Image"].isHittable, "Reached invalid state.")
      app.buttons["Classify Image"].tap()
    #else
      if !image {
        XCUIRemote.shared.press(.down)
        XCUIRemote.shared.press(.down)
        XCUIRemote.shared.press(.up)
        sleep(1)
        XCTAssert(app.cells["Classify Image"].hasFocus, "Reached invalid state.")
      }
      XCUIRemote.shared.press(.select)
    #endif
  }

  func download(image: Bool = false, timeout: TimeInterval = 10) throws {
    #if os(iOS)
      XCTAssert(app.buttons["Download Image"].isHittable, "Reached invalid state.")
      app.buttons["Download Image"].tap()
    #else
      if !image {
        XCUIRemote.shared.press(.up)
        XCUIRemote.shared.press(.up)
        sleep(1)
        XCTAssert(app.cells["Download Image"].hasFocus, "Reached invalid state.")
      }
      XCUIRemote.shared.press(.select)
    #endif
    if image {
      XCTAssert(app.images.firstMatch.waitForExistence(timeout: timeout),
                "Failed to retrieve image.")
      try checkText("Image downloaded successfully!")
    }
  }

  func upload(image: Bool = false, timeout: TimeInterval = 10) throws {
    #if os(iOS)
      XCTAssert(app.buttons["Upload Image"].isHittable, "Reached invalid state.")
      app.buttons["Upload Image"].tap()
    #else
      if !image {
        XCUIRemote.shared.press(.down)
        XCUIRemote.shared.press(.down)
        sleep(1)
        XCTAssert(app.cells["Upload Image"].hasFocus, "Reached invalid state.")
      }
      XCUIRemote.shared.press(.select)
    #endif
    if image { try checkText("Image uploaded successfully!") }
  }

  func testAllViews() throws {
    let buttons = ["Download", "Classify", "Upload"]

    XCTAssert(app.navigationBars["Performance"].exists, "Missing navigation title.")
    XCTAssert(app.navigationBars["Performance"].isHittable, "Navigation title not in view.")

    // Download - Empty
    try checkStatus("⏸ Idle")
    try checkButtons(buttons)
    try download()
    try checkText("No image found!\nPlease download an image first.")
    try checkStatus("⏸ Idle")
    try goBack()

    // Classify - Empty
    try checkStatus("⏸ Idle")
    try checkButtons(buttons)
    try classify()
    try checkText("No image found!\nPlease download an image first.")
    try checkStatus("⏸ Idle")
    try goBack()

    // Upload - Empty
    try checkStatus("⏸ Idle")
    try checkButtons(buttons)
    try upload()
    try checkText("No image found!\nPlease download an image first.")
    try checkStatus("⏸ Idle")
    try goBack()

    // Download - Image
    try checkStatus("⏸ Idle")
    try checkButtons(buttons)
    try download()
    try checkButtons(["Download"])
    try download(image: true)
    try checkText("Image downloaded successfully!", timeout: 5)
    try checkStatus("✅ Success")
    try goBack()

    // Classify - Image
    try checkStatus("✅ Success")
    try checkButtons(buttons)
    try classify()
    try checkButtons(["Classify"])
    try classify(image: true)
    try checkText("Categories found:", timeout: 5)
    try checkStatus("✅ Success")
    try goBack()

    // Upload - Image
    try checkStatus("✅ Success")
    try checkButtons(buttons)
    try upload()
    try checkButtons(["Upload"])
    try upload(image: true)
    try checkText("Image uploaded successfully!", timeout: 5)
    try checkStatus("✅ Success")
    try goBack()

    // Download - Done
    try checkStatus("✅ Success")
    try checkButtons(buttons)
    try download()
    try checkText("Image downloaded successfully!")
    try checkStatus("✅ Success")
    try goBack()

    // Classify - Done
    try checkStatus("✅ Success")
    try checkButtons(buttons)
    try classify()
    try checkText("Categories found:")
    try checkStatus("✅ Success")
    try goBack()

    // Upload - Done
    try checkStatus("✅ Success")
    try checkButtons(buttons)
    try upload()
    try checkText("Image uploaded successfully!")
    try checkStatus("✅ Success")
    try goBack()
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
