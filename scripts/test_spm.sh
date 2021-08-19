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

# Initialize flags
flags=()

# Set project
PROJECT="${DIR}/${SAMPLE}Example.xcodeproj"

# Set scheme
SCHEME="${SAMPLE}Example (${OS})"

# Set destination
if [[ "$OS" == iOS ]]; then
    DESTINATION="platform=iOS Simulator,name=${DEVICE}"
    flags+=( -destination "$DESTINATION" )
elif [[ "$OS" == tvOS ]]; then
    DESTINATION="platform=tvOS Simulator,name=${DEVICE}"
    flags+=( -destination "$DESTINATION" )
elif [[ "$OS" == macOS ]]; then
    DESTINATION="platform=macos"
    flags+=( -destination "$DESTINATION" )
elif [[ "$OS" == watchOS ]]; then
    DESTINATION="platform=watchOS Simulator,name=${DEVICE}"
else
    echo "Unsupported OS: ${OS}"
    exit 1
fi

flags+=(
    ONLY_ACTIVE_ARCH=YES
    CODE_SIGNING_REQUIRED=NO
    CODE_SIGNING_ALLOWED=NO
    OTHER_SWIFT_FLAGS=${SWIFT_DEFINES}
)

function xcb() {
    echo xcodebuild "$@"
    xcodebuild "$@" | xcpretty
}

# xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showdestinations

if [[ "$TEST" == true && "$have_secrets" == true ]]; then
    xcb -project "$PROJECT" -scheme "$SCHEME" "${flags[@]}" build test
else
    xcb -project "$PROJECT" -scheme "$SCHEME" "${flags[@]}" build
    if [[ "$TEST" == true ]]; then
        echo "Missing secrets: tests did not run."
    fi
fi
