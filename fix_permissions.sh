#!/bin/bash
# Fix permissions for ScriptEditorBG.app
# Run this script if double-clicking the app doesn't work

echo "🔧 Fixing ScriptEditorBG permissions..."

cd "$(dirname "$0")"

# Remove Gatekeeper quarantine
echo "1. Removing Gatekeeper quarantine..."
xattr -d com.apple.quarantine ScriptEditorBG.app 2>/dev/null || echo "   (No quarantine attribute found)"

# Ad-hoc code sign
echo "2. Code signing app..."
codesign --force --deep --sign - ScriptEditorBG.app

# Verify
echo "3. Verifying signature..."
codesign -dv ScriptEditorBG.app 2>&1 | head -5

echo ""
echo "✅ Done! Try double-clicking ScriptEditorBG.app now."
echo ""
echo "If it still doesn't open, try:"
echo "  open ScriptEditorBG.app"
