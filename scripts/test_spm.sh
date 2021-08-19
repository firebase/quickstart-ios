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

# Get Xcode version
system=$(uname -s)
case "$system" in
  Darwin)
    xcode_version=$(xcodebuild -version | head -n 1)
    xcode_version="${xcode_version/Xcode /}"
    xcode_major="${xcode_version/.*/}"
    ;;
  *)
    xcode_major="0"
    ;;
esac

# Check Xcode version when testing watchOS
if [[ "$TEST" == true && \
      "$OS" == watchOS && \
      "$xcode_major" -lt 13 && \
      "$xcode_version" != "12.5.1" && \
      "$xcode_version" != "12.5" ]]; then
    echo "Xcode version does not yet supporting testing on watchOS"
    exit 1
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

if [[ "$TEST" == true && "$have_secrets" == true ]]; then
    xcb -project "$PROJECT" -scheme "$SCHEME" "${flags[@]}" build test
else
    xcb -project "$PROJECT" -scheme "$SCHEME" "${flags[@]}" build
    if [[ "$TEST" == true ]]; then
        echo "Missing secrets: tests did not run."
    fi
fi
