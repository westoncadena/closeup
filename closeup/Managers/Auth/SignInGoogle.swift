//
//  SignInGoogle.swift
//  closeup
//
//  Created by Weston Cadena on 5/15/25.
//

import CryptoKit
import UIKit
import GoogleSignIn

struct SignInGoogleResult {
    let idToken: String
    let nonce: String
}

@MainActor
class SignInGoogle {
    
    func startSignInWithGoogleFlow() async throws -> SignInGoogleResult {
        try await withCheckedThrowingContinuation({ [weak self] continuation in
            self?.signInWithGoogleFlow { result in
                continuation.resume(with: result)
            }
        })
    }
    
    func signInWithGoogleFlow(completion: @escaping (Result<SignInGoogleResult, Error>) -> (Void)){
        DispatchQueue.main.async {
            guard let topVC = UIApplication.getTopViewController() else {
                completion(.failure(NSError()))
                return
            }
            let nonce = self.randomNonceString()
            GIDSignIn.sharedInstance.signIn(withPresenting: topVC) {signInResult, error in
                guard let user = signInResult?.user, let idToken = user.idToken else {
                    completion(.failure(NSError()))
                    return
                }
                print(user)
                completion(.success(.init(idToken: idToken.tokenString, nonce: nonce)))
            }
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate \(length) random bytes: \(errorCode)"
            )
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWSYZabcdefghijklmnopqrstuvwsyz-._")
        
        let nonce = randomBytes.map { byte in charset[Int(byte) % charset.count]}
        
        return String(nonce)
    }
    
}

extension UIApplication {
    class func getTopViewController(base: UIViewController? = nil) -> UIViewController? {
        // Ensure we're on the main thread
        if !Thread.isMainThread {
            var result: UIViewController?
            DispatchQueue.main.sync {
                result = getTopViewController(base: base)
            }
            return result
        }

        // Determine the base view controller if not provided
        let effectiveBase: UIViewController?
        if let providedBase = base {
            effectiveBase = providedBase
        } else {
            // Use the new approach for scene-based applications
            effectiveBase = UIApplication.shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .compactMap { $0 as? UIWindowScene }
                .first?.windows
                .filter { $0.isKeyWindow }
                .first?.rootViewController
        }
        
        // Now we can safely access UI elements
        if let nav = effectiveBase as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)
        } else if let tab = effectiveBase as? UITabBarController, let selected = tab.selectedViewController {
            return getTopViewController(base: selected)
        } else if let presented = effectiveBase?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return effectiveBase
    }
}
