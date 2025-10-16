#!/bin/bash

# Get the short git commit hash (7 characters)
GIT_COMMIT=$(git rev-parse --short=7 HEAD 2>/dev/null || echo "unknown")

# Path to the Info.plist
INFO_PLIST="${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}"

# Only inject in Release builds (not Debug)
if [ "${CONFIGURATION}" = "Release" ]; then
    echo "Injecting git commit hash: ${GIT_COMMIT}"
    /usr/libexec/PlistBuddy -c "Add :GitCommitHash string ${GIT_COMMIT}" "${INFO_PLIST}" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :GitCommitHash ${GIT_COMMIT}" "${INFO_PLIST}"
else
    echo "Debug build - skipping git commit injection"
fi
