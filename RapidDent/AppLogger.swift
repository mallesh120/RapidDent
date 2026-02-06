//
//  AppLogger.swift
//  RapidDent
//
//  Structured logging that replaces scattered print() statements.
//  Uses os.Logger so messages appear in Console.app with proper filtering.
//

import Foundation
import os

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.manya.RapidDent"

    /// General app lifecycle events (Firebase init, etc.)
    static let general  = Logger(subsystem: subsystem, category: "General")

    /// Firestore data fetching and parsing.
    static let data     = Logger(subsystem: subsystem, category: "Data")

    /// Game logic: scoring, answer checking, progress.
    static let game     = Logger(subsystem: subsystem, category: "Game")

    /// Progress persistence (UserDefaults save/load).
    static let progress = Logger(subsystem: subsystem, category: "Progress")
}
