//
//  Redactor.swift
//  RKLoggingKit
//
//  Created by Rama Krishna on 12/16/25.
//

import Foundation

public final class Redactor {

    private let rules: [PrivacyRule]

    public init(rules: [PrivacyRule]) {
        self.rules = rules
    }

    public func redact(_ text: String) -> String {
        rules.reduce(text) { partial, rule in
            rule.redact(partial)
        }
    }

    public func redact(metadata: [String: String]?) -> [String: String]? {
        guard let metadata else { return nil }
        return metadata.mapValues { redact($0) }
    }
}
