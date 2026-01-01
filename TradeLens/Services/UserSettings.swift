//
//  UserSettings.swift
//  TradeLens
//
//  Manages user preferences stored in UserDefaults.
//

import Foundation
import SwiftUI

@MainActor
final class UserSettings: ObservableObject {
    static let shared = UserSettings()
    
    private let simpleModKey = "TradeLens.SimpleExplanationsMode"
    
    @Published var isSimpleModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSimpleModeEnabled, forKey: simpleModKey)
        }
    }
    
    private init() {
        self.isSimpleModeEnabled = UserDefaults.standard.bool(forKey: simpleModKey)
    }
}



