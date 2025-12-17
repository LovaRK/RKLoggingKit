//
//  OSLogDestination.swift
//  RKLoggingKit
//
//  Created by Rama Krishna on 12/15/25.
//

import Foundation
import OSLog

public final class OSLogDestination: LogDestination {

    private let logger: Logger

    public init(subsystem: String = Bundle.main.bundleIdentifier ?? "App",
                category: String = "General") {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    public func log(
        level: LogLevel,
        message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: String,
        function: String,
        line: Int
    ) {
        let msg = message()

        switch level {
        case .verbose:
            logger.trace("\(msg, privacy: .public)")
        case .debug:
            logger.debug("\(msg, privacy: .public)")
        case .info:
            logger.info("\(msg, privacy: .public)")
        case .warning:
            logger.warning("\(msg, privacy: .public)")
        case .error:
            logger.error("\(msg, privacy: .public)")
        }
    }
}
