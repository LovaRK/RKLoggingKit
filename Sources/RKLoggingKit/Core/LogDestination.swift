//
//  LogDestination.swift
//  RKLoggingKit
//
//  Created by Rama Krishna on 12/15/25.
//

import Foundation

public protocol LogDestination {
    func log(
        level: LogLevel,
        message: @autoclosure () -> String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    )
}
