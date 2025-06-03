//
//  WorkoutChoiceView.swift
//  PortfolioFitVoice
//
//  Created by Joshua Fahey on 6/3/25.
//

import SwiftUI

struct WorkoutChoiceView: View {
    
    @Binding var workout: Workout?
    
    @State var currentSelection: SelectionState?
    
    enum SelectionState: String, CaseIterable, Hashable {
        case option1
        case option2
        case option3
        
        var workout: Workout? {
            switch self {
            case .option1:
                return Workout(exercises: [
                    Exercise(name: "Push-ups", duration: 30, description: "Standard push-ups"),
                    Exercise(name: "Squats", duration: 45, description: "Bodyweight squats"),
                    Exercise(name: "Plank", duration: 60, description: "Hold plank position")
                ])
            case .option2:
                return Workout(exercises: [
                    Exercise(name: "Pull-ups", duration: 30, description: "Standard pull-ups"),
                    Exercise(name: "Jumping Jacks", duration: 45, description: "Standard jumping jacks"),
                    Exercise(name: "Pull-ups", duration: 20, description: "Standard pull-ups")
                ])
            case .option3:
                return Workout(exercises: [
                    Exercise(name: "Plank", duration: 30, description: "Hold plank position"),
                    Exercise(name: "Sit-ups", duration: 45, description: "Standard sit ups"),
                    Exercise(name: "Push-ups", duration: 45, description: "Standard push ups"),
                    Exercise(name: "Plank", duration: 60, description: "Hold plank position")
                ])
            }
        }
    }
    
    var body: some View {
        VStack{
            Spacer()
            if let selectedWorkout = currentSelection?.workout {
                WorkoutDescriptionView(workout: selectedWorkout)
                    .padding()
            }
            ForEach(SelectionState.allCases, id: \.self) {
                state in
                Button(action:{
                    currentSelection = state
                }, label: {
                    WorkoutChoiceButtonView(title: state.rawValue)
                })
            }
            Spacer()
            Button(action: {
                workout = currentSelection?.workout
            }, label: {
                Text("Choose selection")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
                    .frame(width: 300, height: 50)
                    .background(Color.white)
                    .cornerRadius(10)
                    .border(Color.blue)
            })
            .disabled(currentSelection == nil)
        }
    }
}

#Preview {
    WorkoutChoiceView(workout: .constant(nil))
}
