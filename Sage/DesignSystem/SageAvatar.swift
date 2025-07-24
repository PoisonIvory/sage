import SwiftUI

struct SageAvatar: View {
    let image: Image?
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