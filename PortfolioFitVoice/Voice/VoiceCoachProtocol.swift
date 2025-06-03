//
//  VoiceCoachProtocol.swift
//  PortfolioFitVoice
//
//  Created by Joshua Fahey on 6/2/25.
//
import Foundation

@MainActor
protocol VoiceCoachProtocol {
    init()
    func startListening() -> AsyncStream<String>
    func stopListening()
    func speak(text: String) -> AsyncStream<String>
}

