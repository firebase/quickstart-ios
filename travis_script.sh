#!/bin/bash

# Exit on error
set -e

# List of all samples
samples=( admob analytics app-indexing auth config crash database dynamiclinks invites messaging storage )

# Work off travis
#if [[ -v TRAVIS_PULL_REQUEST ]]; then
#  echo "TRAVIS_PULL_REQUEST: $TRAVIS_PULL_REQUEST"
#else
#  echo "TRAVIS_PULL_REQUEST: unset, setting to false"
#  TRAVIS_PULL_REQUEST=false
#fi

for sample in "${samples[@]}"
do
  echo "Building ${sample}"

  # Go to sample directory
  cd $sample
  pod install --repo-update
  cd -
done
