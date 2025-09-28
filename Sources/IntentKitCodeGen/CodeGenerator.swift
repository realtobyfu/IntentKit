import Foundation

public final class IntentCodeGenerator {
    private let configuration: GeneratorConfiguration

    public init(configuration: GeneratorConfiguration = .default) {
        self.configuration = configuration
    }

    public func generate(from manifest: IntentManifest) -> [GeneratedFile] {
        var files: [GeneratedFile] = []

        for intent in manifest.intents {
            let intentCode = generateIntent(intent, manifest: manifest)
            files.append(GeneratedFile(
                name: "\(intent.name).swift",
                content: intentCode
            ))
        }

        if configuration.generateHelpers {
            let helpersCode = generateHelpers(manifest)
            files.append(GeneratedFile(
                name: "IntentHelpers.swift",
                content: helpersCode
            ))
        }

        return files
    }

    private func generateIntent(_ schema: IntentSchema, manifest: IntentManifest) -> String {
        var code = CodeBuilder()

        // Collect all imports and deduplicate
        var importSet = Set<String>()
        importSet.insert("AppIntents")
        importSet.insert("Foundation")

        if let imports = manifest.metadata?.importStatements {
            for importStatement in imports {
                importSet.insert(importStatement)
            }
        }

        // Add imports in consistent order
        let sortedImports = importSet.sorted()
        for importModule in sortedImports {
            code.addLine("import \(importModule)")
        }
        code.addBlankLine()

        code.addLine("struct \(schema.name): AppIntent {")
        code.indent()

        code.addLine("static var title: LocalizedStringResource = \"\(schema.description)\"")

        if let category = schema.category {
            code.addLine("static var category: IntentCategory = .\(category)")
        }

        if let availability = schema.availability {
            generateAvailability(availability, to: &code)
        }

        code.addBlankLine()

        for parameter in schema.parameters {
            generateParameter(parameter, to: &code)
        }

        if !schema.parameters.isEmpty {
            code.addBlankLine()
        }

        generatePerformMethod(schema, to: &code)

        code.outdent()
        code.addLine("}")

        if configuration.generateParameterResolution {
            code.addBlankLine()
            generateParameterExtensions(schema, to: &code)
        }

        return code.build()
    }

    private func generateParameter(_ parameter: ParameterSchema, to code: inout CodeBuilder) {
        let optionalMark = parameter.isOptional ? "?" : ""
        let defaultValue = parameter.defaultValue.map { " = \($0)" } ?? ""

        code.addLine("@Parameter(title: \"\(parameter.description)\")")
        code.addLine("var \(parameter.name): \(parameter.type)\(optionalMark)\(defaultValue)")
    }

    private func generateAvailability(_ availability: AvailabilitySchema, to code: inout CodeBuilder) {
        var conditions: [String] = []

        if let iOS = availability.iOS {
            conditions.append("iOS \(iOS)")
        }
        if let macOS = availability.macOS {
            conditions.append("macOS \(macOS)")
        }
        if let watchOS = availability.watchOS {
            conditions.append("watchOS \(watchOS)")
        }
        if let tvOS = availability.tvOS {
            conditions.append("tvOS \(tvOS)")
        }

        if !conditions.isEmpty {
            code.addLine("@available(\(conditions.joined(separator: ", ")), *)")
        }
    }

    private func generatePerformMethod(_ schema: IntentSchema, to code: inout CodeBuilder) {
        let returnType = schema.returnType ?? "some IntentResult"
        code.addLine("func perform() async throws -> \(returnType) {")
        code.indent()

        if configuration.generateValidation {
            for parameter in schema.parameters where !parameter.isOptional {
                code.addLine("guard \(parameter.name) != nil else {")
                code.indent()
                code.addLine("throw IntentKitError.missingParameter(\"\(parameter.name)\")")
                code.outdent()
                code.addLine("}")
            }

            for parameter in schema.parameters {
                if let validation = parameter.validation {
                    generateValidation(parameter, validation: validation, to: &code)
                }
            }

            if !schema.parameters.isEmpty {
                code.addBlankLine()
            }
        }

        code.addLine("// MARK: - Implement your intent logic here")
        code.addLine("return .result()")

        code.outdent()
        code.addLine("}")
    }

    private func generateValidation(
        _ parameter: ParameterSchema,
        validation: ValidationSchema,
        to code: inout CodeBuilder
    ) {
        let varName = parameter.isOptional ? "if let \(parameter.name) = \(parameter.name)" : "do"

        if let minValue = validation.minValue {
            code.addLine("\(varName) {")
            code.indent()
            code.addLine("if \(parameter.name) < \(minValue) {")
            code.indent()
            code.addLine("throw IntentKitError.validationFailed(\"\(parameter.name) must be at least \(minValue)\")")
            code.outdent()
            code.addLine("}")
            code.outdent()
            code.addLine("}")
        }

        if let maxValue = validation.maxValue {
            code.addLine("\(varName) {")
            code.indent()
            code.addLine("if \(parameter.name) > \(maxValue) {")
            code.indent()
            code.addLine("throw IntentKitError.validationFailed(\"\(parameter.name) must be at most \(maxValue)\")")
            code.outdent()
            code.addLine("}")
            code.outdent()
            code.addLine("}")
        }

        if let allowedValues = validation.allowedValues {
            let valuesString = allowedValues.map { "\"\($0)\"" }.joined(separator: ", ")
            code.addLine("\(varName) {")
            code.indent()
            code.addLine("let allowed = [\(valuesString)]")
            code.addLine("if !allowed.contains(\(parameter.name)) {")
            code.indent()
            let msg = "\(parameter.name) must be one of: \\(allowed.joined(separator: \", \"))"
            code.addLine("throw IntentKitError.validationFailed(\"\(msg)\")")
            code.outdent()
            code.addLine("}")
            code.outdent()
            code.addLine("}")
        }
    }

    private func generateParameterExtensions(_ schema: IntentSchema, to code: inout CodeBuilder) {
        code.addLine("extension \(schema.name) {")
        code.indent()

        for parameter in schema.parameters {
            code.addLine("var \(parameter.name)Helper: IntentParameterHelper<\(parameter.type)> {")
            code.indent()
            let defaultValue = parameter.defaultValue ?? "nil"
            code.addLine("return IntentParameterHelper(")
            code.indent()
            code.addLine("parameter: $\(parameter.name),")
            code.addLine("defaultValue: \(defaultValue)")
            code.outdent()
            code.addLine(")")
            code.outdent()
            code.addLine("}")
            code.addBlankLine()
        }

        code.outdent()
        code.addLine("}")
    }

    private func generateHelpers(_ manifest: IntentManifest) -> String {
        var code = CodeBuilder()

        code.addLine("import Foundation")
        code.addLine("import AppIntents")
        code.addBlankLine()

        code.addLine("enum GeneratedIntents {")
        code.indent()

        for intent in manifest.intents {
            code.addLine("static func \(intent.name.lowercased())() -> \(intent.name) {")
            code.indent()
            code.addLine("return \(intent.name)()")
            code.outdent()
            code.addLine("}")
            code.addBlankLine()
        }

        code.outdent()
        code.addLine("}")

        return code.build()
    }
}

public struct GeneratorConfiguration {
    public let generateHelpers: Bool
    public let generateParameterResolution: Bool
    public let generateValidation: Bool
    public let indentation: String

    public init(
        generateHelpers: Bool = true,
        generateParameterResolution: Bool = true,
        generateValidation: Bool = true,
        indentation: String = "    "
    ) {
        self.generateHelpers = generateHelpers
        self.generateParameterResolution = generateParameterResolution
        self.generateValidation = generateValidation
        self.indentation = indentation
    }

    public static let `default` = GeneratorConfiguration()
}

public struct GeneratedFile {
    public let name: String
    public let content: String

    public init(name: String, content: String) {
        self.name = name
        self.content = content
    }

    public func write(to directory: URL) throws {
        let fileURL = directory.appendingPathComponent(name)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}

private struct CodeBuilder {
    private var lines: [String] = []
    private var indentationLevel = 0
    private let indentString: String

    init(indentString: String = "    ") {
        self.indentString = indentString
    }

    mutating func addLine(_ line: String) {
        let indentation = String(repeating: indentString, count: indentationLevel)
        lines.append(indentation + line)
    }

    mutating func addBlankLine() {
        lines.append("")
    }

    mutating func indent() {
        indentationLevel += 1
    }

    mutating func outdent() {
        indentationLevel = max(0, indentationLevel - 1)
    }

    func build() -> String {
        // Ensure exactly one trailing newline
        return lines.joined(separator: "\n") + "\n"
    }
}
