//
//  SettingsView.swift
//  WordSequence
//

import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: GameViewModel
    @State private var newWord = ""
    @Environment(\.dismiss) private var dismiss

    private var maxWordsPerRound: Int {
        max(2, min(8, viewModel.wordList.count))
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Word List
                Section {
                    ForEach(viewModel.wordList, id: \.self) { word in
                        Text(word)
                            .font(.system(.body, design: .rounded))
                    }
                    .onDelete { indices in
                        viewModel.wordList.remove(atOffsets: indices)
                    }

                    HStack {
                        TextField("Add a word…", text: $newWord)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .onSubmit { addWord() }

                        Button("Add") { addWord() }
                            .disabled(newWord.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("Word List")
                } footer: {
                    Text("Swipe left on a word to remove it. Words are chosen randomly each round.")
                }

                // MARK: Round Settings
                Section("Round Settings") {
                    Stepper(
                        "Words per round: \(viewModel.wordsPerRound)",
                        value: $viewModel.wordsPerRound,
                        in: 2...maxWordsPerRound
                    )
                    .font(.system(.body, design: .rounded))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Time between words: \(String(format: "%.1f", viewModel.revealInterval))s")
                            .font(.system(.body, design: .rounded))
                        Slider(value: $viewModel.revealInterval, in: 0.5...5.0, step: 0.5)
                    }
                    .padding(.vertical, 4)
                }

                // MARK: Progress
                Section("Progress") {
                    LabeledContent("Score") {
                        Text("\(viewModel.score)")
                            .font(.system(.body, design: .rounded))
                    }
                    LabeledContent("Rounds played") {
                        Text("\(viewModel.roundsPlayed)")
                            .font(.system(.body, design: .rounded))
                    }

                    Button("Reset score", role: .destructive) {
                        viewModel.score = 0
                        viewModel.roundsPlayed = 0
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(.body, design: .rounded).weight(.semibold))
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
        }
    }

    private func addWord() {
        let trimmed = newWord.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        viewModel.wordList.append(trimmed)
        newWord = ""
    }
}

#Preview {
    SettingsView(viewModel: GameViewModel())
}
