//
//  ContentView.swift
//  PortfolioFitVoice
//
//  Created by Joshua Fahey on 6/2/25.
//

import SwiftUI

struct ContentView: View {
    
    @State var selectedWorkout: Workout? = nil
    
    var body: some View {
        if let _ = selectedWorkout {
            WorkoutView(workout: $selectedWorkout)
        } else {
            WorkoutChoiceView(workout: $selectedWorkout)
        }
    }
}

#Preview {
    ContentView()
}
