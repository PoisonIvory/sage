import SwiftUI

struct SageTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var error: String? = nil
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences // .none is not available on all platforms

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(SageTypography.body)
                    .padding(12)
                    .background(SageColors.fogWhite)
                    .cornerRadius(10)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
            } else {
                TextField(placeholder, text: $text)
                    .font(SageTypography.body)
                    .padding(12)
                    .background(SageColors.fogWhite)
                    .cornerRadius(10)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
            }
            if let error = error {
                Text(error)
                    .font(SageTypography.caption)
                    .foregroundColor(SageColors.coralBlush)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(placeholder + (error != nil ? ". Error: " + error! : ""))
    }
}

struct SageTextField_Previews: PreviewProvider {
    @State static var text = ""
    static var previews: some View {
        VStack(spacing: 20) {
            SageTextField(placeholder: "Email", text: $text)
            SageTextField(placeholder: "Password", text: $text, isSecure: true, error: "Password too short")
        }
        .padding()
        .background(SageColors.sandstone)
        .previewLayout(.sizeThatFits)
    }
} 