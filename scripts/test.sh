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

xcode_version=$(xcodebuild -version | grep Xcode)
xcode_version="${xcode_version/Xcode /}"
xcode_major="${xcode_version/.*/}"

if [[ "$xcode_major" -ge 26 ]]; then
  iphone_version="17"
elif [[ "$xcode_major" -ge 16 ]]; then
  iphone_version="16"
else
  echo "Unsupported Xcode version $xcode_version; exiting." 1>&2
  exit 1
fi

# Set default parameters
if [[ -z "${SPM:-}" ]]; then
    SPM=false
    echo "Defaulting to SPM=$SPM"
fi
if [[ -z "${LEGACY:-}" ]]; then
    LEGACY=false
    echo "Defaulting to LEGACY=$LEGACY"
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

# Determine Project Path and OS based on LEGACY flag.
if [[ "$LEGACY" == true ]]; then
    echo "Configuring for LEGACY build."
    if [[ "$SPM" == true ]]; then
      PROJECT_PATH="${SAMPLE}/Legacy${SAMPLE}Quickstart/${SAMPLE}Example.xcodeproj"
    else
      WORKSPACE_PATH="${SAMPLE}/Legacy${SAMPLE}Quickstart/${SAMPLE}Example.xcworkspace"
    fi
else
    echo "Configuring for NON-LEGACY build."
    if [[ "$SPM" == true ]]; then
      # For non-legacy, DIR is passed from the workflow and is the product name.
      # This is the same as SAMPLE.
      PROJECT_PATH="${DIR}/${SAMPLE}Example.xcodeproj"
    else
      WORKSPACE_PATH="${SAMPLE}/${SAMPLE}Example.xcworkspace"
    fi
fi

# Initialize flags
flags=()

# Set destination (now uses the potentially overridden OS variable)
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
    CODE_SIGN_IDENTITY=-
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
    echo "xcodebuild $@"
    xcodebuild "$@" | xcpretty
}

# Run xcodebuild
sudo xcode-select -s "/Applications/Xcode_${xcode_version}.app/Contents/Developer"

if [[ "$SPM" == true ]]; then
    if [ ! -d "$PROJECT_PATH" ]; then
        echo "Project path does not exist: $PROJECT_PATH"
        exit 1
    fi
    # Get all schemes from the project, excluding test bundles.
    all_schemes=$(xcodebuild -list -project "$PROJECT_PATH" |
              grep -E '^\s+' |
              sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' |
              grep -v "Tests")

    # Filter for schemes that are relevant to the current OS.
    # This includes schemes with the OS in their name (e.g., "VisionProExample (visionOS)")
    # and generic schemes that don't specify any OS.
    filtered_schemes=$(echo "$all_schemes" | grep -E "(\(${OS}\)$)|(^((?!iOS|tvOS|macOS|watchOS|catalyst|visionOS).)*$)")

    if [ -z "$filtered_schemes" ]; then
        echo "Error: Could not find any suitable schemes for ${SAMPLE}Example in ${OS}."
        echo "Available schemes:"
        echo "$all_schemes"
        exit 1
    fi

    echo "Found schemes to build for OS ${OS}: $filtered_schemes"
    for scheme in $filtered_schemes; do
        echo "Building scheme: $scheme"
        # Create a temporary flags array for this build
        local_flags=("${flags[@]}")
        local_flags+=( -project "$PROJECT_PATH" )
        local_flags+=( -scheme "$scheme" )
        xcb "${local_flags[@]}"
    done
else
    # Legacy workspace logic
    SCHEME="${SAMPLE}Example${SWIFT_SUFFIX:-}"
    local_flags=("${flags[@]}")
    local_flags+=( -workspace "$WORKSPACE_PATH" )
    local_flags+=( -scheme "$SCHEME" )
    xcb "${local_flags[@]}"
fi

echo "$message"
