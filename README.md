# RKLoggingKit

**RKLoggingKit** is a production-grade, privacy-aware logging framework for iOS, built with **Swift** and **Swift Package Manager**.

It is designed for real apps and SDKs where **performance, safety, and correctness** matter.

---

## ✨ Highlights

- ⚡ **Async & non-blocking** (zero main-thread impact)
- 📦 **True batching** (time + size based)
- 🛑 **Backpressure** (bounded memory, drop-oldest)
- 🔐 **Privacy by default** (PII redaction)
- 🧩 **Pluggable destinations**
- 🧪 **Deterministic async tests**
- 🧱 **SOLID & Clean Architecture**
- 📦 **SPM-first**, Swift 5.9+

---

## 📦 Installation (Swift Package Manager)

```swift
.package(
    url: "https://github.com/LovaRK/RKLoggingKit.git",
    from: "1.0.0"
)
```

Add **RKLoggingKit** to your target dependencies.

---

## 🚀 Quick Start

### Configure once (App launch)

```swift
import RKLoggingKit

LoggerManager.configureShared(
    minimumLevel: .info,
    destinations: [
        ConsoleLogger(),
        OSLogDestination(
            subsystem: "com.yourcompany.app",
            category: "general"
        )
    ]
)
```

### Log anywhere

```swift
let logger = LoggerManager.shared

logger.debug("View loaded")
logger.info("User session started")
logger.warning("High network latency", metadata: ["endpoint": "/profile"])
logger.error("API request failed", metadata: ["status": "401"])
```

---

## 🧠 Logging Levels

```swift
.verbose
.debug
.info
.warning
.error
```

Logs below `minimumLevel` are ignored.

---

## 🧩 Destinations

A destination defines **where logs go**.

```swift
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
```

### Built-in destinations

- `ConsoleLogger`
- `FileLogger`
- `OSLogDestination`
- `CrashlyticsDestination`
- `AnalyticsDestination`

### Add a destination

```swift
LoggerManager.shared.addDestination(FileLogger())
```

You can easily build custom destinations for:
- network APIs
- analytics pipelines
- internal observability tools

---

## 🔐 Privacy & Redaction (Default-On)

RKLoggingKit **automatically redacts sensitive data** before logs are buffered or persisted.

### Example

```swift
logger.info(
    "User login",
    metadata: [
        "email": "user@example.com",
        "token": "abcd1234",
        "phone": "9876543210"
    ]
)
```

### Output

```
email=<redacted>
token=<redacted>
phone=<redacted>
```

### Custom privacy rules

```swift
LoggerManager.shared.setPrivacyRules([
    EmailRule(),
    PhoneRule(),
    TokenRule()
])
```

Redaction happens **off the main thread**.

---

## 📦 Batching & Backpressure

### Batching
- Logs are buffered
- Flushed by **size** or **time**
- Fewer system calls → better performance

### Backpressure
- Strict in-memory cap
- **Drop-oldest** strategy
- Prevents memory blowups during log storms

This ensures **stability under load**.

---

## ⚡ Performance

Benchmarked using Xcode Instruments (Debug build):

```
10,000 logs in ~0.47 seconds
≈ 21,000 logs/sec
```

### Characteristics
- Near-zero main-thread cost
- Stable memory usage
- Scales under concurrency
- Batching improves throughput

---

## 🧪 Testing

RKLoggingKit includes deterministic tests for:

- Level filtering
- Destination fan-out
- Thread safety
- Privacy redaction
- Batching behavior
- Backpressure enforcement
- High-concurrency stress cases

Async behavior is tested **without sleeps or flakiness**.

---

## 🏗 Architecture Overview

```
LoggerManager (Facade)
 ├── LogDestination (protocol)
 │    ├── ConsoleLogger
 │    ├── FileLogger
 │    ├── OSLogDestination
 │    ├── CrashlyticsDestination
 │    └── AnalyticsDestination
 ├── Privacy Redactor
 │    └── PrivacyRule(s)
 ├── Batching Engine
 ├── Backpressure Control
 └── Async Worker Queue
```

### Design principles
- SOLID
- Clean Architecture
- Protocol-oriented design
- Minimal public API
- Production-safe defaults

---

## 🧠 Configuration Patterns

### Shared logger (recommended)

```swift
LoggerManager.configureShared(
    minimumLevel: .debug,
    destinations: [ConsoleLogger()]
)
```

### Standalone logger (advanced)

```swift
let logger = LoggerManager.makeStandalone(
    minimumLevel: .info,
    includeConsole: true
)
```

---

## 📚 Use Cases

- App-wide logging
- SDK / framework logging
- Analytics instrumentation
- Crash investigation
- Debug & production telemetry
- Privacy-safe observability

---

## 📄 License

MIT License

---

## 👤 Author

**Rama Krishna**  
Senior iOS Engineer

---

## ⭐️ Feedback

Issues, discussions, and pull requests are welcome.
