//
//  LoginView.swift
//  violet
//
//  Created by Mihail Gjoni on 6/30/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices

struct LoginView: View {
    // State variables to manage form input and UI state
    @State private var email = ""           // Stores the email input from user
    @State private var password = ""        // Stores the password input from user
    @State private var loginError = ""      // Stores error messages to display to user
    @Binding var isLoggedIn: Bool           // CHANGED: Now accepts binding from parent
    @StateObject private var authVM = AuthenticationView() // View model for Google Sign-In authentication
    
    var body: some View {
        NavigationStack{
            VStack{
                // Email input field
                TextField("Email", text: $email)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                
                // Password input field (secure - hides characters)
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                
                // Login button for email/password authentication
                Button(action:{login()
                }){
                    Text("Login")
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                // Google Sign-In button
                GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .light)){
                    // When tapped, triggers Google Sign-In flow
                    authVM.signInWithGoogle()
                }
                .onChange(of: authVM.isLoginSuccessed) { oldValue, success in
                    print("🔄 Google Sign-In success state changed from \(oldValue) to: \(success)")
                    if success {
                        print("🔄 Setting isLoggedIn to true from Google Sign-In...")
                        isLoggedIn = true
                    }
                }
                .onChange(of: isLoggedIn) { oldValue, loggedIn in
                    print("🔄 isLoggedIn state changed from \(oldValue) to: \(loggedIn)")
                }
                
                // Apple Sign-In button
                SignInWithAppleButton(
                    onRequest: { request in
                        // This is handled by the AuthenticationView
                    },
                    onCompletion: { result in
                        // This is handled by the AuthenticationView delegates
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(10)
                .onTapGesture {
                    authVM.signInWithApple()
                }
                
                // Display Google Sign-In error message
                if !authVM.errorMessage.isEmpty {
                    Text(authVM.errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Display error message if login fails
                if !loginError.isEmpty{
                    Text(loginError)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Button to navigate to Sign Up page
                NavigationLink(destination: SignUpView(isLoggedIn: $isLoggedIn)) {
                    Text("Don't have an account? Sign Up")
                        .foregroundColor(.blue)
                        .padding(.top, 20)
                }
                
                // Remove the old navigation link since ContentView handles navigation now
            }
            .padding()
        }
    }
    
    // Function to handle email/password login
    func login() {
        // Clear any previous errors
        loginError = ""
        
        print("🔍 Starting email/password login...")
        
        // Use Firebase Auth to sign in with email and password
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            DispatchQueue.main.async {
                // Check if there was an error during sign-in
                if let error = error {
                    print("❌ Email login error: \(error.localizedDescription)")
                    loginError = error.localizedDescription // Display error to user
                    return // Don't proceed if there's an error
                }
                
                // Only set logged in state to true if login was successful
                if let authResult = authResult {
                    print("✅ Email login successful for user: \(authResult.user.email ?? "No email")")
                    print("🔄 Setting isLoggedIn to true...")
                    isLoggedIn = true // This will trigger navigation to ContentView
                    print("✅ isLoggedIn is now: \(isLoggedIn)")
                } else {
                    print("❌ No auth result received")
                    loginError = "Login failed - no result received"
                }
            }
        }
    }
}

#Preview {
    LoginView(isLoggedIn: .constant(false))
}
