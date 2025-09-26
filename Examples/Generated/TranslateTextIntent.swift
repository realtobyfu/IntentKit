import AppIntents
import CoreData
import Foundation

struct TranslateTextIntent: AppIntent {
    static var title: LocalizedStringResource = "Translate text between languages"
    static var category: IntentCategory = .utilities

    @Parameter(title: "Text to translate")
    var text: String
    @Parameter(title: "Source language code")
    var sourceLanguage: String? = "auto"
    @Parameter(title: "Target language code")
    var targetLanguage: String

    func perform() async throws -> some IntentResult {
        guard text != nil else {
            throw IntentKitError.missingParameter("text")
        }
        guard targetLanguage != nil else {
            throw IntentKitError.missingParameter("targetLanguage")
        }

        // MARK: - Implement your intent logic here
        return .result()
    }
}

extension TranslateTextIntent {
    var textHelper: IntentParameterHelper<String> {
        return IntentParameterHelper(
            parameter: $text,
            defaultValue: nil
        )
    }

    var sourceLanguageHelper: IntentParameterHelper<String> {
        return IntentParameterHelper(
            parameter: $sourceLanguage,
            defaultValue: "auto"
        )
    }

    var targetLanguageHelper: IntentParameterHelper<String> {
        return IntentParameterHelper(
            parameter: $targetLanguage,
            defaultValue: nil
        )
    }

}
