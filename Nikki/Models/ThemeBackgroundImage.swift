import Foundation

/// テーマ(1n)の背景画像の保存・読み込み・削除(#96)。
/// CloudKit 同期はしない。画像1枚のサイズが紙色プリセットのような小さな値と異なり大きくなり得ることと、
/// 同期対象を Plus 加入状態で絞る #93 の判定と独立させたいことから、常にこの端末だけのローカルファイルとして持つ。
enum ThemeBackgroundImage {
    private static var fileURL: URL {
        URL.applicationSupportDirectory.appending(path: "ThemeBackgroundImage.jpg")
    }

    /// 保存済みの背景画像があれば読み込む。無ければ nil。
    static func load() -> Data? {
        try? Data(contentsOf: fileURL)
    }

    /// 背景画像を保存する。既存の画像があれば置き換える(冪等)。
    static func save(data: Data) throws {
        try FileManager.default.createDirectory(at: .applicationSupportDirectory, withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }

    /// 背景画像を削除する。保存済みの画像が無ければ何もしない(冪等)。
    static func remove() throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}
