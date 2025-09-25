import Foundation
import ArgumentParser
import IntentKitCodeGen

@main
struct IntentKitCLI: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "intentkit-gen",
        abstract: "Generate App Intent code from schema files",
        version: "1.0.0",
        subcommands: [Generate.self, Validate.self]
    )
}

struct Generate: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Generate Swift code from intent schema"
    )

    @Argument(help: "Path to the schema file (YAML or JSON)")
    var schemaPath: String

    @Option(name: .shortAndLong, help: "Output directory for generated files")
    var output: String = "./Generated"

    @Flag(name: .long, help: "Skip generating helper files")
    var skipHelpers = false

    @Flag(name: .long, help: "Skip parameter resolution extensions")
    var skipResolution = false

    @Flag(name: .long, help: "Skip validation code generation")
    var skipValidation = false

    @Flag(name: .long, help: "Use JSON format instead of YAML")
    var json = false

    mutating func run() throws {
        let schemaURL = URL(fileURLWithPath: schemaPath)
        let outputURL = URL(fileURLWithPath: output)

        print("📖 Reading schema from: \(schemaPath)")

        let parser = SchemaParser()
        let manifest: IntentManifest

        if json {
            let data = try Data(contentsOf: schemaURL)
            manifest = try parser.parseJSON(from: data)
        } else {
            manifest = try parser.parse(from: schemaURL)
        }

        print("✅ Successfully parsed \(manifest.intents.count) intent(s)")

        let configuration = GeneratorConfiguration(
            generateHelpers: !skipHelpers,
            generateParameterResolution: !skipResolution,
            generateValidation: !skipValidation
        )

        let generator = IntentCodeGenerator(configuration: configuration)
        let files = generator.generate(from: manifest)

        try FileManager.default.createDirectory(
            at: outputURL,
            withIntermediateDirectories: true
        )

        for file in files {
            print("✍️  Generating: \(file.name)")
            try file.write(to: outputURL)
        }

        print("✨ Successfully generated \(files.count) file(s) in \(output)")
    }
}

struct Validate: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Validate an intent schema file"
    )

    @Argument(help: "Path to the schema file (YAML or JSON)")
    var schemaPath: String

    @Flag(name: .long, help: "Use JSON format instead of YAML")
    var json = false

    @Flag(name: .long, help: "Show detailed validation information")
    var verbose = false

    mutating func run() throws {
        let schemaURL = URL(fileURLWithPath: schemaPath)

        print("🔍 Validating schema: \(schemaPath)")

        let parser = SchemaParser()
        let manifest: IntentManifest

        do {
            if json {
                let data = try Data(contentsOf: schemaURL)
                manifest = try parser.parseJSON(from: data)
            } else {
                manifest = try parser.parse(from: schemaURL)
            }
        } catch {
            print("❌ Schema validation failed: \(error.localizedDescription)")
            throw ExitCode.failure
        }

        print("✅ Schema is valid!")
        print("   Version: \(manifest.version)")
        print("   Intents: \(manifest.intents.count)")

        if verbose {
            for intent in manifest.intents {
                print("\n   📦 \(intent.name)")
                print("      Description: \(intent.description)")
                print("      Parameters: \(intent.parameters.count)")

                for parameter in intent.parameters {
                    let optional = parameter.isOptional ? "?" : ""
                    print("         • \(parameter.name): \(parameter.type)\(optional)")
                }
            }
        }
    }
}