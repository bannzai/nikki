PROJECT := Nikki.xcodeproj
SCHEME := Nikki
DERIVED_DATA := tmp/DerivedData

.PHONY: macos ios ios-device

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

# iOS 実機ビルド + インストール。DEVICE 未指定時は接続中 (connected) の実機を自動選択する
ios-device:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination 'generic/platform=iOS' \
		-derivedDataPath $(DERIVED_DATA) \
		-allowProvisioningUpdates -allowProvisioningDeviceRegistration \
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
