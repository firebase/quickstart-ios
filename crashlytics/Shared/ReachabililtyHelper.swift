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

import FirebaseCrashlytics
import Foundation
import Network

class ReachabililtyHelper: NSObject {
    private let monitor: NWPathMonitor

    override init() {
        monitor = NWPathMonitor()
        super.init()
    }

    /**
     * Retrieve the locale information for the app.
     */
    func getLocale() -> String {
        return Locale.preferredLanguages[0]
    }

    /**
     * Retrieve the network status for the app.
     */
    func getNetworkStatus() -> String {
        return networkStatus(from: monitor.currentPath)
    }

    private func networkStatus(from path: NWPath) -> String {
        if path.status == .satisfied {
            if path.usesInterfaceType(.wifi) {
                return "wifi"
            } else if path.usesInterfaceType(.cellular) {
                return "cellular"
            } else if path.usesInterfaceType(.wiredEthernet) {
                return "wired"
            } else {
                return "other"
            }
        } else {
            return "unavailable"
        }
    }

    /**
     * Add a hook to update network status going forward.
     */
    func updateAndTrackNetworkStatus() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let status = self.networkStatus(from: path)
            Crashlytics.crashlytics().setCustomValue(status, forKey: "network_connection")
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
}
