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
            SageButton(title: "Continue Anonymously", action: {
                print("SignupMethodView: Continue Anonymously button tapped")
                onAnonymous()
            })
            SageButton(title: "Sign Up with Email", action: {
                print("SignupMethodView: Sign Up with Email button tapped")
                onEmail()
            })
        }
        .onAppear {
            print("SignupMethodView: appeared")
        }
    }
}

struct SignupMethodView_Previews: PreviewProvider {
    static var previews: some View {
        SignupMethodView(onAnonymous: {}, onEmail: {})
    }
} 