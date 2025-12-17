//
//  ConsoleLogger.swift
//  RKLoggingKit
//
//  Created by Rama Krishna on 12/15/25.
//

import Foundation

public final class ConsoleLogger: LogDestination {
    
    private static let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return df
    }()
    
    public init() { }
    
    private static let formatterQueue = DispatchQueue(label: "com.logger.console.formatter")
    
    private func timestamp() -> String {
        var result = ""
        Self.formatterQueue.sync {
            result = Self.formatter.string(from: Date())
        }
        return result
    }
    
    public func log(
        level: LogLevel,
        message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: String,
        function: String,
        line: Int
    ) {
        let ts = timestamp()
        
        let emoji: String
        switch level {
        case .verbose:
            emoji = "🔍"
        case .debug:
            emoji = "🐞"
        case .info:
            emoji = "ℹ️"
        case .warning:
            emoji = "⚠️"
        case .error:
            emoji = "❌"
        }
        
        let thread = Thread.isMainThread ? "Main" : "BG"
        let shortFile = (file as NSString).lastPathComponent
        
        print("\(ts) \(emoji) [\(thread)] \(shortFile):\(line) \(function) → \(message())")
    }
}
