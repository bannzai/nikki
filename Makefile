PROJECT := Nikki.xcodeproj
SCHEME := Nikki
DERIVED_DATA := tmp/DerivedData
# iOS バイナリを macOS の LaunchServices が起動できるようにする Wrapper 構造の配置先
MAC_APP := tmp/mac-app/Nikki.app

.PHONY: macos ios

# ビルドのみ行い、アプリの起動はしない (ssh 越しの実行を想定)
macos:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination 'platform=macOS,variant=Designed for iPad' \
		-derivedDataPath $(DERIVED_DATA) \
		-allowProvisioningUpdates -allowProvisioningDeviceRegistration \
		build
	rm -rf $(MAC_APP)
	mkdir -p $(MAC_APP)/Wrapper
	cp -R $(DERIVED_DATA)/Build/Products/Debug-iphoneos/Nikki.app $(MAC_APP)/Wrapper/
	ln -sfn Wrapper/Nikki.app $(MAC_APP)/WrappedBundle
	@echo "起動するには: open $(MAC_APP)"

ios:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination 'generic/platform=iOS Simulator' \
		-derivedDataPath $(DERIVED_DATA) \
		build
