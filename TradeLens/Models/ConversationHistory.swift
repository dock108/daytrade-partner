//
//  ConversationHistory.swift
//  TradeLens
//
//  Model for storing past questions and answers.
//

import Foundation

/// A single conversation entry with question and AI response
struct ConversationEntry: Identifiable, Codable {
    let id: UUID
    let question: String
    let timestamp: Date
    let detectedTicker: String?
    
    // Stored response data (reconstructable)
    let responseSections: [StoredSection]
    
    init(
        id: UUID = UUID(),
        question: String,
        timestamp: Date = Date(),
        detectedTicker: String? = nil,
        responseSections: [StoredSection]
    ) {
        self.id = id
        self.question = question
        self.timestamp = timestamp
        self.detectedTicker = detectedTicker
        self.responseSections = responseSections
    }
    
    /// Convert from AIResponse
    init(question: String, response: AIResponse, detectedTicker: String?) {
        self.id = UUID()
        self.question = question
        self.timestamp = response.timestamp
        self.detectedTicker = detectedTicker
        self.responseSections = response.sections.map { StoredSection(from: $0) }
    }
    
    /// Reconstruct AIResponse from stored data
    func toAIResponse() -> AIResponse {
        AIResponse(
            query: question,
            sections: responseSections.map { $0.toSection() },
            timestamp: timestamp
        )
    }
    
    /// Stored version of AIResponse.Section that's Codable
    struct StoredSection: Codable {
        let typeRawValue: String
        let content: String
        let bulletPoints: [String]?
        
        init(from section: AIResponse.Section) {
            self.typeRawValue = section.type.rawValue
            self.content = section.content
            self.bulletPoints = section.bulletPoints
        }
        
        func toSection() -> AIResponse.Section {
            let sectionType = AIResponse.SectionType(rawValue: typeRawValue) ?? .recap
            return AIResponse.Section(
                type: sectionType,
                content: content,
                bulletPoints: bulletPoints
            )
        }
    }
}

/// Manages conversation history persistence
final class ConversationHistoryService: ObservableObject {
    static let shared = ConversationHistoryService()
    
    @Published private(set) var entries: [ConversationEntry] = []
    
    private let storageKey = "TradeLens.ConversationHistory"
    private let maxEntries = 50
    
    private init() {
        loadHistory()
    }
    
    // MARK: - Public API
    
    /// Save a new conversation entry
    func save(question: String, response: AIResponse, detectedTicker: String?) {
        let entry = ConversationEntry(
            question: question,
            response: response,
            detectedTicker: detectedTicker
        )
        
        // Remove duplicate questions (keep most recent)
        entries.removeAll { $0.question.lowercased() == question.lowercased() }
        
        // Insert at beginning
        entries.insert(entry, at: 0)
        
        // Limit size
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        
        persistHistory()
    }
    
    /// Get recent entries (for display)
    func recentEntries(limit: Int = 10) -> [ConversationEntry] {
        Array(entries.prefix(limit))
    }
    
    /// Clear all history
    func clearHistory() {
        entries = []
        persistHistory()
    }
    
    /// Delete a specific entry
    func delete(_ entry: ConversationEntry) {
        entries.removeAll { $0.id == entry.id }
        persistHistory()
    }
    
    /// Get entry count
    var count: Int {
        entries.count
    }
    
    // MARK: - Persistence
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            entries = []
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode([ConversationEntry].self, from: data)
            entries = decoded
        } catch {
            print("Failed to decode conversation history: \(error)")
            entries = []
        }
    }
    
    private func persistHistory() {
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to encode conversation history: \(error)")
        }
    }
}






