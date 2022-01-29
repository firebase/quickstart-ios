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

import SwiftUI
import FirebaseAnalytics

private enum Season: String, CaseIterable {
  case spring = "Spring"
  case summer = "Summer"
  case autumn = "Autumn"
  case winter = "Winter"
}

private enum UnitOfTemperature: String, CaseIterable {
  case celsius = "Celsius"
  case fahrenheit = "Fahrenheit"
}

private enum WeatherPreference: String, CaseIterable {
  case hot = "Hot"
  case cold = "Cold"

  var iconName: String {
    switch self {
    case .hot: return "thermometer.sun.fill"
    case .cold: return "thermometer.snowflake"
    }
  }
}

private enum PrecipitationPreference: String, CaseIterable {
  case rainy = "Rainy"
  case sunny = "Sunny"

  var iconName: String {
    switch self {
    case .rainy: return "cloud.rain.fill"
    case .sunny: return "sun.max.fill"
    }
  }
}

struct ContentView: View {
  @State private var selectedSeason: Season?

  @State private var selectedUnit: UnitOfTemperature?

  @State private var selectedWeatherPreference: WeatherPreference?

  @State private var selectedPrecipitationPreference: PrecipitationPreference?

  var body: some View {
    // tvOS needs a navigation title to look better.
    #if os(tvOS)
      NavigationView {
        allContent
      }
    #else
      // tvOS includes padding by default in the layout, but other platforms don't.
      allContent
        .padding()
    #endif // os(tvOS)
  }

  private var allContent: some View {
    VStack(alignment: .leading) {
      Text("Interact with the various controls to start collecting analytics data.")

      Divider()

      Text("Set user properties")
        .font(.title2)

      weatherProperties
      Divider()

      Text("Log user interactions with events")
        .font(.title2)

      logEventsView
    }.navigationTitle("Firebase Analytics")
      .onAppear {
        Analytics.setUserID(UUID().uuidString)
        Analytics.logEvent("greetings", parameters: nil)
      }
  }

  private var weatherProperties: some View {
    VStack {
      Picker("Favorite Season", selection: $selectedSeason) {
        Text("None").tag(Optional<Season>.none)

        ForEach(Season.allCases, id: \.rawValue) { season in
          Text(season.rawValue).tag(season as Season?)
        }
      }.onChange(of: selectedSeason) { newSelectedSeason in
        Analytics.setUserProperty(newSelectedSeason?.rawValue, forName: "favorite_season") // 🔥
      }

      GeometryReader { proxy in
        ZStack {
          // The blank background.
          RoundedRectangle(cornerRadius: 16)
            .foregroundColor(.secondary)

          Text("""
          Set user properties when a user
          selects their favorite season ↑ or
          preferred temperature units ↓
          """)
            .multilineTextAlignment(.center)

          // The selected image, if there is one.
          selectedSeason.map { season in
            Image(season.rawValue)
              .resizable()
              .scaledToFill()
              .frame(maxHeight: proxy.size.height)
              .clipped()
              .cornerRadius(16)
          }
        }
      }

      // Preferred Temperature Stack
      HStack {
        Text("Preferred Temperature Units:")
          .foregroundColor(.secondary)

        Spacer()

        Picker("Preferred Temperature Units", selection: $selectedUnit) {
          Text("None").tag(Optional<UnitOfTemperature>.none)

          ForEach(UnitOfTemperature.allCases, id: \.rawValue) { unit in
            Text(unit.rawValue).tag(unit as UnitOfTemperature?)
          }
        }.pickerStyle(SegmentedPickerStyle())
          .onChange(of: selectedUnit) { newSelectedUnits in
            Analytics.setUserProperty(newSelectedUnits?.rawValue, forName: "preferred_units") // 🔥
          }
      }
    }
  }

  private var logEventsView: some View {
    VStack {
      // Hot or Cold stack
      HStack {
        Text("Hot or cold weather?")
          .foregroundColor(.secondary)

        Spacer()

        // Selected icon, if there's a selection.
        selectedWeatherPreference.map { Image(systemName: $0.iconName) }

        Picker("Weather Temperature Preference", selection: $selectedWeatherPreference) {
          Text("None").tag(Optional<WeatherPreference>.none)

          ForEach(WeatherPreference.allCases, id: \.rawValue) { weather in
            // Cast the tag to ensure it's an Optional (matches the stored type).
            Text(weather.rawValue).tag(weather as WeatherPreference?)
          }
        }.pickerStyle(SegmentedPickerStyle())
          .onChange(of: selectedWeatherPreference) { newSelectedWeather in
            guard let selection = newSelectedWeather else { return }
            Analytics.logEvent("hot_or_cold_switch", parameters: ["value": selection.rawValue]) // 🔥
          }
      }

      // Rainy or Sunny Stack
      HStack {
        Text("Rainy or sunny days?")
          .foregroundColor(.secondary)

        Spacer()

        // Selected icon, if there's a selection.
        selectedPrecipitationPreference.map { Image(systemName: $0.iconName) }

        Picker("Precipitation Preference", selection: $selectedPrecipitationPreference) {
          Text("None").tag(Optional<PrecipitationPreference>.none)

          ForEach(PrecipitationPreference.allCases, id: \.rawValue) { precipitation in
            Text(precipitation.rawValue).tag(precipitation as PrecipitationPreference?)
          }
        }.pickerStyle(SegmentedPickerStyle())
          .onChange(of: selectedPrecipitationPreference) { newPrecipPreference in
            guard let selection = newPrecipPreference else { return }
            Analytics
              .logEvent("rainy_or_sunny_switch", parameters: ["value": selection.rawValue]) // 🔥
          }
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
