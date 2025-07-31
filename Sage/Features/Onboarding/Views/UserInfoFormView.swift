import SwiftUI

/// UserInfoFormView collects user profile information during onboarding.
/// - Complies with DATA_STANDARDS.md §2.3 (metadata collection) and DATA_DICTIONARY.md (field definitions).
struct UserInfoFormView: View {
    /// True if onboarding is anonymous (see onboarding flow in DATA_STANDARDS.md §2.2)
    var isAnonymous: Bool
    /// Two-way binding to local user info (see DATA_DICTIONARY.md: age, gender, conditions)
    @Binding var userInfo: UserProfileData
    /// Called when the form is complete and validated
    var onComplete: () -> Void

    @State private var showAlert = false
    @State private var ageText: String = ""
    @State private var ageError: String? = nil

    var body: some View {
        VStack(spacing: SageSpacing.large) {
            SageSectionHeader(title: "Tell Us About You")
            Text("We need your age and some basic information for research purposes. Your privacy is always protected.")
                .font(SageTypography.body)
                .foregroundColor(SageColors.espressoBrown)
                .multilineTextAlignment(.center)
            
            // Age Input
            SageTextField(
                placeholder: "Age (required)",
                text: $ageText,
                error: ageError,
                keyboardType: .numberPad
            )
            
            // Gender Identity Picker
            VStack(alignment: .leading, spacing: SageSpacing.small) {
                Text("Gender Identity")
                    .font(SageTypography.caption)
                    .foregroundColor(SageColors.espressoBrown)
                
                Picker("Gender Identity", selection: $userInfo.genderIdentity) {
                    ForEach(GenderIdentity.allCases, id: \.self) { gender in
                        Text(gender.rawValue).tag(gender)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(SageColors.fogWhite)
                .cornerRadius(8)
            }
            
            // Sex Assigned at Birth Picker
            VStack(alignment: .leading, spacing: SageSpacing.small) {
                Text("Sex Assigned at Birth")
                    .font(SageTypography.caption)
                    .foregroundColor(SageColors.espressoBrown)
                
                Picker("Sex Assigned at Birth", selection: $userInfo.sexAssignedAtBirth) {
                    ForEach(SexAssignedAtBirth.allCases, id: \.self) { sex in
                        Text(sex.rawValue).tag(sex)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(SageColors.fogWhite)
                .cornerRadius(8)
            }
            
            SageButton(title: "Continue") {
                print("UserInfoFormView: Continue button tapped with age=\(ageText), gender=\(userInfo.genderIdentity.rawValue)")
                
                // Validate per DATA_STANDARDS.md §2.3 - only age is required
                ageError = ageText.isEmpty || Int(ageText) == nil ? "Valid age is required for research purposes." : nil
                
                if let age = Int(ageText), age >= 13 && age <= 120 {
                    userInfo.age = age
                    print("UserInfoFormView: Form complete, calling onComplete() with age=\(userInfo.age)")
                    onComplete()
                } else {
                    print("UserInfoFormView: Missing or invalid age")
                    showAlert = true
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Age Required"), 
                message: Text("Please enter a valid age between 13 and 120 for research purposes."), 
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            ageText = userInfo.age > 0 ? String(userInfo.age) : ""
            print("UserInfoFormView: appeared")
        }
    }
}

struct UserInfoFormView_Previews: PreviewProvider {
    @State static var userInfo = UserProfileData(age: 25)
    static var previews: some View {
        UserInfoFormView(isAnonymous: true, userInfo: $userInfo, onComplete: {})
    }
} 