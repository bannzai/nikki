#if os(macOS) && DEBUG
import XCTest
import SwiftUI
@testable import Nikki

/// App Store スクリーンショット(macOS 2880x1800)の描画テスト。
/// シミュレータを持たない macOS はウィンドウ撮影だとディスプレイ倍率に依存して寸法が安定しないため、
/// ImageRenderer で 1440x900pt @2x = 2880x1800px を直接描画して XCTAttachment に保存する。
/// 実行は scripts/generate_screenshots/ のパイプラインから行い、xcresult から画像を抽出する。
///
/// プロジェクト既定の SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor のままだと、nonisolated な XCTestCase の
/// init をオーバーライドできずビルドが通らないため、クラスは nonisolated にする(ContextMenuUITests と同じ)。
nonisolated final class AppStoreScreenshotRenderTests: XCTestCase {
    @MainActor
    func testRenderMacScreenshots() throws {
        // 通常の xcodebuild test に 12 個の大型 attachment を足さないよう、
        // パイプライン (run スクリプト) が渡す SNAPSHOT_ENABLED が無ければスキップする (UI 撮影テストと同じガード)。
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["SNAPSHOT_ENABLED"] == "1",
            "スクリーンショット描画は scripts/generate_screenshots/ のパイプラインからだけ実行する(SNAPSHOT_ENABLED=1)"
        )

        for language in filteredLanguages() {
            for page in filteredPages() {
                let renderer = ImageRenderer(
                    content: screenshotPage(page: page, language: language)
                        .frame(width: 1440, height: 900)
                )
                // 2880x1800px を得るための Retina 倍率。
                renderer.scale = 2.0
                let cgImage = try XCTUnwrap(renderer.cgImage, "ImageRenderer が \(page) (\(language)) の描画に失敗")
                XCTAssertEqual(cgImage.width, 2880)
                XCTAssertEqual(cgImage.height, 1800)

                let pngData = try XCTUnwrap(
                    NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:]),
                    "PNG 変換に失敗: \(page) (\(language))"
                )
                let attachment = XCTAttachment(data: pngData, uniformTypeIdentifier: "public.png")
                // organize スクリプトが「---」区切りでページ・言語をパースするための命名(iOS 撮影テストと同形式)。
                attachment.name = "AppStoreScreenshot---\(page.rawValue)---\(language.rawValue)---0"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }

    /// Screen の rawValue に対応するスクショページを Mac キャンバスで組み立てる。
    /// 型の異なる 6 ページを同じループで描画するため AnyView に寄せる。
    @MainActor
    private func screenshotPage(page: Screen, language: AppStoreScreenshotLanguage) -> AnyView {
        switch page {
        case .appstore1: return AnyView(AppStoreScreenshot1Page(language: language, canvas: .mac))
        case .appstore2: return AnyView(AppStoreScreenshot2Page(language: language, canvas: .mac))
        case .appstore3: return AnyView(AppStoreScreenshot3Page(language: language, canvas: .mac))
        case .appstore4: return AnyView(AppStoreScreenshot4Page(language: language, canvas: .mac))
        case .appstore5: return AnyView(AppStoreScreenshot5Page(language: language, canvas: .mac))
        case .appstore6: return AnyView(AppStoreScreenshot6Page(language: language, canvas: .mac))
        default:
            XCTFail("スクショページではない Screen: \(page)")
            return AnyView(EmptyView())
        }
    }

    /// 撮影する言語。環境変数 SNAPSHOT_LANGUAGES(カンマ区切り)で絞り込める。未指定は日英の全言語。
    private func filteredLanguages() -> [AppStoreScreenshotLanguage] {
        let all: [AppStoreScreenshotLanguage] = [.ja, .en]
        if let raw = ProcessInfo.processInfo.environment["SNAPSHOT_LANGUAGES"], !raw.isEmpty {
            return raw.split(separator: ",").compactMap { AppStoreScreenshotLanguage(rawValue: String($0)) }
        }
        return all
    }

    /// 撮影するページ。環境変数 SNAPSHOT_PAGES(カンマ区切りの番号)で絞り込める。未指定は全6ページ。
    private func filteredPages() -> [Screen] {
        let all: [Screen] = [.appstore1, .appstore2, .appstore3, .appstore4, .appstore5, .appstore6]
        if let raw = ProcessInfo.processInfo.environment["SNAPSHOT_PAGES"], !raw.isEmpty {
            return raw.split(separator: ",").compactMap { Screen(rawValue: "appstore\($0)") }.filter { all.contains($0) }
        }
        return all
    }
}
#endif
