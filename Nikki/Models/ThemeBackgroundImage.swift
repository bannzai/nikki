import Foundation
import ImageIO
import UniformTypeIdentifiers

/// テーマ(1n)の背景画像の保存・読み込み・削除(#96)。
/// CloudKit 同期はしない。画像1枚のサイズが紙色プリセットのような小さな値と異なり大きくなり得ることと、
/// 同期対象を Plus 加入状態で絞る #93 の判定と独立させたいことから、常にこの端末だけのローカルファイルとして持つ。
enum ThemeBackgroundImage {
    /// 保存(save)が失敗する理由。
    enum SaveError: Error {
        /// 渡されたデータを画像として解釈できなかった。
        case decodeFailed
        /// 縮小した画像を JPEG へ書き出せなかった。
        case encodeFailed
    }

    private static var fileURL: URL {
        URL.applicationSupportDirectory.appending(path: "ThemeBackgroundImage.jpg")
    }

    /// 保存済みの背景画像があれば読み込む。無ければ nil。
    static func load() -> Data? {
        try? Data(contentsOf: fileURL)
    }

    /// 背景画像を保存する。既存の画像があれば置き換える(冪等)。
    /// 写真アプリの原寸データをそのまま持つとメモリを浪費するため、画面表示に足りる大きさへ縮小してから JPEG で保存する。
    static func save(data: Data) throws {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw SaveError.decodeFailed
        }
        guard let downsampled = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            [
                // 埋め込みサムネイルの有無に左右されないよう、常に原画像から縮小する。
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                // Exif の向き情報を画素へ反映し、横倒しで表示されないようにする。
                kCGImageSourceCreateThumbnailWithTransform: true,
                // iPhone の 3x フルスクリーン背景を賄える実用上限。これ以上は表示で差が出ず、原寸のままではメモリを浪費する。
                kCGImageSourceThumbnailMaxPixelSize: 2048,
            ] as CFDictionary
        ) else {
            throw SaveError.decodeFailed
        }
        let encoded = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(encoded, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw SaveError.encodeFailed
        }
        // 紙地の背後に敷く用途では劣化がほぼ見えず、ファイルサイズを抑えられる品質。
        CGImageDestinationAddImage(destination, downsampled, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
        if !CGImageDestinationFinalize(destination) {
            throw SaveError.encodeFailed
        }
        try FileManager.default.createDirectory(at: .applicationSupportDirectory, withIntermediateDirectories: true)
        try (encoded as Data).write(to: fileURL, options: .atomic)
    }

    /// 背景画像を削除する。保存済みの画像が無ければ何もしない(冪等)。
    static func remove() throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}
