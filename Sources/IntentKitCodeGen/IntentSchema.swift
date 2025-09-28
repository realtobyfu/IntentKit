import Foundation
import Yams

public struct IntentSchema: Codable {
    public let name: String
    public let description: String
    public let category: String?
    public let parameters: [ParameterSchema]
    public let returnType: String?
    public let availability: AvailabilitySchema?

    public init(
        name: String,
        description: String,
        category: String? = nil,
        parameters: [ParameterSchema] = [],
        returnType: String? = nil,
        availability: AvailabilitySchema? = nil
    ) {
        self.name = name
        self.description = description
        self.category = category
        self.parameters = parameters
        self.returnType = returnType
        self.availability = availability
    }
}

public struct ParameterSchema: Codable {
    public let name: String
    public let type: String
    public let description: String
    public let isOptional: Bool
    public let defaultValue: String?
    public let validation: ValidationSchema?

    public init(
        name: String,
        type: String,
        description: String,
        isOptional: Bool = false,
        defaultValue: String? = nil,
        validation: ValidationSchema? = nil
    ) {
        self.name = name
        self.type = type
        self.description = description
        self.isOptional = isOptional
        self.defaultValue = defaultValue
        self.validation = validation
    }
}

public struct ValidationSchema: Codable {
    public let minValue: Double?
    public let maxValue: Double?
    public let minLength: Int?
    public let maxLength: Int?
    public let regex: String?
    public let allowedValues: [String]?

    public init(
        minValue: Double? = nil,
        maxValue: Double? = nil,
        minLength: Int? = nil,
        maxLength: Int? = nil,
        regex: String? = nil,
        allowedValues: [String]? = nil
    ) {
        self.minValue = minValue
        self.maxValue = maxValue
        self.minLength = minLength
        self.maxLength = maxLength
        self.regex = regex
        self.allowedValues = allowedValues
    }
}

public struct AvailabilitySchema: Codable {
    public let iOS: String?
    public let macOS: String?
    public let watchOS: String?
    public let tvOS: String?

    public init(
        iOS: String? = nil,
        macOS: String? = nil,
        watchOS: String? = nil,
        tvOS: String? = nil
    ) {
        self.iOS = iOS
        self.macOS = macOS
        self.watchOS = watchOS
        self.tvOS = tvOS
    }
}

public struct IntentManifest: Codable {
    public let version: String
    public let intents: [IntentSchema]
    public let metadata: ManifestMetadata?

    public init(
        version: String = "1.0",
        intents: [IntentSchema],
        metadata: ManifestMetadata? = nil
    ) {
        self.version = version
        self.intents = intents
        self.metadata = metadata
    }
}

public struct ManifestMetadata: Codable {
    public let author: String?
    public let bundleIdentifier: String?
    public let targetName: String?
    public let importStatements: [String]?

    public init(
        author: String? = nil,
        bundleIdentifier: String? = nil,
        targetName: String? = nil,
        importStatements: [String]? = nil
    ) {
        self.author = author
        self.bundleIdentifier = bundleIdentifier
        self.targetName = targetName
        self.importStatements = importStatements
    }
}

public final class SchemaParser {
    public init() {}

    public func parse(from data: Data) throws -> IntentManifest {
        let decoder = YAMLDecoder()
        return try decoder.decode(IntentManifest.self, from: data)
    }

    public func parse(from url: URL) throws -> IntentManifest {
        let data = try Data(contentsOf: url)
        return try parse(from: data)
    }

    public func parse(from string: String) throws -> IntentManifest {
        guard let data = string.data(using: .utf8) else {
            throw CodeGenerationError.invalidInput("Invalid UTF-8 string")
        }
        return try parse(from: data)
    }

    public func parseJSON(from data: Data) throws -> IntentManifest {
        let decoder = JSONDecoder()
        return try decoder.decode(IntentManifest.self, from: data)
    }
}

public enum CodeGenerationError: LocalizedError {
    case invalidInput(String)
    case templateNotFound(String)
    case writeFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidInput(let description):
            return "Invalid input: \(description)"
        case .templateNotFound(let description):
            return "Template not found: \(description)"
        case .writeFailed(let description):
            return "Write failed: \(description)"
        }
    }
}
