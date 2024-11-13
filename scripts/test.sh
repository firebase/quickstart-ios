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

if [ -d "/Applications/Xcode_16.1.app" ]; then
    xcode_version="16.1"
    iphone_version="16"
else
    xcode_version="15.3"
    iphone_version="15"
fi

# Set default parameters
if [[ -z "${SPM:-}" ]]; then
    SPM=false
    echo "Defaulting to SPM=$SPM"
    if [[ -z "${LEGACY:-}" ]]; then
        LEGACY=false
        echo "Defaulting to LEGACY=$LEGACY"
    fi
fi
if [[ -z "${OS:-}" ]]; then
    OS=iOS
    DEVICE="iPhone ${iphone_version}"
    echo "Defaulting to OS=$OS"
    echo "Defaulting to DEVICE=$DEVICE"
fi
if [[ -z "${TEST:-}" ]]; then
    TEST=true
    echo "Defaulting to TEST=$TEST"
fi

# Set have_secrets to true or false.
source scripts/check_secrets.sh

# Initialize flags
flags=()

# Set project / workspace
if [[ "$SPM" == true ]];then
    flags+=( -project "${DIR}/${SAMPLE}Example.xcodeproj" )
else
    if [[ "$LEGACY" == true ]]; then
        WORKSPACE="${SAMPLE}/Legacy${SAMPLE}Quickstart/${SAMPLE}Example.xcworkspace"
    else
        WORKSPACE="${SAMPLE}/${SAMPLE}Example.xcworkspace"
    fi
    flags+=( -workspace "$WORKSPACE" )
fi

# Set scheme
if [[ -z "${SCHEME:-}" ]]; then
    if [[ "$SPM" == true ]];then
        SCHEME="${SAMPLE}Example (${OS})"
    else
        SCHEME="${SAMPLE}Example${SWIFT_SUFFIX:-}"
    fi
fi

flags+=( -scheme "$SCHEME" )

# Set destination
if [[ "$OS" == iOS ]]; then
    DESTINATION="platform=iOS Simulator,name=${DEVICE}"
    flags+=( -destination "$DESTINATION" )
elif [[ "$OS" == tvOS ]]; then
    DESTINATION="platform=tvOS Simulator,name=${DEVICE}"
    flags+=( -destination "$DESTINATION" )
elif [[ "$OS" == macOS || "$OS" == catalyst ]]; then
    DESTINATION="platform=macOS"
    flags+=( -destination "$DESTINATION" )
elif [[ "$OS" == watchOS ]]; then
    DESTINATION="platform=watchOS Simulator,name=${DEVICE}"
else
    echo "Unsupported OS: ${OS}"
    exit 1
fi

# Add extra flags

if [[ "$SAMPLE" == Config ]];then
    flags+=( -configuration Debug )
fi

if [[ "$OS" == catalyst ]];then
    flags+=(
        ARCHS=x86_64
        VALID_ARCHS=x86_64
        SUPPORTS_MACCATALYST=YES
        SUPPORTS_UIKITFORMAC=YES
    )
fi

flags+=(
    CODE_SIGNING_REQUIRED=NO
    CODE_SIGNING_ALLOWED=NO
    build
)

# Check whether to test on top of building
message=""
if [[ "$TEST" == true && "$have_secrets" == true ]]; then
    flags+=( test )
elif [[ "$TEST" == true ]]; then
    message="Missing secrets: tests did not run."
else
    message="Tests did not run."
fi

function xcb() {
    echo xcodebuild "$@"
    xcodebuild "$@" | xcpretty
}

# Run xcodebuild
sudo xcode-select -s "/Applications/Xcode_${xcode_version}.app/Contents/Developer"
xcb "${flags[@]}"
echo "$message"
