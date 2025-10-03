import Foundation
import AppIntents
@testable import IntentKitCore

struct IntentTestExecutor<T: AppIntent> {
    private let intent: T
    private let expectations: [IntentExpectation<T>]

    init(intent: T, expectations: [IntentExpectation<T>] = []) {
        self.intent = intent
        self.expectations = expectations
    }

    func runTest() async throws -> TestResult {
        let executor = IntentExecutor(intent: intent)
        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            let result = try await executor.execute()
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime

            for expectation in expectations {
                try expectation.verify(intent: intent, result: result)
            }

            return TestResult(
                success: true,
                executionTime: executionTime,
                failureReason: nil
            )
        } catch {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            return TestResult(
                success: false,
                executionTime: executionTime,
                failureReason: error.localizedDescription
            )
        }
    }

    struct TestResult {
        let success: Bool
        let executionTime: TimeInterval
        let failureReason: String?
    }
}

struct IntentExpectation<T: AppIntent> {
    private let verificationClosure: (T, any IntentResult) throws -> Void

    init(_ verification: @escaping (T, any IntentResult) throws -> Void) {
        self.verificationClosure = verification
    }

    func verify(intent: T, result: any IntentResult) throws {
        try verificationClosure(intent, result)
    }
}

final class IntentMockExecutor<T: AppIntent> {
    private var mockResults: [any IntentResult] = []
    private var currentIndex = 0

    init() {}

    func addMockResult(_ result: any IntentResult) {
        mockResults.append(result)
    }

    func execute(_ intent: T) async throws -> any IntentResult {
        guard currentIndex < mockResults.count else {
            throw IntentKitError.executionFailed("No more mock results available")
        }
        let result = mockResults[currentIndex]
        currentIndex += 1
        return result
    }

    func reset() {
        currentIndex = 0
        mockResults.removeAll()
    }
}
