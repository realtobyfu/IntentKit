import AppIntents
import CoreData
import Foundation

struct SetTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Set a timer for a specific duration"
    static var category: IntentCategory = .utilities

    @Parameter(title: "Timer duration in seconds")
    var duration: Int
    @Parameter(title: "Timer label")
    var label: String?
    @Parameter(title: "Alert sound")
    var sound: String? = "default"

    func perform() async throws -> some IntentResult {
        guard duration != nil else {
            throw IntentKitError.missingParameter("duration")
        }
        do {
            if duration < 1.0 {
                throw IntentKitError.validationFailed("duration must be at least 1.0")
            }
        }
        do {
            if duration > 86400.0 {
                throw IntentKitError.validationFailed("duration must be at most 86400.0")
            }
        }

        // MARK: - Implement your intent logic here
        return .result()
    }
}

extension SetTimerIntent {
    var durationHelper: IntentParameterHelper<Int> {
        return IntentParameterHelper(
            parameter: $duration,
            defaultValue: nil
        )
    }

    var labelHelper: IntentParameterHelper<String> {
        return IntentParameterHelper(
            parameter: $label,
            defaultValue: nil
        )
    }

    var soundHelper: IntentParameterHelper<String> {
        return IntentParameterHelper(
            parameter: $sound,
            defaultValue: "default"
        )
    }

}
