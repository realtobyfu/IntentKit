import AppIntents
import Foundation
import Foundation
import CoreData

struct SendMessageIntent: AppIntent {
    static var title: LocalizedStringResource = "Send a message to a contact"
    static var category: IntentCategory = .communication
    @available(iOS 16.0, macOS 13.0, *)

    @Parameter(title: "Message recipient")
    var recipient: String
    @Parameter(title: "Message content")
    var message: String
    @Parameter(title: "Optional attachment")
    var attachmentURL: URL?

    func perform() async throws -> some IntentResult {
        guard recipient != nil else {
            throw IntentKitError.missingParameter("recipient")
        }
        guard message != nil else {
            throw IntentKitError.missingParameter("message")
        }

        // TODO: Implement intent logic
        return .result()
    }
}

extension SendMessageIntent {
    var recipientHelper: IntentParameterHelper<String> {
        return IntentParameterHelper(
            parameter: $recipient,
            defaultValue: nil
        )
    }

    var messageHelper: IntentParameterHelper<String> {
        return IntentParameterHelper(
            parameter: $message,
            defaultValue: nil
        )
    }

    var attachmentURLHelper: IntentParameterHelper<URL> {
        return IntentParameterHelper(
            parameter: $attachmentURL,
            defaultValue: nil
        )
    }

}