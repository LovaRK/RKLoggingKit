//
//  LogLevel.swift
//  RKLoggingKit
//
//  Created by Rama Krishna on 12/15/25.
//

import Foundation

public enum LogLevel: Int, CaseIterable {
    case verbose = 0
    case debug
    case info
    case warning
    case error
}

public extension LogLevel {
    var name: String {
        switch self {
        case .verbose: return "VERBOSE"
        case .debug:   return "DEBUG"
        case .info:    return "INFO"
        case .warning: return "WARNING"
        case .error:   return "ERROR"
        }
    }
}
