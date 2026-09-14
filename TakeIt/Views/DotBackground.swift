import SwiftUI

struct DotBackground: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 24
            let radius: CGFloat = 0.9
            var y: CGFloat = 0
            while y < size.height + spacing {
                var x: CGFloat = 0
                while x < size.width + spacing {
                    let rect = CGRect(x: x, y: y, width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(Theme.bgDots))
                    x += spacing
                }
                y += spacing
            }
        }
        .background(Theme.bg)
        .ignoresSafeArea()
    }
}
