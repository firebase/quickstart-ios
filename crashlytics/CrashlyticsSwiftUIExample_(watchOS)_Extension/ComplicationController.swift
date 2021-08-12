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

import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
  // MARK: - Complication Configuration

  func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
    let descriptors = [
      CLKComplicationDescriptor(
        identifier: "complication",
        displayName: "CrashlyticsExample",
        supportedFamilies: CLKComplicationFamily.allCases
      ),
      // Multiple complication support can be added here with more descriptors
    ]

    // Call the handler with the currently supported complication descriptors
    handler(descriptors)
  }

  func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
    // Do any necessary work to support these newly shared complication descriptors
  }

  // MARK: - Timeline Configuration

  func getTimelineEndDate(for complication: CLKComplication,
                          withHandler handler: @escaping (Date?) -> Void) {
    // Call the handler with the last entry date you can currently provide or nil if you can't support future timelines
    handler(nil)
  }

  func getPrivacyBehavior(for complication: CLKComplication,
                          withHandler handler: @escaping (CLKComplicationPrivacyBehavior)
                            -> Void) {
    // Call the handler with your desired behavior when the device is locked
    handler(.showOnLockScreen)
  }

  // MARK: - Timeline Population

  func getCurrentTimelineEntry(for complication: CLKComplication,
                               withHandler handler: @escaping (CLKComplicationTimelineEntry?)
                                 -> Void) {
    // Call the handler with the current timeline entry
    handler(nil)
  }

  func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int,
                          withHandler handler: @escaping ([CLKComplicationTimelineEntry]?)
                            -> Void) {
    // Call the handler with the timeline entries after the given date
    handler(nil)
  }

  // MARK: - Sample Templates

  func getLocalizableSampleTemplate(for complication: CLKComplication,
                                    withHandler handler: @escaping (CLKComplicationTemplate?)
                                      -> Void) {
    // This method will be called once per supported complication, and the results will be cached
    handler(nil)
  }
}
