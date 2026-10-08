//
//  ThemePickerSheet.swift
//  Respire
//
//  "Where to breathe": a small, still window into each world, in a row that
//  scrolls sideways. Shown at the top of the Scene & Sound sheet. The whole tile is
//  the button; the chosen one wears the prism's ring.
//

import SwiftUI

struct ScenePicker: View {
    @Binding var theme: BreathTheme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Space.s) {
                ForEach(BreathTheme.allCases) { option in
                    tile(option)
                }
            }
            .padding(.vertical, 3)
        }
        .scrollClipDisabled()
    }

    private func tile(_ option: BreathTheme) -> some View {
        let isSelected = option == theme
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
        return Button {
            withAnimation(.easeInOut(duration: 0.3)) { theme = option }
        } label: {
            ZStack(alignment: .bottomLeading) {
                SceneThumbnail(theme: option)
                LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .center, endPoint: .bottom)
                Label(option.title, systemImage: option.symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .padding(Theme.Space.xs)
            }
            .frame(width: 132, height: 120)
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(
                    isSelected
                        ? AnyShapeStyle(AngularGradient(colors: Theme.prism + [Theme.prism[0]], center: .center))
                        : AnyShapeStyle(.white.opacity(0.15)),
                    lineWidth: isSelected ? 2.5 : 1
                )
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
