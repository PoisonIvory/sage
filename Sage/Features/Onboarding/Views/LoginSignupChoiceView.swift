import SwiftUI

struct LoginSignupChoiceView: View {
    var onLogin: () -> Void
    var onSignup: () -> Void

    var body: some View {
        VStack(spacing: SageSpacing.large) {
            SageSectionHeader(title: "Welcome to Sage")
            Text("Get started by logging in or creating a new account.")
                .font(SageTypography.body)
                .foregroundColor(SageColors.espressoBrown)
                .multilineTextAlignment(.center)
                .onAppear {
                    print("LoginSignupChoiceView: appeared")
                }
            SageButton(title: "Log In", action: {
                print("LoginSignupChoiceView: Log In button tapped")
                onLogin()
            })
            SageButton(title: "Sign Up", action: {
                print("LoginSignupChoiceView: Sign Up button tapped")
                onSignup()
            })
        }
    }
}

struct LoginSignupChoiceView_Previews: PreviewProvider {
    static var previews: some View {
        LoginSignupChoiceView(onLogin: {}, onSignup: {})
    }
} 