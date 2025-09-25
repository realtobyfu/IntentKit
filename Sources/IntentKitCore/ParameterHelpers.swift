import Foundation
import AppIntents

/// Protocol for types that can asynchronously resolve parameter values.
public protocol ParameterResolvable {
    associatedtype Value

    /// Asynchronously resolves and returns the parameter value.
    /// - Returns: The resolved value.
    /// - Throws: Any error that occurs during resolution.
    func resolve() async throws -> Value
}

/// A type-safe wrapper for App Intent parameters that provides convenient access methods.
///
/// Use this helper to safely extract and validate parameter values from App Intents.
/// Reduces boilerplate code by providing common parameter handling patterns.
public struct IntentParameterHelper<T: _IntentValue> {
    /// The wrapped intent parameter.
    public let parameter: IntentParameter<T>

    /// An optional default value to use as fallback.
    public let defaultValue: T?

    /// Creates a new parameter helper.
    /// - Parameters:
    ///   - parameter: The intent parameter to wrap.
    ///   - defaultValue: An optional default value.
    public init(parameter: IntentParameter<T>, defaultValue: T? = nil) {
        self.parameter = parameter
        self.defaultValue = defaultValue
    }

    /// Returns the current parameter value.
    /// - Returns: The wrapped parameter value.
    public func value() -> T {
        return parameter.wrappedValue
    }

    /// Returns the parameter value, throwing if nil.
    /// - Returns: The non-nil parameter value.
    /// - Throws: `IntentKitError.missingParameter` if the value is nil.
    public func requireValue() throws -> T {
        return parameter.wrappedValue
    }

    /// Returns the parameter value or the default if available.
    /// - Returns: The parameter value or default value.
    public func valueOrDefault() -> T {
        if let defaultValue = defaultValue {
            return defaultValue
        }
        return parameter.wrappedValue
    }
}

/// Resolves parameter values asynchronously, useful for fetching data from external sources.
///
/// Example:
/// ```swift
/// let userResolver = AsyncParameterResolver<User> {
///     try await fetchUser(id: userId)
/// }
/// let user = try await userResolver.resolve()
/// ```
public struct AsyncParameterResolver<T> {
    private let fetchClosure: () async throws -> T

    /// Creates a new async parameter resolver.
    /// - Parameter fetch: A closure that asynchronously fetches the value.
    public init(_ fetch: @escaping () async throws -> T) {
        self.fetchClosure = fetch
    }

    public func resolve() async throws -> T {
        return try await fetchClosure()
    }
}

public struct RangeValidatedParameter<T: Comparable> {
    public let value: T
    public let range: ClosedRange<T>

    public init(value: T, range: ClosedRange<T>) throws {
        guard range.contains(value) else {
            throw IntentKitError.validationFailed("Value \(value) is not in range \(range)")
        }
        self.value = value
        self.range = range
    }
}

public extension IntentParameter {
    func withHelper(defaultValue: Value? = nil) -> IntentParameterHelper<Value> {
        return IntentParameterHelper(parameter: self, defaultValue: defaultValue)
    }
}

public struct ParameterExtractor {
    public static func extract<T: _IntentValue>(
        from parameter: IntentParameter<T>,
        fallback: T? = nil,
        validator: ((T) -> Bool)? = nil
    ) throws -> T {
        let value = parameter.wrappedValue

        if let validator = validator, !validator(value) {
            throw IntentKitError.validationFailed("Validation failed for parameter")
        }

        return value
    }

    public static func extractAsync<T>(
        resolver: AsyncParameterResolver<T>
    ) async throws -> T {
        return try await resolver.resolve()
    }
}

public struct ParameterBuilder {
    public static func buildEnum<T: CaseIterable & RawRepresentable>(
        from rawValue: T.RawValue
    ) -> T? {
        return T(rawValue: rawValue)
    }

    public static func buildOptional<T>(
        from value: T?,
        defaultValue: T
    ) -> T {
        return value ?? defaultValue
    }

    public static func buildArray<T>(
        from values: [T],
        filter: ((T) -> Bool)? = nil,
        transform: ((T) -> T)? = nil
    ) -> [T] {
        var result = values

        if let filter = filter {
            result = result.filter(filter)
        }

        if let transform = transform {
            result = result.map(transform)
        }

        return result
    }
}