import AppIntents
import Foundation
import Foundation
import CoreData

struct PlayMusicIntent: AppIntent {
    static var title: LocalizedStringResource = "Play music by artist or playlist"
    static var category: IntentCategory = .media

    @Parameter(title: "Artist, song, or playlist name")
    var searchQuery: String
    @Parameter(title: "Enable shuffle")
    var shuffleMode: Bool? = false
    @Parameter(title: "Repeat mode")
    var repeatMode: String? = "off"

    func perform() async throws -> some ProvidesDialog {
        guard searchQuery != nil else {
            throw IntentKitError.missingParameter("searchQuery")
        }
        if let repeatMode = repeatMode {
            let allowed = ["off", "one", "all"]
            if !allowed.contains(repeatMode) {
                throw IntentKitError.validationFailed("repeatMode must be one of: \(allowed.joined(separator: ", "))")
            }
        }

        // TODO: Implement intent logic
        return .result()
    }
}

extension PlayMusicIntent {
    var searchQueryHelper: IntentParameterHelper<String> {
        return IntentParameterHelper(
            parameter: $searchQuery,
            defaultValue: nil
        )
    }

    var shuffleModeHelper: IntentParameterHelper<Bool> {
        return IntentParameterHelper(
            parameter: $shuffleMode,
            defaultValue: false
        )
    }

    var repeatModeHelper: IntentParameterHelper<String> {
        return IntentParameterHelper(
            parameter: $repeatMode,
            defaultValue: "off"
        )
    }

}