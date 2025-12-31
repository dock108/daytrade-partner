//
//  AIResponse.swift
//  TradeLens
//
//  Structured AI response model for article-style display.
//

import Foundation
import SwiftUI

/// A structured AI response broken into readable sections
struct AIResponse: Identifiable {
    let id = UUID()
    let query: String
    let sections: [Section]
    let sources: [SourceReference]
    let timestamp: Date
    
    init(query: String, sections: [Section], sources: [SourceReference] = [], timestamp: Date = Date()) {
        self.query = query
        self.sections = sections
        self.sources = sources
        self.timestamp = timestamp
    }
    
    struct Section: Identifiable {
        let id = UUID()
        let type: SectionType
        let content: String
        let bulletPoints: [String]?
        
        init(type: SectionType, content: String, bulletPoints: [String]? = nil) {
            self.type = type
            self.content = content
            self.bulletPoints = bulletPoints
        }
    }
    
    enum SectionType: String, CaseIterable {
        case currentSituation = "What's happening now"
        case keyDrivers = "Key drivers"
        case riskOpportunity = "Risk vs opportunity"
        case historical = "Historical context"
        case recap = "Quick take"
        case yourContext = "Your trading context"
        case personalNote = "Personal note"
        case digest = "Here's the story in simple terms"
        
        var icon: String {
            switch self {
            case .currentSituation: return "bolt.fill"
            case .keyDrivers: return "arrow.triangle.branch"
            case .riskOpportunity: return "scale.3d"
            case .historical: return "clock.arrow.circlepath"
            case .recap: return "text.quote"
            case .yourContext: return "person.crop.circle"
            case .personalNote: return "heart.text.square"
            case .digest: return "doc.text.fill"
            }
        }
        
        var accentColor: Color {
            switch self {
            case .currentSituation: return Color(red: 0.4, green: 0.7, blue: 1.0)
            case .keyDrivers: return Color(red: 0.6, green: 0.8, blue: 0.4)
            case .riskOpportunity: return Color(red: 1.0, green: 0.7, blue: 0.3)
            case .historical: return Color(red: 0.7, green: 0.5, blue: 0.9)
            case .recap: return Color(red: 0.3, green: 0.8, blue: 0.7)
            case .yourContext: return Color(red: 0.9, green: 0.5, blue: 0.6)
            case .personalNote: return Color(red: 0.85, green: 0.75, blue: 0.95)
            case .digest: return Color(red: 0.95, green: 0.85, blue: 0.55)
            }
        }
    }
    
    /// Source reference for deeper reading
    struct SourceReference: Identifiable {
        let id = UUID()
        let title: String
        let source: String
        let type: SourceType
        let summary: String
        
        enum SourceType: String {
            case news = "News"
            case research = "Research"
            case filings = "Filings"
            case analysis = "Analysis"
            
            var icon: String {
                switch self {
                case .news: return "newspaper.fill"
                case .research: return "doc.text.magnifyingglass"
                case .filings: return "doc.badge.gearshape.fill"
                case .analysis: return "chart.bar.doc.horizontal.fill"
                }
            }
            
            var color: Color {
                switch self {
                case .news: return Color(red: 0.4, green: 0.7, blue: 1.0)
                case .research: return Color(red: 0.7, green: 0.5, blue: 0.9)
                case .filings: return Color(red: 0.6, green: 0.8, blue: 0.4)
                case .analysis: return Color(red: 1.0, green: 0.7, blue: 0.3)
                }
            }
        }
    }
}

