#!/bin/bash

# Copyright 2021 Google LLC
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

# Usage:
# ./scripts/style.sh
#

# Ensure that tools in `Mintfile` are installed locally to avoid permissions
# problems that would otherwise arise from the default of installing in
# /usr/local.

export MINT_PATH=Mint

system=$(uname -s)

# Joins the given arguments with the separator given as the first argument.
function join() {
  local IFS="$1"
  shift
  echo "$*"
}

# Rules to disable in swiftformat:
swift_disable=(
    # sortedImports moves comments that are hooks for the docs
  sortedImports
  # Too many of our swift files have simplistic examples. While technically
  # it's correct to remove the unused argument labels, it makes our examples
  # look wrong.
  unusedArguments

  # We prefer trailing braces.
  wrapMultilineStatementBraces
)

swift_options=(
  # Mimic Objective-C style.
  --indent 2
  --maxwidth 100
  --wrapparameters afterfirst

  --disable $(join , "${swift_disable[@]}")
)

if [[ $# -gt 0 && "$1" == "test-only" ]]; then
  test_only=true
  swift_options+=(--dryrun)
  shift
else
  test_only=false
fi

files=$(
(
  if [[ $# -gt 0 ]]; then
    if git rev-parse "$1" -- >& /dev/null; then
      # Argument was a branch name show files changed since that branch
      git diff --name-only --relative --diff-filter=ACMR "$1"
    else
      # Otherwise assume the passed things are files or directories
      find "$@" -type f
    fi
  else
    # Do everything by default
    find . -type f
  fi
) | sed -E -n '
# find . includes a leading "./" that git does not include
s%^./%%

# Build outputs
\%/Pods/% d
\%^build/% d
\%^Debug/% d
\%^Release/% d
\%^cmake-build-debug/% d
\%^.build/% d
\%^.swiftpm/% d

# Sources controlled outside this tree
\%/third_party/% d

# Sources pulled in by the Mint package manager
\%^Mint% d

# Format Swift sources only
\%\.(swift)$% p
'
)

needs_formatting=false
for f in $files; do
  if [[ "${f: -6}" == '.swift' ]]; then
    if [[ "$system" == 'Darwin' ]]; then
      # Match output that says:
      # 1/1 files would have been formatted.  (with --dryrun)
      # 1/1 files formatted.                  (without --dryrun)
      mint run swiftformat "${swift_options[@]}" "$f" 2>&1 | grep '^1/1 files' > /dev/null
    else
      false
    fi
  fi

  if [[ "$test_only" == true && $? -ne 1 ]]; then
    echo "$f needs formatting."
    needs_formatting=true
  fi
done

if [[ "$needs_formatting" == true ]]; then
  echo "Proposed commit is not style compliant."
  echo "Run scripts/style.sh and git add the result."
  exit 1
fi
