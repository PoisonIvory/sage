import SwiftUI

struct OnboardingFlowView: View {
    @State private var step: Step = .loginSignupChoice
    @State private var isAnonymous: Bool = false
    @State private var userInfo: UserInfo = UserInfo()

    enum Step {
        case loginSignupChoice, signupMethod, userInfoForm, completed
    }

    var body: some View {
        VStack {
            switch step {
            case .loginSignupChoice:
                LoginSignupChoiceView(onLogin: { step = .userInfoForm; isAnonymous = false },
                                      onSignup: { step = .signupMethod })
            case .signupMethod:
                SignupMethodView(onAnonymous: {
                    isAnonymous = true
                    step = .userInfoForm
                }, onEmail: {
                    isAnonymous = false
                    step = .userInfoForm
                })
            case .userInfoForm:
                UserInfoFormView(isAnonymous: isAnonymous, userInfo: $userInfo, onComplete: {
                    step = .completed
                })
            case .completed:
                Text("Onboarding Complete! Navigating to Home...")
            }
        }
        .padding()
    }
}

struct UserInfo {
    var name: String = ""
    var age: String = ""
    var gender: String = ""
}

struct OnboardingFlowView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingFlowView()
    }
} 