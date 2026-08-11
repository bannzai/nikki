PROJECT := Nikki.xcodeproj
SCHEME := Nikki
DERIVED_DATA := tmp/DerivedData
INSTALL_APP := /Applications/Nikki.app
# LicenseList の BuildToolPlugin (PrepareLicenseList) は初回に信頼の確認を求める。
# GUI での承認結果は共有されない xcuserdata に入るため、CLI ビルドでは検証をスキップする
SKIP_PLUGIN_VALIDATION := -skipPackagePluginValidation
LSREGISTER := /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

.PHONY: macos ios ios-device

# Release ビルドを /Applications に配置して普段使いできるようにする (PUTS ADR 0009 と同じ方式)。
# 起動はしないため ssh 越しでも実行できる
macos:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-configuration Release \
		-destination 'platform=macOS' \
		-derivedDataPath $(DERIVED_DATA) \
		-allowProvisioningUpdates -allowProvisioningDeviceRegistration \
		$(SKIP_PLUGIN_VALIDATION) \
		build
	rm -rf $(INSTALL_APP)
	ditto $(DERIVED_DATA)/Build/Products/Release/Nikki.app $(INSTALL_APP)
	$(LSREGISTER) -f $(INSTALL_APP)
	@echo "起動するには: open $(INSTALL_APP)"

ios:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination 'generic/platform=iOS Simulator' \
		-derivedDataPath $(DERIVED_DATA) \
		$(SKIP_PLUGIN_VALIDATION) \
		build

# iOS 実機ビルド + インストール。DEVICE 未指定時は接続中 (connected) の実機を自動選択する
ios-device:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination 'generic/platform=iOS' \
		-derivedDataPath $(DERIVED_DATA) \
		-allowProvisioningUpdates -allowProvisioningDeviceRegistration \
		$(SKIP_PLUGIN_VALIDATION) \
		build
	@set -e; \
	device="$(DEVICE)"; \
	if [ -z "$$device" ]; then \
		xcrun devicectl list devices --json-output $(DERIVED_DATA)/devices.json --quiet; \
		device=$$(jq -r '[.result.devices[] | select(.connectionProperties.tunnelState == "connected")][0].identifier // empty' $(DERIVED_DATA)/devices.json); \
	fi; \
	if [ -z "$$device" ]; then \
		echo "接続中の実機が見つかりません。make ios-device DEVICE=<identifier> で指定してください" >&2; \
		exit 1; \
	fi; \
	xcrun devicectl device install app --device $$device $(DERIVED_DATA)/Build/Products/Debug-iphoneos/Nikki.app; \
	echo "起動するには: xcrun devicectl device process launch --device $$device com.bannzai.Nikki"
