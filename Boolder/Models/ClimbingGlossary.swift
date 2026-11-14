//
//  ClimbingGlossary.swift
//  Boolder
//

import Foundation

/// French climbing terms found in problem names ("assis", "rallongé", "du bas"...),
/// with an English explanation for climbers who don't speak French.
///
/// The terms live in glossary.json, a file shared as-is with the Android app.
struct ClimbingGlossary {
    struct Term: Decodable, Identifiable, Equatable {
        let term: String
        let category: String
        let en: Definition

        var id: String { term }
    }

    struct Definition: Decodable, Equatable {
        let translation: String
        let explanation: String?
    }

    struct Match {
        let range: Range<String.Index>
        let term: Term
    }

    private struct GlossaryFile: Decodable {
        let terms: [Term]
    }

    static let shared: ClimbingGlossary = {
        guard let url = Bundle.main.url(forResource: "glossary", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(GlossaryFile.self, from: data)
        else {
            return ClimbingGlossary(terms: [])
        }

        return ClimbingGlossary(terms: file.terms)
    }()

    private let termsByText: [String: Term]
    private let regex: NSRegularExpression?

    init(terms: [Term]) {
        termsByText = Dictionary(terms.map { ($0.term.lowercased(), $0) }, uniquingKeysWith: { first, _ in first })

        // Longest terms first, so that "sans convention" wins over "sans".
        // Whole words only: "bas" matches in "Le Bas-Cul" but not in "Bassine".
        let alternatives = termsByText.keys
            .sorted { $0.count > $1.count }
            .map { NSRegularExpression.escapedPattern(for: $0) }
            .joined(separator: "|")

        regex = alternatives.isEmpty
            ? nil
            : try? NSRegularExpression(pattern: "(?<!\\p{L})(\(alternatives))(?!\\p{L})", options: [.caseInsensitive])
    }

    /// The glossary terms found in `text`, in order and not overlapping.
    func findTerms(in text: String) -> [Match] {
        guard let regex = regex else { return [] }

        let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

        return results.compactMap { result in
            guard let range = Range(result.range, in: text),
                  let term = termsByText[text[range].lowercased()]
            else { return nil }

            return Match(range: range, term: term)
        }
    }
}
