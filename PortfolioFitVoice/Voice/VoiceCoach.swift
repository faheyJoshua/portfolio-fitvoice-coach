//
//  VoiceCoach.swift
//  PortfolioFitVoice
//
//  Created by Joshua Fahey on 6/2/25.
//
import AVFoundation
import Speech

@MainActor
final class VoiceCoach: NSObject, VoiceCoachProtocol, AVSpeechSynthesizerDelegate {
    
    private static var sharedInstances: [ObjectIdentifier: Any] = [:]
    
    static func shared<T: VoiceCoachProtocol>(type: T.Type = VoiceCoach.self) -> T {
        let key = ObjectIdentifier(type)
        if let instance = sharedInstances[key] as? T {
            return instance
        }
        let newInstance = type.init()
        sharedInstances[key] = newInstance
        return newInstance
    }
    
    
    // MARK: - Properties
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var recognitionTask: SFSpeechRecognitionTask?
    private let commands: Set<String> = ["start", "pause", "resume", "next", "stop"]
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        speechSynthesizer.delegate = self
    }
    
    // MARK: - VoiceCoachProtocol Methods
    
    func startListening() -> AsyncStream<String> {
        AsyncStream { continuation in
            // Check permissions
            checkAuthorizations { authorized in
                guard authorized else {
                    print("Permissions not granted")
                    continuation.finish()
                    return
                }

                // Configure audio session
                let audioSession = AVAudioSession.sharedInstance()
                do {
                    try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                } catch {
                    continuation.finish()
                    return
                }

                // Set up audio engine
                let audioEngine = self.audioEngine
                let inputNode = audioEngine.inputNode
                let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                recognitionRequest.shouldReportPartialResults = true

                // Configure audio format
                let recordingFormat = inputNode.outputFormat(forBus: 0)
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                    recognitionRequest.append(buffer)
                }

                // Start audio engine
                do {
                    audioEngine.prepare()
                    try audioEngine.start()
                } catch {
                    continuation.finish()
                    return
                }

                // Start recognition task
                Task { @MainActor in
                    self.recognitionTask = self.speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
                        if let result = result {
                            let transcription = result.bestTranscription.formattedString.lowercased()
                            let words = transcription.components(separatedBy: " ")
                            for word in words {
                                if self.commands.contains(word) {
                                    continuation.yield(word)
                                }
                            }
                        }
                        if let _ = error {
                            continuation.finish()
                        } else if result?.isFinal == true {
                            continuation.finish()
                        }
                    }
                }

                // Clean up on termination
                continuation.onTermination = { @Sendable _ in
                    Task { @MainActor in
                        self.recognitionTask?.cancel()
                        self.recognitionTask = nil
                        audioEngine.stop()
                        inputNode.removeTap(onBus: 0)
                        try? audioSession.setActive(false)
                    }
                }
            }
        }
    }

    private func checkAuthorizations(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { speechStatus in
            AVAudioApplication.requestRecordPermission { micGranted in
                DispatchQueue.main.async {
                    let authorized = speechStatus == .authorized && micGranted
                    print("Speech: \(speechStatus == .authorized), Mic: \(micGranted)")
                    completion(authorized)
                }
            }
        }
    }
    
    func stopListening() {
        recognitionTask?.cancel()
        recognitionTask = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    func speak(text: String) -> AsyncStream<String> {
        AsyncStream { continuation in
            Task { @MainActor in
                self.stopListening()
                print("Attempting to speak: \(text)")
                guard !text.isEmpty else {
                    print("Error: Empty text provided")
                    continuation.yield("error")
                    continuation.finish()
                    return
                }
                
                    let audioSession = AVAudioSession.sharedInstance()
                do {
                    try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                } catch {
                    print("Audio session error: \(error)")
                    continuation.yield("error")
                    continuation.finish()
                    return
                }

                let utterance = AVSpeechUtterance(string: text)
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US") ?? AVSpeechSynthesisVoice(language: "en")
                utterance.rate = 0.5

                // Store continuation in a property or closure to use in delegate
                let continuationBox = ContinuationBox(continuation: continuation)
                self.speechSynthesizer.stopSpeaking(at: .immediate)
                self.speechSynthesizer.speak(utterance)

                // Clean up on stream termination
                continuation.onTermination = { @Sendable _ in
                    Task { @MainActor in
                        self.speechSynthesizer.stopSpeaking(at: .immediate)
                        try? audioSession.setActive(false)
                        continuationBox.release() // Avoid retain cycle
                    }
                }
            }
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("Started speaking: \(utterance.speechString)")
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("Finished speaking: \(utterance.speechString)")
        try? AVAudioSession.sharedInstance().setActive(false)
        Task {
            await MainActor.run {
                if let continuation = ContinuationBox.currentContinuation {
                    continuation.yield("completed")
                    continuation.finish()
                }
            }
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("Cancelled speaking: \(utterance.speechString)")
        try? AVAudioSession.sharedInstance().setActive(false)
        Task {
            await MainActor.run {
                if let continuation = ContinuationBox.currentContinuation {
                    continuation.yield("canceled")
                    continuation.finish()
                }
            }
        }
    }
}

private class ContinuationBox {
    static var currentContinuation: AsyncStream<String>.Continuation?
    private var continuation: AsyncStream<String>.Continuation?

    init(continuation: AsyncStream<String>.Continuation) {
        self.continuation = continuation
        ContinuationBox.currentContinuation = continuation
    }

    func release() {
        continuation = nil
        ContinuationBox.currentContinuation = nil
    }
}
