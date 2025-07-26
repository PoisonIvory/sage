import SwiftUI

public struct AbstractWaveBackground: View {
    public init() {}
    public var body: some View {
        GeometryReader { geo in
            Path { path in
                let width = geo.size.width
                let height = geo.size.height
                path.move(to: CGPoint(x: 0, y: height * 0.8))
                path.addCurve(to: CGPoint(x: width, y: height * 0.7),
                              control1: CGPoint(x: width * 0.3, y: height),
                              control2: CGPoint(x: width * 0.7, y: height * 0.5))
                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: 0, y: height))
                path.closeSubpath()
            }
            .fill(SageColors.softTaupe)
        }
    }
} 