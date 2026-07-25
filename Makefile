.PHONY: build app run clean install dev

APP_NAME = ScriptEditorBG
BUNDLE_ID = com.jeremy.scripteditor-bg
BUILD_DIR = .build
RELEASE_DIR = $(BUILD_DIR)/release
APP_BUNDLE = $(APP_NAME).app

# Default: build the app bundle
all: app

# Build release binary
build:
	swift build -c release

# Create .app bundle
app: build
	@echo "Creating $(APP_BUNDLE)..."
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	@mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	@cp "$(RELEASE_DIR)/$(APP_NAME)" "$(APP_BUNDLE)/Contents/MacOS/"
	@chmod +x "$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)"
	@cp Info.plist "$(APP_BUNDLE)/Contents/"
	@codesign --force --deep --sign - "$(APP_BUNDLE)"
	@xattr -d com.apple.quarantine "$(APP_BUNDLE)" 2>/dev/null || true
	@echo "✅ Created $(APP_BUNDLE)"

# Run directly without .app bundle (best for development - no signature issues)
dev: build
	@echo "🚀 Running directly (dev mode)..."
	@echo "   No .app bundle = no code signature changes = no re-authorization needed"
	@"$(RELEASE_DIR)/$(APP_NAME)"

# Build and run .app bundle
run: app
	@echo "🚀 Running $(APP_BUNDLE)..."
	@open "$(APP_BUNDLE)"

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(APP_BUNDLE)

# Install to /Applications for daily use
# ⚠️ You MUST re-authorize after each install because codesign creates a new signature
install: app
	@echo "📦 Installing to /Applications..."
	@rm -rf "/Applications/$(APP_BUNDLE)"
	@cp -R "$(APP_BUNDLE)" /Applications/
	@codesign --force --deep --sign - "/Applications/$(APP_BUNDLE)"
	@echo "✅ Installed to /Applications/$(APP_BUNDLE)"
	@echo ""
	@echo "⚠️  IMPORTANT: Because the app was re-built, macOS sees it as a NEW app."
	@echo "    You need to re-authorize it in System Settings:"
	@echo ""
	@echo "    1. Remove 'ScriptEditorBG' from System Settings > Privacy > Accessibility"
	@echo "    2. Open /Applications/$(APP_BUNDLE)"
	@echo "    3. Click 'Open Settings' when the dialog appears"
	@echo "    4. Check the box for 'ScriptEditorBG'"
	@echo ""
	@open "/Applications/$(APP_BUNDLE)"
