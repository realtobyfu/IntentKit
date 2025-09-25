import Foundation
import AppIntents
import IntentKitCore

// MARK: - Example 1: Basic Parameter Handling

struct BasicExampleIntent: AppIntent {
    static var title: LocalizedStringResource = "Basic Example"

    @Parameter(title: "Name")
    var name: String?

    @Parameter(title: "Age")
    var age: Int?

    func perform() async throws -> some IntentResult {
        // Using IntentKit parameter helpers
        let nameHelper = name.withHelper(defaultValue: "Anonymous")
        let userName = nameHelper.value()!

        // Validate age parameter
        if let userAge = age {
            let validatedAge = try RangeValidatedParameter(value: userAge, range: 0...120)
            print("Hello \(userName), age \(validatedAge.value)")
        } else {
            print("Hello \(userName)")
        }

        return .result()
    }
}

// MARK: - Example 2: Async Parameter Resolution

struct AsyncExampleIntent: AppIntent {
    static var title: LocalizedStringResource = "Async Example"

    @Parameter(title: "User ID")
    var userId: String?

    func perform() async throws -> some IntentResult {
        // Async resolution of user data
        let userResolver = AsyncParameterResolver<User> {
            guard let id = self.userId else {
                throw IntentKitError.missingParameter("userId")
            }
            return try await fetchUser(id: id)
        }

        let user = try await userResolver.resolve()
        print("Fetched user: \(user.name)")

        return .result()
    }

    private func fetchUser(id: String) async throws -> User {
        // Simulate network call
        try await Task.sleep(nanoseconds: 100_000_000)
        return User(id: id, name: "User \(id)")
    }
}

struct User {
    let id: String
    let name: String
}

// MARK: - Example 3: Intent with Validation

struct ValidatedIntent: AppIntent {
    static var title: LocalizedStringResource = "Validated Intent"

    @Parameter(title: "Email")
    var email: String?

    @Parameter(title: "Phone")
    var phone: String?

    func perform() async throws -> some IntentResult {
        // Extract with validation
        let validEmail = try ParameterExtractor.extract(
            from: $email,
            validator: { email in
                let regex = "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$"
                let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
                return predicate.evaluate(with: email)
            }
        )

        let validPhone = try ParameterExtractor.extract(
            from: $phone,
            validator: { phone in
                phone.count >= 10 && phone.allSatisfy { $0.isNumber }
            }
        )

        print("Valid email: \(validEmail), phone: \(validPhone)")
        return .result()
    }
}

// MARK: - Example 4: Intent Donation

func demonstrateDonation() async throws {
    // Simple donation
    let simpleIntent = BasicExampleIntent()
    simpleIntent.name = "John"
    simpleIntent.age = 30

    try await IntentDonationManager.shared.donate(simpleIntent)

    // Batch donation
    let intents = (1...5).map { index in
        let intent = BasicExampleIntent()
        intent.name = "User\(index)"
        intent.age = 20 + index
        return intent
    }

    try await IntentDonationManager.shared.donateBatch(intents)

    // Using builder pattern
    let builtIntent = IntentDonationBuilder(intent: BasicExampleIntent())
        .with(keyPath: \.name, value: "Alice")
        .with(keyPath: \.age, value: 25)
        .build()

    try await IntentDonationManager.shared.donate(builtIntent)
}

// MARK: - Example 5: Intent Execution with Retry

func demonstrateExecution() async throws {
    let intent = AsyncExampleIntent()
    intent.userId = "123"

    // Configure execution
    let config = ExecutionConfiguration(
        timeout: 10.0,
        retryCount: 3,
        retryDelay: 0.5,
        recordMetrics: true
    )

    let executor = IntentExecutor(intent: intent, configuration: config)

    // Execute with retry logic
    do {
        let result = try await executor.executeWithRetry()
        print("Execution successful")

        // Check metrics
        if let avgTime = ExecutionMetrics.shared.averageExecutionTime(for: "AsyncExampleIntent") {
            print("Average execution time: \(avgTime)s")
        }
    } catch {
        print("Execution failed after retries: \(error)")
    }
}

// MARK: - Example 6: Testing Support

import XCTest

class IntentExamples: XCTestCase {
    func testBasicIntent() async throws {
        let intent = BasicExampleIntent()
        intent.name = "Test User"
        intent.age = 25

        // Create test expectations
        let expectations = [
            IntentExpectation<BasicExampleIntent> { intent, result in
                XCTAssertEqual(intent.name, "Test User")
                XCTAssertEqual(intent.age, 25)
            }
        ]

        let testExecutor = IntentTestExecutor(
            intent: intent,
            expectations: expectations
        )

        let result = try await testExecutor.runTest()
        XCTAssertTrue(result.success)
        XCTAssertNil(result.failureReason)
    }

    func testWithMock() async throws {
        let mock = IntentMockExecutor<AsyncExampleIntent>()
        mock.addMockResult(.result())

        let intent = AsyncExampleIntent()
        intent.userId = "mock123"

        let result = try await mock.execute(intent)
        // Verify mock was called
    }
}

// MARK: - Example 7: Custom Donation Observer

class CustomDonationObserver: IntentDonationObserver {
    func intentWillDonate(_ intent: any AppIntent) {
        print("About to donate: \(type(of: intent))")
    }

    func intentDidDonate(_ intent: any AppIntent) {
        print("Successfully donated: \(type(of: intent))")
    }

    func intentDonationFailed(_ intent: any AppIntent, error: Error) {
        print("Donation failed for \(type(of: intent)): \(error)")
    }
}

func setupDonationObserver() {
    let observer = CustomDonationObserver()
    DonationObserverRegistry.shared.register(observer)
}

// MARK: - Example 8: Building Complex Parameters

func demonstrateParameterBuilder() {
    enum Priority: String, CaseIterable {
        case low, medium, high
    }

    // Build enum from raw value
    let priority = ParameterBuilder.buildEnum(from: "high") as Priority?
    print("Priority: \(priority?.rawValue ?? "unknown")")

    // Build with default
    let title = ParameterBuilder.buildOptional(from: nil, defaultValue: "Untitled")
    print("Title: \(title)")

    // Build and transform array
    let tags = ["work", "personal", "urgent", ""]
    let processedTags = ParameterBuilder.buildArray(
        from: tags,
        filter: { !$0.isEmpty },
        transform: { $0.uppercased() }
    )
    print("Tags: \(processedTags)")
}