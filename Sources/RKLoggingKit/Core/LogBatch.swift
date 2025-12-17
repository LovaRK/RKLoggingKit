//
//  LogBatch.swift
//  RKLoggingKit
//
//  Created by Rama Krishna on 12/16/25.
//

import Foundation

struct LogBatch {
    let level: LogLevel
    let message: String
    let metadata: [String: String]?
    let file: String
    let function: String
    let line: Int
}
