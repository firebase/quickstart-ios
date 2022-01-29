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

struct ContentView: View {
  @ObservedObject var appConfig: AppConfig
  var body: some View {
    #if !os(macOS)
      NavigationView { FirebaseList(appConfig: appConfig) }
        .navigationViewStyle(StackNavigationViewStyle())
    #else
      FirebaseList(appConfig: appConfig)
    #endif
  }
}

struct FirebaseList: View {
  @ObservedObject var appConfig: AppConfig
  let data: [(title: String, subtitle: String)] = [
    ("Getting Started with Firebase", "An Introduction to Firebase"),
    ("Google Firestore", "Powerful Querying and Automatic Scaling"),
    ("Analytics", "Simple App Insights"),
    ("Remote Config", "Parameterize App Behavior"),
    ("A/B Testing", "Optimize App Experience through Experiments"),
  ]
  var body: some View {
    VStack {
      #if compiler(>=5.5) && canImport(_Concurrency)
        if #available(iOS 15, tvOS 15, macOS 12, watchOS 8, *) {
          BasicList(data: data)
            .preferredColorScheme(appConfig.colorScheme)
            .foregroundColor(appConfig.colorScheme == .dark ? .orange : .primary)
            .task { await appConfig.updateFromRemoteConfigAsync() }
            .refreshable { await appConfig.updateFromRemoteConfigAsync() }
        } else {
          BasicList(data: data)
            .preferredColorScheme(appConfig.colorScheme)
            .foregroundColor(appConfig.colorScheme == .dark ? .orange : .primary)
            .onAppear { appConfig.updateFromRemoteConfig() }
        }
      #else
        BasicList(data: data)
          .preferredColorScheme(appConfig.colorScheme)
          .foregroundColor(appConfig.colorScheme == .dark ? .orange : .primary)
          .onAppear { appConfig.updateFromRemoteConfig() }
      #endif
      Button("Refresh") { appConfig.updateFromRemoteConfig() }
      Spacer()
    }
    .navigationTitle("Firenotes")
  }
}

struct BasicList: View {
  let data: [(title: String, subtitle: String)]
  var body: some View {
    List(data, id: \.title) { item in
      VStack(alignment: .leading) {
        Text(item.title)
        Text(item.subtitle).font(.subheadline)
      }
    }
    .listStyle(PlainListStyle())
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(appConfig: AppConfig())
  }
}
