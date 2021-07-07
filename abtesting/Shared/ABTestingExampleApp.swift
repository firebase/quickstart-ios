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

import SwiftUI
import Firebase

@main
struct ABTestingExampleApp: App {
  var appConfig: AppConfig
  init() {
    FirebaseApp.configure()
    let remoteConfig = RemoteConfig.remoteConfig()
    #if DEBUG
      let devSettings = RemoteConfigSettings()
      devSettings.minimumFetchInterval = 0
      remoteConfig.configSettings = devSettings
    #endif
    remoteConfig.setDefaults(["color_scheme": "light" as NSObject])
    appConfig = AppConfig()
  }

  var body: some Scene {
    WindowGroup {
      ContentView(appConfig: appConfig)
    }
  }
}
