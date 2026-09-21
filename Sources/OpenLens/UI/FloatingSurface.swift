import SwiftUI

extension View {
    /// The background for a pill or card that floats over the picture.
    ///
    /// macOS 26 draws these as Liquid Glass, which is what the system's own
    /// floating controls look like there. Older systems, down to the
    /// deployment target of 14, keep the material they have always had; the
    /// call site does not have to know which it got.
    @ViewBuilder
    func floatingSurface(in shape: some Shape) -> some View {
        if #available(macOS 26.0, *) {
            glassEffect(.regular, in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
        }
    }
}
