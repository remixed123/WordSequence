//
//  ContentView.swift
//  WordSequence
//
//  Created by Glenn Vassallo on 7/4/2026.
//

import SwiftUI

// MARK: - Root View

struct ContentView: View {
    @State private var viewModel = GameViewModel()
    @State private var showSettings = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Deep navy background
                Color(red: 0.05, green: 0.05, blue: 0.15)
                    .ignoresSafeArea()

                switch viewModel.phase {
                case .idle:
                    IdleView(viewModel: viewModel, size: geo.size)
                        .transition(.opacity)

                case .revealing, .tapping:
                    GamePlayView(viewModel: viewModel, size: geo.size)
                        .transition(.opacity)

                case .success:
                    GamePlayView(viewModel: viewModel, size: geo.size)
                    SuccessOverlay(viewModel: viewModel, size: geo.size)
                        .transition(.opacity)

                case .failure:
                    GamePlayView(viewModel: viewModel, size: geo.size)
                    FailureOverlay(viewModel: viewModel, size: geo.size)
                        .transition(.opacity)
                }

                // Hidden settings tap target — top-left corner (parent access)
                VStack {
                    HStack {
                        Color.clear
                            .frame(width: 70, height: 70)
                            .contentShape(Rectangle())
                            .onTapGesture { showSettings = true }
                        Spacer()
                    }
                    Spacer()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.phase)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Idle / Start Screen

private struct IdleView: View {
    var viewModel: GameViewModel
    let size: CGSize

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Title
            Text("Word Sequence")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer().frame(height: 16)

            Text("Remember the order!")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            // Score badge
            if viewModel.score > 0 {
                HStack(spacing: 10) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.yellow)
                    Text("\(viewModel.score)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white.opacity(0.1))
                )
                Spacer()
            }

            // Play button
            Button {
                viewModel.startRound(in: size)
            } label: {
                Text("Play")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 220, height: 90)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.25, green: 0.65, blue: 1.0),
                                             Color(red: 0.15, green: 0.45, blue: 0.9)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .blue.opacity(0.5), radius: 12, x: 0, y: 6)
                    )
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }
}

// MARK: - Game Play View

private struct GamePlayView: View {
    var viewModel: GameViewModel
    let size: CGSize

    var body: some View {
        ZStack {
            // Word cards
            ForEach(viewModel.placedWords) { word in
                WordCardView(word: word, phase: viewModel.phase) {
                    viewModel.wordTapped(word)
                }
                .position(word.position)
            }

            // "Tap in order" prompt when tapping phase begins
            if viewModel.phase == .tapping {
                VStack {
                    Text("Tap in order!")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(.white.opacity(0.12))
                        )
                        .padding(.top, 60)
                    Spacer()
                }
                .transition(.opacity.animation(.easeIn(duration: 0.4)))
            }
        }
    }
}

// MARK: - Word Card

private struct WordCardView: View {
    let word: PlacedWord
    let phase: GamePhase
    let onTap: () -> Void

    private var canTap: Bool {
        phase == .tapping && !word.isTapped
    }

    private var cardColor: Color {
        if word.isTapped {
            return .green
        }
        // On failure, highlight the word the player should have tapped next
        if case .failure(let correctOrder) = phase, word.sequenceOrder == correctOrder {
            return Color(red: 0.2, green: 0.85, blue: 0.4)
        }
        return word.color
    }

    var body: some View {
        Text(word.text)
            .font(.system(size: 30, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardColor)
                    .shadow(color: .black.opacity(0.45), radius: 7, x: 0, y: 4)
            )
            .scaleEffect(word.isRevealed ? 1.0 : 0.05)
            .opacity(word.isRevealed ? 1.0 : 0.0)
            .animation(.spring(response: 0.45, dampingFraction: 0.58), value: word.isRevealed)
            .animation(.easeInOut(duration: 0.2), value: word.isTapped)
            .animation(.easeInOut(duration: 0.25), value: cardColor)
            .onTapGesture {
                if canTap { onTap() }
            }
    }
}

// MARK: - Success Overlay

private struct SuccessOverlay: View {
    var viewModel: GameViewModel
    let size: CGSize
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Text("🌟")
                    .font(.system(size: 90))
                    .scaleEffect(appeared ? 1.0 : 0.2)
                    .animation(.spring(response: 0.5, dampingFraction: 0.5), value: appeared)

                Text("Well Done!")
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(.yellow)
                    .scaleEffect(appeared ? 1.0 : 0.2)
                    .animation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.1), value: appeared)

                Button {
                    viewModel.startRound(in: size)
                } label: {
                    Text("Play Again")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 230, height: 74)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.green)
                                .shadow(color: .green.opacity(0.5), radius: 10, x: 0, y: 4)
                        )
                }
                .buttonStyle(.plain)
                .scaleEffect(appeared ? 1.0 : 0.2)
                .animation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.2), value: appeared)
            }
        }
        .onAppear { appeared = true }
    }
}

// MARK: - Failure Overlay

private struct FailureOverlay: View {
    var viewModel: GameViewModel
    let size: CGSize
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Text("🙈")
                    .font(.system(size: 80))
                    .scaleEffect(appeared ? 1.0 : 0.2)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appeared)

                Text("Try Again!")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .scaleEffect(appeared ? 1.0 : 0.2)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: appeared)

                HStack(spacing: 16) {
                    Button {
                        viewModel.startRound(in: size)
                    } label: {
                        Text("Try Again")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 160, height: 64)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.orange)
                                    .shadow(color: .orange.opacity(0.4), radius: 8, x: 0, y: 4)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.resetToIdle()
                    } label: {
                        Text("Home")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 120, height: 64)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.white.opacity(0.2))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .scaleEffect(appeared ? 1.0 : 0.2)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2), value: appeared)
            }
        }
        .onAppear { appeared = true }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
