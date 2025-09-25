import XCTest
@testable import IntentKitCodeGen

final class CodeGeneratorTests: XCTestCase {

    func testGenerateSimpleIntent() {
        let schema = IntentSchema(
            name: "SendMessageIntent",
            description: "Send a message",
            parameters: [
                ParameterSchema(
                    name: "recipient",
                    type: "String",
                    description: "Message recipient"
                ),
                ParameterSchema(
                    name: "message",
                    type: "String",
                    description: "Message content"
                )
            ]
        )

        let manifest = IntentManifest(intents: [schema])
        let generator = IntentCodeGenerator()
        let files = generator.generate(from: manifest)

        XCTAssertEqual(files.count, 2) // Intent file + Helpers
        XCTAssertTrue(files[0].name.contains("SendMessageIntent"))

        let code = files[0].content
        XCTAssertTrue(code.contains("struct SendMessageIntent: AppIntent"))
        XCTAssertTrue(code.contains("var recipient: String"))
        XCTAssertTrue(code.contains("var message: String"))
    }

    func testGenerateIntentWithOptionalParameters() {
        let schema = IntentSchema(
            name: "CreateNoteIntent",
            description: "Create a note",
            parameters: [
                ParameterSchema(
                    name: "title",
                    type: "String",
                    description: "Note title"
                ),
                ParameterSchema(
                    name: "tags",
                    type: "[String]",
                    description: "Optional tags",
                    isOptional: true,
                    defaultValue: "[]"
                )
            ]
        )

        let manifest = IntentManifest(intents: [schema])
        let generator = IntentCodeGenerator()
        let files = generator.generate(from: manifest)

        let code = files[0].content
        XCTAssertTrue(code.contains("var title: String"))
        XCTAssertTrue(code.contains("var tags: [String]? = []"))
    }

    func testGenerateIntentWithValidation() {
        let validation = ValidationSchema(
            minValue: 0,
            maxValue: 100,
            allowedValues: ["low", "medium", "high"]
        )

        let schema = IntentSchema(
            name: "SetPriorityIntent",
            description: "Set priority",
            parameters: [
                ParameterSchema(
                    name: "priority",
                    type: "String",
                    description: "Priority level",
                    validation: validation
                )
            ]
        )

        let manifest = IntentManifest(intents: [schema])
        let config = GeneratorConfiguration(generateValidation: true)
        let generator = IntentCodeGenerator(configuration: config)
        let files = generator.generate(from: manifest)

        let code = files[0].content
        XCTAssertTrue(code.contains("allowed.contains"))
    }

    func testGenerateHelpers() {
        let schemas = [
            IntentSchema(name: "FirstIntent", description: "First"),
            IntentSchema(name: "SecondIntent", description: "Second")
        ]

        let manifest = IntentManifest(intents: schemas)
        let generator = IntentCodeGenerator()
        let files = generator.generate(from: manifest)

        let helpersFile = files.first { $0.name == "IntentHelpers.swift" }
        XCTAssertNotNil(helpersFile)

        let helpersCode = helpersFile!.content
        XCTAssertTrue(helpersCode.contains("enum GeneratedIntents"))
        XCTAssertTrue(helpersCode.contains("static func firstintent()"))
        XCTAssertTrue(helpersCode.contains("static func secondintent()"))
    }

    func testSkipHelpers() {
        let schema = IntentSchema(name: "TestIntent", description: "Test")
        let manifest = IntentManifest(intents: [schema])

        let config = GeneratorConfiguration(generateHelpers: false)
        let generator = IntentCodeGenerator(configuration: config)
        let files = generator.generate(from: manifest)

        XCTAssertEqual(files.count, 1)
        XCTAssertFalse(files[0].name.contains("Helper"))
    }

    func testGenerateWithCategory() {
        let schema = IntentSchema(
            name: "PlayMusicIntent",
            description: "Play music",
            category: "media"
        )

        let manifest = IntentManifest(intents: [schema])
        let generator = IntentCodeGenerator()
        let files = generator.generate(from: manifest)

        let code = files[0].content
        XCTAssertTrue(code.contains("static var category: IntentCategory = .media"))
    }

    func testGenerateWithAvailability() {
        let availability = AvailabilitySchema(
            iOS: "16.0",
            macOS: "13.0"
        )

        let schema = IntentSchema(
            name: "FeatureIntent",
            description: "Feature",
            availability: availability
        )

        let manifest = IntentManifest(intents: [schema])
        let generator = IntentCodeGenerator()
        let files = generator.generate(from: manifest)

        let code = files[0].content
        XCTAssertTrue(code.contains("@available(iOS 16.0, macOS 13.0, *)"))
    }

    func testGenerateParameterExtensions() {
        let schema = IntentSchema(
            name: "ExtensionIntent",
            description: "Test extensions",
            parameters: [
                ParameterSchema(
                    name: "value",
                    type: "Int",
                    description: "Value",
                    defaultValue: "42"
                )
            ]
        )

        let manifest = IntentManifest(intents: [schema])
        let config = GeneratorConfiguration(generateParameterResolution: true)
        let generator = IntentCodeGenerator(configuration: config)
        let files = generator.generate(from: manifest)

        let code = files[0].content
        XCTAssertTrue(code.contains("extension ExtensionIntent"))
        XCTAssertTrue(code.contains("var valueHelper: IntentParameterHelper<Int>"))
    }

    func testGeneratedFileWrite() throws {
        let file = GeneratedFile(
            name: "Test.swift",
            content: "// Test content"
        )

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        try file.write(to: tempDir)

        let writtenURL = tempDir.appendingPathComponent("Test.swift")
        XCTAssertTrue(FileManager.default.fileExists(atPath: writtenURL.path))

        let content = try String(contentsOf: writtenURL)
        XCTAssertEqual(content, "// Test content")

        // Cleanup
        try FileManager.default.removeItem(at: tempDir)
    }
}