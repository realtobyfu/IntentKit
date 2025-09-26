import AppIntents
import CoreData
import Foundation

struct CreateReminderIntent: AppIntent {
    static var title: LocalizedStringResource = "Create a new reminder"
    static var category: IntentCategory = .productivity

    @Parameter(title: "Reminder title")
    var title: String
    @Parameter(title: "When the reminder is due")
    var dueDate: Date
    @Parameter(title: "Priority level")
    var priority: String? = "medium"
    @Parameter(title: "Additional notes")
    var notes: String?

    func perform() async throws -> some IntentResult {
        guard title != nil else {
            throw IntentKitError.missingParameter("title")
        }
        guard dueDate != nil else {
            throw IntentKitError.missingParameter("dueDate")
        }
        if let priority = priority {
            let allowed = ["low", "medium", "high", "urgent"]
            if !allowed.contains(priority) {
                throw IntentKitError.validationFailed("priority must be one of: \(allowed.joined(separator: ", "))")
            }
        }

        // MARK: - Implement your intent logic here
        return .result()
    }
}

extension CreateReminderIntent {
    var titleHelper: IntentParameterHelper<String> {
        return IntentParameterHelper(
            parameter: $title,
            defaultValue: nil
        )
    }

    var dueDateHelper: IntentParameterHelper<Date> {
        return IntentParameterHelper(
            parameter: $dueDate,
            defaultValue: nil
        )
    }

    var priorityHelper: IntentParameterHelper<String> {
        return IntentParameterHelper(
            parameter: $priority,
            defaultValue: "medium"
        )
    }

    var notesHelper: IntentParameterHelper<String> {
        return IntentParameterHelper(
            parameter: $notes,
            defaultValue: nil
        )
    }

}
