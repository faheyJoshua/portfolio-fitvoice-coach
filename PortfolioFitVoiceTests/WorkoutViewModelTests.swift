//
//  WorkoutViewModelTests.swift
//  PortfolioFitVoice
//
//  Created by Joshua Fahey on 6/2/25.
//

import Testing
@testable import PortfolioFitVoice
import Combine

// Sample workout for testing
let sampleExercises = [
    Exercise(name: "Push-ups", duration: 30, description: "Standard push-ups"),
    Exercise(name: "Squats", duration: 45, description: "Bodyweight squats"),
    Exercise(name: "Plank", duration: 60, description: "Hold plank position")
]
let sampleWorkout = Workout(exercises: sampleExercises)

@MainActor
@Test("Initial state is idle with correct properties")
func testInitialState() {
    let viewModel = WorkoutViewModel(workout: sampleWorkout, voiceCoach: MockVoiceCoach.self)
    var idle = false
    if case .idle = viewModel.currentState {
        idle = true
    }
    #expect(idle)
    #expect(viewModel.currentExercise == nil)
    #expect(viewModel.remainingTime == nil)
    #expect(viewModel.isWorkoutActive == false)
}

@Test("Starting workout transitions to running and speaks")
func testStartWorkout() async {
    let mock = await MockVoiceCoach()
    let viewModel = await WorkoutViewModel(workout: sampleWorkout, voiceCoach: MockVoiceCoach.self)
    // Access voiceCoach to trigger lazy initialization
    _ = await viewModel.voiceCoach
    // Replace default mock with our instance
    await MainActor.run {viewModel.voiceCoach = mock}
    await viewModel.startWorkout()
    if case .running(let index, let time) = await viewModel.currentState {
        #expect(index == 0)
        #expect(time == 30)
    } else {
        #expect(Bool(false), "Expected running state")
    }
    await #expect(mock.spokenTexts.last == "Workout started. First exercise: Push-ups")
}

@Test("Pausing workout transitions to paused and speaks")
func testPauseWorkout() async {
    let mock = await MockVoiceCoach()
    let viewModel = await WorkoutViewModel(workout: sampleWorkout, voiceCoach: MockVoiceCoach.self)
    _ = await viewModel.voiceCoach
    await MainActor.run {viewModel.voiceCoach = mock}
    await viewModel.startWorkout()
    await viewModel.pauseWorkout()
    if case .paused(let index, let time) = await viewModel.currentState {
        #expect(index == 0)
        #expect(time == 30)
    } else {
        #expect(Bool(false), "Expected paused state")
    }
    await #expect(mock.spokenTexts.last == "Workout paused")
}

@Test("Resuming workout transitions back to running and speaks")
func testResumeWorkout() async {
    let mock = await MockVoiceCoach()
    let viewModel = await WorkoutViewModel(workout: sampleWorkout, voiceCoach: MockVoiceCoach.self)
    _ = await viewModel.voiceCoach
    await MainActor.run {viewModel.voiceCoach = mock}
    await viewModel.startWorkout()
    await viewModel.pauseWorkout()
    await viewModel.resumeWorkout()
    if case .running(let index, let time) = await viewModel.currentState {
        #expect(index == 0)
        #expect(time == 30)
    } else {
        #expect(Bool(false), "Expected running state")
    }
    await #expect(mock.spokenTexts.last == "Workout resumed")
}

@Test("Next exercise advances to next exercise and speaks")
func testNextExercise() async {
    let mock = await MockVoiceCoach()
    let viewModel = await WorkoutViewModel(workout: sampleWorkout, voiceCoach: MockVoiceCoach.self)
    _ = await viewModel.voiceCoach
    await MainActor.run {viewModel.voiceCoach = mock}
    await viewModel.startWorkout()
    await viewModel.nextExercise()
    if case .running(let index, let time) = await viewModel.currentState {
        #expect(index == 1)
        #expect(time == 45)
    } else {
        #expect(Bool(false), "Expected running state")
    }
    await #expect(mock.spokenTexts.last == "Next exercise: Squats")
}

@Test("Stopping workout transitions to idle and speaks")
func testStopWorkout() async {
    let mock = await MockVoiceCoach()
    let viewModel = await WorkoutViewModel(workout: sampleWorkout, voiceCoach: MockVoiceCoach.self)
    _ = await viewModel.voiceCoach
    await MainActor.run {viewModel.voiceCoach = mock}
    await viewModel.startWorkout()
    await viewModel.stopWorkout()
    try? await Task.sleep(nanoseconds: 100_000_000)
    var idle = false
    if case .idle = await viewModel.currentState {
        idle = true
    }
    #expect(idle)
    await #expect(mock.spokenTexts.last == "Workout stopped")
}

@Test("Voice command 'start' triggers workout start")
func testVoiceCommandStart() async {
    let mock = await MockVoiceCoach()
    let viewModel = await WorkoutViewModel(workout: sampleWorkout, voiceCoach: MockVoiceCoach.self)
    _ = await viewModel.voiceCoach
    await MainActor.run {viewModel.voiceCoach = mock}
    await viewModel.setupListening()
    
    await mock.simulateCommand("start")
    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    if case .running(let index, let time) = await viewModel.currentState {
        #expect(index == 0)
        #expect(time == 30)
    } else {
        #expect(Bool(false), "Expected running state")
    }
    await #expect(mock.spokenTexts.last == "Workout started. First exercise: Push-ups")
}

@Test("Voice command 'next' advances to next exercise")
func testVoiceCommandNext() async {
    let mock = await MockVoiceCoach()
    let viewModel = await WorkoutViewModel(workout: sampleWorkout, voiceCoach: MockVoiceCoach.self)
    _ = await viewModel.voiceCoach
    await MainActor.run {viewModel.voiceCoach = mock}
    await viewModel.setupListening()
    await viewModel.startWorkout()
    await mock.simulateCommand("next")
    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    if case .running(let index, let time) = await viewModel.currentState {
        #expect(index == 1)
        #expect(time == 45)
    } else {
        #expect(Bool(false), "Expected running state")
    }
    await #expect(mock.spokenTexts.last == "Next exercise: Squats")
}
