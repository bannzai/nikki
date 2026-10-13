import SwiftUI

#if DEBUG
/// App Store スクリーンショットの言語。キャッチコピーとモック画面内の文言を切り替える。
/// 撮影はシミュレータの言語設定に依存せず環境変数で言語を指定するため、アプリ本体の String Catalog ではなく
/// スクショ機能内の switch で言語別文言を持つ。
enum AppStoreScreenshotLanguage: String {
    case ja
    case en

    /// 環境変数 NIKKI_APPSTORE_LANG から言語を解決する。
    /// 未指定・不明値はプライマリ市場の日本語に倒す(スクショの主対象が日本のため)。
    static func fromEnvironment() -> AppStoreScreenshotLanguage {
        AppStoreScreenshotLanguage(rawValue: ProcessInfo.processInfo.environment["NIKKI_APPSTORE_LANG"] ?? "") ?? .ja
    }
}

/// App Store スクリーンショットの出力キャンバス。App Store Connect の必須サイズに対応する。
/// iphone: 6.9インチ(1320x2868 = 440x956pt @3x) / ipad: 13インチ(2064x2752 = 1032x1376pt @2x) /
/// mac: 2880x1800(= 1440x900pt @2x) /
/// duoOuter: iPhone Duo の外側ディスプレイ(1398x2034 = 466x678pt @3x、縦) /
/// duoInner: iPhone Duo の内側ディスプレイ(2853x2007 = 951x669pt @3x、横。開いた姿勢の simulator が
/// landscapeRight になり、ホストの simctl が回転なしで横長を返すため横で作る)。
enum AppStoreScreenshotCanvas: String {
    case iphone
    case ipad
    case mac
    case duoOuter
    case duoInner

    /// 撮影テストが環境変数 NIKKI_APPSTORE_CANVAS で指定したキャンバス、無ければ実行中のデバイスから解決する(シミュレータ撮影用)。
    /// iPhone Duo は idiom が phone のまま画面の寸法だけが違い、デバイスからは判定できないため、
    /// Duo の撮影テストは外側・内側のどちらを撮るかを環境変数で渡す。
    /// macOS のスクショは ImageRenderer が直接 .mac を指定するため、ここでは iOS 系のみ判定する。
    static func fromEnvironmentOrDevice() -> AppStoreScreenshotCanvas {
        if let canvas = AppStoreScreenshotCanvas(rawValue: ProcessInfo.processInfo.environment["NIKKI_APPSTORE_CANVAS"] ?? "") {
            return canvas
        }
        #if os(macOS)
        return .mac
        #else
        return UIDevice.current.userInterfaceIdiom == .pad ? .ipad : .iphone
        #endif
    }
}

/// スクショ全ページ共通のレイアウトコンテナ。
/// 背景 + キャッチコピー + デバイスフレーム(iPhone/iPad)またはウィンドウモック(Mac)を1画面に構成する。
/// content にはモック画面(アプリ画面風 UI)を渡す。
struct AppStoreScreenshotFrame<Content: View>: View {
    let canvas: AppStoreScreenshotCanvas
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        // デバイスフレームは下端をキャンバス外へ見切れさせる構図のため、コンテンツ全体の高さはキャンバスを超える。
        // 子として置くとルートが理想サイズを報告してキャンバス中央に配置され上端が見切れるため、
        // レイアウトサイズに影響しない overlay として背景に載せ、上端基準で下だけに溢れさせる。
        AppStoreScreenshotBackground()
            .overlay(alignment: .top) {
                switch canvas {
                case .iphone:
                    VStack(spacing: 0) {
                        AppStoreScreenshotHeadline(title: title, subtitle: subtitle, titleSize: 33, subtitleSize: 15.5)
                            .padding(.top, 74)
                            .padding(.horizontal, 32)
                        AppStoreScreenshotPhoneBezel {
                            content
                        }
                        .padding(.top, 40)
                    }
                case .ipad:
                    VStack(spacing: 0) {
                        AppStoreScreenshotHeadline(title: title, subtitle: subtitle, titleSize: 46, subtitleSize: 21)
                            .padding(.top, 104)
                            .padding(.horizontal, 80)
                        AppStoreScreenshotPadBezel {
                            content
                        }
                        .padding(.top, 56)
                    }
                case .mac:
                    AppStoreScreenshotMacWindow {
                        content
                    }
                    .padding(.trailing, 96)
                    .padding(.top, 120)
                    .frame(maxWidth: .infinity, alignment: .topTrailing)
                case .duoOuter:
                    // 外側ディスプレイ(466x678pt)は iPhone より背が低く幅が広いため、
                    // iPhone の縦構図のままキャッチコピーの余白と文字を詰め、フレームを縮めて画面の見える範囲を保つ。
                    VStack(spacing: 0) {
                        AppStoreScreenshotHeadline(title: title, subtitle: subtitle, titleSize: 29, subtitleSize: 14)
                            .padding(.top, 48)
                            .padding(.horizontal, 36)
                        AppStoreScreenshotPhoneBezel(scale: 0.82) {
                            content
                        }
                        .padding(.top, 28)
                    }
                case .duoInner:
                    // 内側ディスプレイ(951x669pt、横)は Mac と同じ「左にキャッチコピー・右に端末」の2カラム構図にし、
                    // 端末は iPhone フレームを縮めて置く(Nikki の画面は縦長の端末で見せるのが主用途のため)。
                    AppStoreScreenshotPhoneBezel(scale: 0.78) {
                        content
                    }
                    .padding(.trailing, 80)
                    .padding(.top, 44)
                    .frame(maxWidth: .infinity, alignment: .topTrailing)
                }
            }
            // Mac と Duo の内側は端末モックの左にキャッチコピーを縦中央で置く2カラム構図のため、overlay を分ける。
            .overlay(alignment: .leading) {
                switch canvas {
                case .mac:
                    AppStoreScreenshotHeadline(title: title, subtitle: subtitle, titleSize: 38, subtitleSize: 17.5, alignment: .leading)
                        .frame(width: 560, alignment: .leading)
                        .padding(.leading, 100)
                case .duoInner:
                    AppStoreScreenshotHeadline(title: title, subtitle: subtitle, titleSize: 33, subtitleSize: 15.5, alignment: .leading)
                        .frame(width: 440, alignment: .leading)
                        .padding(.leading, 72)
                case .iphone, .ipad, .duoOuter:
                    EmptyView()
                }
            }
            // overlay の上端が safe area に押し下げられないよう、背景単体ではなく overlay 込みの全体をキャンバス全面に広げる。
            .ignoresSafeArea()
            // 撮影テストが描画完了を待つための目印。起動画面や描画途中の画面を撮らないようにする。
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("AppStoreScreenshotFrame")
            // シミュレータ実機撮影で OS の時刻・電池・ホームインジケータが写り込まないようにする。
            #if os(iOS)
            .statusBarHidden(true)
            .persistentSystemOverlays(.hidden)
            #endif
    }
}

/// モック画面の先頭コンテンツに与える上端の余白。
/// iPhone と Duo (iPhone フレームを使う) は Dynamic Island、iPad はベゼル上端、Mac はウィンドウのタイトルバーとの間隔に合わせる。
func appStoreScreenshotScreenTopPadding(canvas: AppStoreScreenshotCanvas) -> CGFloat {
    switch canvas {
    case .iphone, .duoOuter, .duoInner: return 56
    case .ipad: return 28
    case .mac: return 14
    }
}

/// キャッチコピー(メイン + サブ)のブロック。
struct AppStoreScreenshotHeadline: View {
    let title: String
    let subtitle: String
    let titleSize: CGFloat
    let subtitleSize: CGFloat
    // iPhone / iPad は中央寄せ、Mac の左カラムは leading 寄せで使うため。
    var alignment: HorizontalAlignment = .center

    var body: some View {
        VStack(alignment: alignment, spacing: 0) {
            Text(title)
                .font(.ink(titleSize, .bold))
                .lineSpacing(inkLineSpacing(fontSize: titleSize, multiplier: 1.45))
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(alignment == .center ? .center : .leading)
                // 親のレイアウト圧縮で複数行のコピーが省略記号に潰れないよう、テキストの高さを確保する。
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.ink(subtitleSize, .regular))
                .lineSpacing(inkLineSpacing(fontSize: subtitleSize, multiplier: 1.6))
                .foregroundStyle(Color.inkTextSecondary)
                .multilineTextAlignment(alignment == .center ? .center : .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
    }
}

/// スクショの背景。アプリの紙地(inkPaper)よりわずかに濃い生成りのグラデーションにし、
/// デバイスフレーム内の画面(inkPaper)が浮き上がって見えるようにする。
struct AppStoreScreenshotBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(hex: 0xF6F4EC), Color(hex: 0xEAE5D8)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

/// iPhone 風のデバイスフレーム。墨色ベゼル + Dynamic Island をコードで描画し、外部画像は使わない。
/// フレーム下端はキャンバス外に見切れる前提の構図のため、画面の高さはキャンバスより長く固定し、
/// 最下部のアクションボタン類はモック画面に置かない。
struct AppStoreScreenshotPhoneBezel<Content: View>: View {
    // iPhone のキャンバスは等倍、Duo のキャンバスは画面に収まるように縮めて置く。
    // モック画面は等倍で組んでからフレームごと縮めるため、各ページのレイアウトはキャンバスを問わず同じになる。
    var scale: CGFloat = 1
    @ViewBuilder let content: Content

    var body: some View {
        // 6.9インチ(440x956pt)のキャンバスで、下端がほどよく見切れる画面サイズ。
        Color.inkPaper
            .frame(width: 352, height: 880)
            // モック画面は画面枠より縦に長くなり得る。子として置くと VStack の圧縮・中央寄せで
            // 上端が欠けるため、レイアウトサイズに影響しない overlay として載せ、
            // 画面枠より長い固定の高さを与えて上端基準で見切れさせる。
            .overlay(alignment: .top) {
                content
                    .frame(width: 352, height: 1400, alignment: .top)
            }
            // Dynamic Island。実機の見た目に合わせて画面上端の中央に置く。
            .overlay(alignment: .top) {
                Capsule()
                    .fill(Color.ink)
                    .frame(width: 96, height: 28)
                    .padding(.top, 12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 58, style: .continuous)
                .fill(Color.ink)
        )
        .shadow(color: Color.ink.opacity(0.18), radius: 24, x: 0, y: 18)
        // scaleEffect は描画だけを縮めてレイアウトの大きさを変えないため、縮めた後の大きさを frame で与え直す
        // (与えないと、上のキャッチコピーとの間隔が等倍のフレームを基準に計算される)。
        .scaleEffect(scale)
        .frame(width: 372 * scale, height: 900 * scale)
    }
}

/// iPad 風のデバイスフレーム。均一な墨色ベゼルの角丸矩形をコードで描画する。
struct AppStoreScreenshotPadBezel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        // 13インチ(1032x1376pt)のキャンバスで、下端がほどよく見切れる画面サイズ。
        Color.inkPaper
            .frame(width: 754, height: 1240)
            // モック画面の載せ方は AppStoreScreenshotPhoneBezel と同じ理由で overlay + 固定の高さにする。
            .overlay(alignment: .top) {
                content
                    .frame(width: 754, height: 1700, alignment: .top)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(Color.ink)
        )
        .shadow(color: Color.ink.opacity(0.18), radius: 24, x: 0, y: 18)
    }
}

/// macOS 風のウィンドウモック。信号機ボタン付きのタイトルバー + 本体をコードで描画する。
/// Mac App Store の慣例に合わせ、iPhone フレームではなくウィンドウの見た目にする。
struct AppStoreScreenshotMacWindow<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Circle().fill(Color(hex: 0xFF5F57)).frame(width: 12, height: 12)
                Circle().fill(Color(hex: 0xFEBC2E)).frame(width: 12, height: 12)
                Circle().fill(Color(hex: 0x28C840)).frame(width: 12, height: 12)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .frame(height: 42)
            .background(Color(hex: 0xF1EFE9))

            // モック画面はウィンドウより縦に長くなり得る。子として置くと VStack の計測を狂わせて
            // タイトルバーが押し出されるため、レイアウトサイズに影響しない overlay として紙地に載せ、
            // ウィンドウより長い固定の高さを与えて上端基準で見切れさせる。
            Color.inkPaper
                .overlay(alignment: .top) {
                    content
                        .frame(width: 600, height: 1300, alignment: .top)
                }
        }
        // アプリ既定のウィンドウ(520x800pt)に近い縦長プロポーション。下端はキャンバス外に見切れる。
        .frame(width: 600, height: 840)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 12, style: .continuous))
        .overlay(
            UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 12, style: .continuous)
                .strokeBorder(Color.ink.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.ink.opacity(0.2), radius: 28, x: 0, y: 16)
    }
}
#endif
