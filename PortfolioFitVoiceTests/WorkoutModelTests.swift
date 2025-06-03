//
//  PortfolioFitVoiceTests.swift
//  PortfolioFitVoiceTests
//
//  Created by Joshua Fahey on 6/2/25.
//

import Testing
@testable import PortfolioFitVoice

@Test func testExerciseInitialization() {
    let exercise = Exercise(name: "Push-ups", duration: 30, description: "Standard push-ups")
    #expect(exercise.name == "Push-ups")
    #expect(exercise.duration == 30)
    #expect(exercise.description == "Standard push-ups")
}

@Test func testWorkoutInitialization() {
    let exercises = [
        Exercise(name: "Push-ups", duration: 30, description: "Standard push-ups"),
        Exercise(name: "Squats", duration: 45, description: "Bodyweight squats")
    ]
    let workout = Workout(exercises: exercises)
    #expect(workout.exercises.count == 2)
    #expect(workout.exercises[0].name == "Push-ups")
    #expect(workout.exercises[1].name == "Squats")
}

@Test func testWorkoutEmpty() {
    let workout = Workout(exercises: [])
    #expect(workout.exercises.isEmpty)
}
