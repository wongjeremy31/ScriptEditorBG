.PHONY: build app run clean install

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
	@cp Info.plist "$(APP_BUNDLE)/Contents/"
	@codesign --force --deep --sign - "$(APP_BUNDLE)"
	@echo "Created $(APP_BUNDLE)"

# Build and run
run: build
	@echo "Running $(APP_NAME)..."
	@"$(RELEASE_DIR)/$(APP_NAME)"

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(APP_BUNDLE)

# Install to /Applications
install: app
	@cp -R "$(APP_BUNDLE)" /Applications/
	@echo "Installed to /Applications/$(APP_BUNDLE)"
