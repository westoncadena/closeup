//
//  SignUpView.swift
//  closeup
//
//  Created by Weston Cadena on 5/4/25.
//

import SwiftUI
import Combine

struct SignUpView: View {
    @StateObject private var viewModel = SignUpViewModel()
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // App Logo and Name
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)
                        
                        Text("Create Account")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.bottom, 30)
                    
                    // Sign Up Form
                    VStack(spacing: 16) {
                        TextField("Full Name", text: $viewModel.name)
                            .textContentType(.name)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        TextField("Email", text: $viewModel.email)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        SecureField("Password", text: $viewModel.password)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        SecureField("Confirm Password", text: $viewModel.confirmPassword)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        if !viewModel.errorMessage.isEmpty {
                            Text(viewModel.errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: {
                            viewModel.signUp(userService: appState.userService)
                        }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            } else {
                                Text("Create Account")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .disabled(viewModel.isLoading)
                        .padding(.top, 10)
                        
                        Text("By signing up, you agree to our Terms of Service and Privacy Policy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 5)
                    }
                    .padding(.horizontal, 30)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
        }
    }
}

class SignUpViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var errorMessage = ""
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    func signUp(userService: UserService) {
        guard validateInput() else { return }
        
        isLoading = true
        errorMessage = ""
        
        userService.createAccount(name: name, email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        if let authError = error as? AuthError {
                            switch authError {
                            case .invalidInput:
                                self?.errorMessage = "Please provide valid information"
                            default:
                                self?.errorMessage = "An error occurred. Please try again."
                            }
                        } else {
                            self?.errorMessage = "An error occurred. Please try again."
                        }
                    }
                },
                receiveValue: { _ in
                    // Sign up successful, app state will handle navigation
                }
            )
            .store(in: &cancellables)
    }
    
    private func validateInput() -> Bool {
        if name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            errorMessage = "All fields are required"
            return false
        }
        
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            return false
        }
        
        if password != confirmPassword {
            errorMessage = "Passwords do not match"
            return false
        }
        
        if !email.contains("@") {
            errorMessage = "Please enter a valid email address"
            return false
        }
        
        return true
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(AppState())
    }
}
