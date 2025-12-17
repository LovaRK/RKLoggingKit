//
//  FileLogger.swift
//  RKLoggingKit
//
//  Created by Rama Krishna on 12/15/25.
//

import Foundation

public final class FileLogger: LogDestination {
    
    private let queue: DispatchQueue
    private let logFileURL: URL
    private let maxFileSizeBytes: UInt64
    
    public init(
        fileName: String = "app.log",
        maxFileSizeBytes: UInt64 = 5 * 1024 * 1024 // ~5 MB
    ) {
        self.queue = DispatchQueue(label: "com.logger.file")
        self.maxFileSizeBytes = maxFileSizeBytes
        
        let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        
        self.logFileURL = documentsDirectory.appendingPathComponent(fileName)
        print("Documents directory:", FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!)
    }
    
    public func log(
        level: LogLevel,
        message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: String,
        function: String,
        line: Int
    ) {
        let ts = Self.timestamp()
        let shortFile = (file as NSString).lastPathComponent
        let thread = Thread.isMainThread ? "Main" : "BG"
        
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
        
        let lineEntry = "\(ts) \(emoji) [\(thread)] \(shortFile):\(line) \(function) → \(message())\n"
        
        queue.async { [logFileURL, maxFileSizeBytes] in
            Self.rotateIfNeeded(fileURL: logFileURL, maxSize: maxFileSizeBytes)
            Self.append(lineEntry, to: logFileURL)
        }
    }
    
    // MARK: - Helpers
    
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return df
    }()
    
    private static func timestamp() -> String {
        dateFormatter.string(from: Date())
    }
    
    private static func append(_ text: String, to url: URL) {
        guard let data = text.data(using: .utf8) else { return }
        
        let fm = FileManager.default
        if fm.fileExists(atPath: url.path) {
            if let handle = try? FileHandle(forWritingTo: url) {
                defer { try? handle.close() }
                _ = try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
            }
        } else {
            try? data.write(to: url, options: .atomic)
        }
    }
    
    private static func rotateIfNeeded(fileURL: URL, maxSize: UInt64) {
        let fm = FileManager.default

        // If file doesn't exist, nothing to rotate
        guard
            let attrs = try? fm.attributesOfItem(atPath: fileURL.path),
            let size = attrs[.size] as? UInt64,
            size > maxSize
        else {
            return
        }

        // Build backup URLs
        let log1 = fileURL.appendingPathExtension("1")
        let log2 = fileURL.appendingPathExtension("2")
        let log3 = fileURL.appendingPathExtension("3")

        // Delete oldest backup
        try? fm.removeItem(at: log3)

        // Shift backups
        if fm.fileExists(atPath: log2.path) {
            try? fm.moveItem(at: log2, to: log3)
        }
        if fm.fileExists(atPath: log1.path) {
            try? fm.moveItem(at: log1, to: log2)
        }
        if fm.fileExists(atPath: fileURL.path) {
            try? fm.moveItem(at: fileURL, to: log1)
        }
    }
}
