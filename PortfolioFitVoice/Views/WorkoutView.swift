//
//  WorkoutView.swift
//  PortfolioFitVoice
//
//  Created by Joshua Fahey on 6/3/25.
//

import SwiftUI

struct WorkoutView: View {
    
    @Binding var workout: Workout?
    
    @StateObject private var viewModel: WorkoutViewModel
    
    init(workout: Binding<Workout?>){
        self._workout = workout
        self._viewModel = .init(wrappedValue: .init(workout: workout.wrappedValue ?? .empty))
    }
    
    var body: some View {
        ZStack{
            colorForState()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("FitVoice")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black.opacity(0.3))
                
                Divider()
                    .frame(height: 20)
                
                if let exercise = viewModel.currentExercise {
                    Text(exercise.name)
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    Text(exercise.description)
                        .font(.body)
                        .foregroundColor(.white)
                } else {
                    Text("Say start to begin")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .onAppear(){
                            viewModel.setupListening()
                            print("set up")
                        }
                }
                Spacer()
                
                if let timeRemaining = viewModel.remainingTime {
                    Text("Time left in exercise")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(timeRemaining.formatted())
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
            }
            
            if viewModel.finishedWorkout {
                Color.white
                    .onAppear(){
                        workout = nil
                    }
            }
        }
    }
    
    func colorForState() -> Color {
        if viewModel.isWorkoutActive {
            Color.green
        } else {
            Color.gray
        }
    }
}

#Preview {
    WorkoutView(workout: .constant(.empty))
}
