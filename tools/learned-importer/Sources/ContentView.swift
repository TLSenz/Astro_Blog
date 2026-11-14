import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var model: ImporterModel

    private var dropTarget: Binding<Bool> {
        Binding(
            get: { model.isDropTarget },
            set: { model.isDropTarget = $0 }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            folderBar
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    filePicker

                    field("Title") {
                        TextField("What did you learn?", text: $model.title)
                            .textFieldStyle(.roundedBorder)
                            .font(.title3)
                            .controlSize(.large)
                    }

                    HStack(alignment: .top, spacing: 16) {
                        field("Date") {
                            DatePicker(
                                "",
                                selection: $model.date,
                                displayedComponents: .date
                            )
                            .labelsHidden()
                        }
                        .frame(width: 150, alignment: .leading)

                        field("Slug", hint: "optional") {
                            HStack(spacing: 2) {
                                Text("/learned/")
                                    .font(.callout.monospaced())
                                    .foregroundStyle(.tertiary)
                                TextField(model.slug, text: $model.customSlug)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.callout)
                            }
                        }
                    }

                    field("Summary", hint: "shown on the list") {
                        TextField("One short sentence about what you learned", text: $model.summary)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack(alignment: .top, spacing: 16) {
                        field("Tags", hint: "comma separated") {
                            TextField("rust, linux, css", text: $model.tags)
                                .textFieldStyle(.roundedBorder)
                        }

                        field("Source", hint: "optional URL") {
                            TextField("https://…", text: $model.source)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            fieldLabel("Markdown")
                            Spacer()
                            Text("\(wordCount) words")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        TextEditor(text: $model.body)
                            .font(.system(size: 13, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .frame(height: 240)
                            .background(Color(nsColor: .textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(Color(nsColor: .separatorColor))
                            )
                            .overlay(alignment: .topLeading) {
                                if model.body.isEmpty {
                                    Text("Paste or write Markdown here…")
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundStyle(.tertiary)
                                        .padding(.horizontal, 13)
                                        .padding(.vertical, 12)
                                        .allowsHitTesting(false)
                                }
                            }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        fieldLabel("Destination")
                        HStack(spacing: 6) {
                            Image(systemName: "doc.text")
                                .foregroundStyle(.secondary)
                            Text(model.relativeDestination)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color(nsColor: .controlBackgroundColor))
                        )
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Toggle("Commit and push after saving", isOn: $model.commitAndPush)
                            .toggleStyle(.checkbox)
                        Text("Stages this note, commits it and pushes the current branch.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .padding(.leading, 20)
                    }
                }
                .padding(20)
            }
            Divider()
            footer
        }
        .frame(minWidth: 600, minHeight: 560)
        .onDrop(of: [.fileURL], isTargeted: dropTarget) { providers in
            handleDrop(providers)
        }
    }

    private var wordCount: Int {
        model.body.split(whereSeparator: { $0.isWhitespace }).count
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text("Learned Importer")
                    .font(.title2.bold())
                Text("Turn a Markdown file into a note under Things I Learned.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private var folderBar: some View {
        HStack(spacing: 8) {
            Image(systemName: model.repoIsValid ? "folder" : "exclamationmark.triangle.fill")
                .foregroundStyle(model.repoIsValid ? Color.secondary : Color.orange)
            Text(model.repoIsValid ? model.repoPath : "Blog folder not found — choose it")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(model.repoPath)

            Spacer(minLength: 8)

            if model.repoIsValid {
                Button("Open") {
                    model.openRepoInFinder()
                }
                .buttonStyle(.link)
                .font(.caption)
            }

            Button("Change…") {
                model.chooseRepo()
            }
            .controlSize(.small)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var filePicker: some View {
        Button {
            model.chooseFile()
        } label: {
            VStack(spacing: 7) {
                Image(systemName: model.selectedFileName == nil ? "arrow.down.doc" : "checkmark.circle.fill")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(model.selectedFileName == nil ? Color.secondary : Color.green)

                if let name = model.selectedFileName {
                    Text(name)
                        .font(.headline)
                    Text("Markdown loaded — drop another file or click to replace.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Drop a Markdown file here")
                        .font(.headline)
                    Text("or click to choose a .md file")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(model.isDropTarget ? Color.accentColor.opacity(0.12) : Color(nsColor: .textBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        model.isDropTarget ? Color.accentColor : Color(nsColor: .separatorColor),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: model.isDropTarget)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            bannerView

            Spacer(minLength: 8)

            if let savedURL = model.banner?.savedURL {
                Button("Reveal") {
                    model.reveal(savedURL)
                }
            }

            Button("New") {
                model.reset()
            }
            .disabled(
                model.isBusy
                    || (model.title.isEmpty && model.body.isEmpty && model.selectedFileName == nil)
            )

            Button {
                model.save()
            } label: {
                HStack(spacing: 6) {
                    if model.isBusy {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(model.isBusy ? "Working…" : "Import Note")
                }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return, modifiers: [.command])
            .disabled(!model.canImport)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private var bannerView: some View {
        if let banner = model.banner {
            HStack(alignment: .top, spacing: 7) {
                Image(systemName: bannerIcon(banner.kind))
                    .foregroundStyle(bannerColor(banner.kind))
                Text(banner.message)
                    .font(.callout)
                    .foregroundStyle(bannerColor(banner.kind))
                    .lineLimit(2)
                    .help(banner.message)
            }
        } else {
            Text("Ready when you are.")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
    }

    private func bannerIcon(_ kind: ImporterModel.Banner.Kind) -> String {
        switch kind {
        case .info: return "info.circle"
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    private func bannerColor(_ kind: ImporterModel.Banner.Kind) -> Color {
        switch kind {
        case .info: return .secondary
        case .success: return .green
        case .error: return .red
        }
    }

    private func fieldLabel(_ text: String, hint: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(text)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            Spacer()
            if let hint {
                Text(hint)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func field<Content: View>(
        _ label: String,
        hint: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(label, hint: hint)
            content()
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(
            where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }
        ) else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            var url: URL?
            if let data = item as? Data {
                url = URL(dataRepresentation: data, relativeTo: nil)
            } else if let itemURL = item as? URL {
                url = itemURL
            }

            if let url {
                DispatchQueue.main.async {
                    model.load(from: url)
                }
            }
        }

        return true
    }
}
