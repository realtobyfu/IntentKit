import XCTest
import AppIntents
@testable import IntentKitCore

struct TestIntent: AppIntent {
    static var title: LocalizedStringResource = "Test Intent"

    @Parameter(title: "Test Parameter")
    var testValue: String?

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

final class IntentDonationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        IntentDonationManager.shared.clearDonationQueue()
    }

    func testSingleIntentDonation() async throws {
        let intent = TestIntent()
        intent.testValue = "test"

        // Note: In a real app, this would actually donate to the system
        // For testing, we're mainly checking that no errors are thrown
        try await IntentDonationManager.shared.donate(intent)
    }

    func testBatchDonation() async throws {
        let intents = (0..<5).map { index in
            let intent = TestIntent()
            intent.testValue = "test\(index)"
            return intent
        }

        try await IntentDonationManager.shared.donateBatch(intents)
    }

    func testQueuedDonation() async throws {
        let intent1 = TestIntent()
        intent1.testValue = "queued1"

        let intent2 = TestIntent()
        intent2.testValue = "queued2"

        IntentDonationManager.shared.queueDonation(intent1)
        IntentDonationManager.shared.queueDonation(intent2)

        // Small delay to ensure queue operations complete
        try await Task.sleep(nanoseconds: 100_000_000)

        try await IntentDonationManager.shared.flushDonationQueue()
    }

    func testClearDonationQueue() {
        let intent = TestIntent()
        intent.testValue = "to_be_cleared"

        IntentDonationManager.shared.queueDonation(intent)
        IntentDonationManager.shared.clearDonationQueue()

        // Queue should be empty, so flushing should not throw
        Task {
            try await IntentDonationManager.shared.flushDonationQueue()
        }
    }

    func testIntentDonationBuilder() async throws {
        let builder = IntentDonationBuilder(intent: TestIntent())
            .with(keyPath: \.testValue, value: "built_value")

        let intent = builder.build()
        XCTAssertEqual(intent.testValue, "built_value")

        try await builder.donate()
    }

    func testDonationConfiguration() {
        let config = DonationConfiguration(
            isEnabled: true,
            batchSize: 20,
            delayBetweenBatches: 0.5,
            retryCount: 5
        )

        XCTAssertTrue(config.isEnabled)
        XCTAssertEqual(config.batchSize, 20)
        XCTAssertEqual(config.delayBetweenBatches, 0.5)
        XCTAssertEqual(config.retryCount, 5)
    }

    func testDonationObserver() async throws {
        class TestObserver: IntentDonationObserver {
            var willDonateCalled = false
            var didDonateCalled = false
            var donationFailedCalled = false

            func intentWillDonate(_ intent: any AppIntent) {
                willDonateCalled = true
            }

            func intentDidDonate(_ intent: any AppIntent) {
                didDonateCalled = true
            }

            func intentDonationFailed(_ intent: any AppIntent, error: Error) {
                donationFailedCalled = true
            }
        }

        let observer = TestObserver()
        DonationObserverRegistry.shared.register(observer)

        // Notify observers
        let intent = TestIntent()
        DonationObserverRegistry.shared.notifyWillDonate(intent)
        DonationObserverRegistry.shared.notifyDidDonate(intent)

        XCTAssertTrue(observer.willDonateCalled)
        XCTAssertTrue(observer.didDonateCalled)
        XCTAssertFalse(observer.donationFailedCalled)

        // Test unregister
        DonationObserverRegistry.shared.unregister(observer)
    }

    func testChunkedArray() {
        let array = Array(1...15)
        let chunked = array.chunked(into: 5)

        XCTAssertEqual(chunked.count, 3)
        XCTAssertEqual(chunked[0], [1, 2, 3, 4, 5])
        XCTAssertEqual(chunked[1], [6, 7, 8, 9, 10])
        XCTAssertEqual(chunked[2], [11, 12, 13, 14, 15])
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
