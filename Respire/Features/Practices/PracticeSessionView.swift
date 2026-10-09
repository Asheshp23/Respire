//
//  PracticeSessionView.swift
//  Respire
//
//  A persona's guided practice: the regular session in its own world and rhythm,
//  with its own spoken script, ending on a quiet completion card.
//

import SwiftUI

struct PracticeSessionView: View {
    let practice: Practice

    var body: some View {
        GuidedPracticeView(
            pattern: practice.pattern,
            cycles: practice.breaths,
            world: practice.world,
            focus: practice.focus,
            title: practice.title,
            guidance: practice.guidance,
            practice: practice,
            onComplete: {}
        ) { leave in
            CompletionCard(eyebrow: "\(practice.category.title) · \(practice.lengthLabel)", hue: Theme.prism[3], title: "Well done.") {
                Text("Notice how you feel now, before you move on.")
                    .font(Theme.Typography.note)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                PulseCheckRow()
                Button(action: leave) {
                    Text("Done").frame(maxWidth: .infinity)
                }
                .buttonStyle(.pill)
            }
        }
    }
}
