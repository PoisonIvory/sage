import SwiftUI

struct ProfilePagePlaceholderView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isLoggingOut = false
    
    private var isLoading: Bool {
        if case .loading = authViewModel.state { return true }
        return false
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            SageCard {
                VStack(spacing: 16) {
                    Text("Profile Page Placeholder")
                        .font(.largeTitle.bold())
                        .foregroundColor(SageColors.espressoBrown)
                        .padding(.bottom, 8)
                    Text("This is where your profile will live. For now, you can log out to restart onboarding.")
                        .font(.body)
                        .foregroundColor(SageColors.softTaupe)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            Button(action: {
                isLoggingOut = true
                authViewModel.signOut()
                isLoggingOut = false
            }) {
                if isLoggingOut || isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: SageColors.sageTeal))
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Log Out and Restart")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(SageColors.sageTeal)
                        .cornerRadius(12)
                }
            }
            .disabled(isLoggingOut || isLoading)
            .padding(.horizontal, 32)
            Spacer()
        }
        .background(SageColors.fogWhite.ignoresSafeArea())
    }
}

#if DEBUG
struct ProfilePagePlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        ProfilePagePlaceholderView()
            .environmentObject(AuthViewModel())
    }
}
#endif 