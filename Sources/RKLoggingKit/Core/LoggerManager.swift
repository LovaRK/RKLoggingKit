//
//  LoggerManager.swift
//  BhagavadGita
//
//  Created by Rama Krishna on 12/9/25.
//

import Foundation

public final class LoggerManager {
    
    // MARK: - Singleton
    
    public static let shared = LoggerManager()
    
    // MARK: - Queues
    
    /// Protects destinations
    private let destinationsQueue = DispatchQueue(
        label: "com.rklogging.destinations",
        attributes: .concurrent
    )
    
    /// Serial worker queue for async logging (preserves order)
    private let workerQueue = DispatchQueue(
        label: "com.rklogging.worker",
        qos: .utility
    )
    
    /// Protects configuration (level, redactor)
    private let configQueue = DispatchQueue(
        label: "com.rklogging.config"
    )
    
    // MARK: - Backpressure
    private let backpressurePolicy: BackpressurePolicy = .dropOldest
    private(set) var droppedLogCount: Int = 0
    
    // MARK: - Batching
    private var buffer: [LogBatch] = []
    private let maxBatchSize = 50          // flush threshold
    private let maxBufferSize = 500        // backpressure cap
    private var flushTimer: DispatchSourceTimer?
    
    // MARK: - State
    
    private var destinations: [LogDestination] = []
    private var _minimumLevel: LogLevel = .verbose
    private var _redactor = Redactor(
        rules: [
            EmailRule(),
            PhoneRule(),
            TokenRule()
        ]
    )
    
    // Always present override property for batch size (for tests)
    public var testMaxBatchSizeOverride: Int? = nil
    
    // MARK: - Public configuration
    
    public var minimumLevel: LogLevel {
        get { configQueue.sync { _minimumLevel } }
        set { configQueue.sync { _minimumLevel = newValue } }
    }
    
    // Internal init (testable, but not public API)
    init() {
        startFlushTimer()
    }
    
    // MARK: - Destinations
    
    public func addDestination(_ destination: LogDestination) {
        destinationsQueue.async(flags: .barrier) {
            self.destinations.append(destination)
        }
    }
    
    public func setDestinations(_ destinations: [LogDestination]) {
        destinationsQueue.async(flags: .barrier) {
            self.destinations = destinations
        }
    }
    
    // MARK: - Privacy
    
    public func setPrivacyRules(_ rules: [PrivacyRule]) {
        configQueue.sync {
            self._redactor = Redactor(rules: rules)
        }
    }
    
    private func currentRedactor() -> Redactor {
        configQueue.sync { _redactor }
    }
    
    // MARK: - Core logging
    
    public func log(
        _ level: LogLevel,
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        guard level.rawValue >= minimumLevel.rawValue else { return }
        
        // Capture values immediately (cheap work only)
        let rawMessage = message()
        let redactor = currentRedactor()
        let safeMessage = redactor.redact(rawMessage)
        let safeMetadata = redactor.redact(metadata: metadata)
        
        // 🔥 Async, non-blocking destination writes
        workerQueue.async {
            let entry = LogBatch(
                level: level,
                message: safeMessage,
                metadata: safeMetadata,
                file: "\(file)",
                function: "\(function)",
                line: Int(line)
            )
            
            // Enforce backpressure
            if self.buffer.count >= self.maxBufferSize {
                switch self.backpressurePolicy {
                case .dropOldest:
                    self.buffer.removeFirst()
                    self.droppedLogCount += 1
                    
                case .dropNewest:
                    self.droppedLogCount += 1
                    return
                }
            }
            
            self.buffer.append(entry)
            
            // Size-based flush
            let effectiveBatchSize = self.testMaxBatchSizeOverride ?? self.maxBatchSize

            if self.buffer.count >= effectiveBatchSize {
                self.flushInternal()
            }
            
        }
    }
    
    private func startFlushTimer() {
        let timer = DispatchSource.makeTimerSource(queue: workerQueue)
        timer.schedule(deadline: .now() + 2, repeating: 2)
        timer.setEventHandler { [weak self] in
            self?.flushInternal()
        }
        timer.resume()
        flushTimer = timer
    }
    
    private func flushInternal() {
        guard !buffer.isEmpty else { return }
        
        let batch = buffer
        buffer.removeAll(keepingCapacity: true)
        
        let destinationsSnapshot = destinationsQueue.sync { destinations }
        
        batch.forEach { entry in
            destinationsSnapshot.forEach {
                $0.log(
                    level: entry.level,
                    message: entry.message,
                    metadata: entry.metadata,
                    file: entry.file,
                    function: entry.function,
                    line: entry.line
                )
            }
        }
    }
    
#if DEBUG
   public func flush() {
        workerQueue.sync {
            flushInternal()
        }
    }
#endif
    
#if DEBUG
    func _disableFlushTimerForTests() {
        flushTimer?.cancel()
        flushTimer = nil
    }
#endif
    
#if DEBUG
    func _setMaxBatchSizeForTests(_ size: Int) {
        testMaxBatchSizeOverride = size
    }
#endif
    
    
}

// MARK: - Convenience APIs

public extension LoggerManager {
    
    func verbose(
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        log(.verbose, message(), metadata: metadata, file: file, function: function, line: line)
    }
    
    func debug(
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        log(.debug, message(), metadata: metadata, file: file, function: function, line: line)
    }
    
    func info(
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        log(.info, message(), metadata: metadata, file: file, function: function, line: line)
    }
    
    func warning(
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        log(.warning, message(), metadata: metadata, file: file, function: function, line: line)
    }
    
    func error(
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        log(.error, message(), metadata: metadata, file: file, function: function, line: line)
    }
}

// MARK: - Defaults & App configuration

public extension LoggerManager {
    
    /// Creates a standalone logger with sensible defaults.
    static func makeStandalone(
        minimumLevel: LogLevel = .info,
        includeConsole: Bool = true
    ) -> LoggerManager {
        let logger = LoggerManager()
        logger.minimumLevel = minimumLevel
        
        if includeConsole {
            logger.addDestination(ConsoleLogger())
        }
        
        return logger
    }
    
    /// Configure the shared logger once at app launch.
    static func configureShared(
        minimumLevel: LogLevel = .info,
        destinations: [LogDestination] = [ConsoleLogger()]
    ) {
        shared.minimumLevel = minimumLevel
        shared.setDestinations(destinations)
    }
}

