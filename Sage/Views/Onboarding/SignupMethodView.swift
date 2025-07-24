import SwiftUI

struct SignupMethodView: View {
    var onAnonymous: () -> Void
    var onEmail: () -> Void

    var body: some View {
        VStack(spacing: SageSpacing.large) {
            SageSectionHeader(title: "Sign Up")
            Text("Choose how you want to sign up.")
                .font(SageTypography.body)
                .foregroundColor(SageColors.espressoBrown)
                .multilineTextAlignment(.center)
            SageButton(title: "Continue Anonymously", action: onAnonymous)
            SageButton(title: "Sign Up with Email", action: onEmail)
        }
    }
}

struct SignupMethodView_Previews: PreviewProvider {
    static var previews: some View {
        SignupMethodView(onAnonymous: {}, onEmail: {})
    }
} 