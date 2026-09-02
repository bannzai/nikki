import Testing
import Foundation
import CryptoKit
@testable import Nikki

/// パスキーの登録結果(attestation object)の読み取りと、解除時の署名検証(Passkey.swift)を検証する。
/// OS の認証ダイアログは介さず、WebAuthn の仕様に沿って組み立てたバイト列と CryptoKit の鍵で確かめる。
struct PasskeyTests {
    private let relyingPartyIdentifier = "bannzai.github.io"

    /// WebAuthn の authenticatorData(rpIdHash + flags + signCount)を組み立てる。
    private func authenticatorData(relyingPartyIdentifier: String, flags: UInt8) -> Data {
        Data(SHA256.hash(data: Data(relyingPartyIdentifier.utf8))) + Data([flags]) + Data([0, 0, 0, 1])
    }

    /// 登録時に OS が返す attestation object(fmt: none)を、与えた公開鍵と credentialID で組み立てる。
    private func attestationObject(publicKey: P256.Signing.PublicKey, credentialID: Data) -> Data {
        let x963 = publicKey.x963Representation
        let x = x963[1..<33]
        let y = x963[33..<65]
        // COSE_Key(EC2 / ES256 / P-256): {1: 2, 3: -7, -1: 1, -2: x, -3: y}
        let coseKey = Data([0xa5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20]) + x + Data([0x22, 0x58, 0x20]) + y
        let aaguid = Data(repeating: 0, count: 16)
        let attestedCredentialData = aaguid + Data([UInt8(credentialID.count >> 8), UInt8(credentialID.count & 0xff)]) + credentialID + coseKey
        // flags: UP | UV | AT
        let authData = authenticatorData(relyingPartyIdentifier: relyingPartyIdentifier, flags: 0x45) + attestedCredentialData
        // {"fmt": "none", "attStmt": {}, "authData": <bytes>}
        return Data([0xa3])
            + Data([0x63]) + Data("fmt".utf8) + Data([0x64]) + Data("none".utf8)
            + Data([0x67]) + Data("attStmt".utf8) + Data([0xa0])
            + Data([0x68]) + Data("authData".utf8) + Data([0x58, UInt8(authData.count)]) + authData
    }

    /// 解除時に OS が返す clientDataJSON を組み立てる。
    private func clientDataJSON(challenge: Data) -> Data {
        Data("{\"type\":\"webauthn.get\",\"challenge\":\"\(challenge.base64URLEncodedString())\",\"origin\":\"https://\(relyingPartyIdentifier)\"}".utf8)
    }

    @Test("attestation object から P-256 公開鍵を X9.63 表現で取り出せる")
    func extractsPublicKeyFromAttestationObject() throws {
        let privateKey = P256.Signing.PrivateKey()
        let credentialID = Data((0..<16).map { UInt8($0) })
        let publicKey = try passkeyPublicKey(attestationObject: attestationObject(publicKey: privateKey.publicKey, credentialID: credentialID))
        #expect(publicKey == privateKey.publicKey.x963Representation)
        #expect(publicKey.count == 65)
    }

    @Test("途中で切れた attestation object は不正として扱う")
    func rejectsTruncatedAttestationObject() {
        let object = attestationObject(publicKey: P256.Signing.PrivateKey().publicKey, credentialID: Data(repeating: 1, count: 16))
        #expect(throws: (any Error).self) {
            try passkeyPublicKey(attestationObject: object.prefix(object.count - 10))
        }
    }

    @Test("ES256 以外の公開鍵は受け付けない")
    func rejectsNonES256Key() {
        // alg を ES256(-7) から RS256(-257) に差し替える。-257 は CBOR で 39 01 00(negative, 2 バイト引数)。
        let privateKey = P256.Signing.PrivateKey()
        var object = attestationObject(publicKey: privateKey.publicKey, credentialID: Data(repeating: 1, count: 16))
        let algRange = object.range(of: Data([0x03, 0x26, 0x20, 0x01]))!
        object.replaceSubrange(algRange, with: Data([0x03, 0x39, 0x01, 0x00, 0x20, 0x01]))
        // authData の長さが 2 バイト増えるため、bytes ヘッダの長さも合わせる。
        let lengthRange = object.range(of: Data([0x68]) + Data("authData".utf8) + Data([0x58]))!
        object[lengthRange.upperBound] += 2
        #expect(throws: PasskeyVerificationError.unsupportedPublicKey) {
            try passkeyPublicKey(attestationObject: object)
        }
    }

    @Test("登録した鍵による本人確認済みの署名は検証を通る")
    func verifiesValidAssertion() throws {
        let privateKey = P256.Signing.PrivateKey()
        let challenge = Data(repeating: 7, count: 32)
        let authData = authenticatorData(relyingPartyIdentifier: relyingPartyIdentifier, flags: 0x05)
        let clientData = clientDataJSON(challenge: challenge)
        let signature = try privateKey.signature(for: authData + Data(SHA256.hash(data: clientData))).derRepresentation
        #expect(verifyPasskeyAssertion(
            publicKey: privateKey.publicKey.x963Representation,
            authenticatorData: authData,
            clientDataJSON: clientData,
            signature: signature,
            challenge: challenge,
            relyingPartyIdentifier: relyingPartyIdentifier
        ))
    }

    @Test("別の鍵・別のチャレンジ・別の relying party・本人確認なし・改ざんされた署名は検証を通らない")
    func rejectsInvalidAssertions() throws {
        let privateKey = P256.Signing.PrivateKey()
        let challenge = Data(repeating: 7, count: 32)
        let authData = authenticatorData(relyingPartyIdentifier: relyingPartyIdentifier, flags: 0x05)
        let clientData = clientDataJSON(challenge: challenge)
        let signature = try privateKey.signature(for: authData + Data(SHA256.hash(data: clientData))).derRepresentation
        let publicKey = privateKey.publicKey.x963Representation

        // 別の鍵
        #expect(!verifyPasskeyAssertion(publicKey: P256.Signing.PrivateKey().publicKey.x963Representation, authenticatorData: authData, clientDataJSON: clientData, signature: signature, challenge: challenge, relyingPartyIdentifier: relyingPartyIdentifier))
        // 別のチャレンジ(リプレイ)
        #expect(!verifyPasskeyAssertion(publicKey: publicKey, authenticatorData: authData, clientDataJSON: clientData, signature: signature, challenge: Data(repeating: 8, count: 32), relyingPartyIdentifier: relyingPartyIdentifier))
        // 別の relying party
        #expect(!verifyPasskeyAssertion(publicKey: publicKey, authenticatorData: authData, clientDataJSON: clientData, signature: signature, challenge: challenge, relyingPartyIdentifier: "example.com"))
        // 本人確認(UV)なしの署名
        let unverifiedAuthData = authenticatorData(relyingPartyIdentifier: relyingPartyIdentifier, flags: 0x01)
        let unverifiedSignature = try privateKey.signature(for: unverifiedAuthData + Data(SHA256.hash(data: clientData))).derRepresentation
        #expect(!verifyPasskeyAssertion(publicKey: publicKey, authenticatorData: unverifiedAuthData, clientDataJSON: clientData, signature: unverifiedSignature, challenge: challenge, relyingPartyIdentifier: relyingPartyIdentifier))
        // 改ざんされた署名
        var tampered = signature
        tampered[tampered.count - 1] ^= 0xff
        #expect(!verifyPasskeyAssertion(publicKey: publicKey, authenticatorData: authData, clientDataJSON: clientData, signature: tampered, challenge: challenge, relyingPartyIdentifier: relyingPartyIdentifier))
        // 登録(webauthn.create)の clientDataJSON を解除に流用したもの
        let createClientData = Data("{\"type\":\"webauthn.create\",\"challenge\":\"\(challenge.base64URLEncodedString())\"}".utf8)
        let createSignature = try privateKey.signature(for: authData + Data(SHA256.hash(data: createClientData))).derRepresentation
        #expect(!verifyPasskeyAssertion(publicKey: publicKey, authenticatorData: authData, clientDataJSON: createClientData, signature: createSignature, challenge: challenge, relyingPartyIdentifier: relyingPartyIdentifier))
    }

    @Test("CBOR の整数・負数・バイト列・文字列・配列・map を読める")
    func decodesCBOR() throws {
        // {1: 2, 3: -7, -1: 1, "a": [0x18 0x64 = 100, h'0102'], 500: "b"}
        let bytes = Data([0xa5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x61, 0x61, 0x82, 0x18, 0x64, 0x42, 0x01, 0x02, 0x19, 0x01, 0xf4, 0x61, 0x62])
        var decoder = CBORDecoder(data: bytes)
        let value = try decoder.decodeValue()
        #expect(value.mapValue(intKey: 1) == .unsigned(2))
        #expect(value.mapValue(intKey: 3) == .negative(-7))
        #expect(value.mapValue(intKey: -1) == .unsigned(1))
        #expect(value.mapValue(textKey: "a") == .array([.unsigned(100), .bytes(Data([1, 2]))]))
        #expect(value.mapValue(intKey: 500) == .text("b"))
        #expect(value.mapValue(intKey: 4) == nil)
    }

    @Test("base64url はパディング無しで + / を - _ に置き換える")
    func base64URLEncoding() {
        #expect(Data([0xfb, 0xff, 0xbf]).base64URLEncodedString() == "-_-_")
        #expect(Data([0x01]).base64URLEncodedString() == "AQ")
    }
}
