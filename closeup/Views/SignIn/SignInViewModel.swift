//
//  SignInViewModel.swift
//  closeup
//
//  Created by Weston Cadena on 5/9/25.
//

import Foundation
import GoogleSignIn
import CryptoKit


class SignInViewModel: ObservableObject {
    
    func signInWithGoogle() async throws -> AppUser{
        let signInGoogle = SignInGoogle()
        let googleResult = try await signInGoogle.startSignInWithGoogleFlow()
        return try await AuthManager.shared.signInWithGoogle(idToken: googleResult.idToken, nonce: googleResult.nonce)
    }
    
    
}

struct SignInGoogleResult {
    let idToken: String
    let nonce: String
    
}

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
    class func getTopViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        // Ensure we're on the main thread
        if !Thread.isMainThread {
            var result: UIViewController?
            DispatchQueue.main.sync {
                result = getTopViewController(base: base)
            }
            return result
        }
        
        // Now we can safely access UI elements
        if let nav = base as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)
        } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return getTopViewController(base: selected)
        } else if let presented = base?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return base
    }
}
