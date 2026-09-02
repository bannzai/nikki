import AuthenticationServices
import CryptoKit
import SwiftUI

/// パスキーの登録・解除認証を OS(AuthenticationServices)に依頼する入口。
/// relying party は Const.passkeyRelyingPartyIdentifier で、そのドメイン直下の
/// /.well-known/apple-app-site-association が本アプリを webcredentials で許可している必要がある。
/// 署名の検証(Passkey.swift)はサーバを持たない本アプリ自身が行う。

/// パスキーを新規登録し、解除時の検証に必要な値を返す。キャンセル・失敗は OS のエラーをそのまま投げる。
/// userID を登録ごとに乱数にするのは、同じ userID で登録し直すと iCloud キーチェーン上の既存パスキーが
/// 置き換わり、別の端末に保存済みの公開鍵と食い違って解除できなくなるため。
@MainActor
func registerPasskey() async throws -> PasskeyCredential {
    let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: Const.passkeyRelyingPartyIdentifier)
    let request = provider.createCredentialRegistrationRequest(
        challenge: randomChallenge(),
        name: "Nikki",
        userID: randomChallenge()
    )
    let authorization = try await PasskeyAuthorizationRunner().perform(request: request)
    guard let registration = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration,
          let attestationObject = registration.rawAttestationObject else {
        throw PasskeyVerificationError.malformedAuthenticatorData
    }
    return PasskeyCredential(
        credentialID: registration.credentialID,
        publicKey: try passkeyPublicKey(attestationObject: attestationObject)
    )
}

/// 登録済みのパスキーでロック解除の認証を行い、保存済みの公開鍵で検証できたかを返す。キャンセル・失敗時は false を返す。
@MainActor
func evaluatePasskeyUnlockAuthentication(credential: PasskeyCredential) async -> Bool {
    let challenge = randomChallenge()
    let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: Const.passkeyRelyingPartyIdentifier)
    let request = provider.createCredentialAssertionRequest(challenge: challenge)
    // 登録時のパスキーだけを候補にし、同じ relying party の別のパスキー(他端末で登録したもの)を選ばせない。
    request.allowedCredentials = [ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: credential.credentialID)]
    guard let authorization = try? await PasskeyAuthorizationRunner().perform(request: request),
          let assertion = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion,
          assertion.credentialID == credential.credentialID else {
        return false
    }
    return verifyPasskeyAssertion(
        publicKey: credential.publicKey,
        authenticatorData: assertion.rawAuthenticatorData,
        clientDataJSON: assertion.rawClientDataJSON,
        signature: assertion.signature,
        challenge: challenge,
        relyingPartyIdentifier: Const.passkeyRelyingPartyIdentifier
    )
}

/// パスキーの認証エラーがユーザーのキャンセルによるものかを返す。キャンセルはエラー表示の対象にしない。
func isPasskeyCanceled(error: Error) -> Bool {
    (error as? ASAuthorizationError)?.code == .canceled
}

/// WebAuthn のチャレンジと userID に使う乱数。
private func randomChallenge() -> Data {
    SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
}

/// ASAuthorizationController のデリゲート応答を async に変換する。
/// 認証が終わるまでコントローラとデリゲート(self)を生かしておくため、continuation の完了までインスタンスを保持する。
@MainActor
private final class PasskeyAuthorizationRunner: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<ASAuthorization, Error>?
    private var controller: ASAuthorizationController?

    func perform(request: ASAuthorizationRequest) async throws -> ASAuthorization {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            self.controller = controller
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation?.resume(returning: authorization)
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if os(macOS)
        return NSApp.keyWindow ?? NSApp.windows.first ?? ASPresentationAnchor()
        #else
        let windows = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
        return windows.first { $0.isKeyWindow } ?? windows.first ?? ASPresentationAnchor()
        #endif
    }
}
