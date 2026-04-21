import SwiftUI
import AppKit
import A2UI
import A2UISkills
import Foundation

/// AppKit delegate — required so `swift run` opens a real window.
final class StarterDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct StarterApp: App {
    @NSApplicationDelegateAdaptor(StarterDelegate.self) var delegate
    @State private var runtime: SkillRuntime
    @State private var startupError: String?

    init() {
        do {
            let skills = [
                try Skill.parse(markdown: BundledSkills.greeting, id: "greeting"),
                try Skill.parse(markdown: BundledSkills.planner,  id: "planner"),
                try Skill.parse(markdown: BundledSkills.decider,  id: "decider"),
                try Skill.parse(markdown: BundledSkills.critic,   id: "critic"),
            ]
            let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? ""
            let llm = AnthropicLLMProvider(apiKey: apiKey)
            let rt = SkillRuntime(skills: skills, defaultSkillId: "greeting", llm: llm)
            _runtime = State(initialValue: rt)
            if apiKey.isEmpty {
                _startupError = State(initialValue:
                    "ANTHROPIC_API_KEY not set — LLM calls will fail. Set it in your env and restart.")
            }
        } catch {
            // This can't actually happen with our bundled strings, but fail
            // gracefully so `swift run` surfaces the error.
            fatalError("Failed to parse bundled SKILL.md: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup("A2UI Starter") {
            StarterChatView(startupError: startupError)
                .environment(runtime)
                .frame(minWidth: 560, minHeight: 720)
                .preferredColorScheme(.light)
                .onAppear { runtime.primeGreeting() }
        }
        .windowResizability(.contentSize)
    }
}
