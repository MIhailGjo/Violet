//
//  AuthenticationView.swift
//  Violet
//
//  Created by Mihail Gjoni on 7/5/25.
//

import SwiftUI
import AuthenticationServices  // Add this for Apple Sign-In
import CryptoKit  // Add this for Apple Sign-In
import Firebase
import FirebaseAuth
import GoogleSignIn

class AuthenticationView: NSObject, ObservableObject {
    
    @Published var isLoginSuccessed = false
    @Published var errorMessage = ""
    
    // Apple Sign-In property
    @Published var currentNonce: String?
    
    func signInWithGoogle() {
        // Clear any previous error messages
        errorMessage = ""
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Failed to get client ID"
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Get the root view controller properly
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Could not find root view controller"
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    print("Google Sign-In Error: \(error.localizedDescription)")
                    return
                }
                
                guard let user = result?.user,
                      let idToken = user.idToken else {
                    self?.errorMessage = "Failed to get user token"
                    return
                }
                
                let accessToken = user.accessToken
                let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString,
                                                               accessToken: accessToken.tokenString)
                
                // Sign in with Firebase
                Auth.auth().signIn(with: credential) { authResult, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self?.errorMessage = error.localizedDescription
                            print("Firebase Sign-In Error: \(error.localizedDescription)")
                            return
                        }
                        
                        guard let user = authResult?.user else {
                            self?.errorMessage = "Failed to get Firebase user"
                            return
                        }
                        
                        print("Successfully signed in user: \(user.displayName ?? "No name")")
                        
                        // Update the success state - THIS WAS MISSING!
                        self?.isLoginSuccessed = true
                        self?.errorMessage = ""
                    }
                }
            }
        }
    }
    
    // MARK: - Apple Sign-In Function (NEW)
    func signInWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func logout() async throws {
        await MainActor.run {
            GIDSignIn.sharedInstance.signOut()
            isLoginSuccessed = false
            errorMessage = ""
        }
        try Auth.auth().signOut()
    }
    
    // Helper functions for Apple Sign-In
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// MARK: - Apple Sign-In Delegates (NEW)
extension AuthenticationView: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                errorMessage = "Invalid state: A login callback was received, but no login request was sent."
                return
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                errorMessage = "Unable to fetch identity token"
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "Unable to serialize token string from data"
                return
            }
            
            let credential = OAuthProvider.credential(providerID: AuthProviderID.apple,
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let user = authResult?.user else {
                        self?.errorMessage = "Failed to get Firebase user"
                        return
                    }
                    
                    print("Successfully signed in with Apple: \(user.displayName ?? "No name")")
                    
                    self?.isLoginSuccessed = true
                    self?.errorMessage = ""
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
        }
    }
}

extension AuthenticationView: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
}
