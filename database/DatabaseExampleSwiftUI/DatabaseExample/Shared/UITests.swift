//
//  Copyright (c) 2021 Google Inc.
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
  let app: XCUIApplication = XCUIApplication()

  override func setUpWithError() throws {
    #if !os(iOS) && !os(macOS) && !os(tvOS)
      throw Error("Unsupported platform.")
    #endif
    continueAfterFailure = false
    app.launch()
  }

  override func tearDownWithError() throws {
    app.terminate()
  }

  func checkText(_ text: String, _ view: String) throws {
    let staticText = app.staticTexts[text]
    XCTAssert(staticText.exists, "Missing text '\(text)' in '\(view)'.")
    XCTAssert(staticText.isHittable, "Text '\(text)' not in '\(view)'.")
  }

  func checkTextFields(_ text: String, _ view: String) throws {
    let textField = app.textFields[text]
    XCTAssert(textField.exists, "Missing text field '\(text)' in '\(view)'.")
  }

  func checkSecureTextFields(_ text: String, _ view: String) throws {
    let secureTextField = app.secureTextFields[text]
    XCTAssert(secureTextField.exists, "Missing secure text field '\(text)' in '\(view)'.")
  }

  func checkButtons(_ text: String, _ view: String) throws {
    let button = app.buttons[text]
    XCTAssert(button.exists, "Missing button '\(text)' in '\(view)'.")
  }

  func testStaticLoginView() throws {
    let view = "LoginView"
    try checkText("Login".uppercased(), view)
    try checkTextFields("Email", view)
    try checkSecureTextFields("Password", view)
    try checkButtons("Login".uppercased(), view)
    try checkText("Don't have an account?", view)
    try checkButtons("Sign up".uppercased(), view)
  }

  func testStaticSignUpView() throws {
    let view = "SignUpView"
    #if os(iOS)
      app.buttons["Sign up".uppercased()].tap()
    #elseif os(macOS)
      app.buttons["Sign up".uppercased()].click()
    #elseif os(tvOS)
      XCUIRemote.shared.press(.down)
      XCUIRemote.shared.press(.down)
      XCUIRemote.shared.press(.down)
      XCUIRemote.shared.press(.select)
    #endif
    try checkText("Sign up".uppercased(), view)
    try checkTextFields("Email", view)
    try checkSecureTextFields("Password", view)
    try checkButtons("Sign up".uppercased(), view)
    try checkText("Already have an account?", view)
    try checkButtons("Login".uppercased(), view)
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
