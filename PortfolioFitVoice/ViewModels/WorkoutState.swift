//
//  WorkoutState.swift
//  PortfolioFitVoice
//
//  Created by Joshua Fahey on 6/2/25.
//

enum WorkoutState {
    case idle
    case running(exerciseIndex: Int, remainingTime: Int)
    case paused(exerciseIndex: Int, remainingTime: Int)
}
