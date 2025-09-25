import Foundation

public enum IntentKitError: LocalizedError {
    case missingParameter(String)
    case validationFailed(String)
    case donationFailed(String)
    case executionFailed(String)
    case codeGenerationFailed(String)
    case invalidConfiguration(String)

    public var errorDescription: String? {
        switch self {
        case .missingParameter(let description):
            return "Missing required parameter: \(description)"
        case .validationFailed(let description):
            return "Validation failed: \(description)"
        case .donationFailed(let description):
            return "Intent donation failed: \(description)"
        case .executionFailed(let description):
            return "Intent execution failed: \(description)"
        case .codeGenerationFailed(let description):
            return "Code generation failed: \(description)"
        case .invalidConfiguration(let description):
            return "Invalid configuration: \(description)"
        }
    }
}