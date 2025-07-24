import SwiftUI

struct UserInfoFormView: View {
    var isAnonymous: Bool
    @Binding var userInfo: UserInfo
    var onComplete: () -> Void

    @State private var showAlert = false

    var body: some View {
        VStack(spacing: SageSpacing.large) {
            SageSectionHeader(title: "Tell Us About You")
            Text("We use this info to personalize your experience. Your privacy is always protected.")
                .font(SageTypography.body)
                .foregroundColor(SageColors.espressoBrown)
                .multilineTextAlignment(.center)
            TextField("Name", text: $userInfo.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Age", text: $userInfo.age)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Gender (optional)", text: $userInfo.gender)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            SageButton(title: "Continue") {
                if userInfo.name.isEmpty || userInfo.age.isEmpty {
                    showAlert = true
                } else {
                    onComplete()
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Missing Info"), message: Text("Please enter your name and age."), dismissButton: .default(Text("OK")))
        }
    }
}

struct UserInfoFormView_Previews: PreviewProvider {
    @State static var userInfo = UserInfo()
    static var previews: some View {
        UserInfoFormView(isAnonymous: true, userInfo: $userInfo, onComplete: {})
    }
} 