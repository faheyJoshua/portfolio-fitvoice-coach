//
//  MockVoiceCoach.swift
//  PortfolioFitVoice
//
//  Created by Joshua Fahey on 6/2/25.
//
import Foundation
@testable import PortfolioFitVoice

@MainActor
class MockVoiceCoach: PortfolioFitVoice.VoiceCoachProtocol {
    // MARK: - Properties for Testing
    
    /// Array to track texts that were "spoken" via the speak(text:) method.
    private(set) var spokenTexts: [String] = []
    
    /// Continuation for the AsyncStream to yield simulated voice commands.
    private var continuation: AsyncStream<String>.Continuation?
    
    // MARK: - Initialization
    
    required init() {}
    
    // MARK: - VoiceCoachProtocol Methods
    
    /// Starts "listening" for voice commands by returning an AsyncStream.
    /// In this mock, commands are simulated via simulateCommand(_:).
    func startListening() -> AsyncStream<String> {
        AsyncStream { cont in
            self.continuation = cont
            cont.onTermination = { @Sendable _ in
                Task { @MainActor in
                    self.continuation = nil
                }
            }
        }
    }
    
    /// Stops "listening" by finishing the AsyncStream.
    func stopListening() {
        continuation?.finish()
        continuation = nil
    }
    
    /// Simulates speaking the given text by appending it to spokenTexts.
    func speak(text: String) -> AsyncStream<String> {
        spokenTexts.append(text)
        return AsyncStream { cont in
            cont.finish()
        }
    }
    
    // MARK: - Testing Helpers
    
    /// Simulates recognizing a voice command by yielding it to the AsyncStream.
    func simulateCommand(_ command: String) {
        continuation?.yield(command)
    }
}
