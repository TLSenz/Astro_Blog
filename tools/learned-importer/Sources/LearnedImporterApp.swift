import SwiftUI

@main
struct LearnedImporterApp: App {
    private let model = ImporterModel.shared

    var body: some Scene {
        WindowGroup("Learned Importer") {
            ContentView(model: model)
        }
        .defaultSize(width: 680, height: 760)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Markdown File…") {
                    model.chooseFile()
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("New Note") {
                    model.reset()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}
