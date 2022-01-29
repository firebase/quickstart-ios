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

import SwiftUI
import FirebaseCrashlytics

struct CrashButtonView: View {
  var body: some View {
    NavigationView {
      Button(action: {
        fatalError()
      }) {
        Text("Crash")
      }
      .navigationTitle("Crashlytics Example")
    }
  }
}

struct ContentView: View {
  private var crashlyticsReference = Crashlytics.crashlytics()

  #if compiler(>=5.5) && canImport(_Concurrency)
    @available(iOS 15, tvOS 15, macOS 12, watchOS 8, *) func checkForUnsentReportsAsync() async {
      let reportFound = await crashlyticsReference.checkForUnsentReports()
      if reportFound {
        crashlyticsReference.sendUnsentReports()
      }
    }
  #endif

  func checkForUnsentReports() {
    crashlyticsReference.checkForUnsentReports { reportFound in
      if reportFound {
        Crashlytics.crashlytics().sendUnsentReports()
      }
    }
  }

  var body: some View {
    if #available(iOS 15, tvOS 15, macOS 12, watchOS 8, *) {
      #if compiler(>=5.5) && canImport(_Concurrency)
        CrashButtonView()
          .task {
            await self.checkForUnsentReportsAsync()
          }
      #else
        CrashButtonView()
          .onAppear {
            self.checkForUnsentReports()
          }
      #endif
    } else {
      CrashButtonView()
        .onAppear {
          self.checkForUnsentReports()
        }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
