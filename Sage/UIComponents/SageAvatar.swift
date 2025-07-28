import SwiftUI

struct SageAvatar: View {
    let image: Image?
    init(image: Image? = nil) {
        self.image = image
        if image == nil {
            print("SageAvatar: initialized with default image")
        } else {
            print("SageAvatar: initialized with custom image")
        }
    }
    var body: some View {
        (image ?? Image(systemName: "person.crop.circle"))
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 64, height: 64)
            .clipShape(Circle())
            .overlay(Circle().stroke(SageColors.sageTeal, lineWidth: 2))
            .shadow(radius: 2)
    }
} 