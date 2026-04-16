//
//  GameViewModel.swift
//  WordSequence
//
//  Created for WordSequence — a sequencing game for young children.
//

import SwiftUI
import Observation

// MARK: - Game Phase

enum GamePhase: Equatable {
    case idle
    case revealing
    case tapping
    case success
    case failure(correctSequenceOrder: Int)
}

// MARK: - Placed Word

struct PlacedWord: Identifiable, Equatable {
    let id: UUID
    let text: String
    let sequenceOrder: Int   // 0 = first word shown
    let color: Color
    var position: CGPoint
    var isRevealed: Bool
    var isTapped: Bool

    init(text: String, sequenceOrder: Int, color: Color) {
        self.id = UUID()
        self.text = text
        self.sequenceOrder = sequenceOrder
        self.color = color
        self.position = .zero
        self.isRevealed = false
        self.isTapped = false
    }
}

// MARK: - Game View Model

@Observable
final class GameViewModel {

    // MARK: Game State
    var phase: GamePhase = .idle
    var placedWords: [PlacedWord] = []
    var nextExpectedTap: Int = 0
    var score: Int = 0
    var roundsPlayed: Int = 0

    // MARK: Settings (persisted)
    var wordList: [String] {
        didSet {
            Self.saveStrings(wordList, forKey: "wordList")
            // Keep wordsPerRound within valid bounds
            if !wordList.isEmpty && wordsPerRound > wordList.count {
                wordsPerRound = max(2, wordList.count)
            }
        }
    }

    var wordsPerRound: Int {
        didSet { UserDefaults.standard.set(wordsPerRound, forKey: "wordsPerRound") }
    }

    var revealInterval: Double {
        didSet { UserDefaults.standard.set(revealInterval, forKey: "revealInterval") }
    }

    // MARK: Private
    private var revealTask: Task<Void, Never>?

    static let wordColors: [Color] = [
        Color(red: 1.00, green: 0.40, blue: 0.40),  // coral
        Color(red: 1.00, green: 0.60, blue: 0.20),  // orange
        Color(red: 0.95, green: 0.80, blue: 0.10),  // yellow
        Color(red: 0.20, green: 0.78, blue: 0.92),  // cyan
        Color(red: 0.50, green: 0.38, blue: 1.00),  // purple
        Color(red: 1.00, green: 0.38, blue: 0.78),  // pink
        Color(red: 0.28, green: 0.65, blue: 1.00),  // blue
        Color(red: 0.95, green: 0.45, blue: 0.65),  // rose
    ]

    static let defaultWords: [String] = [
        "Cat", "Dog", "Sun", "Hat", "Car",
        "Tree", "Ball", "Fish", "Bird", "Star"
    ]

    // MARK: Init

    init() {
        wordList = Self.loadStrings(forKey: "wordList") ?? Self.defaultWords

        let savedWordsPerRound = UserDefaults.standard.integer(forKey: "wordsPerRound")
        wordsPerRound = savedWordsPerRound > 1 ? savedWordsPerRound : 3

        let savedReveal = UserDefaults.standard.double(forKey: "revealInterval")
        revealInterval = savedReveal > 0 ? savedReveal : 1.5
    }

    // MARK: - Game Control

    func startRound(in size: CGSize) {
        revealTask?.cancel()
        nextExpectedTap = 0
        phase = .revealing
        roundsPlayed += 1

        let available = wordList.isEmpty ? Self.defaultWords : wordList
        let count = min(wordsPerRound, available.count)
        let selected = Array(available.shuffled().prefix(count))
        let shuffledColors = Self.wordColors.shuffled()

        var placed: [PlacedWord] = []
        for (i, word) in selected.enumerated() {
            var w = PlacedWord(
                text: word,
                sequenceOrder: i,
                color: shuffledColors[i % shuffledColors.count]
            )
            w.position = randomPosition(in: size, avoiding: placed.map(\.position))
            placed.append(w)
        }
        placedWords = placed

        revealTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for i in self.placedWords.indices {
                do {
                    try await Task.sleep(for: .seconds(self.revealInterval))
                } catch {
                    return // cancelled
                }
                self.placedWords[i].isRevealed = true
            }
            do {
                try await Task.sleep(for: .seconds(0.5))
            } catch {
                return
            }
            self.phase = .tapping
        }
    }

    func wordTapped(_ word: PlacedWord) {
        guard phase == .tapping, !word.isTapped else { return }

        if word.sequenceOrder == nextExpectedTap {
            // Correct tap
            if let idx = placedWords.firstIndex(where: { $0.id == word.id }) {
                placedWords[idx].isTapped = true
            }
            nextExpectedTap += 1
            if nextExpectedTap == placedWords.count {
                score += 1
                phase = .success
            }
        } else {
            // Wrong tap — highlight the correct next word
            phase = .failure(correctSequenceOrder: nextExpectedTap)
        }
    }

    func resetToIdle() {
        revealTask?.cancel()
        placedWords = []
        phase = .idle
    }

    // MARK: - Position Helpers

    private func randomPosition(in size: CGSize, avoiding existing: [CGPoint]) -> CGPoint {
        let hPad: CGFloat = 110
        let vPad: CGFloat = 140
        let minSpacing: CGFloat = 145

        for _ in 0..<80 {
            let x = CGFloat.random(in: hPad...(size.width - hPad))
            let y = CGFloat.random(in: vPad...(size.height - vPad))
            let candidate = CGPoint(x: x, y: y)
            let tooClose = existing.contains {
                hypot($0.x - candidate.x, $0.y - candidate.y) < minSpacing
            }
            if !tooClose { return candidate }
        }
        // Fallback — relax spacing
        return CGPoint(
            x: CGFloat.random(in: hPad...(size.width - hPad)),
            y: CGFloat.random(in: vPad...(size.height - vPad))
        )
    }

    // MARK: - Persistence

    private static func loadStrings(forKey key: String) -> [String]? {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let list = try? JSONDecoder().decode([String].self, from: data),
            !list.isEmpty
        else { return nil }
        return list
    }

    private static func saveStrings(_ list: [String], forKey key: String) {
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
