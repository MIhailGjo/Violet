//
//  SignUpView.swift
//  violet
//
//  Created by Mihail Gjoni on 7/14/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices

struct SignUpView: View {
    // Environment variable to handle navigation dismissal
    @Environment(\.dismiss) private var dismiss
    
    // State variables to manage form input and UI state
    @State private var email = ""                    // Stores the email input from user
    @State private var password = ""                 // Stores the password input from user
    @State private var confirmPassword = ""          // Stores the password confirmation input
    @State private var fullName = ""                 // Stores the full name input from user
    @State private var signUpError = ""              // Stores error messages to display to user
    @Binding var isLoggedIn: Bool                    // CHANGED: Now accepts binding from parent
    @StateObject private var authVM = AuthenticationView()   // View model for Google Sign-In authentication
    
    var body: some View {
        NavigationStack{
            VStack(spacing: 20){
                // Title
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 20)
                
                // Full name input field
                TextField("Full Name", text: $fullName)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .autocapitalization(.words)
                
                // Email input field
                TextField("Email", text: $email)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                // Password input field (secure - hides characters)
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                
                // Confirm password input field
                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                
                // Sign Up button for email/password registration
                Button(action: {signUp()}) {
                    Text("Sign Up")
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .disabled(!isFormValid()) // Disable button if form is invalid
                
                // Divider with "OR" text
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(height: 1)
                    
                    Text("OR")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(height: 1)
                }
                .padding(.vertical, 10)
                
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
                // Google Sign-In button
                GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .light)){
                    // When tapped, triggers Google Sign-In flow
                    authVM.signInWithGoogle()
                }
                .onChange(of: authVM.isLoginSuccessed) { success in
                    if success {
                        isLoggedIn = true
                    }
                }
                
                // Display Google Sign-In error message
                if !authVM.errorMessage.isEmpty {
                    Text(authVM.errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Display error message if sign up fails
                if !signUpError.isEmpty{
                    Text(signUpError)
                        .foregroundColor(.red)
                        .padding()
                        .multilineTextAlignment(.center)
                }
                
                // Link to go back to login page
                Button(action: {
                    // Navigate back to login page
                    dismiss()
                }) {
                    Text("Already have an account? Log In")
                        .foregroundColor(.blue)
                        .padding(.top, 10)
                }
                
                // Remove the old navigation link since ContentView handles navigation now
            }
            .padding()
        }
    }
    
    // Function to validate form inputs
    func isFormValid() -> Bool {
        return !email.isEmpty &&
               !password.isEmpty &&
               !confirmPassword.isEmpty &&
               !fullName.isEmpty &&
               password == confirmPassword &&
               password.count >= 6 &&
               email.contains("@")
    }
    
    // Function to handle email/password registration
    func signUp() {
        // Clear any previous errors
        signUpError = ""
        
        // Validate passwords match
        guard password == confirmPassword else {
            signUpError = "Passwords do not match"
            return
        }
        
        // Validate password length
        guard password.count >= 6 else {
            signUpError = "Password must be at least 6 characters"
            return
        }
        
        // Validate email format (basic check)
        guard email.contains("@") && email.contains(".") else {
            signUpError = "Please enter a valid email address"
            return
        }
        
        // Use Firebase Auth to create new user with email and password
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            DispatchQueue.main.async {
                // Check if there was an error during registration
                if let error = error {
                    signUpError = error.localizedDescription
                    return
                }
                
                // If registration successful, update user profile with full name
                if let user = authResult?.user {
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = fullName
                    changeRequest.commitChanges { error in
                        if let error = error {
                            print("Error updating display name: \(error.localizedDescription)")
                        }
                    }
                }
                
                // Set registered state to true (this will trigger navigation)
                isLoggedIn = true  // Update parent's state instead
            }
        }
    }
}

#Preview {
    SignUpView(isLoggedIn: .constant(false))
}
