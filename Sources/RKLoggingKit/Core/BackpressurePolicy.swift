//
//  BackpressurePolicy.swift
//  RKLoggingKit
//
//  Created by Rama Krishna on 12/16/25.
//

public enum BackpressurePolicy {
    /// Drop the oldest log entry to make room for new ones
    case dropOldest

    /// Drop the newest incoming log
    case dropNewest
}
