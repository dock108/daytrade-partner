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
    private let devModeKey = "TradeLens.DevModeEnabled"
    
    @Published var isSimpleModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSimpleModeEnabled, forKey: simpleModKey)
        }
    }

    @Published var isDevModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isDevModeEnabled, forKey: devModeKey)
        }
    }
    
    private init() {
        self.isSimpleModeEnabled = UserDefaults.standard.bool(forKey: simpleModKey)
        self.isDevModeEnabled = UserDefaults.standard.bool(forKey: devModeKey)
    }
}





