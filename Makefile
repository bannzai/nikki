PROJECT := Nikki.xcodeproj
SCHEME := Nikki
DERIVED_DATA := tmp/DerivedData

.PHONY: macos ios

# ネイティブ macOS ビルド。ビルドのみ行い、アプリの起動はしない (ssh 越しの実行を想定)
macos:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination 'platform=macOS' \
		-derivedDataPath $(DERIVED_DATA) \
		-allowProvisioningUpdates -allowProvisioningDeviceRegistration \
		build
	@echo "起動するには: open $(DERIVED_DATA)/Build/Products/Debug/Nikki.app"

ios:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination 'generic/platform=iOS Simulator' \
		-derivedDataPath $(DERIVED_DATA) \
		build
