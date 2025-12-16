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
  lazy var download: PerformanceFunction = .download(self)
  lazy var classify: PerformanceFunction = .classify(self)
  lazy var saliencyMap: PerformanceFunction = .saliencyMap(self)
  lazy var upload: PerformanceFunction = .upload(self)

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

  func checkMainView() throws {
    XCTAssert(app.navigationBars["Performance"].exists, "Missing navigation title.")
    XCTAssert(app.navigationBars["Performance"].isHittable, "Navigation title not in view.")
  }

  func checkButtons(_ candidates: [PerformanceFunction]? = nil, timeout: TimeInterval = 1) throws {
    let functions: [PerformanceFunction] = candidates ?? [download, classify, saliencyMap, upload]
    for function in functions {
      let button = function.button
      let task = function.task
      XCTAssert(button.waitForExistence(timeout: timeout), "Missing \(task) button.")
      XCTAssert(button.isEnabled, "\(task) button not enabled.")
      XCTAssert(button.isHittable, "\(task) button not in view.")
    }
  }

  func checkText(_ text: String, timeout: TimeInterval = 1) throws {
    let element = app.staticTexts[text]
    XCTAssert(element.waitForExistence(timeout: timeout), "Missing text '\(text)'.")
    XCTAssert(element.isHittable, "Text '\(text)' not in view.")
  }

  func checkStatus(_ status: ProcessStatus, timeout: TimeInterval = 1) throws {
    try checkText(status.text, timeout: timeout)
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

  func download(run: Bool = false) throws {
    #if os(iOS)
      XCTAssert(download.button.isHittable, "Reached invalid state.")
      download.button.tap()
    #else
      if !run {
        XCUIRemote.shared.press(.up)
        XCUIRemote.shared.press(.up)
        XCUIRemote.shared.press(.up)
        sleep(1)
        XCTAssert(download.cell.hasFocus, "Reached invalid state.")
      }
      XCUIRemote.shared.press(.select)
    #endif
  }

  func classify(run: Bool = false) throws {
    #if os(iOS)
      XCTAssert(classify.button.isHittable, "Reached invalid state.")
      classify.button.tap()
    #else
      if !run {
        XCUIRemote.shared.press(.up)
        XCUIRemote.shared.press(.up)
        XCUIRemote.shared.press(.up)
        XCUIRemote.shared.press(.down)
        sleep(1)
        XCTAssert(classify.cell.hasFocus, "Reached invalid state.")
      }
      XCUIRemote.shared.press(.select)
    #endif
  }

  func saliencyMap(run: Bool = false) throws {
    #if os(iOS)
      XCTAssert(saliencyMap.button.isHittable, "Reached invalid state.")
      saliencyMap.button.tap()
    #else
      if !run {
        XCUIRemote.shared.press(.down)
        XCUIRemote.shared.press(.down)
        XCUIRemote.shared.press(.down)
        XCUIRemote.shared.press(.up)
        sleep(1)
        XCTAssert(saliencyMap.cell.hasFocus, "Reached invalid state.")
      }
      XCUIRemote.shared.press(.select)
    #endif
  }

  func upload(run: Bool = false) throws {
    #if os(iOS)
      XCTAssert(upload.button.isHittable, "Reached invalid state.")
      upload.button.tap()
    #else
      if !run {
        XCUIRemote.shared.press(.down)
        XCUIRemote.shared.press(.down)
        XCUIRemote.shared.press(.down)
        sleep(1)
        XCTAssert(upload.cell.hasFocus, "Reached invalid state.")
      }
      XCUIRemote.shared.press(.select)
    #endif
  }

  func checkEmptyView(function: PerformanceFunction) throws {
    try checkStatus(.idle)
    try checkButtons()
    try function.run(false)
    try checkText(function.emptyText)
    try checkStatus(.idle)
    try goBack()
  }

  func checkFunctionality(function: PerformanceFunction, startingStatus: ProcessStatus,
                          timeout: TimeInterval = 10) throws {
    try checkStatus(startingStatus)
    try checkButtons()
    try function.run(false)
    try checkButtons([function])
    try function.run(true)
    try checkText(function.endText, timeout: timeout)
    try checkStatus(.success(function.task))
    try goBack()
  }

  func checkDoneView(function: PerformanceFunction, lastTask: ProcessTask) throws {
    try checkStatus(.success(lastTask))
    try checkButtons()
    try function.run(false)
    try checkText(function.endText)
    try checkStatus(.success(lastTask))
    try goBack()
  }

  func testDownloadView() throws {
    try checkMainView()
    try checkEmptyView(function: download)
    try checkFunctionality(function: download, startingStatus: .idle)
  }

  func testClassifyView() throws {
    try checkMainView()
    try checkEmptyView(function: classify)
    try checkFunctionality(function: download, startingStatus: .idle)
    try checkFunctionality(function: classify, startingStatus: .success(.download))
  }

  func testSaliencyMapView() throws {
    try checkMainView()
    try checkEmptyView(function: saliencyMap)
    try checkFunctionality(function: download, startingStatus: .idle)
    try checkFunctionality(function: saliencyMap, startingStatus: .success(.download))
  }

  func testUploadView() throws {
    try checkMainView()
    try checkEmptyView(function: upload)
    try checkFunctionality(function: download, startingStatus: .idle)
    try checkFunctionality(function: saliencyMap, startingStatus: .success(.download))
    try checkFunctionality(function: upload, startingStatus: .success(.saliencyMap))
  }

  func testAllViews() throws {
    try checkMainView()

    try checkEmptyView(function: download)
    try checkEmptyView(function: classify)
    try checkEmptyView(function: saliencyMap)
    try checkEmptyView(function: upload)

    try checkFunctionality(function: download, startingStatus: .idle)
    try checkFunctionality(function: classify, startingStatus: .success(.download))
    try checkFunctionality(function: saliencyMap, startingStatus: .success(.classify))
    try checkFunctionality(function: upload, startingStatus: .success(.saliencyMap))

    try checkDoneView(function: download, lastTask: .upload)
    try checkDoneView(function: classify, lastTask: .upload)
    try checkDoneView(function: saliencyMap, lastTask: .upload)
    try checkDoneView(function: upload, lastTask: .upload)
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

enum PerformanceFunction {
  case download(UITests)
  case classify(UITests)
  case saliencyMap(UITests)
  case upload(UITests)

  var task: ProcessTask {
    switch self {
    case .download:
      return .download
    case .classify:
      return .classify
    case .saliencyMap:
      return .saliencyMap
    case .upload:
      return .upload
    }
  }

  var button: XCUIElement {
    switch self {
    case let .download(test):
      return test.app.buttons["Download Image"]
    case let .classify(test):
      return test.app.buttons["Classify Image"]
    case let .saliencyMap(test):
      return test.app.buttons["Generate Saliency Map"]
    case let .upload(test):
      return test.app.buttons["Upload Saliency Map"]
    }
  }

  var cell: XCUIElement {
    switch self {
    case let .download(test):
      return test.app.cells["Download Image"]
    case let .classify(test):
      return test.app.cells["Classify Image"]
    case let .saliencyMap(test):
      return test.app.cells["Generate Saliency Map"]
    case let .upload(test):
      return test.app.cells["Upload Saliency Map"]
    }
  }

  var endText: String {
    switch self {
    case .download:
      return "Image downloaded successfully!"
    case .classify:
      return "Categories found:"
    case .saliencyMap:
      return "Saliency map generated successfully!"
    case .upload:
      return "Saliency map uploaded successfully!"
    }
  }

  var emptyText: String {
    switch self {
    case .download, .classify, .saliencyMap:
      return "No image found!\nPlease download an image first."
    case .upload:
      return "No saliency map found!\nPlease download an image and generate a saliency map first."
    }
  }

  var run: (Bool) throws -> Void {
    switch self {
    case let .download(test):
      return test.download
    case let .classify(test):
      return test.classify
    case let .saliencyMap(test):
      return test.saliencyMap
    case let .upload(test):
      return test.upload
    }
  }
}
