import XCTest
import AppIntents
@testable import IntentKitCore

struct TestExecutableIntent: AppIntent {
    static var title: LocalizedStringResource = "Test Executable Intent"

    @Parameter(title: "Input")
    var input: String?

    func perform() async throws -> some IntentResult {
        if input == "error" {
            throw IntentKitError.executionFailed("Test error")
        }

        // Simulate some work
        try await Task.sleep(nanoseconds: 10_000_000)

        return .result()
    }
}

final class IntentExecutionTests: XCTestCase {

    func testBasicExecution() async throws {
        let intent = TestExecutableIntent()
        intent.input = "test"

        let executor = IntentExecutor(intent: intent)
        _ = try await executor.execute()

        // Check that metrics were recorded
        let avgTime = ExecutionMetrics.shared.averageExecutionTime(for: "TestExecutableIntent")
        XCTAssertNotNil(avgTime)
    }

    func testExecutionWithError() async {
        let intent = TestExecutableIntent()
        intent.input = "error"

        let executor = IntentExecutor(intent: intent)

        do {
            _ = try await executor.execute()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is IntentKitError)
        }

        // Check that failure was recorded
        let successRate = ExecutionMetrics.shared.successRate(for: "TestExecutableIntent")
        XCTAssertNotNil(successRate)
    }

    func testExecutionWithRetry() async throws {
        let intent = TestExecutableIntent()
        intent.input = "test"

        let config = ExecutionConfiguration(
            timeout: 5.0,
            retryCount: 3,
            retryDelay: 0.1
        )

        let executor = IntentExecutor(intent: intent, configuration: config)
        _ = try await executor.executeWithRetry()
    }

    func testExecutionConfiguration() {
        let config = ExecutionConfiguration(
            timeout: 60.0,
            retryCount: 5,
            retryDelay: 2.0,
            recordMetrics: false
        )

        XCTAssertEqual(config.timeout, 60.0)
        XCTAssertEqual(config.retryCount, 5)
        XCTAssertEqual(config.retryDelay, 2.0)
        XCTAssertFalse(config.recordMetrics)
    }

    func testExecutionMetrics() async throws {
        ExecutionMetrics.shared.reset()

        let intent = TestExecutableIntent()
        intent.input = "test"

        // Execute multiple times
        for _ in 0..<3 {
            let executor = IntentExecutor(intent: intent)
            _ = try await executor.execute()
        }

        let avgTime = ExecutionMetrics.shared.averageExecutionTime(for: "TestExecutableIntent")
        XCTAssertNotNil(avgTime)

        let successRate = ExecutionMetrics.shared.successRate(for: "TestExecutableIntent")
        XCTAssertEqual(successRate, 1.0)
    }

    func testIntentTestExecutor() async throws {
        let intent = TestExecutableIntent()
        intent.input = "test"

        let expectation = IntentExpectation<TestExecutableIntent> { intent, _ in
            XCTAssertEqual(intent.input, "test")
        }

        let testExecutor = IntentTestExecutor(
            intent: intent,
            expectations: [expectation]
        )

        let result = try await testExecutor.runTest()
        XCTAssertTrue(result.success)
        XCTAssertNil(result.failureReason)
    }

    func testIntentMockExecutor() async throws {
        let mock = IntentMockExecutor<TestExecutableIntent>()

        struct MockResult: IntentResult {
            var value: Never? { nil }
        }
        let mockResult = MockResult()
        mock.addMockResult(mockResult)

        let intent = TestExecutableIntent()
        _ = try await mock.execute(intent)

        // Try to execute again without mock result
        do {
            _ = try await mock.execute(intent)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is IntentKitError)
        }

        // Reset and add new result
        mock.reset()
        mock.addMockResult(MockResult())
        _ = try await mock.execute(intent)
    }

    func testExecutionTimeout() async {
        struct SlowIntent: AppIntent {
            static var title: LocalizedStringResource = "Slow Intent"

            func perform() async throws -> some IntentResult {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                return .result()
            }
        }

        let intent = SlowIntent()
        let config = ExecutionConfiguration(timeout: 0.1)
        let executor = IntentExecutor(intent: intent, configuration: config)

        do {
            _ = try await executor.execute()
            XCTFail("Should have timed out")
        } catch {
            XCTAssertTrue(error is IntentKitError)
            if case IntentKitError.executionFailed(let message) = error {
                XCTAssertTrue(message.contains("timed out"))
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
}
