import Foundation
import AppIntents

public protocol IntentExecutable {
    associatedtype Intent: AppIntent
    associatedtype Result: IntentResult
    func execute() async throws -> Result
}

public struct IntentExecutor<T: AppIntent> {
    private let intent: T
    private let configuration: ExecutionConfiguration

    public init(intent: T, configuration: ExecutionConfiguration = .default) {
        self.intent = intent
        self.configuration = configuration
    }

    public func execute() async throws -> some IntentResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            let result = try await withTimeout(seconds: configuration.timeout) {
                try await intent.perform()
            }

            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            ExecutionMetrics.shared.recordExecution(
                intentType: String(describing: T.self),
                time: executionTime,
                success: true
            )

            return result
        } catch {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            ExecutionMetrics.shared.recordExecution(
                intentType: String(describing: T.self),
                time: executionTime,
                success: false
            )

            throw IntentKitError.executionFailed(
                "Failed to execute intent: \(error.localizedDescription)"
            )
        }
    }

    public func executeWithRetry() async throws -> some IntentResult {
        var lastError: Error?

        for attempt in 1...configuration.retryCount {
            do {
                return try await execute()
            } catch {
                lastError = error
                if attempt < configuration.retryCount {
                    try await Task.sleep(nanoseconds: UInt64(configuration.retryDelay * 1_000_000_000))
                }
            }
        }

        throw lastError ?? IntentKitError.executionFailed("Unknown error")
    }

    private func withTimeout<R: IntentResult>(
        seconds: TimeInterval,
        operation: @escaping () async throws -> R
    ) async throws -> R {
        try await withThrowingTaskGroup(of: R.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw IntentKitError.executionFailed("Operation timed out")
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

public struct ExecutionConfiguration {
    public let timeout: TimeInterval
    public let retryCount: Int
    public let retryDelay: TimeInterval
    public let recordMetrics: Bool

    public init(
        timeout: TimeInterval = 30.0,
        retryCount: Int = 3,
        retryDelay: TimeInterval = 1.0,
        recordMetrics: Bool = true
    ) {
        self.timeout = timeout
        self.retryCount = retryCount
        self.retryDelay = retryDelay
        self.recordMetrics = recordMetrics
    }

    public static let `default` = ExecutionConfiguration()
}

public final class ExecutionMetrics {
    public static let shared = ExecutionMetrics()

    private var metrics: [String: [ExecutionRecord]] = [:]
    private let queue = DispatchQueue(label: "com.intentkit.metrics", attributes: .concurrent)

    private init() {}

    public struct ExecutionRecord {
        public let timestamp: Date
        public let executionTime: TimeInterval
        public let success: Bool
    }

    internal func recordExecution(intentType: String, time: TimeInterval, success: Bool) {
        queue.async(flags: .barrier) { [weak self] in
            let record = ExecutionRecord(
                timestamp: Date(),
                executionTime: time,
                success: success
            )

            if self?.metrics[intentType] != nil {
                self?.metrics[intentType]?.append(record)
            } else {
                self?.metrics[intentType] = [record]
            }
        }
    }

    public func averageExecutionTime(for intentType: String) -> TimeInterval? {
        queue.sync {
            guard let records = metrics[intentType], !records.isEmpty else {
                return nil
            }
            let totalTime = records.reduce(0.0) { $0 + $1.executionTime }
            return totalTime / Double(records.count)
        }
    }

    public func successRate(for intentType: String) -> Double? {
        queue.sync {
            guard let records = metrics[intentType], !records.isEmpty else {
                return nil
            }
            let successCount = records.filter { $0.success }.count
            return Double(successCount) / Double(records.count)
        }
    }

    public func reset() {
        queue.async(flags: .barrier) { [weak self] in
            self?.metrics.removeAll()
        }
    }
}

public struct IntentTestExecutor<T: AppIntent> {
    private let intent: T
    private let expectations: [IntentExpectation<T>]

    public init(intent: T, expectations: [IntentExpectation<T>] = []) {
        self.intent = intent
        self.expectations = expectations
    }

    public func runTest() async throws -> TestResult {
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

    public struct TestResult {
        public let success: Bool
        public let executionTime: TimeInterval
        public let failureReason: String?
    }
}

public struct IntentExpectation<T: AppIntent> {
    private let verificationClosure: (T, any IntentResult) throws -> Void

    public init(_ verification: @escaping (T, any IntentResult) throws -> Void) {
        self.verificationClosure = verification
    }

    public func verify(intent: T, result: any IntentResult) throws {
        try verificationClosure(intent, result)
    }
}

public final class IntentMockExecutor<T: AppIntent> {
    private var mockResults: [any IntentResult] = []
    private var currentIndex = 0

    public init() {}

    public func addMockResult(_ result: any IntentResult) {
        mockResults.append(result)
    }

    public func execute(_ intent: T) async throws -> any IntentResult {
        guard currentIndex < mockResults.count else {
            throw IntentKitError.executionFailed("No more mock results available")
        }
        let result = mockResults[currentIndex]
        currentIndex += 1
        return result
    }

    public func reset() {
        currentIndex = 0
        mockResults.removeAll()
    }
}
