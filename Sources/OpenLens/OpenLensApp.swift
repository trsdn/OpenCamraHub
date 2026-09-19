import SwiftUI

@main
struct OpenLensApp: App {
    @StateObject private var model = AppModel()

    private static func infoURL(_ key: String) -> URL? {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String).flatMap(URL.init(string:))
    }

    var body: some Scene {
        Window("OpenCamraHub", id: "main") {
            ContentView(model: model)
                .frame(minWidth: 960, minHeight: 560)
        }
        .defaultSize(width: 1120, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) {}

            // Without this there is no Edit menu at all, and a menu item is
            // what carries the shortcut: ⌘A in a number field would do
            // nothing, so typing a value appended to it instead of replacing
            // it.
            TextEditingCommands()

            CommandMenu("Scene") {
                // Control-Option-number is deliberately not a plain number: the shortcut
                // has to survive being pressed while a text field has focus.
                ForEach(0..<9, id: \.self) { index in
                    Button("Switch to Scene \(index + 1)") {
                        model.selectScene(at: index)
                    }
                    .keyboardShortcut(
                        KeyEquivalent(Character("\(index + 1)")),
                        modifiers: [.control, .option]
                    )
                }
                Divider()
                Button("New Scene") { model.addScene() }
                    .keyboardShortcut("n", modifiers: .command)
                Button("Duplicate Scene") { model.duplicateSelectedScene() }
                    .keyboardShortcut("d", modifiers: .command)
                Button("Delete Scene") { model.removeSelectedScene() }
                Divider()
                Button("Zoom In") { model.zoomIn() }
                    .keyboardShortcut("+", modifiers: .command)
                Button("Zoom Out") { model.zoomOut() }
                    .keyboardShortcut("-", modifiers: .command)
                Button("Reset Zoom") { model.resetZoom() }
                    .keyboardShortcut("0", modifiers: .command)
            }

            CommandMenu("View") {
                Toggle("Show Preview", isOn: $model.previewEnabled)
                    .keyboardShortcut("p", modifiers: .command)
            }

            CommandGroup(after: .appInfo) {
                UpdateCommands(updates: model.updates)
                Divider()
                Button("Reinstall Camera Extension") { model.installer.activate() }
                Button("Remove Camera Extension") { model.installer.deactivate() }
            }

            // The repository and issue tracker come from Info.plist, the same
            // entries a release build carries, so the menu cannot drift from them.
            CommandGroup(replacing: .help) {
                if let url = Self.infoURL("OCHRepositoryURL") {
                    Link("OpenCamraHub on GitHub", destination: url)
                }
                if let url = Self.infoURL("OCHIssueTrackerURL") {
                    Link("Report an Issue…", destination: url)
                }
            }
        }
    }
}
