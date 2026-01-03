//
//  SpeechRecognitionService.swift
//  TradeLens
//
//  Native speech recognition service for voice input.
//

import Foundation
import Speech
import AVFoundation

/// Service that handles speech-to-text conversion using native iOS APIs
@MainActor
final class SpeechRecognitionService: ObservableObject {
    
    // MARK: - Published State
    
    @Published var isListening = false
    @Published var transcribedText = ""
    @Published var error: SpeechError?
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    // MARK: - Private Properties
    
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var autoStopTimer: Timer?
    private let autoStopDuration: TimeInterval = 7.0 // Auto-stop after 7 seconds
    private var silenceTimer: Timer?
    private let silenceDuration: TimeInterval = 2.0 // Stop after 2 seconds of silence
    
    // MARK: - Error Types
    
    enum SpeechError: LocalizedError {
        case notAuthorized
        case notAvailable
        case audioSessionError
        case recognitionFailed
        case noMicrophone
        
        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Microphone access not authorized. Please enable in Settings."
            case .notAvailable:
                return "Speech recognition is not available on this device."
            case .audioSessionError:
                return "Unable to access audio. Please try again."
            case .recognitionFailed:
                return "Could not understand speech. Please try again."
            case .noMicrophone:
                return "No microphone detected."
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    private func checkAuthorizationStatus() {
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }
    
    func requestAuthorization() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                Task { @MainActor in
                    self?.authorizationStatus = status
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }
    
    // MARK: - Recording Control
    
    func startListening(onResult: @escaping (String) -> Void, onComplete: @escaping (String?) -> Void) {
        // Reset state
        error = nil
        transcribedText = ""
        
        // Check authorization
        guard authorizationStatus == .authorized else {
            Task {
                let authorized = await requestAuthorization()
                if authorized {
                    startListening(onResult: onResult, onComplete: onComplete)
                } else {
                    error = .notAuthorized
                    onComplete(nil)
                }
            }
            return
        }
        
        // Check availability
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            error = .notAvailable
            onComplete(nil)
            return
        }
        
        // Stop any existing session
        stopListening()
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.error = .audioSessionError
            onComplete(nil)
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            self.error = .recognitionFailed
            onComplete(nil)
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .search
        
        // Get input node
        let inputNode = audioEngine.inputNode
        
        // Start recognition task
        var finalResult: String?
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let result = result {
                    let text = result.bestTranscription.formattedString
                    self.transcribedText = text
                    onResult(text)
                    
                    // Reset silence timer on new speech
                    self.resetSilenceTimer(onComplete: onComplete)
                    
                    if result.isFinal {
                        finalResult = text
                        self.stopListening()
                        onComplete(finalResult)
                    }
                }
                
                if let error = error {
                    // Ignore cancellation errors
                    if (error as NSError).code != 216 { // Cancelled
                        self.error = .recognitionFailed
                    }
                    self.stopListening()
                    onComplete(finalResult)
                }
            }
        }
        
        // Configure audio input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
            
            // Start auto-stop timer
            startAutoStopTimer(onComplete: onComplete)
            
            // Start initial silence timer
            resetSilenceTimer(onComplete: onComplete)
            
        } catch {
            self.error = .audioSessionError
            stopListening()
            onComplete(nil)
        }
    }
    
    func stopListening() {
        // Cancel timers
        autoStopTimer?.invalidate()
        autoStopTimer = nil
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        // Stop audio
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        // End recognition
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        isListening = false
    }
    
    // MARK: - Timers
    
    private func startAutoStopTimer(onComplete: @escaping (String?) -> Void) {
        autoStopTimer?.invalidate()
        autoStopTimer = Timer.scheduledTimer(withTimeInterval: autoStopDuration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                let text = self.transcribedText.isEmpty ? nil : self.transcribedText
                self.stopListening()
                onComplete(text)
            }
        }
    }
    
    private func resetSilenceTimer(onComplete: @escaping (String?) -> Void) {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceDuration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, !self.transcribedText.isEmpty else { return }
                let text = self.transcribedText
                self.stopListening()
                onComplete(text)
            }
        }
    }
    
    // MARK: - Permissions Check
    
    var canRequestMicrophone: Bool {
        return authorizationStatus != .denied && authorizationStatus != .restricted
    }
    
    var needsAuthorization: Bool {
        return authorizationStatus == .notDetermined
    }
}






