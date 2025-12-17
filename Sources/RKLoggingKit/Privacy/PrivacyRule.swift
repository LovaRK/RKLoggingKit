//
//  PrivacyRule.swift
//  RKLoggingKit
//
//  Created by Rama Krishna on 12/16/25.
//

import Foundation

public protocol PrivacyRule {
    func redact(_ input: String) -> String
}
