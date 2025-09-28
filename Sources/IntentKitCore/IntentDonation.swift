import Foundation
import AppIntents
import Intents

/// Protocol for types that can donate intents to the system.
public protocol IntentDonatable {
    associatedtype Intent: AppIntent
    /// The intent to be donated.
    var intent: Intent { get }
}

/// Manages intent donations to the system for Siri and Shortcuts predictions.
///
/// The donation manager provides a simplified API for donating intents with
/// support for batching, queueing, and error handling.
///
/// Example:
/// ```swift
/// let intent = MyIntent()
/// try await IntentDonationManager.shared.donate(intent)
/// ```
public final class IntentDonationManager {
    /// Shared singleton instance.
    public static let shared = IntentDonationManager()

    private let donationQueue = DispatchQueue(label: "com.intentkit.donation", qos: .background)
    private var pendingDonations: [any AppIntent] = []
    private let batchSize: Int

    private init(batchSize: Int = 10) {
        self.batchSize = batchSize
    }

    /// Donates a single intent to the system.
    /// - Parameter intent: The intent to donate.
    /// - Throws: `IntentKitError.donationFailed` if donation fails.
    public func donate<T: AppIntent>(_ intent: T) async throws {
        do {
            try await intent.donate()
        } catch {
            throw IntentKitError.donationFailed("Failed to donate intent: \(error.localizedDescription)")
        }
    }

    /// Donates multiple intents in optimized batches.
    /// - Parameter intents: Array of intents to donate.
    /// - Throws: `IntentKitError.donationFailed` if any donations fail.
    public func donateBatch<T: AppIntent>(_ intents: [T]) async throws {
        var errors: [Error] = []

        for batch in intents.chunked(into: batchSize) {
            await withTaskGroup(of: Error?.self) { group in
                for intent in batch {
                    group.addTask {
                        do {
                            try await intent.donate()
                            return nil
                        } catch {
                            return error
                        }
                    }
                }

                for await error in group {
                    if let error = error {
                        errors.append(error)
                    }
                }
            }
        }

        if !errors.isEmpty {
            let errorDescriptions = errors.map { $0.localizedDescription }.joined(separator: ", ")
            throw IntentKitError.donationFailed(
                "Failed to donate \(errors.count) intents: \(errorDescriptions)"
            )
        }
    }

    public func queueDonation<T: AppIntent>(_ intent: T) {
        donationQueue.async { [weak self] in
            self?.pendingDonations.append(intent)
        }
    }

    public func flushDonationQueue() async throws {
        let donations = donationQueue.sync { [weak self] in
            let current = self?.pendingDonations ?? []
            self?.pendingDonations.removeAll()
            return current
        }

        for donation in donations {
            try await donation.donate()
        }
    }

    public func clearDonationQueue() {
        donationQueue.sync { [weak self] in
            self?.pendingDonations.removeAll()
        }
    }
}

public struct IntentDonationBuilder<T: AppIntent> {
    private var intent: T
    private var metadata: [String: Any] = [:]

    public init(intent: T) {
        self.intent = intent
    }

    public func with<Value>(keyPath: WritableKeyPath<T, Value>, value: Value) -> Self {
        var builder = self
        builder.intent[keyPath: keyPath] = value
        return builder
    }

    public func withMetadata(key: String, value: Any) -> Self {
        var builder = self
        builder.metadata[key] = value
        return builder
    }

    public func build() -> T {
        return intent
    }

    public func donate() async throws {
        try await IntentDonationManager.shared.donate(intent)
    }
}

public struct DonationConfiguration {
    public let isEnabled: Bool
    public let batchSize: Int
    public let delayBetweenBatches: TimeInterval
    public let retryCount: Int

    public init(
        isEnabled: Bool = true,
        batchSize: Int = 10,
        delayBetweenBatches: TimeInterval = 0.1,
        retryCount: Int = 3
    ) {
        self.isEnabled = isEnabled
        self.batchSize = batchSize
        self.delayBetweenBatches = delayBetweenBatches
        self.retryCount = retryCount
    }
}

public protocol IntentDonationObserver: AnyObject {
    func intentWillDonate(_ intent: any AppIntent)
    func intentDidDonate(_ intent: any AppIntent)
    func intentDonationFailed(_ intent: any AppIntent, error: Error)
}

public final class DonationObserverRegistry {
    public static let shared = DonationObserverRegistry()
    private var observers: [WeakObserverWrapper] = []

    private init() {}

    private class WeakObserverWrapper {
        weak var observer: IntentDonationObserver?

        init(_ observer: IntentDonationObserver) {
            self.observer = observer
        }
    }

    public func register(_ observer: IntentDonationObserver) {
        observers.append(WeakObserverWrapper(observer))
    }

    public func unregister(_ observer: IntentDonationObserver) {
        observers.removeAll { $0.observer === observer }
    }

    internal func notifyWillDonate(_ intent: any AppIntent) {
        observers.compactMap { $0.observer }.forEach {
            $0.intentWillDonate(intent)
        }
    }

    internal func notifyDidDonate(_ intent: any AppIntent) {
        observers.compactMap { $0.observer }.forEach {
            $0.intentDidDonate(intent)
        }
    }

    internal func notifyDonationFailed(_ intent: any AppIntent, error: Error) {
        observers.compactMap { $0.observer }.forEach {
            $0.intentDonationFailed(intent, error: error)
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
