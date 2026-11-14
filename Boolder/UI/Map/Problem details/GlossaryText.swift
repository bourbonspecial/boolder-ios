//
//  GlossaryText.swift
//  Boolder
//

import SwiftUI

/// Text, typically a problem name, whose French climbing terms ("assis",
/// "rallongé", "du bas"...) get a subtle dotted underline and show their
/// English meaning when tapped. Plain text when the app is in French.
struct GlossaryText: View {
    let text: String

    @State private var shownTerm: ClimbingGlossary.Term?

    private static let urlScheme = "boolder-glossary"

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        let matches = NSLocale.websiteLocale == "fr" ? [] : ClimbingGlossary.shared.findTerms(in: text)

        Text(attributedText(matches: matches))
            // terms are links, so that each one can be tapped; keep them the color of the text
            .tint(.primary)
            .environment(\.openURL, OpenURLAction { url in
                guard url.scheme == Self.urlScheme,
                      let index = url.host.flatMap({ Int($0) }),
                      matches.indices.contains(index)
                else { return .systemAction }

                shownTerm = matches[index].term
                return .handled
            })
            .popover(item: $shownTerm) { term in
                GlossaryTermView(term: term)
                    .presentationCompactAdaptation(.popover)
            }
    }

    private func attributedText(matches: [ClimbingGlossary.Match]) -> AttributedString {
        var attributed = AttributedString(text)

        for (index, match) in matches.enumerated() {
            guard let range = Range(match.range, in: attributed) else { continue }

            attributed[range].link = URL(string: "\(Self.urlScheme)://\(index)")
            attributed[range].underlineStyle = Text.LineStyle(pattern: .dot, color: .secondary)
        }

        return attributed
    }
}

private struct GlossaryTermView: View {
    let term: ClimbingGlossary.Term

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: "\(term.term) · \(term.en.translation)")
                .font(.headline)

            if let explanation = term.en.explanation {
                Text(verbatim: explanation)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .frame(maxWidth: 280, alignment: .leading)
    }
}
