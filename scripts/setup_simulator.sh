#!/usr/bin/env bash

# Copyright 2026 Google LLC
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

# TODO: Temporary local copy of firebase/firebase-ios-sdk/scripts/setup_simulator.sh
# (with SDK-major runtime matching and `macOS|catalyst` no-op support).
# Consolidate once upstream `firebase-ios-sdk` supports cross-repo composite
# action invocation.

set -euo pipefail

PLATFORM="${1:-all}"

echo " Active Xcode Info:"
xcodebuild -version
echo " Installed Simulator Runtimes:"
xcrun simctl list runtimes

get_runtime() {
  local platform_prefix="$1"
  local sdk_name=""
  case "$platform_prefix" in
    iOS) sdk_name="iphonesimulator" ;;
    tvOS) sdk_name="appletvsimulator" ;;
    watchOS) sdk_name="watchsimulator" ;;
    visionOS) sdk_name="xrsimulator" ;;
  esac

  # Match the latest installed runtime for the active SDK's major version so it
  # aligns with xcodebuild's implicit `OS:latest` destination resolution (e.g.,
  # selecting iOS 26.5 on macos-26 when 26.2, 26.4, and 26.5 are installed).
  local target_major=""
  if [[ -n "$sdk_name" ]]; then
    local sdk_ver
    sdk_ver=$(xcrun --sdk "$sdk_name" --show-sdk-version 2>/dev/null || true)
    if [[ -n "$sdk_ver" ]]; then
      target_major="${sdk_ver%%.*}"
    fi
  fi

  local runtime=""
  if [[ -n "$target_major" ]]; then
    runtime=$(xcrun simctl list runtimes available | grep "^[[:space:]]*${platform_prefix} ${target_major}\." | grep -o "com\.apple\.CoreSimulator\.SimRuntime\.${platform_prefix}-[0-9-]*" | tail -n 1 || true)
  fi

  if [[ -z "$runtime" ]]; then
    runtime=$(xcrun simctl list runtimes available | grep "^[[:space:]]*${platform_prefix}" | grep -o "com\.apple\.CoreSimulator\.SimRuntime\.${platform_prefix}-[0-9-]*" | tail -n 1 || true)
  fi

  echo "$runtime"
}

create_sim() {
  local sim_name="$1"
  local runtime="$2"
  shift 2
  local device_types=("$@")

  if [[ -z "$runtime" ]]; then
    echo "⚠️ Warning: No available runtime found for $sim_name. Skipping creation."
    return 0
  fi

  if xcrun simctl list devices available | grep -Fq "${sim_name} ("; then
    echo "✅ Simulator '$sim_name' already exists and is available."
  else
    # Clean up any existing (but unavailable) simulators with the same name to avoid duplicates
    xcrun simctl list devices | grep -F "${sim_name} (" | grep -oE '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}' | while read -r uuid; do
      echo "🧹 Removing existing/unavailable simulator $uuid..."
      xcrun simctl delete "$uuid" || true
    done || true

    local created=false
    for device_type in "${device_types[@]}"; do
      echo "📲 Attempting to create '$sim_name' with type '$device_type' and runtime '$runtime'..."
      if xcrun simctl create "$sim_name" "$device_type" "$runtime" 2>/dev/null; then
        echo "✅ Successfully created '$sim_name' using '$device_type'."
        created=true
        break
      else
        echo "⚠️ Device type '$device_type' is incompatible with '$runtime' or unavailable."
      fi
    done

    if [[ "$created" = false ]]; then
      echo "❌ Failed to create simulator '$sim_name' with any provided device types."
      return 1
    fi
  fi
}

case "$PLATFORM" in
  iOS)
    create_sim "Firebase-iPhone-15-Pro" "$(get_runtime iOS)" \
      "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro" \
      "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro" \
      "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro" \
      "com.apple.CoreSimulator.SimDeviceType.iPhone-Duo"
    ;;
  tvOS)
    create_sim "Firebase-Apple-TV-4K-Gen-2" "$(get_runtime tvOS)" \
      "com.apple.CoreSimulator.SimDeviceType.Apple-TV-4K-2nd-generation-1080p" \
      "com.apple.CoreSimulator.SimDeviceType.Apple-TV-4K-3rd-generation-1080p"
    ;;
  watchOS)
    create_sim "Firebase-Apple-Watch-Ultra-2" "$(get_runtime watchOS)" \
      "com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Ultra-2-49mm" \
      "com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Ultra-3-49mm" \
      "com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Ultra-4-49mm" \
      "com.apple.CoreSimulator.SimDeviceType.Apple-Watch-SE-3-44mm"
    ;;
  visionOS)
    create_sim "Firebase-Apple-Vision-Pro" "$(get_runtime visionOS)" \
      "com.apple.CoreSimulator.SimDeviceType.Apple-Vision-Pro"
    ;;
  macOS|catalyst)
    echo "ℹ️ Platform '$PLATFORM' does not require a simulator."
    ;;
  all)
    create_sim "Firebase-iPhone-15-Pro" "$(get_runtime iOS)" \
      "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro" \
      "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro" \
      "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro" \
      "com.apple.CoreSimulator.SimDeviceType.iPhone-Duo"
    create_sim "Firebase-Apple-TV-4K-Gen-2" "$(get_runtime tvOS)" \
      "com.apple.CoreSimulator.SimDeviceType.Apple-TV-4K-2nd-generation-1080p" \
      "com.apple.CoreSimulator.SimDeviceType.Apple-TV-4K-3rd-generation-1080p"
    create_sim "Firebase-Apple-Watch-Ultra-2" "$(get_runtime watchOS)" \
      "com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Ultra-2-49mm" \
      "com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Ultra-3-49mm" \
      "com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Ultra-4-49mm" \
      "com.apple.CoreSimulator.SimDeviceType.Apple-Watch-SE-3-44mm"
    create_sim "Firebase-Apple-Vision-Pro" "$(get_runtime visionOS)" \
      "com.apple.CoreSimulator.SimDeviceType.Apple-Vision-Pro"
    ;;
  *)
    echo "❌ Unknown platform: $PLATFORM"
    exit 1
    ;;
esac
