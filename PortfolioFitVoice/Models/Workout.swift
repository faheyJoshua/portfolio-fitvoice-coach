//
//  Workout.swift
//  PortfolioFitVoice
//
//  Created by Joshua Fahey on 6/2/25.
//


struct Workout {
    let exercises: [Exercise]
}

extension Workout {
    static let empty: Workout = .init(exercises: [])
}
