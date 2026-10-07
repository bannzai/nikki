PROJECT := Nikki.xcodeproj
SCHEME := Nikki
DERIVED_DATA := tmp/DerivedData
INSTALL_APP := /Applications/Nikki.app
# LicenseList の BuildToolPlugin (PrepareLicenseList) は初回に信頼の確認を求める。
# GUI での承認結果は共有されない xcuserdata に入るため、CLI ビルドでは検証をスキップする
SKIP_PLUGIN_VALIDATION := -skipPackagePluginValidation
LSREGISTER := /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
# ユニットテストを実行する simulator の runtime。StoreKit テスト (StoreKitConfigurationTests) は iOS 26.5 simulator の
# 既知の問題で skip されるため、CI (test.yml) と同じ runtime に固定して skip を成功扱いにしない
TEST_SIM_RUNTIME := com.apple.CoreSimulator.SimRuntime.iOS-26-2

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

# iOS 実機ビルド + インストール。DEVICE 未指定時は接続中 (connected) の実機を自動選択する。
# Debug ビルドは開発用ストア (CloudKit 同期なし) を使うため、普段使いする実機には Release を入れる。
# pbxproj の Release[sdk=iphoneos*] は TestFlight 配布 (ios-deploy.yml) 用に Manual + Apple Distribution に
# なっているが、App Store 用 profile では実機へ直接インストールできないため、ローカルの実機向けは
# コマンドラインで Automatic (開発署名) に戻す
ios-device:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-configuration Release \
		-destination 'generic/platform=iOS' \
		-derivedDataPath $(DERIVED_DATA) \
		-allowProvisioningUpdates -allowProvisioningDeviceRegistration \
		"CODE_SIGN_STYLE[sdk=iphoneos*]=Automatic" \
		"CODE_SIGN_IDENTITY[sdk=iphoneos*]=Apple Development" \
		"PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]=" \
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
	xcrun devicectl device install app --device $$device $(DERIVED_DATA)/Build/Products/Release-iphoneos/Nikki.app; \
	echo "起動するには: xcrun devicectl device process launch --device $$device com.bannzai.Nikki"

# Debug ビルドを Release と同じ /Applications/Nikki.app に上書き配置する。
# Debug ビルドにしか無い操作 (開発者メニュー等) を普段使いのデータに対して行うための一時的な配置で、
# 終わったら make macos で Release に戻す
# 起動は自動では行わない (ssh 越しの実行を想定)
.PHONY: macos-debug

macos-debug:
	xcodebuild -project 'Nikki.xcodeproj' -scheme 'Nikki' \
		-configuration Debug \
		-destination 'platform=macOS' \
		-derivedDataPath 'tmp/DerivedData' \
		-allowProvisioningUpdates -allowProvisioningDeviceRegistration \
		'-skipPackagePluginValidation' \
		build
	rm -rf $(INSTALL_APP)
	ditto 'tmp/DerivedData/Build/Products/Debug/Nikki.app' $(INSTALL_APP)
	$(LSREGISTER) -f $(INSTALL_APP)
	@echo "起動するには: open $(INSTALL_APP)"
	@echo "Release に戻すには: make macos"

# ユニットテスト (NikkiTests) を CI (test.yml) と同じ iOS Simulator 向け・同じ runtime で実行する。
# simulator は sim-boot で起動した worktree 固有のものを使い、起動済みなら再利用する。
# CI と同じく、StoreKit テストが skip・未実行のまま成功扱いになっていないことをログで検査する
.PHONY: test

test:
	@set -e; set -o pipefail; \
	simulator_udid=$$(SCRIPT_QUIET=1 SIM_RUNTIME=$(TEST_SIM_RUNTIME) sim-boot | sed -n 's/^DEVICE_UDID=//p' | tail -n 1); \
	[ -n "$$simulator_udid" ] || { echo "Error: sim-boot で Simulator を解決できません (sim-boot が PATH にあるか確認してください)" >&2; exit 1; }; \
	mkdir -p tmp; \
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination "platform=iOS Simulator,id=$$simulator_udid" \
		-derivedDataPath $(DERIVED_DATA) \
		$(SKIP_PLUGIN_VALIDATION) \
		-only-testing:NikkiTests \
		test 2>&1 | tee tmp/test.log; \
	if [ "$$(grep -cE 'Test Case .*StoreKitConfigurationTests.* passed' tmp/test.log)" -lt 5 ]; then \
		echo "Error: StoreKitConfigurationTests の pass が 5 件未満です (skip または未実行の可能性。実行可能な runtime を使ってください)" >&2; \
		exit 1; \
	fi

# 引数なしの make で macos を実行する (人が手で動作確認するための入口。検査・テストは CI が行う)
.DEFAULT_GOAL := macos

.PHONY: verify
verify: test
