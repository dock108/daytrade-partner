//
//  AskViewModel.swift
//  TradeLens
//
//  ViewModel for the Ask Anything screen.
//

import Foundation

@MainActor
final class AskViewModel: ObservableObject {
    @Published var question: String = ""
    @Published var response: String?

    private let service: AIServiceStub

    init(service: AIServiceStub = AIServiceStub()) {
        self.service = service
    }

    func submit() {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            response = nil
            return
        }
        response = service.response(for: trimmed)
    }
}
