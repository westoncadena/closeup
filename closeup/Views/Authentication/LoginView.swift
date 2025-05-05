import SwiftUI
import Combine

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var isShowingSignUp = false
    
    var body: some View {
        NavigationView {
            VStack {
                // App Logo and Name
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    
                    Text("close up")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .padding(.bottom, 40)
                
                // Login Form
                VStack(spacing: 20) {
                    TextField("Email", text: $viewModel.email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button(action: {
                        viewModel.login(userService: appState.userService)
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
                            Text("Log In")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .disabled(viewModel.isLoading)
                    
                    Button(action: {
                        // Handle forgot password
                    }) {
                        Text("Forgot Password?")
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Add this debug button
                Button(action: {
                    print("Debug bypass login pressed")
                    // Directly set authentication to true
                    appState.userService.currentUser = User(name: "Debug User", profileImage: "user1")
                    appState.userService.isAuthenticated = true
                }) {
                    Text("DEBUG: Skip Login")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                
                // Sign Up Button
                Button(action: {
                    isShowingSignUp = true
                }) {
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.secondary)
                        Text("Sign Up")
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    .font(.callout)
                }
                .padding(.bottom, 20)
            }
            .padding()
            .navigationBarHidden(true)
            .sheet(isPresented: $isShowingSignUp) {
                SignUpView()
                    .environmentObject(appState)
            }
        }
    }
}

class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage = ""
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    func login(userService: UserService) {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        userService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        if let authError = error as? AuthError {
                            switch authError {
                            case .invalidCredentials:
                                self?.errorMessage = "Invalid email or password"
                            default:
                                self?.errorMessage = "An error occurred. Please try again."
                            }
                        } else {
                            self?.errorMessage = "An error occurred. Please try again."
                        }
                    }
                },
                receiveValue: { _ in
                    // Login successful, app state will handle navigation
                }
            )
            .store(in: &cancellables)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AppState())
    }
}
