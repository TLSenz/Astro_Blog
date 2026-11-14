import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
final class ImporterModel: ObservableObject {
    static let shared = ImporterModel()

    struct Banner: Equatable {
        enum Kind: Equatable {
            case info
            case success
            case error
        }

        var kind: Kind
        var message: String
        var savedURL: URL?
    }

    private enum Keys {
        static let repoPath = "blogRepoPath"
        static let commitAndPush = "commitAndPush"
    }

    @Published var title = ""
    @Published var date = Date()
    @Published var summary = ""
    @Published var tags = ""
    @Published var source = ""
    @Published var body = ""
    @Published var customSlug = ""
    @Published var selectedFileName: String?
    @Published var banner: Banner?
    @Published var isBusy = false
    @Published var isDropTarget = false

    @Published var repoPath: String {
        didSet {
            UserDefaults.standard.set(repoPath, forKey: Keys.repoPath)
        }
    }

    @Published var commitAndPush: Bool {
        didSet {
            UserDefaults.standard.set(commitAndPush, forKey: Keys.commitAndPush)
        }
    }

    init() {
        let stored = UserDefaults.standard.string(forKey: Keys.repoPath)
        let bundled = Bundle.main.object(forInfoDictionaryKey: "DefaultBlogRepoPath") as? String
        let fallback = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Astro_Blog")
            .path

        let candidates = [stored, bundled, fallback]
            .compactMap { $0 }
            .filter { !$0.isEmpty }

        let validPath = candidates.first { path in
            FileManager.default.fileExists(
                atPath: URL(fileURLWithPath: path).appendingPathComponent("src/content").path
            )
        }

        repoPath = validPath ?? candidates.first ?? fallback
        commitAndPush = UserDefaults.standard.bool(forKey: Keys.commitAndPush)
    }

    var slug: String {
        TILNote.slugify(customSlug.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? title : customSlug)
    }

    var destinationURL: URL? {
        guard !repoPath.isEmpty, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return URL(fileURLWithPath: repoPath)
            .appendingPathComponent("src/content/learned/\(slug).md")
    }

    var relativeDestination: String {
        "src/content/learned/\(slug).md"
    }

    var repoIsValid: Bool {
        guard !repoPath.isEmpty else { return false }
        return FileManager.default.fileExists(
            atPath: URL(fileURLWithPath: repoPath).appendingPathComponent("src/content").path
        )
    }

    var canImport: Bool {
        repoIsValid
            && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isBusy
    }

    func chooseFile() {
        let panel = NSOpenPanel()
        panel.title = "Choose a Markdown file"
        panel.prompt = "Import"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            UTType(filenameExtension: "md"),
            UTType(filenameExtension: "markdown"),
            .plainText,
            .text,
        ].compactMap { $0 }

        guard panel.runModal() == .OK, let url = panel.url else { return }
        load(from: url)
    }

    func load(from url: URL) {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              !isDirectory.boolValue else {
            banner = Banner(kind: .error, message: "That is a folder, not a Markdown file.")
            return
        }

        let allowedExtensions = ["md", "markdown", "txt"]
        guard allowedExtensions.contains(url.pathExtension.lowercased()) else {
            banner = Banner(kind: .error, message: "Please choose a .md or .markdown file.")
            return
        }

        do {
            let raw: String
            if let utf8 = try? String(contentsOf: url, encoding: .utf8) {
                raw = utf8
            } else {
                raw = try String(contentsOf: url, encoding: .isoLatin1)
            }

            let withoutFrontmatter = MarkdownImport.stripFrontmatter(raw)
            let extracted = MarkdownImport.extractTitle(
                from: withoutFrontmatter,
                fallback: MarkdownImport.fallbackTitle(for: url)
            )

            title = extracted.title
            body = extracted.body
            summary = MarkdownImport.summary(from: extracted.body)
            tags = ""
            source = ""
            customSlug = ""
            date = Date()
            selectedFileName = url.lastPathComponent
            banner = nil
        } catch {
            banner = Banner(kind: .error, message: "Could not read the file: \(error.localizedDescription)")
        }
    }

    func chooseRepo() {
        let panel = NSOpenPanel()
        panel.title = "Choose your Astro blog folder"
        panel.message = "Select the root of the blog — the folder that contains src/content."
        panel.prompt = "Choose"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        if !repoPath.isEmpty {
            panel.directoryURL = URL(fileURLWithPath: repoPath)
        }

        guard panel.runModal() == .OK, let url = panel.url else { return }

        guard FileManager.default.fileExists(
            atPath: url.appendingPathComponent("src/content").path
        ) else {
            banner = Banner(
                kind: .error,
                message: "That folder doesn't look like the blog. Choose the folder that contains src/content."
            )
            return
        }

        repoPath = url.standardizedFileURL.path
        banner = Banner(kind: .success, message: "Blog folder updated.")
    }

    func save() {
        guard repoIsValid else {
            banner = Banner(kind: .error, message: "Choose a valid blog folder first.")
            return
        }
        guard let destination = destinationURL else {
            banner = Banner(kind: .error, message: "Add a title first.")
            return
        }
        guard !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            banner = Banner(kind: .error, message: "The note is empty.")
            return
        }

        var normalizedSource = source.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalizedSource.isEmpty {
            if !normalizedSource.contains("://") {
                normalizedSource = "https://" + normalizedSource
            }
            guard let parsed = URL(string: normalizedSource),
                  let scheme = parsed.scheme?.lowercased(),
                  scheme == "http" || scheme == "https",
                  parsed.host?.isEmpty == false else {
                banner = Banner(
                    kind: .error,
                    message: "Source must be a full URL, like https://example.com."
                )
                return
            }
            source = normalizedSource
        }

        let note = TILNote(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: TILNote.parseTags(tags),
            source: normalizedSource,
            body: body
        )

        if FileManager.default.fileExists(atPath: destination.path) {
            let alert = NSAlert()
            alert.messageText = "A note with this filename already exists"
            alert.informativeText = destination.lastPathComponent
            alert.addButton(withTitle: "Replace")
            alert.addButton(withTitle: "Cancel")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
        }

        do {
            try FileManager.default.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try note.markdown.write(to: destination, atomically: true, encoding: .utf8)
            banner = Banner(
                kind: .success,
                message: "Saved to \(relativeDestination)",
                savedURL: destination
            )
        } catch {
            banner = Banner(kind: .error, message: "Could not save: \(error.localizedDescription)")
            return
        }

        if commitAndPush {
            commitAndPushInBackground(noteTitle: note.title, destination: destination)
        }
    }

    private func commitAndPushInBackground(noteTitle: String, destination: URL) {
        isBusy = true
        banner = Banner(
            kind: .info,
            message: "Saved. Committing and pushing…",
            savedURL: destination
        )

        let repo = repoPath
        let relativePath = relativeDestination
        let message = "Add learned note: \(noteTitle)"

        Task { [weak self] in
            let result = await Task.detached(priority: .userInitiated) {
                Git.commitAndPush(repo: repo, relativePath: relativePath, message: message)
            }.value

            guard let self else { return }
            self.isBusy = false

            if result.ok {
                self.banner = Banner(
                    kind: .success,
                    message: "Saved, committed and pushed.",
                    savedURL: destination
                )
            } else {
                let detail = result.output.isEmpty
                    ? "git exited with an error."
                    : String(result.output.suffix(400))
                self.banner = Banner(
                    kind: .error,
                    message: "Saved, but git failed: \(detail)",
                    savedURL: destination
                )
            }
        }
    }

    func reset() {
        title = ""
        date = Date()
        summary = ""
        tags = ""
        source = ""
        body = ""
        customSlug = ""
        selectedFileName = nil
        banner = nil
    }

    func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func openRepoInFinder() {
        guard !repoPath.isEmpty else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: repoPath))
    }
}
