import SwiftUI

/// Temporary UserInfo struct for onboarding form state (replace with domain model if needed)
struct UserInfo {
    var name: String = ""
    var age: Int = 0
    var gender: String = ""
}

/// UserInfoFormView collects user profile information during onboarding.
/// - Complies with DATA_STANDARDS.md §2.3 (metadata collection) and DATA_DICTIONARY.md (field definitions).
struct UserInfoFormView: View {
    /// True if onboarding is anonymous (see onboarding flow in DATA_STANDARDS.md §2.2)
    var isAnonymous: Bool
    /// Two-way binding to local user info (see DATA_DICTIONARY.md: name, age, gender)
    @Binding var userInfo: UserInfo
    /// Called when the form is complete and validated
    var onComplete: () -> Void

    @State private var showAlert = false
    @State private var ageText: String = ""
    @State private var nameError: String? = nil
    @State private var ageError: String? = nil

    var body: some View {
        VStack(spacing: SageSpacing.large) {
            SageSectionHeader(title: "Tell Us About You")
            Text("We only need your age for research purposes. Your privacy is always protected.")
                .font(SageTypography.body)
                .foregroundColor(SageColors.espressoBrown)
                .multilineTextAlignment(.center)
            SageTextField(
                placeholder: "Name (optional)",
                text: $userInfo.name
            )
            #if os(iOS)
            SageTextField(
                placeholder: "Age",
                text: $ageText,
                error: ageError,
                keyboardType: .numberPad
            )
            #else
            SageTextField(
                placeholder: "Age",
                text: $ageText,
                error: ageError
            )
            #endif
            SageTextField(
                placeholder: "Gender (optional)",
                text: $userInfo.gender
            )
            SageButton(title: "Continue") {
                print("UserInfoFormView: Continue button tapped with name=\(userInfo.name), ageText=\(ageText), gender=\(userInfo.gender)")
                // Validate per DATA_STANDARDS.md §2.3 - only age is required
                ageError = ageText.isEmpty || Int(ageText) == nil ? "Valid age is required for research purposes." : nil
                if ageError == nil {
                    userInfo.age = Int(ageText) ?? 0
                    print("UserInfoFormView: Form complete, calling onComplete() with age=\(userInfo.age)")
                    onComplete()
                } else {
                    print("UserInfoFormView: Missing or invalid age")
                    showAlert = true
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Age Required"), message: Text("Please enter your age for research purposes."), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            ageText = userInfo.age > 0 ? String(userInfo.age) : ""
            print("UserInfoFormView: appeared")
        }
    }
}

struct UserInfoFormView_Previews: PreviewProvider {
    @State static var userInfo = UserInfo()
    static var previews: some View {
        UserInfoFormView(isAnonymous: true, userInfo: $userInfo, onComplete: {})
    }
} 