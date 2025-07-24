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
            SageButton(title: "Log In", action: onLogin)
            SageButton(title: "Sign Up", action: onSignup)
        }
    }
}

struct LoginSignupChoiceView_Previews: PreviewProvider {
    static var previews: some View {
        LoginSignupChoiceView(onLogin: {}, onSignup: {})
    }
} 