import XCTest
@testable import IntentKitCodeGen

final class SchemaParserTests: XCTestCase {

    func testParseYAMLSchema() throws {
        let yamlContent = """
        version: "1.0"
        intents:
          - name: TestIntent
            description: A test intent
            parameters:
              - name: input
                type: String
                description: Input parameter
                isOptional: false
              - name: count
                type: Int
                description: Count parameter
                isOptional: true
                defaultValue: "0"
        """

        let parser = SchemaParser()
        let manifest = try parser.parse(from: yamlContent)

        XCTAssertEqual(manifest.version, "1.0")
        XCTAssertEqual(manifest.intents.count, 1)

        let intent = manifest.intents[0]
        XCTAssertEqual(intent.name, "TestIntent")
        XCTAssertEqual(intent.description, "A test intent")
        XCTAssertEqual(intent.parameters.count, 2)

        let firstParam = intent.parameters[0]
        XCTAssertEqual(firstParam.name, "input")
        XCTAssertEqual(firstParam.type, "String")
        XCTAssertFalse(firstParam.isOptional)

        let secondParam = intent.parameters[1]
        XCTAssertEqual(secondParam.name, "count")
        XCTAssertEqual(secondParam.type, "Int")
        XCTAssertTrue(secondParam.isOptional)
        XCTAssertEqual(secondParam.defaultValue, "0")
    }

    func testParseJSONSchema() throws {
        let jsonContent = """
        {
            "version": "1.0",
            "intents": [{
                "name": "JSONIntent",
                "description": "JSON test intent",
                "parameters": [{
                    "name": "value",
                    "type": "Double",
                    "description": "Value",
                    "isOptional": false
                }]
            }]
        }
        """

        guard let data = jsonContent.data(using: .utf8) else {
            XCTFail("Failed to create data")
            return
        }

        let parser = SchemaParser()
        let manifest = try parser.parseJSON(from: data)

        XCTAssertEqual(manifest.version, "1.0")
        XCTAssertEqual(manifest.intents.count, 1)
        XCTAssertEqual(manifest.intents[0].name, "JSONIntent")
    }

    func testParseWithValidation() throws {
        let yamlContent = """
        version: "1.0"
        intents:
          - name: ValidatedIntent
            description: Intent with validation
            parameters:
              - name: age
                type: Int
                description: Age parameter
                isOptional: false
                validation:
                  minValue: 0
                  maxValue: 150
              - name: email
                type: String
                description: Email parameter
                isOptional: false
                validation:
                  regex: "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$"
        """

        let parser = SchemaParser()
        let manifest = try parser.parse(from: yamlContent)

        let intent = manifest.intents[0]
        let ageParam = intent.parameters[0]
        XCTAssertNotNil(ageParam.validation)
        XCTAssertEqual(ageParam.validation?.minValue, 0)
        XCTAssertEqual(ageParam.validation?.maxValue, 150)

        let emailParam = intent.parameters[1]
        XCTAssertNotNil(emailParam.validation)
        XCTAssertEqual(emailParam.validation?.regex, "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$")
    }

    func testParseWithMetadata() throws {
        let yamlContent = """
        version: "1.0"
        metadata:
          author: "Test Author"
          bundleIdentifier: "com.test.app"
          targetName: "TestApp"
          importStatements:
            - CoreData
            - SwiftUI
        intents:
          - name: MetadataIntent
            description: Intent with metadata
            parameters: []
        """

        let parser = SchemaParser()
        let manifest = try parser.parse(from: yamlContent)

        XCTAssertNotNil(manifest.metadata)
        XCTAssertEqual(manifest.metadata?.author, "Test Author")
        XCTAssertEqual(manifest.metadata?.bundleIdentifier, "com.test.app")
        XCTAssertEqual(manifest.metadata?.targetName, "TestApp")
        XCTAssertEqual(manifest.metadata?.importStatements, ["CoreData", "SwiftUI"])
    }

    func testParseWithAvailability() throws {
        let yamlContent = """
        version: "1.0"
        intents:
          - name: AvailableIntent
            description: Intent with availability
            parameters: []
            availability:
              iOS: "16.0"
              macOS: "13.0"
              watchOS: "9.0"
        """

        let parser = SchemaParser()
        let manifest = try parser.parse(from: yamlContent)

        let intent = manifest.intents[0]
        XCTAssertNotNil(intent.availability)
        XCTAssertEqual(intent.availability?.iOS, "16.0")
        XCTAssertEqual(intent.availability?.macOS, "13.0")
        XCTAssertEqual(intent.availability?.watchOS, "9.0")
    }

    func testParseWithCategory() throws {
        let yamlContent = """
        version: "1.0"
        intents:
          - name: CategorizedIntent
            description: Intent with category
            category: media
            parameters: []
        """

        let parser = SchemaParser()
        let manifest = try parser.parse(from: yamlContent)

        let intent = manifest.intents[0]
        XCTAssertEqual(intent.category, "media")
    }

    func testParseWithReturnType() throws {
        let yamlContent = """
        version: "1.0"
        intents:
          - name: ReturningIntent
            description: Intent with return type
            parameters: []
            returnType: "some ProvidesDialog"
        """

        let parser = SchemaParser()
        let manifest = try parser.parse(from: yamlContent)

        let intent = manifest.intents[0]
        XCTAssertEqual(intent.returnType, "some ProvidesDialog")
    }

    func testParseInvalidData() {
        let invalidYaml = "This is not: valid: YAML: content:"

        let parser = SchemaParser()

        XCTAssertThrowsError(try parser.parse(from: invalidYaml))
    }

    func testParseFromFile() throws {
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_schema.yaml")

        let content = """
        version: "1.0"
        intents:
          - name: FileIntent
            description: From file
            parameters: []
        """

        try content.write(to: tempFile, atomically: true, encoding: .utf8)

        let parser = SchemaParser()
        let manifest = try parser.parse(from: tempFile)

        XCTAssertEqual(manifest.intents[0].name, "FileIntent")

        // Cleanup
        try FileManager.default.removeItem(at: tempFile)
    }
}
