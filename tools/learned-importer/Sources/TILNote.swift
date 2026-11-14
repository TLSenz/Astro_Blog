import Foundation

struct TILNote {
    var title: String
    var date: Date
    var summary: String
    var tags: [String]
    var source: String
    var body: String

    static func slugify(_ input: String) -> String {
        let folded = input
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789")
        var slug = ""
        var lastWasDash = false

        for scalar in folded.unicodeScalars {
            if allowed.contains(scalar) {
                slug.unicodeScalars.append(scalar)
                lastWasDash = false
            } else if !lastWasDash {
                slug.append("-")
                lastWasDash = true
            }
        }

        slug = slug.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        if slug.count > 80 {
            slug = String(slug.prefix(80)).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        }
        return slug.isEmpty ? "note" : slug
    }

    static func parseTags(_ input: String) -> [String] {
        var seen = Set<String>()
        var tags: [String] = []

        for part in input.split(separator: ",") {
            var tag = part.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            while tag.hasPrefix("#") {
                tag.removeFirst()
            }
            tag = tag.replacingOccurrences(of: " ", with: "-")
            if !tag.isEmpty, seen.insert(tag).inserted {
                tags.append(tag)
            }
        }
        return tags
    }

    var markdown: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        var lines = [
            "---",
            "title: \"\(yamlEscaped(title))\"",
            "date: \(formatter.string(from: date))",
        ]

        if !summary.isEmpty {
            lines.append("summary: \"\(yamlEscaped(summary))\"")
        }
        if !tags.isEmpty {
            lines.append("tags: [\(tags.map { "\"\(yamlEscaped($0))\"" }.joined(separator: ", "))]")
        }
        if !source.isEmpty {
            lines.append("source: \"\(yamlEscaped(source))\"")
        }
        lines.append("---")

        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        return lines.joined(separator: "\n") + "\n\n" + trimmedBody + "\n"
    }

    private func yamlEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum MarkdownImport {
    /// Removes a YAML frontmatter block so imported notes don't end up with two.
    static func stripFrontmatter(_ text: String) -> String {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        var lines = normalized.components(separatedBy: "\n")

        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
            return normalized
        }

        guard let closing = lines.dropFirst().firstIndex(where: {
            $0.trimmingCharacters(in: .whitespaces) == "---"
        }) else {
            return normalized
        }

        lines = Array(lines[(closing + 1)...])
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func fallbackTitle(for url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .capitalized
    }

    /// Uses a leading `# Heading` as the title and removes it from the body.
    static func extractTitle(from body: String, fallback: String) -> (title: String, body: String) {
        var lines = body.components(separatedBy: "\n")

        guard let index = lines.firstIndex(where: {
            !$0.trimmingCharacters(in: .whitespaces).isEmpty
        }) else {
            return (fallback, body)
        }

        let firstLine = lines[index].trimmingCharacters(in: .whitespaces)
        guard firstLine.hasPrefix("# ") else {
            return (fallback, body)
        }

        let title = String(firstLine.dropFirst(2)).trimmingCharacters(in: .whitespaces)
        lines.remove(at: index)
        while index < lines.count, lines[index].trimmingCharacters(in: .whitespaces).isEmpty {
            lines.remove(at: index)
        }

        return (title.isEmpty ? fallback : title, lines.joined(separator: "\n"))
    }

    /// Picks the first paragraph and cleans it up for use as a summary.
    static func summary(from body: String, limit: Int = 180) -> String {
        let lines = body.components(separatedBy: "\n")
        var paragraph: [String] = []
        var inFence = false

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.hasPrefix("```") {
                if paragraph.isEmpty {
                    inFence.toggle()
                    continue
                } else {
                    break
                }
            }
            if inFence { continue }

            if line.isEmpty {
                if paragraph.isEmpty { continue }
                break
            }

            if paragraph.isEmpty {
                if line.hasPrefix("#") || line == "---" || line.hasPrefix("|") {
                    continue
                }
            }

            paragraph.append(line)
        }

        var text = paragraph.joined(separator: " ")
        text = text.replacingOccurrences(
            of: #"!\[([^\]]*)\]\([^)]*\)"#,
            with: "$1",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: #"\[([^\]]+)\]\([^)]*\)"#,
            with: "$1",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: #"[`*_>#]"#,
            with: "",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespaces)

        if text.count > limit {
            let cut = text.prefix(limit)
            let shortened = cut.split(separator: " ").dropLast().joined(separator: " ")
            text = (shortened.isEmpty ? String(cut) : shortened) + "…"
        }

        return text
    }
}

enum Git {
    struct Result: Sendable {
        var ok: Bool
        var output: String
    }

    static func commitAndPush(repo: String, relativePath: String, message: String) -> Result {
        let add = run(["-C", repo, "add", "--", relativePath])
        guard add.ok else { return add }

        let commit = run(["-C", repo, "-c", "commit.gpgsign=false", "commit", "-m", message, "--", relativePath])
        guard commit.ok else { return commit }

        return run(["-C", repo, "push"])
    }

    private static func run(_ arguments: [String]) -> Result {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            return Result(ok: false, output: error.localizedDescription)
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let output = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return Result(ok: process.terminationStatus == 0, output: output)
    }
}
