//
//  JourneyPracticeView.swift
//  Respire
//
//  A journey day's practice, set in the chapter's world with its rhythm, focus, and
//  guiding line, and sized to its minutes. When it finishes, the day is recorded and
//  the completion card offers the day's last words and a question to carry.
//

import SwiftUI

struct JourneyPracticeView: View {
    let journey: Journey
    let chapter: JourneyChapter

    @Environment(JourneyProgressStore.self) private var progress
    @Environment(DharanaLibrary.self) private var gates

    var body: some View {
        GuidedPracticeView(
            pattern: chapter.pattern(in: journey),
            cycles: chapter.targetCycles(in: journey),
            world: chapter.theme,
            focus: chapter.focus,
            title: "Day \(chapter.day) · \(chapter.title)",
            guidance: chapter.practice.guidance,
            gate: chapter.gate.flatMap { gates.collection?.dharana(number: $0) },
            onComplete: { progress.complete(chapter, in: journey) }
        ) { leave in
            CompletionCard(eyebrow: "Day \(chapter.day) complete", hue: hue, title: chapter.completion.title) {
                Text(chapter.completion.body)
                    .font(Theme.Typography.note)
                    .lineSpacing(Theme.Typography.noteLineSpacing)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Rule()

                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    Text("To carry with you")
                        .font(Theme.Typography.eyebrow)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.Palette.inkTertiary)
                    Text(chapter.reflection)
                        .font(.system(.title3, design: .serif).italic())
                        .foregroundStyle(Theme.Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let nextChapter {
                    Label("Day \(nextChapter.day), \(nextChapter.title), opens tomorrow", systemImage: "sunrise")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }

                Button(action: leave) {
                    Text("Return to the journey")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.pill)
            }
        }
    }

    private var hue: Color {
        JourneyPathView.hue(for: journey.chapters.firstIndex(of: chapter) ?? 0, in: journey)
    }

    private var nextChapter: JourneyChapter? {
        guard let index = journey.chapters.firstIndex(of: chapter), index + 1 < journey.chapters.count else { return nil }
        return journey.chapters[index + 1]
    }
}
