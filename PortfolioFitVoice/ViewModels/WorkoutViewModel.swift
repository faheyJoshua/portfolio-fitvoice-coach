//
//  WorkoutViewModel.swift
//  PortfolioFitVoice
//
//  Created by Joshua Fahey on 6/2/25.
//
import Combine

@MainActor
class WorkoutViewModel: ObservableObject {
    @Published var currentState: WorkoutState = .idle
    
    @Published var finishedWorkout: Bool = false
    
    let workout: Workout
    private let voiceType: VoiceCoachProtocol.Type
    lazy var voiceCoach: VoiceCoachProtocol = {
        VoiceCoach.shared(type: voiceType)
    }()
    
    private var workoutTask: Task<Void, Never>?
    private var listeningTask: Task<Void, Never>?
    private var speakingTask: Task<Void, Never>?
    
    init(workout: Workout, voiceCoach: VoiceCoachProtocol.Type = VoiceCoach.self) {
        self.workout = workout
        self.voiceType = voiceCoach
    }
    
    func setupListening(){
        listeningTask = Task {
            for await command in self.voiceCoach.startListening() {
                handleVoiceCommand(command)
            }
        }
    }
    
    func startWorkout() {
        guard case .idle = currentState else { return }
        
        currentState = .running(exerciseIndex: 0, remainingTime: workout.exercises[0].duration)
        speak(text: "Workout started. First exercise: \(workout.exercises[0].name)")
        
        workoutTask = Task {
            while true {
                switch currentState {
                case .running(let index, let time):
                    if time > 0 {
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        if case .running(let i, let t) = currentState, i == index {
                            currentState = .running(exerciseIndex: index, remainingTime: t - 1)
                        }
                    } else {
                        if index < workout.exercises.count - 1 {
                            let nextIndex = index + 1
                            currentState = .running(exerciseIndex: nextIndex, remainingTime: workout.exercises[nextIndex].duration)
                            speak(text: "Next exercise: \(workout.exercises[nextIndex].name)")
                        } else {
                            currentState = .idle
                            speak(text: "Workout completed")
                            stopWorkout()
                        }
                    }
                case .paused:
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                    // Wait until resumed
                case .idle:
                    return
                }
            }
        }
    }
    
    func pauseWorkout() {
        if case .running(let index, let time) = currentState {
            currentState = .paused(exerciseIndex: index, remainingTime: time)
            speak(text: "Workout paused")
        }
    }
    
    func resumeWorkout() {
        if case .paused(let index, let time) = currentState {
            currentState = .running(exerciseIndex: index, remainingTime: time)
            speak(text: "Workout resumed")
        }
    }
    
    func nextExercise() {
        if case .running(let index, _) = currentState, index < workout.exercises.count - 1 {
            let nextIndex = index + 1
            currentState = .running(exerciseIndex: nextIndex, remainingTime: workout.exercises[nextIndex].duration)
            speak(text: "Next exercise: \(workout.exercises[nextIndex].name)")
        }
    }
    
    func stopWorkout() {
        speak(text: "Workout stopped", resumeListening: false)
    }
    
    private func handleVoiceCommand(_ command: String) {
        switch command {
        case "start":
            startWorkout()
        case "pause":
            pauseWorkout()
        case "resume":
            resumeWorkout()
        case "next":
            nextExercise()
        case "stop":
            stopWorkout()
        default:
            break
        }
    }
    
    private func speak(text: String, resumeListening: Bool = true){
        speakingTask = Task {
            for await command in voiceCoach.speak(text: text) {
                print("command \(command)")
            }
            if resumeListening {
                setupListening()
            } else {
                currentState = .idle
                workoutTask?.cancel()
                listeningTask?.cancel()
                voiceCoach.stopListening()
                finishedWorkout = true
            }
        }
    }
    
    // MARK: - Computed Properties for UI
    
    var currentExercise: Exercise? {
        switch currentState {
        case .running(let index, _), .paused(let index, _):
            return workout.exercises[index]
        case .idle:
            return nil
        }
    }
    
    var remainingTime: Int? {
        switch currentState {
        case .running(_, let time), .paused(_, let time):
            return time
        case .idle:
            return nil
        }
    }
    
    var isWorkoutActive: Bool {
        if case .idle = currentState {
            return false
        } else {
            return true
        }
    }
}
