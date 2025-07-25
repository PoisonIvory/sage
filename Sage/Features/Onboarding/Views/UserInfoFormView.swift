import SwiftUI

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

    var body: some View {
        VStack(spacing: SageSpacing.large) {
            SageSectionHeader(title: "Tell Us About You")
            Text("We use this info to personalize your experience. Your privacy is always protected.")
                .font(SageTypography.body)
                .foregroundColor(SageColors.espressoBrown)
                .multilineTextAlignment(.center)
            // Name (DATA_DICTIONARY.md: name)
            TextField("Name", text: $userInfo.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            #if os(iOS)
            // Age (DATA_DICTIONARY.md: age)
            TextField("Age", text: $ageText)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            #else
            TextField("Age", text: $ageText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            #endif
            // Gender (DATA_DICTIONARY.md: gender)
            TextField("Gender (optional)", text: $userInfo.gender)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            SageButton(title: "Continue") {
                print("UserInfoFormView: Continue button tapped with name=\(userInfo.name), ageText=\(ageText), gender=\(userInfo.gender)")
                // Validate per DATA_STANDARDS.md §2.3
                if userInfo.name.isEmpty || ageText.isEmpty || Int(ageText) == nil {
                    print("UserInfoFormView: Missing or invalid required fields")
                    showAlert = true
                } else {
                    userInfo.age = Int(ageText) ?? 0
                    print("UserInfoFormView: Form complete, calling onComplete() with age=\(userInfo.age)")
                    onComplete()
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Missing Info"), message: Text("Please enter your name and a valid age."), dismissButton: .default(Text("OK")))
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