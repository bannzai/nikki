import SwiftUI
import CoreGraphics

/// 日記全件を装飾付き PDF に書き出す(#95、Plus 限定)。1日記を1ページとし、ページの高さは内容に合わせて可変にする。
/// CoreGraphics の CGContext へ直接書き出すため、UIKit/AppKit 固有の PDF API に頼らず iOS/macOS 共通の実装で書ける。
@MainActor
enum SettingsExportPDFGenerator {
    /// PDF ページの幅。markdown プレビュー等、既存の読みやすい行長に近い値。
    private static let pageWidth: CGFloat = 560

    /// entries を1ページ1日記の PDF データにする。空配列の場合は表紙も本文もない空の PDF になる。
    static func makeData(entries: [JournalEntry], paperColor: Color) -> Data {
        let pdfData = CFDataCreateMutable(nil, 0)!
        guard let consumer = CGDataConsumer(data: pdfData) else {
            return Data()
        }
        // 最初のページの箱として使うだけで、ページごとに beginPDFPage の pageInfo で実寸へ上書きする。
        var initialMediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageWidth)
        guard let context = CGContext(consumer: consumer, mediaBox: &initialMediaBox, nil) else {
            return Data()
        }
        for entry in entries {
            let renderer = ImageRenderer(content: SettingsExportEntryLayout(entry: entry, paperColor: paperColor, pageWidth: pageWidth))
            // render のクロージャで渡ってくる size が、.fixedSize で計測された実際のページ寸法になる。
            renderer.render { size, renderInContext in
                var pageBox = CGRect(origin: .zero, size: size)
                let pageInfo = [kCGPDFContextMediaBox as String: Data(bytes: &pageBox, count: MemoryLayout<CGRect>.size)] as CFDictionary
                context.beginPDFPage(pageInfo)
                renderInContext(context)
                context.endPDFPage()
            }
        }
        context.closePDF()
        return pdfData as Data
    }
}
