//
//  DefaultPrivacyRules.swift
//  RKLoggingKit
//
//  Created by Rama Krishna on 12/16/25.
//

import Foundation

public struct EmailRule: PrivacyRule {
    public init() {}
    public func redact(_ input: String) -> String {
        input.replacingOccurrences(
            of: #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#,
            with: "<redacted:email>",
            options: [.regularExpression, .caseInsensitive]
        )
    }
}

public struct PhoneRule: PrivacyRule {
    public init() {}
    public func redact(_ input: String) -> String {
        input.replacingOccurrences(
            of: #"\b\d{10}\b"#,
            with: "<redacted:phone>",
            options: [.regularExpression]
        )
    }
}

public struct TokenRule: PrivacyRule {
    public init() {}
    public func redact(_ input: String) -> String {
        input.replacingOccurrences(
            of: #"(token|apikey|secret)=\S+"#,
            with: "$1=<redacted>",
            options: [.regularExpression, .caseInsensitive]
        )
    }
}
