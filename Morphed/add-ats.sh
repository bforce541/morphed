#!/bin/bash
# Add ATS settings to generated Info.plist

PLIST="${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}"

if [ -f "$PLIST" ]; then
    /usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity dict" "$PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSAllowsLocalNetworking bool true" "$PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :NSAppTransportSecurity:NSAllowsLocalNetworking true" "$PLIST" 2>/dev/null || true
fi

