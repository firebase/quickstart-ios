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

EXIT_STATUS=0

# Set have_secrets to true or false.
. ./scripts/check_secrets.sh

if [[ "$have_secrets" == true ]]; then
    (xcodebuild \
      -project "${PROJ_PATH}/${SAMPLE}Example.xcodeproj" \
      -scheme "${SAMPLE}Example (${OS})" \
      -sdk "${PLATFORM}simulator" \
      -destination "platform=${OS} Simulator,name=${DEVICE}" \
      build \
      test \
      ONLY_ACTIVE_ARCH=YES \
      OTHER_SWIFT_FLAGS=${SWIFT_DEFINES} \
      | xcpretty) || EXIT_STATUS=$?
else
    # Skip running tests if GoogleService-Info.plist's weren't decoded.
    (xcodebuild \
      -project "${PROJ_PATH}/${SAMPLE}Example.xcodeproj" \
      -scheme "${SAMPLE}Example (${OS})" \
      -sdk "${PLATFORM}simulator" \
      -destination "platform=${OS} Simulator,name=${DEVICE}" \
      build \
      ONLY_ACTIVE_ARCH=YES \
      OTHER_SWIFT_FLAGS=${SWIFT_DEFINES} \
      | xcpretty) || EXIT_STATUS=$?
    echo "Missing secrets: tests did not run."
fi

  exit $EXIT_STATUS
