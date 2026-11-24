import Foundation
import CryptoKit

/// パスキー(WebAuthn)の登録結果と解除時の署名を、AuthenticationServices に依存せず検証する純粋関数群。
/// パスキーはロック解除の代替手段として使い、日記の暗号鍵には紐づけない(issue #84)。
/// サーバを持たないため relying party の検証はアプリ自身が行う。登録時に attestation object から
/// 取り出した公開鍵を端末に保存し、解除時は OS が返した署名をその公開鍵で検証する。

/// パスキーの登録で端末に保存する値。credentialID は解除時に使うパスキーの指定に、publicKey は署名の検証に使う。
struct PasskeyCredential: Equatable {
    /// OS が採番したパスキーの識別子。
    let credentialID: Data
    /// 登録時の attestation object から取り出した P-256 公開鍵(X9.63 の非圧縮表現)。
    let publicKey: Data
}

/// パスキーの登録結果・署名の検証で見つかった不整合。
enum PasskeyVerificationError: Error, Equatable {
    /// attestation object・authenticatorData の構造が WebAuthn の仕様と一致しない。
    case malformedAuthenticatorData
    /// 公開鍵が ES256(P-256 + ECDSA)以外。Apple のパスキーは ES256 のみのため想定外。
    case unsupportedPublicKey
}

/// 登録時の attestation object から P-256 公開鍵(X9.63 表現)を取り出す。
/// attestation object は CBOR の map { fmt, attStmt, authData } で、authData の末尾の
/// attestedCredentialData に COSE 形式の公開鍵が入っている。
func passkeyPublicKey(attestationObject: Data) throws -> Data {
    let object = try CBORDecoder.decode(data: attestationObject)
    guard case .bytes(let authenticatorData) = object.mapValue(textKey: "authData") else {
        throw PasskeyVerificationError.malformedAuthenticatorData
    }
    // authenticatorData: rpIdHash(32) + flags(1) + signCount(4) + aaguid(16) + credentialIdLength(2) + credentialId + credentialPublicKey(COSE)
    let attestedCredentialDataOffset = 32 + 1 + 4
    let credentialIDLengthOffset = attestedCredentialDataOffset + 16
    if authenticatorData.count < credentialIDLengthOffset + 2 {
        throw PasskeyVerificationError.malformedAuthenticatorData
    }
    let flags = authenticatorData[authenticatorData.startIndex + 32]
    // AT(attested credential data included)フラグ。
    if flags & 0x40 == 0 {
        throw PasskeyVerificationError.malformedAuthenticatorData
    }
    let lengthStart = authenticatorData.startIndex + credentialIDLengthOffset
    let credentialIDLength = Int(authenticatorData[lengthStart]) << 8 | Int(authenticatorData[lengthStart + 1])
    let publicKeyStart = lengthStart + 2 + credentialIDLength
    if authenticatorData.count < publicKeyStart - authenticatorData.startIndex {
        throw PasskeyVerificationError.malformedAuthenticatorData
    }
    let coseKey = try CBORDecoder.decode(data: authenticatorData[publicKeyStart...])
    // COSE_Key: kty(1) = EC2(2), alg(3) = ES256(-7), crv(-1) = P-256(1), x(-2), y(-3)
    guard case .unsigned(2) = coseKey.mapValue(intKey: 1),
          case .negative(-7) = coseKey.mapValue(intKey: 3),
          case .unsigned(1) = coseKey.mapValue(intKey: -1),
          case .bytes(let x) = coseKey.mapValue(intKey: -2),
          case .bytes(let y) = coseKey.mapValue(intKey: -3),
          x.count == 32, y.count == 32 else {
        throw PasskeyVerificationError.unsupportedPublicKey
    }
    return Data([0x04]) + x + y
}

/// 解除時に OS が返した署名を、登録時に保存した公開鍵で検証し、正しいパスキーによる解除かを返す。
/// relying party の一致(rpIdHash)・本人確認済み(UV フラグ)・チャレンジの一致まで確認し、署名の検証だけで済ませない。
func verifyPasskeyAssertion(
    publicKey: Data,
    authenticatorData: Data,
    clientDataJSON: Data,
    signature: Data,
    challenge: Data,
    relyingPartyIdentifier: String
) -> Bool {
    // authenticatorData: rpIdHash(32) + flags(1) + signCount(4)
    if authenticatorData.count < 37 {
        return false
    }
    let rpIDHash = Data(SHA256.hash(data: Data(relyingPartyIdentifier.utf8)))
    if authenticatorData.prefix(32) != rpIDHash {
        return false
    }
    let flags = authenticatorData[authenticatorData.startIndex + 32]
    // UP(user present)と UV(user verified)の両方が立っていること。生体認証・パスコードを通っていない署名は受け付けない。
    if flags & 0x01 == 0 || flags & 0x04 == 0 {
        return false
    }
    guard let clientData = try? JSONSerialization.jsonObject(with: clientDataJSON) as? [String: Any],
          clientData["type"] as? String == "webauthn.get",
          clientData["challenge"] as? String == challenge.base64URLEncodedString() else {
        return false
    }
    guard let key = try? P256.Signing.PublicKey(x963Representation: publicKey),
          let ecdsaSignature = try? P256.Signing.ECDSASignature(derRepresentation: signature) else {
        return false
    }
    // WebAuthn の署名対象は authenticatorData || SHA256(clientDataJSON)。isValidSignature がその SHA256 を取って検証する。
    return key.isValidSignature(ecdsaSignature, for: authenticatorData + Data(SHA256.hash(data: clientDataJSON)))
}

extension Data {
    /// WebAuthn の clientDataJSON がチャレンジを表すのに使う、パディング無しの base64url 文字列。
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - CBOR

/// attestation object と COSE 公開鍵の読み取りに必要な範囲だけの CBOR 値。
indirect enum CBORValue: Equatable {
    case unsigned(UInt64)
    case negative(Int64)
    case bytes(Data)
    case text(String)
    case array([CBORValue])
    /// CBOR の map。キーの型が混在し得るため、辞書ではなくペアの配列で持つ。
    case map([(key: CBORValue, value: CBORValue)])

    static func == (lhs: CBORValue, rhs: CBORValue) -> Bool {
        // map がタプル配列のため自動合成できない。ペアの配列同士を要素ごとに比べる。
        switch (lhs, rhs) {
        case (.unsigned(let a), .unsigned(let b)): return a == b
        case (.negative(let a), .negative(let b)): return a == b
        case (.bytes(let a), .bytes(let b)): return a == b
        case (.text(let a), .text(let b)): return a == b
        case (.array(let a), .array(let b)): return a == b
        case (.map(let a), .map(let b)):
            return a.count == b.count && zip(a, b).allSatisfy { $0.key == $1.key && $0.value == $1.value }
        default: return false
        }
    }

    /// map から文字列キーの値を取り出す。map でない・キーが無い場合は nil。
    func mapValue(textKey: String) -> CBORValue? {
        mapValue(key: .text(textKey))
    }

    /// map から整数キー(COSE_Key のラベル)の値を取り出す。負のキーは CBOR の negative として探す。
    func mapValue(intKey: Int64) -> CBORValue? {
        mapValue(key: intKey >= 0 ? .unsigned(UInt64(intKey)) : .negative(intKey))
    }

    private func mapValue(key: CBORValue) -> CBORValue? {
        guard case .map(let pairs) = self else {
            return nil
        }
        return pairs.first { $0.key == key }?.value
    }
}

/// CBOR(RFC 8949)の最小デコーダ。整数・バイト列・文字列・配列・map だけを扱い、
/// 不定長やタグ・浮動小数点などパスキーの読み取りに現れない型はエラーにする。
struct CBORDecoder {
    enum DecodeError: Error, Equatable {
        case truncated
        case unsupported(majorType: UInt8, additionalInfo: UInt8)
    }

    private let data: Data
    private var index: Data.Index

    init(data: Data) {
        self.data = data
        index = data.startIndex
    }

    /// データ先頭の1値をデコードする。
    static func decode(data: Data) throws -> CBORValue {
        var decoder = CBORDecoder(data: data)
        return try decoder.decodeValue()
    }

    /// 現在位置の1値をデコードして読み進める。
    mutating func decodeValue() throws -> CBORValue {
        let initialByte = try readByte()
        let majorType = initialByte >> 5
        let additionalInfo = initialByte & 0x1f
        let argument = try readArgument(additionalInfo: additionalInfo, majorType: majorType)
        switch majorType {
        case 0:
            return .unsigned(argument)
        case 1:
            if argument > UInt64(Int64.max) {
                throw DecodeError.unsupported(majorType: majorType, additionalInfo: additionalInfo)
            }
            return .negative(-1 - Int64(argument))
        case 2:
            return .bytes(try readBytes(count: argument))
        case 3:
            guard let text = String(data: try readBytes(count: argument), encoding: .utf8) else {
                throw DecodeError.unsupported(majorType: majorType, additionalInfo: additionalInfo)
            }
            return .text(text)
        case 4:
            var items: [CBORValue] = []
            for _ in 0..<argument {
                items.append(try decodeValue())
            }
            return .array(items)
        case 5:
            var pairs: [(key: CBORValue, value: CBORValue)] = []
            for _ in 0..<argument {
                let key = try decodeValue()
                let value = try decodeValue()
                pairs.append((key: key, value: value))
            }
            return .map(pairs)
        default:
            throw DecodeError.unsupported(majorType: majorType, additionalInfo: additionalInfo)
        }
    }

    private mutating func readArgument(additionalInfo: UInt8, majorType: UInt8) throws -> UInt64 {
        switch additionalInfo {
        case 0...23:
            return UInt64(additionalInfo)
        case 24:
            return UInt64(try readByte())
        case 25:
            return try readBytes(count: 2).reduce(0) { $0 << 8 | UInt64($1) }
        case 26:
            return try readBytes(count: 4).reduce(0) { $0 << 8 | UInt64($1) }
        case 27:
            return try readBytes(count: 8).reduce(0) { $0 << 8 | UInt64($1) }
        default:
            throw DecodeError.unsupported(majorType: majorType, additionalInfo: additionalInfo)
        }
    }

    private mutating func readByte() throws -> UInt8 {
        if index >= data.endIndex {
            throw DecodeError.truncated
        }
        let byte = data[index]
        index += 1
        return byte
    }

    private mutating func readBytes(count: UInt64) throws -> Data {
        if count > UInt64(data.endIndex - index) {
            throw DecodeError.truncated
        }
        let end = index + Int(count)
        let bytes = data[index..<end]
        index = end
        return Data(bytes)
    }
}
