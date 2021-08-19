#!/usr/bin/env bash

# Copyright 2021 Google
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Build the quickstart. If we're running on the main repo (not a fork), we
# also run the tests along with the decoded GoogleService-Info.plist files.

set -euo pipefail

# Check Xcode version when testing watchOS
if [[ "$TEST" == true && "$OS" == watchOS ]]; then
    version="$(xcode-select -p)"
    if [[ "$version" != "/Applications/Xcode_13.0.app" && \
          "$version" != "/Applications/Xcode_12.5.1.app" && \
          "$version" != "/Applications/Xcode_12.5.app" ]]; then
        echo "Xcode version does not yet supporting testing on watchOS"
        exit 1
    fi
fi

# Set project
PROJECT="${DIR}/${SAMPLE}Example.xcodeproj"

# Set scheme
if [[ "$SAMPLE" == Crashlytics ]]; then
    SCHEME="CrashlyticsSwiftUIExample (${OS})"
else
    SCHEME="${SAMPLE}Example (${OS})"
fi

# Set destination
if [[ "$OS" == iOS ]]; then
    DESTINATION="platform=iOS Simulator,name=${DEVICE}"
elif [[ "$OS" == tvOS ]]; then
    DESTINATION="platform=tvOS Simulator,name=${DEVICE}"
elif [[ "$OS" == watchOS ]]; then
    DESTINATION="platform=watchOS Simulator,name=${DEVICE}"
elif [[ "$OS" == macOS ]]; then
    DESTINATION="platform=macos"
else
    echo "Unsupported OS: ${OS}"
    exit 1
fi

if [[ "$TEST" == true && "$have_secrets" == true ]]; then
    xcodebuild \
     -project "$PROJECT" \
     -scheme "$SCHEME" \
     -destination "$DESTINATION" \
     build \
     test \
     ONLY_ACTIVE_ARCH=YES \
     CODE_SIGN_IDENTITY="" \
     CODE_SIGNING_REQUIRED=NO \
     CODE_SIGNING_ALLOWED=NO \
     OTHER_SWIFT_FLAGS=${SWIFT_DEFINES} \
     | xcpretty
else
    # Skip running tests if disabled or GoogleService-Info.plist's weren't decoded.
    xcodebuild \
     -project "$PROJECT" \
     -scheme "$SCHEME" \
     -destination "$DESTINATION" \
     build \
     ONLY_ACTIVE_ARCH=YES \
     CODE_SIGN_IDENTITY="" \
     CODE_SIGNING_REQUIRED=NO \
     CODE_SIGNING_ALLOWED=NO \
     OTHER_SWIFT_FLAGS=${SWIFT_DEFINES} \
     | xcpretty
    if [[ "$TEST" == true ]]; then
        echo "Missing secrets: tests did not run."
    fi
fi
