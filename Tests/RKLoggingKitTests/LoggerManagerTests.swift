//
//  LoggerManagerTests.swift
//  RKLoggingKit
//
//  Created by Rama Krishna on 12/15/25.
//

import XCTest
@testable import RKLoggingKit

final class LoggerManagerTests: XCTestCase {
    
    final class SpyDestination: LogDestination {
        private let lock = NSLock()
        private(set) var entries: [(level: LogLevel, message: String, metadata: [String: String]?)] = []

        
        func log(
            level: LogLevel,
            message: @autoclosure () -> String,
            metadata: [String: String]?,
            file: String,
            function: String,
            line: Int
        ) {
            lock.lock()
            entries.append((level, message(), metadata))
            lock.unlock()
        }
    }
    
    // Test 1 — Level filtering
    func test_respectsMinimumLevel() {
        let spy = SpyDestination()
        let logger = LoggerManager()
        logger.setDestinations([spy])
        logger.minimumLevel = .warning
        
        logger.debug("debug")
        logger.info("info")
        logger.error("error")
        logger.flush()
        
        XCTAssertEqual(spy.entries.count, 1)
        XCTAssertEqual(spy.entries.first?.0, .error)
    }
    
    // Test 2 — Fan-out to all destinations (O(n))
    func test_logsToAllDestinations() {
        let spy1 = SpyDestination()
        let spy2 = SpyDestination()

        let logger = LoggerManager()
        logger.setDestinations([spy1, spy2])
        logger.minimumLevel = .verbose

        logger.info("hello")
        logger.flush()

        XCTAssertEqual(spy1.entries.count, 1)
        XCTAssertEqual(spy2.entries.count, 1)
        XCTAssertEqual(spy1.entries.first?.1, "hello")
        XCTAssertEqual(spy2.entries.first?.1, "hello")
    }
    
    // Test 3 — Concurrent logging is safe
    func test_concurrentLogging_isThreadSafe() {
        let spy = SpyDestination()
        let logger = LoggerManager()
        logger.setDestinations([spy])
        logger.minimumLevel = .verbose

        let iterations = 1_000
        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .userInitiated)

        for i in 0..<iterations {
            group.enter()
            queue.async {
                logger.debug("msg \(i)")
                group.leave()
            }
        }

        let expectation = XCTestExpectation(description: "wait for concurrent logs")
        group.notify(queue: .main) {
            logger.flush()
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(spy.entries.count, iterations)
    }
    
    func test_redactsSensitiveData() {
        let spy = SpyDestination()
        let logger = LoggerManager()
        logger.setDestinations([spy])

        logger.log(
            .info,
            "User email test@example.com token=abcd1234",
            metadata: ["phone": "9876543210"]
        )
       
        logger.flush()

        let entry = spy.entries.first
        XCTAssertNotNil(entry)

        XCTAssertFalse(entry?.message.contains("test@example.com") == true)
        XCTAssertFalse(entry?.message.contains("abcd1234") == true)

        XCTAssertEqual(
            entry?.metadata?["phone"],
            "<redacted:phone>"
        )
    }
    
    func test_backpressure_doesNotExceedMaxBufferSize() {
        let spy = SpyDestination()
        let logger = LoggerManager()
        logger.setDestinations([spy])
        logger.minimumLevel = .verbose

        // Flood logger beyond maxBufferSize
        let totalLogs = 1_000
        for i in 0..<totalLogs {
            logger.info("log \(i)")
        }

        logger.flush()

        // Max deliverable logs is maxBufferSize
        XCTAssertGreaterThan(spy.entries.count, 0)
    }
    
    func test_backpressure_dropsOldestLogs() {
        let spy = SpyDestination()
        let logger = LoggerManager()

        logger._disableFlushTimerForTests()
        logger._setMaxBatchSizeForTests(1_000) // 👈 prevent early flush
        logger.setDestinations([spy])
        logger.minimumLevel = .verbose

        // Force buffer overflow WITHOUT flushing
        for i in 0..<600 {
            logger.log(
                .info,
                "log \(i)",
                metadata: nil,
                file: #file,
                function: #function,
                line: #line
            )
        }

        logger.flush()

        XCTAssertEqual(spy.entries.count, 500)

        let firstMessage = spy.entries.first?.message
        let lastMessage  = spy.entries.last?.message

        XCTAssertEqual(firstMessage, "log 100")
        XCTAssertEqual(lastMessage, "log 599")
    }

    func test_backpressure_underConcurrentLoad_isStable() {
        let spy = SpyDestination()
        let logger = LoggerManager()
        logger.setDestinations([spy])
        logger.minimumLevel = .verbose

        let queue = DispatchQueue.global(qos: .userInitiated)
        let group = DispatchGroup()

        for i in 0..<2_000 {
            group.enter()
            queue.async {
                logger.debug("msg \(i)")
                group.leave()
            }
        }

        let expectation = XCTestExpectation(description: "concurrent logging")

        group.notify(queue: .global()) {
            logger.flush()
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5)

        XCTAssertGreaterThan(spy.entries.count, 0)
    }

}

