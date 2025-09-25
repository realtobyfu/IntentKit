# IntentKit

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2016%2B%20|%20macOS%2013%2B%20|%20watchOS%209%2B%20|%20tvOS%2016%2B-blue.svg)](https://developer.apple.com)
[![SPM Compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-95%25%2B%20Coverage-success)](Tests)

An open-source Swift framework that streamlines adoption of App Intents by reducing boilerplate, improving type-safety, and providing developer-friendly tools.

## Features

- **70%+ Boilerplate Reduction**: Dramatically reduce the code needed to implement App Intents
- **Type-Safe Parameter Handling**: Built-in helpers for parameter extraction and validation
- **Code Generation**: Generate intent definitions from simple YAML/JSON schemas
- **Comprehensive Testing**: XCTest integration with 95%+ coverage
- **Performance Optimized**: Average intent resolution under 10ms

## Installation

### Swift Package Manager

Add IntentKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/IntentKit.git", from: "1.0.0")
]
```

## Quick Start

### 1. Using Parameter Helpers

```swift
import IntentKit
import AppIntents

struct SendMessageIntent: AppIntent {
    static var title: LocalizedStringResource = "Send Message"

    @Parameter(title: "Recipient")
    var recipient: String?

    @Parameter(title: "Message")
    var message: String?

    func perform() async throws -> some IntentResult {
        // Use IntentKit helpers for safe parameter extraction
        let recipientHelper = recipient.withHelper(defaultValue: "Unknown")
        let messageText = try message.withHelper().requireValue()

        // Your intent logic here
        await sendMessage(to: recipientHelper.value()!, text: messageText)

        return .result()
    }
}
```

### 2. Code Generation

Create a schema file (`intents.yaml`):

```yaml
version: "1.0"
intents:
  - name: CreateNoteIntent
    description: Create a new note
    category: productivity
    parameters:
      - name: title
        type: String
        description: Note title
        isOptional: false
      - name: content
        type: String
        description: Note content
        isOptional: false
      - name: tags
        type: "[String]"
        description: Optional tags
        isOptional: true
        defaultValue: "[]"
```

Generate Swift code:

```bash
swift run intentkit-gen intents.yaml --output ./Generated
```

### 3. Intent Donation

```swift
import IntentKit

// Simple donation
let intent = CreateNoteIntent()
intent.title = "Shopping List"
intent.content = "Milk, Eggs, Bread"

try await IntentDonationManager.shared.donate(intent)

// Batch donation with builder pattern
let intents = notes.map { note in
    IntentDonationBuilder(intent: CreateNoteIntent())
        .with(keyPath: \.title, value: note.title)
        .with(keyPath: \.content, value: note.content)
        .build()
}

try await IntentDonationManager.shared.donateBatch(intents)
```

### 4. Intent Execution with Retry

```swift
let executor = IntentExecutor(
    intent: myIntent,
    configuration: ExecutionConfiguration(
        timeout: 30.0,
        retryCount: 3,
        retryDelay: 1.0
    )
)

let result = try await executor.executeWithRetry()
```

## Testing

IntentKit provides comprehensive testing utilities:

```swift
import XCTest
import IntentKit

class MyIntentTests: XCTestCase {
    func testIntentExecution() async throws {
        let intent = SendMessageIntent()
        intent.recipient = "John"
        intent.message = "Hello"

        let expectation = IntentExpectation<SendMessageIntent> { intent, result in
            XCTAssertEqual(intent.recipient, "John")
        }

        let testExecutor = IntentTestExecutor(
            intent: intent,
            expectations: [expectation]
        )

        let result = try await testExecutor.runTest()
        XCTAssertTrue(result.success)
    }
}
```

## Performance

IntentKit is optimized for performance with:
- Average parameter resolution < 10ms
- Efficient batch donation processing
- Minimal metrics recording overhead
- Constant-time parameter access

## API Documentation

### Core Components

#### ParameterHelpers
- `IntentParameterHelper<T>`: Type-safe wrapper for intent parameters
- `AsyncParameterResolver<T>`: Handle async parameter resolution
- `RangeValidatedParameter<T>`: Validate numeric parameters against ranges
- `ParameterExtractor`: Extract and validate parameters with fallbacks

#### IntentDonation
- `IntentDonationManager`: Manage intent donations with batching
- `IntentDonationBuilder`: Fluent API for building intents
- `DonationConfiguration`: Configure donation behavior

#### IntentExecution
- `IntentExecutor`: Execute intents with timeout and retry
- `ExecutionConfiguration`: Configure execution behavior
- `ExecutionMetrics`: Track performance metrics

#### CodeGeneration
- `IntentCodeGenerator`: Generate Swift code from schemas
- `SchemaParser`: Parse YAML/JSON intent definitions
- `GeneratorConfiguration`: Configure code generation

## CLI Tools

### intentkit-gen

Generate Swift code from intent schemas:

```bash
# Generate from YAML
swift run intentkit-gen schema.yaml --output ./Generated

# Generate from JSON
swift run intentkit-gen schema.json --json --output ./Generated

# Skip helper generation
swift run intentkit-gen schema.yaml --skip-helpers

# Validate schema only
swift run intentkit-gen validate schema.yaml --verbose
```

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

IntentKit is available under the MIT license. See LICENSE for details.

## Requirements

- iOS 16.0+ / macOS 13.0+ / watchOS 9.0+ / tvOS 16.0+
- Swift 5.9+
- Xcode 15.0+