import XCTest
import AppIntents
@testable import IntentKitCore

final class ParameterHelpersTests: XCTestCase {

    // Note: These tests need to be adjusted when running in an actual App Intent context
    // For now, testing the core functionality that doesn't require IntentParameter

    // IntentParameter tests removed - these require actual App Intent context

    // IntentParameter tests removed - these require actual App Intent context

    // IntentParameter tests removed - these require actual App Intent context

    func testAsyncParameterResolver() async throws {
        let resolver = AsyncParameterResolver<Int> {
            try await Task.sleep(nanoseconds: 100_000)
            return 42
        }

        let result = try await resolver.resolve()
        XCTAssertEqual(result, 42)
    }

    func testRangeValidatedParameter() throws {
        let validParameter = try RangeValidatedParameter(value: 5, range: 0...10)
        XCTAssertEqual(validParameter.value, 5)
        XCTAssertEqual(validParameter.range, 0...10)
    }

    func testRangeValidatedParameterThrowsOutOfRange() {
        XCTAssertThrowsError(try RangeValidatedParameter(value: 15, range: 0...10)) { error in
            XCTAssertTrue(error is IntentKitError)
            if case IntentKitError.validationFailed = error {
                // Expected error
            } else {
                XCTFail("Unexpected error type")
            }
        }
    }

    // IntentParameter tests removed - these require actual App Intent context

    // IntentParameter tests removed - these require actual App Intent context

    // IntentParameter tests removed - these require actual App Intent context

    func testParameterBuilderBuildEnum() {
        enum TestEnum: String, CaseIterable {
            case one = "1"
            case two = "2"
            case three = "3"
        }

        let result = ParameterBuilder.buildEnum(from: "2") as TestEnum?
        XCTAssertEqual(result, .two)

        let invalidResult = ParameterBuilder.buildEnum(from: "4") as TestEnum?
        XCTAssertNil(invalidResult)
    }

    func testParameterBuilderBuildOptional() {
        let withValue = ParameterBuilder.buildOptional(from: "test", defaultValue: "default")
        XCTAssertEqual(withValue, "test")

        let withoutValue = ParameterBuilder.buildOptional(from: nil, defaultValue: "default")
        XCTAssertEqual(withoutValue, "default")
    }

    func testParameterBuilderBuildArray() {
        let numbers = [1, 2, 3, 4, 5]

        let filtered = ParameterBuilder.buildArray(
            from: numbers,
            filter: { $0 > 2 }
        )
        XCTAssertEqual(filtered, [3, 4, 5])

        let transformed = ParameterBuilder.buildArray(
            from: numbers,
            transform: { $0 * 2 }
        )
        XCTAssertEqual(transformed, [2, 4, 6, 8, 10])

        let filteredAndTransformed = ParameterBuilder.buildArray(
            from: numbers,
            filter: { $0 % 2 == 0 },
            transform: { $0 * 3 }
        )
        XCTAssertEqual(filteredAndTransformed, [6, 12])
    }
}
