//
//  VoiceCoachTests.swift
//  PortfolioFitVoice
//
//  Created by Joshua Fahey on 6/2/25.
//

import Testing
@testable import PortfolioFitVoice

@MainActor @Test func testSpeak() {
    let mock = MockVoiceCoach()
    let _ = mock.speak(text: "Test")
    #expect(mock.spokenTexts == ["Test"])
}

@Test func testStartListening() async {
    let mock = await MockVoiceCoach()
    let stream = await mock.startListening()
    var receivedCommands: [String] = []
    
    let task = Task {
        for await command in stream {
            receivedCommands.append(command)
        }
    }
    
    await mock.simulateCommand("start")
    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    #expect(receivedCommands == ["start"])
    
    task.cancel()
}

@Test func testStopListening() async {
    let mock = await MockVoiceCoach()
    let stream = await mock.startListening()
    var receivedCommands: [String] = []
    
    let task = Task {
        for await command in stream {
            receivedCommands.append(command)
        }
    }
    
    await mock.stopListening()
    await mock.simulateCommand("stop") // Should not be yielded
    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    #expect(receivedCommands.isEmpty)
    
    task.cancel()
}

@Test func testMultipleCommands() async {
    let mock = await MockVoiceCoach()
    let stream = await mock.startListening()
    var receivedCommands: [String] = []
    
    let task = Task {
        for await command in stream {
            receivedCommands.append(command)
        }
    }
    
    await mock.simulateCommand("start")
    await mock.simulateCommand("next")
    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    #expect(receivedCommands == ["start", "next"])
    
    task.cancel()
}
