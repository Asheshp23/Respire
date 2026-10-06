//
//  ThemePickerSheet.swift
//  Respire
//
//  "Where to breathe": a small, still window into each world. The whole tile is
//  the button; the chosen one wears the prism's ring.
//

import SwiftUI

struct ThemePickerSheet: View {
    @Binding var theme: BreathTheme

    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: Theme.Space.s)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.s) {
                    Text("Where to breathe")
                        .font(Theme.Typography.meta.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .textCase(.uppercase)
                        .accessibilityAddTraits(.isHeader)

                    LazyVGrid(columns: columns, spacing: Theme.Space.s) {
                        ForEach(BreathTheme.allCases) { option in
                            tile(option)
                        }
                    }
                }
                .padding(Theme.Space.page)
            }
            .background(Theme.Palette.paper)
            .navigationTitle("Scene")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func tile(_ option: BreathTheme) -> some View {
        let isSelected = option == theme
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
        return Button {
            theme = option
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
            .frame(height: 150)
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

#Preview {
    @Previewable @State var theme = BreathTheme.sakura
    ThemePickerSheet(theme: $theme)
        .preferredColorScheme(.dark)
}
