//
//  WorkoutDescriptionView.swift
//  PortfolioFitVoice
//
//  Created by Joshua Fahey on 6/3/25.
//

import SwiftUI

struct WorkoutDescriptionView: View {
    
    let workout: Workout
    
    var body: some View {
        VStack {
            ForEach(workout.exercises.map(\.name), id: \.self) { exercise in
                Text(exercise)
            }
        }
    }
}

#Preview {
    WorkoutDescriptionView(workout: .init(exercises: []))
}
