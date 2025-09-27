#!/usr/bin/env swift

import Foundation
import AppIntents
import IntentKitCore

// Example 1: Simple Message Intent using IntentKit
struct MessageIntent: AppIntent {
    static var title: LocalizedStringResource = "Send Message"
    static var description = IntentDescription("Send a message to someone")

    @Parameter(title: "Recipient")
    var recipient: String

    @Parameter(title: "Message")
    var message: String

    @Parameter(title: "Urgent")
    var isUrgent: Bool

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Using IntentKit helpers for safe parameter extraction
        let recipientHelper = IntentParameterHelper(
            parameter: $recipient,
            defaultValue: "Unknown"
        )

        let messageHelper = IntentParameterHelper(
            parameter: $message,
            defaultValue: ""
        )

        let recipientName = try recipientHelper.requireValue()
        let messageText = try messageHelper.requireValue()

        // Validate message length
        let validatedMessage = try ParameterExtractor.extract(
            from: $message,
            validator: { msg in
                msg.count > 0 && msg.count <= 500
            }
        )

        // Simulate sending message
        print("📤 Sending message to \(recipientName)")
        print("   Message: \(validatedMessage)")
        print("   Urgent: \(isUrgent)")

        // Donate intent for future predictions
        Task {
            try? await IntentDonationManager.shared.donate(self)
        }

        return .result(dialog: "Message sent to \(recipientName)!")
    }
}

// Example 2: Note Creation Intent with async resolution
struct CreateNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Note"

    @Parameter(title: "Title")
    var noteTitle: String

    @Parameter(title: "Content")
    var content: String

    @Parameter(title: "Category")
    var category: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Async resolution for category validation
        let categoryResolver = AsyncParameterResolver<String> { [self] in
            // Simulate fetching valid categories from a database
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

            let validCategories = ["Personal", "Work", "Ideas", "Tasks"]

            if validCategories.contains(self.category) {
                return self.category
            } else {
                return "General" // Default category
            }
        }

        let resolvedCategory = try await categoryResolver.resolve()

        // Create note
        let note = Note(
            title: noteTitle,
            content: content,
            category: resolvedCategory,
            createdAt: Date()
        )

        print("📝 Note created:")
        print("   Title: \(note.title)")
        print("   Category: \(note.category)")
        print("   Content: \(note.content)")

        return .result(dialog: "Note '\(note.title)' created in \(note.category)")
    }
}

struct Note {
    let title: String
    let content: String
    let category: String
    let createdAt: Date
}

// Example 3: Timer Intent with validation
struct SetTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Timer"

    @Parameter(title: "Duration (seconds)")
    var duration: Int

    @Parameter(title: "Label")
    var label: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Validate duration is in acceptable range (1 second to 1 hour)
        let validatedDuration = try RangeValidatedParameter(
            value: duration,
            range: 1...3600
        )

        print("⏰ Timer set:")
        print("   Duration: \(validatedDuration.value) seconds")
        print("   Label: \(label)")

        // Simulate timer
        Task {
            try await Task.sleep(nanoseconds: UInt64(validatedDuration.value) * 1_000_000_000)
            print("⏰ Timer '\(label)' completed!")
        }

        let minutes = validatedDuration.value / 60
        let seconds = validatedDuration.value % 60

        return .result(
            dialog: "Timer '\(label)' set for \(minutes)m \(seconds)s"
        )
    }
}

// Main execution demonstrating the intents
@main
struct IntentKitExample {
    static func main() async {
        print("🚀 IntentKit Example App")
        print("=" .padding(toLength: 40, withPad: "=", startingAt: 0))

        await executeMessageIntent()
        await executeCreateNoteIntent()
        await executeTimerIntent()
        await performBatchDonation()
        showMetrics()

        print("\n✨ IntentKit Example Complete!")
    }

    private static func executeMessageIntent() async {
        print("\n📱 Executing Message Intent:")
        let messageIntent = MessageIntent()
        messageIntent.recipient = "Alice"
        messageIntent.message = "Hello from IntentKit!"
        messageIntent.isUrgent = false

        let messageExecutor = IntentExecutor(
            intent: messageIntent,
            configuration: ExecutionConfiguration(
                timeout: 5.0,
                retryCount: 2
            )
        )

        do {
            _ = try await messageExecutor.execute()
        } catch {
            print("❌ Message intent failed: \(error)")
        }
    }

    private static func executeCreateNoteIntent() async {
        print("\n📝 Executing Create Note Intent:")
        let noteIntent = CreateNoteIntent()
        noteIntent.noteTitle = "IntentKit Demo"
        noteIntent.content = "This is a demonstration of IntentKit framework"
        noteIntent.category = "Work"

        do {
            _ = try await IntentExecutor(intent: noteIntent).execute()
        } catch {
            print("❌ Note intent failed: \(error)")
        }
    }

    private static func executeTimerIntent() async {
        print("\n⏱ Executing Timer Intent:")
        let timerIntent = SetTimerIntent()
        timerIntent.duration = 5
        timerIntent.label = "Demo Timer"

        do {
            _ = try await IntentExecutor(intent: timerIntent).execute()
        } catch {
            print("❌ Timer intent failed: \(error)")
        }
    }

    private static func performBatchDonation() async {
        print("\n📤 Performing Batch Donation:")
        let messageIntent = MessageIntent()
        messageIntent.recipient = "Alice"
        messageIntent.message = "Hello from IntentKit!"
        messageIntent.isUrgent = false

        let noteIntent = CreateNoteIntent()
        noteIntent.noteTitle = "IntentKit Demo"
        noteIntent.content = "This is a demonstration of IntentKit framework"
        noteIntent.category = "Work"

        let timerIntent = SetTimerIntent()
        timerIntent.duration = 5
        timerIntent.label = "Demo Timer"

        let intents: [any AppIntent] = [
            messageIntent,
            noteIntent,
            timerIntent
        ]

        do {
            for intent in intents {
                try await IntentDonationManager.shared.donate(intent)
            }
            print("✅ Successfully donated \(intents.count) intents")
        } catch {
            print("❌ Donation failed: \(error)")
        }
    }

    private static func showMetrics() {
        print("\n📊 Execution Metrics:")
        if let avgTime = ExecutionMetrics.shared.averageExecutionTime(for: "MessageIntent") {
            print("   MessageIntent avg time: \(String(format: "%.3f", avgTime))s")
        }
        if let successRate = ExecutionMetrics.shared.successRate(for: "MessageIntent") {
            print("   MessageIntent success rate: \(String(format: "%.1f", successRate * 100))%")
        }
    }
}

extension String {
    func padding(toLength length: Int, withPad pad: String, startingAt index: Int) -> String {
        return String(repeating: pad, count: length)
    }
}
